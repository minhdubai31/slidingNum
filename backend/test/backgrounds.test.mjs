import { test } from 'node:test';
import assert from 'node:assert/strict';
import { BACKGROUND_SLOTS, backgroundsFromObjects, listBackgrounds, replaceBackground, resetBackground, validateSlot } from '../lib/backgrounds.js';
import handler from '../api/admin/backgrounds/[slot].js';

const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const publicUrl = (path) => `https://storage.example/${path}`;
const object = (name) => ({ id: name, name, metadata: { size: 123 } });
function storageFixture(names = []) {
  const files = new Map(names.map((name) => [name, object(name)]));
  const calls = [];
  return {
    files, calls,
    getPublicUrl: (path) => ({ data: { publicUrl: publicUrl(path) } }),
    async list(folder, { offset, limit }) {
      calls.push(['list', folder]);
      return { data: [...files.values()].sort((a, b) => a.name.localeCompare(b.name)).slice(offset, offset + limit), error: null };
    },
    async upload(path, buffer, options) {
      calls.push(['upload', path, options]);
      files.set(path.split('/')[1], object(path.split('/')[1]));
      return { error: null };
    },
    async remove(paths) {
      calls.push(['remove', paths]);
      for (const path of paths) files.delete(path.split('/')[1]);
      return { error: null };
    },
  };
}

test('background slots cover Home, shared game, and all eight app themes', () => {
  assert.equal(BACKGROUND_SLOTS.length, 10);
  for (const slot of BACKGROUND_SLOTS) assert.equal(validateSlot(slot), slot);
  for (const slot of ['theme-8', 'theme--1', '../home', '', undefined]) assert.throws(() => validateSlot(slot), { status: 400 });
});

test('background configuration picks newest immutable URL and preserves defaults', () => {
  const config = backgroundsFromObjects([
    object('home--1000-old.png'), object('home--2000-new.webp'), object('theme-3--1000-marble.jpg'),
    object('unknown--1000.png'), { name: 'home--3000-folder', id: null },
  ], publicUrl);
  assert.equal(config.home.url, publicUrl('_backgrounds/home--2000-new.webp'));
  assert.equal(config.game, null);
  assert.equal(config.themes['3'].bytes, 123);
  assert.equal(config.themes['0'], null);
  assert.equal(Object.keys(config.themes).length, 8);
});

test('upload replaces only the selected slot, reset restores inheritance', async () => {
  const storage = storageFixture(['home--1000-old.png', 'game--1000-shared.png', 'theme-2--1000-ceramic.png']);
  const background = await replaceBackground('home', png, storage);
  assert.match(background.url, /_backgrounds\/home--\d+-[\w-]+\.png$/);
  assert.equal(storage.files.has('home--1000-old.png'), false);
  assert.equal(storage.files.has('game--1000-shared.png'), true);
  assert.equal(storage.calls.findIndex(([op]) => op === 'upload') < storage.calls.findIndex(([op]) => op === 'remove'), true);
  await resetBackground('theme-2', storage);
  const config = await listBackgrounds(storage);
  assert.equal(config.themes['2'], null);
  assert.ok(config.game);
  assert.equal(config.home.url, background.url);
});

test('list handles pagination and failed uploads preserve previous background', async () => {
  const storage = storageFixture(Array.from({ length: 101 }, (_, i) => `home--${String(i).padStart(4, '0')}.png`));
  assert.ok((await listBackgrounds(storage)).home.url.endsWith('home--0100.png'));
  assert.equal(storage.calls.filter(([op]) => op === 'list').length, 2);
  storage.upload = async () => ({ error: new Error('Upload failed') });
  await assert.rejects(replaceBackground('home', png, storage), /Upload failed/);
  assert.equal(storage.files.size, 101);
});

test('invalid image data and oversized uploads cannot alter storage', async () => {
  const storage = storageFixture();
  await assert.rejects(replaceBackground('home', Buffer.from('not an image'), storage), { status: 415 });
  await assert.rejects(replaceBackground('game', Buffer.alloc(4 * 1024 * 1024 + 1), storage), { status: 413 });
  assert.deepEqual(storage.calls, []);
});

test('background write routes require admin authentication before accessing storage', async () => {
  const previous = process.env.ADMIN_TOKEN;
  process.env.ADMIN_TOKEN = 'test-background-admin-token';
  try {
    for (const method of ['PUT', 'DELETE']) {
      const res = { setHeader() {}, end(body) { this.body = body; } };
      await handler({ method, headers: {}, query: { slot: 'home' } }, res);
      assert.equal(res.statusCode, 401);
    }
  } finally {
    if (previous === undefined) delete process.env.ADMIN_TOKEN;
    else process.env.ADMIN_TOKEN = previous;
  }
});
