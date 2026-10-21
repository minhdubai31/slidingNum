import { allow, handle, readBody, requireAdmin, send } from '../../../lib/http.js';
import { replaceBackground, resetBackground, validateSlot } from '../../../lib/backgrounds.js';
import { MAX_IMAGE_BYTES } from '../../../lib/validate.js';

export default handle(async (req, res) => {
  if (!allow(req, res, ['PUT', 'DELETE']) || !requireAdmin(req, res)) return;
  const slot = validateSlot(req.query.slot);
  if (req.method === 'PUT') {
    const buffer = await readBody(req, MAX_IMAGE_BYTES);
    send(res, 200, { background: await replaceBackground(slot, buffer) });
    return;
  }
  await resetBackground(slot);
  res.statusCode = 204;
  res.end();
});
