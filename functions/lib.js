'use strict';

/** Requests allowed per user per hour. Tune to your API plan. */
const LIMITS = { groq: 120, plantid: 30, weather: 120 };

const PLANTID_PATHS = [/^usage_info$/, /^identification$/, /^identification\/[A-Za-z0-9_-]+$/];

/**
 * Maps an incoming request to an upstream service, or null if it is not
 * allowed. Only the exact endpoints the app uses are exposed.
 */
function route(method, path) {
  const clean = String(path || '').replace(/^\/+|\/+$/g, '');

  if (clean === 'groq') return method === 'POST' ? { service: 'groq' } : null;

  if (clean.startsWith('plantid/')) {
    const sub = clean.slice('plantid/'.length);
    const ok = PLANTID_PATHS.some((re) => re.test(sub));
    return ok && (method === 'GET' || method === 'POST') ? { service: 'plantid', path: sub } : null;
  }

  if (clean === 'weather/forecast.json') {
    return method === 'GET' ? { service: 'weather', path: 'forecast.json' } : null;
  }
  return null;
}

/**
 * Validates and limits a Groq chat request. Returns the sanitized body or null.
 * Caps output size and conversation length so one user cannot burn the quota.
 */
function buildGroqBody(body) {
  if (!body || typeof body !== 'object') return null;
  if (typeof body.model !== 'string' || !Array.isArray(body.messages)) return null;
  if (body.messages.length === 0 || body.messages.length > 40) return null;
  if (body.stream) return null;
  const out = { ...body };
  out.max_tokens = Math.min(Number(body.max_tokens) || 1024, 2048);
  return out;
}

module.exports = { route, LIMITS, buildGroqBody };
