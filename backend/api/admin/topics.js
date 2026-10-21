import { allow, handle, jsonBody, requireAdmin, send } from '../../lib/http.js';
import { createTopic, listTopics } from '../../lib/catalogue.js';

// GET  /api/admin/topics                 every topic with every picture, including hidden ones
// POST /api/admin/topics                 JSON { "name", "position"? }
export default handle(async (req, res) => {
  if (!allow(req, res, ['GET', 'POST'])) return;
  if (!requireAdmin(req, res)) return;

  if (req.method === 'GET') {
    send(res, 200, { topics: await listTopics({ activeOnly: false }) });
    return;
  }
  const topic = await createTopic(jsonBody(req));
  send(res, 201, { topic });
});
