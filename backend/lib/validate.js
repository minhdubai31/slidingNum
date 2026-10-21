import { HttpError } from './http.js';

export const MAX_IMAGE_BYTES = 4 * 1024 * 1024;
export const MAX_POSITION = 9999;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Identifies PNG, JPEG and WebP by their magic bytes, ignoring whatever Content-Type the client sent.
export function sniffImage(buf) {
  if (buf.length >= 8 && buf.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return { contentType: 'image/png', ext: 'png' };
  }
  if (buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) {
    return { contentType: 'image/jpeg', ext: 'jpg' };
  }
  if (buf.length >= 12 && buf.subarray(0, 4).toString('ascii') === 'RIFF' && buf.subarray(8, 12).toString('ascii') === 'WEBP') {
    return { contentType: 'image/webp', ext: 'webp' };
  }
  return null;
}

export function validateName(value) {
  const name = typeof value === 'string' ? value.trim() : '';
  if (name.length < 1 || name.length > 40) throw new HttpError(400, 'name must be 1-40 characters');
  return name;
}

export function validatePosition(value) {
  const position = Number(value);
  if (!Number.isInteger(position) || position < 0 || position > MAX_POSITION) {
    throw new HttpError(400, `position must be an integer 0-${MAX_POSITION}`);
  }
  return position;
}

export function validateId(value) {
  if (typeof value !== 'string' || !UUID.test(value)) throw new HttpError(400, 'id must be a UUID');
  return value;
}
