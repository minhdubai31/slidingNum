import { timingSafeEqual } from 'node:crypto';

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function send(res, status, body) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(body));
}

// Returns false (and sends 405) when the request method is not allowed.
export function allow(req, res, methods) {
  if (methods.includes(req.method)) return true;
  res.setHeader('Allow', methods.join(', '));
  send(res, 405, { error: 'Method not allowed' });
  return false;
}

// Wraps a handler so HttpError becomes its status code and anything else becomes a logged 500.
export function handle(fn) {
  return async (req, res) => {
    try {
      await fn(req, res);
    } catch (err) {
      if (err instanceof HttpError) {
        send(res, err.status, { error: err.message });
        return;
      }
      console.error(err);
      send(res, 500, { error: 'Internal server error' });
    }
  };
}

// Returns false (and sends 401) unless the Bearer token matches ADMIN_TOKEN.
export function requireAdmin(req, res) {
  const expected = process.env.ADMIN_TOKEN;
  if (!expected) {
    send(res, 500, { error: 'ADMIN_TOKEN is not configured' });
    return false;
  }
  const header = req.headers.authorization ?? '';
  const given = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    send(res, 401, { error: 'Unauthorized' });
    return false;
  }
  return true;
}

// Vercel parses JSON bodies into req.body; this rejects anything that is not a plain object.
export function jsonBody(req) {
  const body = req.body;
  if (!body || typeof body !== 'object' || Array.isArray(body)) throw new HttpError(400, 'Body must be a JSON object');
  return body;
}

// Reads the raw request body, refusing anything over maxBytes.
export async function readBody(req, maxBytes) {
  const declared = Number(req.headers['content-length']);
  if (declared > maxBytes) throw new HttpError(413, 'Image is larger than 4 MB');
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    total += chunk.length;
    if (total > maxBytes) throw new HttpError(413, 'Image is larger than 4 MB');
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
