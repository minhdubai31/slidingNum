import { randomUUID } from 'node:crypto';
import { db, BUCKET } from './supabase.js';
import { HttpError } from './http.js';
import { sniffImage, MAX_IMAGE_BYTES, validateId, validateName, validatePosition } from './validate.js';

const TOPIC_COLUMNS = 'id,name,position,active,updated_at';
const PICTURE_COLUMNS = 'id,topic_id,position,active,storage_path,bytes,updated_at';
// Image files never change once written (each upload gets a new path), so they can be cached forever.
const IMAGE_CACHE_CONTROL = '31536000';

function publicUrl(path) {
  return db().storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
}

function toPicture(row) {
  return {
    id: row.id,
    topic_id: row.topic_id,
    position: row.position,
    active: row.active,
    url: publicUrl(row.storage_path),
    bytes: row.bytes,
    updated_at: row.updated_at,
  };
}

function toTopic(row, pictures = []) {
  return {
    id: row.id,
    name: row.name,
    position: row.position,
    active: row.active,
    updated_at: row.updated_at,
    pictures,
  };
}

// Returns every topic with its pictures in display order. With activeOnly, hidden topics and pictures are dropped.
export async function listTopics({ activeOnly }) {
  let topicQuery = db().from('topics').select(TOPIC_COLUMNS).order('position').order('created_at');
  if (activeOnly) topicQuery = topicQuery.eq('active', true);
  const { data: topics, error: topicError } = await topicQuery;
  if (topicError) throw topicError;

  let pictureQuery = db().from('pictures').select(PICTURE_COLUMNS).order('position').order('created_at');
  if (activeOnly) pictureQuery = pictureQuery.eq('active', true);
  const { data: pictures, error: pictureError } = await pictureQuery;
  if (pictureError) throw pictureError;

  const byTopic = new Map();
  for (const row of pictures) {
    const list = byTopic.get(row.topic_id) ?? [];
    list.push(toPicture(row));
    byTopic.set(row.topic_id, list);
  }
  return topics.map((topic) => toTopic(topic, byTopic.get(topic.id) ?? []));
}

async function nextPosition(table, filter) {
  let query = db().from(table).select('position').order('position', { ascending: false }).limit(1);
  if (filter) query = query.eq(filter.column, filter.value);
  const { data, error } = await query;
  if (error) throw error;
  return data.length ? data[0].position + 1 : 0;
}

async function findTopic(id) {
  const { data, error } = await db().from('topics').select(TOPIC_COLUMNS).eq('id', id).maybeSingle();
  if (error) throw error;
  if (!data) throw new HttpError(404, 'Topic not found');
  return data;
}

async function findPicture(id) {
  const { data, error } = await db().from('pictures').select(PICTURE_COLUMNS).eq('id', id).maybeSingle();
  if (error) throw error;
  if (!data) throw new HttpError(404, 'Picture not found');
  return data;
}

export async function createTopic({ name, position }) {
  const { data, error } = await db()
    .from('topics')
    .insert({
      name: validateName(name),
      position: position === undefined ? await nextPosition('topics') : validatePosition(position),
    })
    .select(TOPIC_COLUMNS)
    .single();
  if (error) throw error;
  return toTopic(data);
}

export async function updateTopic(id, body) {
  await findTopic(id);
  const patch = { updated_at: new Date().toISOString() };
  if (body.name !== undefined) patch.name = validateName(body.name);
  if (body.position !== undefined) patch.position = validatePosition(body.position);
  if (body.active !== undefined) {
    if (typeof body.active !== 'boolean') throw new HttpError(400, 'active must be true or false');
    patch.active = body.active;
  }
  const { data, error } = await db().from('topics').update(patch).eq('id', id).select(TOPIC_COLUMNS).single();
  if (error) throw error;
  return toTopic(data);
}

// Deleting a topic cascades to its pictures in the database; the image files are removed here.
export async function deleteTopic(id) {
  await findTopic(id);
  const { data: files, error: listError } = await db().from('pictures').select('storage_path').eq('topic_id', id);
  if (listError) throw listError;
  const { error } = await db().from('topics').delete().eq('id', id);
  if (error) throw error;
  await removeObjects(files.map((f) => f.storage_path));
}

function storagePath(id, ext) {
  return `${id}/${Date.now()}.${ext}`;
}

async function uploadObject(path, buffer, contentType) {
  const { error } = await db().storage.from(BUCKET).upload(path, buffer, {
    contentType,
    cacheControl: IMAGE_CACHE_CONTROL,
    upsert: false,
  });
  if (error) throw error;
}

async function removeObjects(paths) {
  if (paths.length === 0) return;
  const { error } = await db().storage.from(BUCKET).remove(paths);
  if (error) console.error('Failed to remove storage objects', paths, error);
}

function requireImage(buffer) {
  if (buffer.length > MAX_IMAGE_BYTES) throw new HttpError(413, 'Image is larger than 4 MB');
  const image = sniffImage(buffer);
  if (!image) throw new HttpError(415, 'Upload must be a PNG, JPEG or WebP image');
  return image;
}

export async function createPicture({ topicId, buffer, position }) {
  validateId(topicId);
  await findTopic(topicId);
  const image = requireImage(buffer);
  const id = randomUUID();
  const path = storagePath(id, image.ext);
  await uploadObject(path, buffer, image.contentType);

  const { data, error } = await db()
    .from('pictures')
    .insert({
      id,
      topic_id: topicId,
      position: position === undefined ? await nextPosition('pictures', { column: 'topic_id', value: topicId }) : validatePosition(position),
      storage_path: path,
      content_type: image.contentType,
      bytes: buffer.length,
    })
    .select(PICTURE_COLUMNS)
    .single();
  if (error) {
    await removeObjects([path]);
    throw error;
  }
  return toPicture(data);
}

// Replaces the image bytes. The new file gets a new path, so the public URL changes and
// clients that cache by URL pick it up immediately.
export async function replacePicture(id, buffer) {
  const current = await findPicture(id);
  const image = requireImage(buffer);
  const path = storagePath(id, image.ext);
  await uploadObject(path, buffer, image.contentType);

  const { data, error } = await db()
    .from('pictures')
    .update({
      storage_path: path,
      content_type: image.contentType,
      bytes: buffer.length,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id)
    .select(PICTURE_COLUMNS)
    .single();
  if (error) {
    await removeObjects([path]);
    throw error;
  }
  await removeObjects([current.storage_path]);
  return toPicture(data);
}

// Updates position, visibility, or moves the picture to another topic.
export async function updatePicture(id, body) {
  await findPicture(id);
  const patch = { updated_at: new Date().toISOString() };
  if (body.position !== undefined) patch.position = validatePosition(body.position);
  if (body.active !== undefined) {
    if (typeof body.active !== 'boolean') throw new HttpError(400, 'active must be true or false');
    patch.active = body.active;
  }
  if (body.topic_id !== undefined) {
    patch.topic_id = validateId(body.topic_id);
    await findTopic(patch.topic_id);
  }
  const { data, error } = await db().from('pictures').update(patch).eq('id', id).select(PICTURE_COLUMNS).single();
  if (error) throw error;
  return toPicture(data);
}

export async function deletePicture(id) {
  const current = await findPicture(id);
  const { error } = await db().from('pictures').delete().eq('id', id);
  if (error) throw error;
  await removeObjects([current.storage_path]);
}
