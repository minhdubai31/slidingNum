import { allow, handle, requireAdmin, send } from '../../lib/http.js';
import { listBackgrounds } from '../../lib/backgrounds.js';

export default handle(async (req, res) => {
  if (!allow(req, res, ['GET']) || !requireAdmin(req, res)) return;
  res.setHeader('Cache-Control', 'no-store');
  send(res, 200, { backgrounds: await listBackgrounds() });
});
