import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sniffImage, validateName, validatePosition, validateId } from '../lib/validate.js';

test('sniffImage recognises PNG, JPEG and WebP by magic bytes', () => {
  const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  const webp = Buffer.concat([Buffer.from('RIFF'), Buffer.from([0, 0, 0, 0]), Buffer.from('WEBP')]);
  assert.deepEqual(sniffImage(png), { contentType: 'image/png', ext: 'png' });
  assert.deepEqual(sniffImage(jpeg), { contentType: 'image/jpeg', ext: 'jpg' });
  assert.deepEqual(sniffImage(webp), { contentType: 'image/webp', ext: 'webp' });
});

test('sniffImage rejects other content, including a renamed file', () => {
  assert.equal(sniffImage(Buffer.from('<html>not an image</html>')), null);
  assert.equal(sniffImage(Buffer.alloc(0)), null);
  assert.equal(sniffImage(Buffer.from('GIF89a')), null);
});

test('validateName trims and enforces 1-40 characters', () => {
  assert.equal(validateName('  Vũ trụ  '), 'Vũ trụ');
  assert.throws(() => validateName('   '), /1-40/);
  assert.throws(() => validateName(undefined), /1-40/);
  assert.throws(() => validateName('x'.repeat(41)), /1-40/);
});

test('validatePosition accepts integers 0-9999 only', () => {
  assert.equal(validatePosition('3'), 3);
  assert.throws(() => validatePosition(-1), /position/);
  assert.throws(() => validatePosition(10000), /position/);
  assert.throws(() => validatePosition(1.5), /position/);
});

test('validateId requires a UUID', () => {
  assert.equal(validateId('2f1c9a52-7a1e-4f0e-9b7e-1d2c3b4a5f60'), '2f1c9a52-7a1e-4f0e-9b7e-1d2c3b4a5f60');
  assert.throws(() => validateId('../../etc/passwd'), /UUID/);
});
