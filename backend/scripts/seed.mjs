// Creates the six bundled game topics, each with its matching picture, so the catalogue starts with the same content as the app.
// Run from backend/: node --env-file=.env scripts/seed.mjs [--force]
import { readFile } from 'node:fs/promises';
import { db } from '../lib/supabase.js';
import { createPicture, createTopic } from '../lib/catalogue.js';

const ASSETS = new URL('../../assets/', import.meta.url);
const SEED = [
  ['alpine.png', 'Thiên nhiên'],
  ['kitten-soft.png', 'Thú cưng'],
  ['seaside.png', 'Du lịch'],
  ['oasis.png', 'Sa mạc'],
  ['flowers.png', 'Hoa lá'],
  ['cosmos.png', 'Vũ trụ'],
];

const force = process.argv.includes('--force');

const { count, error } = await db().from('topics').select('id', { count: 'exact', head: true });
if (error) throw error;
if (count > 0 && !force) {
  console.log(`topics already has ${count} rows; pass --force to add the seed topics anyway`);
  process.exit(0);
}

for (const [position, [file, name]] of SEED.entries()) {
  const topic = await createTopic({ name, position });
  const buffer = await readFile(new URL(file, ASSETS));
  const picture = await createPicture({ topicId: topic.id, buffer, position: 0 });
  console.log(`${name}: topic ${topic.id}, picture ${picture.url}`);
}
