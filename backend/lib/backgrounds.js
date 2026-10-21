import { randomUUID } from 'node:crypto';
import { db, BUCKET } from './supabase.js';
import { HttpError } from './http.js';
import { MAX_IMAGE_BYTES, sniffImage } from './validate.js';

// Reuse the existing image bucket; no database migration or new public write policy is needed.
const FOLDER = '_backgrounds';
export const BACKGROUND_SLOTS = ['home', 'game', ...Array.from({ length: 8 }, (_, i) => `theme-${i}`)];

export function validateSlot(slot) {
  if (!BACKGROUND_SLOTS.includes(slot)) throw new HttpError(400, 'Unknown background slot');
  return slot;
}

async function objects(storage) {
  const all = [];
  for (let offset = 0; ; offset += 100) {
    const { data, error } = await storage.list(FOLDER, { limit: 100, offset, sortBy: { column: 'name', order: 'asc' } });
    if (error) throw error;
    all.push(...data);
    if (data.length < 100) return all;
  }
}

// Exported separately so ordering and fallback data can be tested without a live bucket.
export function backgroundsFromObjects(files, publicUrl) {
  const slots = {};
  for (const file of [...files].sort((a, b) => b.name.localeCompare(a.name))) {
    const slot = file.name.split('--')[0];
    if (!BACKGROUND_SLOTS.includes(slot) || slots[slot] || !file.id) continue;
    slots[slot] = { url: publicUrl(`${FOLDER}/${file.name}`), bytes: file.metadata?.size ?? 0 };
  }
  return {
    home: slots.home ?? null,
    game: slots.game ?? null,
    themes: Object.fromEntries(Array.from({ length: 8 }, (_, i) => [String(i), slots[`theme-${i}`] ?? null])),
  };
}

export async function listBackgrounds(storage = db().storage.from(BUCKET)) {
  return backgroundsFromObjects(await objects(storage), (path) => storage.getPublicUrl(path).data.publicUrl);
}

export async function replaceBackground(slot, buffer, storage = db().storage.from(BUCKET)) {
  validateSlot(slot);
  if (buffer.length > MAX_IMAGE_BYTES) throw new HttpError(413, 'Image is larger than 4 MB');
  const image = sniffImage(buffer);
  if (!image) throw new HttpError(415, 'Upload must be a PNG, JPEG or WebP image');
  const previous = (await objects(storage)).filter((file) => file.name.startsWith(`${slot}--`));
  const path = `${FOLDER}/${slot}--${Date.now()}-${randomUUID()}.${image.ext}`;
  const { error } = await storage.upload(path, buffer, { contentType: image.contentType, cacheControl: '31536000', upsert: false });
  if (error) throw error;
  // Only remove the files observed before this upload, so concurrent uploads cannot delete each other.
  if (previous.length) {
    const { error: cleanupError } = await storage.remove(previous.map((file) => `${FOLDER}/${file.name}`));
    if (cleanupError) console.error('Background cleanup failed', cleanupError);
  }
  return { url: storage.getPublicUrl(path).data.publicUrl, bytes: buffer.length };
}

export async function resetBackground(slot, storage = db().storage.from(BUCKET)) {
  validateSlot(slot);
  const paths = (await objects(storage)).filter((file) => file.name.startsWith(`${slot}--`)).map((file) => `${FOLDER}/${file.name}`);
  if (!paths.length) return;
  const { error } = await storage.remove(paths);
  if (error) throw error;
}
