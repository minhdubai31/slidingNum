import { allow, handle, jsonBody, readBody, requireAdmin, send } from '../../../lib/http.js';
import { deletePicture, replacePicture, updatePicture } from '../../../lib/catalogue.js';
import { MAX_IMAGE_BYTES, validateId } from '../../../lib/validate.js';

// PUT    /api/admin/pictures/:id   body = raw image bytes, replaces the file
// PATCH  /api/admin/pictures/:id   JSON { "position"?, "active"?, "topic_id"? } (topic_id moves it)
// DELETE /api/admin/pictures/:id
export default handle(async (req, res) => {
  if (!allow(req, res, ['PUT', 'PATCH', 'DELETE'])) return;
  if (!requireAdmin(req, res)) return;
  const id = validateId(req.query.id);

  if (req.method === 'PUT') {
    const buffer = await readBody(req, MAX_IMAGE_BYTES);
    send(res, 200, { picture: await replacePicture(id, buffer) });
    return;
  }

  if (req.method === 'PATCH') {
    send(res, 200, { picture: await updatePicture(id, jsonBody(req)) });
    return;
  }

  await deletePicture(id);
  res.statusCode = 204;
  res.end();
});
