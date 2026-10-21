import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { allow, handle, HttpError, jsonBody, readBody, requireAdmin } from '../lib/http.js';

function response() {
  return { headers: {}, setHeader(key, value) { this.headers[key] = value; }, end(body) { this.body = body; } };
}

test('admin authentication accepts only the configured Bearer token', () => {
  const original = process.env.ADMIN_TOKEN;
  try {
    process.env.ADMIN_TOKEN = 'test-only-admin-token';
    for (const authorization of ['', 'Bearer wrong', 'Basic test-only-admin-token']) {
      const res = response();
      assert.equal(requireAdmin({ headers: { authorization } }, res), false);
      assert.equal(res.statusCode, 401);
    }
    assert.equal(requireAdmin({ headers: { authorization: 'Bearer test-only-admin-token' } }, response()), true);
    delete process.env.ADMIN_TOKEN;
    const res = response();
    assert.equal(requireAdmin({ headers: {} }, res), false);
    assert.equal(res.statusCode, 500);
  } finally {
    if (original === undefined) delete process.env.ADMIN_TOKEN;
    else process.env.ADMIN_TOKEN = original;
  }
});

test('method and JSON validation reject invalid requests', () => {
  const res = response();
  assert.equal(allow({ method: 'POST' }, res, ['GET']), false);
  assert.equal(res.statusCode, 405);
  assert.equal(res.headers.Allow, 'GET');
  for (const body of [undefined, null, [], 'text']) assert.throws(() => jsonBody({ body }), HttpError);
  assert.deepEqual(jsonBody({ body: { name: 'Topic' } }), { name: 'Topic' });
});

test('raw upload enforces declared and streamed size limits', async () => {
  const request = (parts, headers = {}) => Object.assign(Readable.from(parts), { headers });
  assert.deepEqual(await readBody(request([Buffer.from('abc')]), 3), Buffer.from('abc'));
  await assert.rejects(readBody(request([], { 'content-length': '4' }), 3), { status: 413 });
  await assert.rejects(readBody(request([Buffer.from('ab'), Buffer.from('cd')]), 3), { status: 413 });
});

test('handler returns validation failures as JSON', async () => {
  const res = response();
  await handle(async () => { throw new HttpError(400, 'Invalid input'); })({}, res);
  assert.equal(res.statusCode, 400);
  assert.deepEqual(JSON.parse(res.body), { error: 'Invalid input' });
});
