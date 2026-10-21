import { createHash } from 'node:crypto';
import { allow, handle, send } from '../lib/http.js';
import { listTopics } from '../lib/catalogue.js';

// Public catalogue for the game: visible topics that contain at least one visible picture.
// "version" changes whenever anything in the list changes, so the client only compares it
// to decide whether to re-download images.
export default handle(async (req, res) => {
  if (!allow(req, res, ['GET'])) return;
  const topics = (await listTopics({ activeOnly: true }))
    .filter((topic) => topic.pictures.length > 0)
    .map(({ active, ...topic }) => ({ ...topic, pictures: topic.pictures.map(({ active, ...picture }) => picture) }));
  const version = createHash('sha1').update(JSON.stringify(topics)).digest('hex').slice(0, 16);
  res.setHeader('Cache-Control', 'no-store');
  send(res, 200, { version, topics });
});
