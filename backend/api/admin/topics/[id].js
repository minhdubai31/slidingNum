import { allow, handle, jsonBody, requireAdmin, send } from '../../../lib/http.js';
import { deleteTopic, updateTopic } from '../../../lib/catalogue.js';
import { validateId } from '../../../lib/validate.js';

// PATCH  /api/admin/topics/:id   JSON { "name"?, "position"?, "active"? }
// DELETE /api/admin/topics/:id   removes the topic and all its pictures
export default handle(async (req, res) => {
  if (!allow(req, res, ['PATCH', 'DELETE'])) return;
  if (!requireAdmin(req, res)) return;
  const id = validateId(req.query.id);

  if (req.method === 'PATCH') {
    send(res, 200, { topic: await updateTopic(id, jsonBody(req)) });
    return;
  }

  await deleteTopic(id);
  res.statusCode = 204;
  res.end();
});
