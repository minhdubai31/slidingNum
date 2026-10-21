import { allow, handle, readBody, requireAdmin, send } from '../../../../lib/http.js';
import { createPicture } from '../../../../lib/catalogue.js';
import { MAX_IMAGE_BYTES, validatePosition } from '../../../../lib/validate.js';

// POST /api/admin/topics/:id/pictures?position=0
// body = raw image bytes (PNG, JPEG or WebP, max 4 MB). Appended to the end unless position is given.
export default handle(async (req, res) => {
  if (!allow(req, res, ['POST'])) return;
  if (!requireAdmin(req, res)) return;

  const position = req.query.position === undefined ? undefined : validatePosition(req.query.position);
  const buffer = await readBody(req, MAX_IMAGE_BYTES);
  const picture = await createPicture({ topicId: req.query.id, position, buffer });
  send(res, 201, { picture });
});
