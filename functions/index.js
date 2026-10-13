'use strict';

/**
 * AgriGuard API proxy.
 *
 * The mobile app sends the signed-in user's Firebase ID token; this function
 * verifies it, applies a per-user rate limit, and forwards the request to
 * Groq / Plant.id / WeatherAPI using keys stored as Firebase secrets. The keys
 * never ship inside the APK.
 *
 *   POST /groq                    -> Groq chat completions
 *   GET|POST /plantid/<path>      -> Plant.id v3 (usage_info, identification[/token])
 *   GET /weather/forecast.json    -> WeatherAPI forecast
 *
 * Setup: see functions/README.md
 */

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const { route, LIMITS, buildGroqBody } = require('./lib');

admin.initializeApp();

const GROQ_API_KEY = defineSecret('GROQ_API_KEY');
const PLANTID_API_KEY = defineSecret('PLANTID_API_KEY');
const WEATHER_API_KEY = defineSecret('WEATHER_API_KEY');

async function authenticate(req) {
  const header = req.get('Authorization') || '';
  const match = header.match(/^Bearer (.+)$/);
  if (!match) return null;
  try {
    return await admin.auth().verifyIdToken(match[1]);
  } catch (_) {
    return null;
  }
}

/** Fixed-window counter per user, service and hour. Returns true if allowed. */
async function allow(uid, service) {
  const hour = Math.floor(Date.now() / 3600000);
  const ref = admin.firestore().collection('rateLimits').doc(`${uid}_${service}_${hour}`);
  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = snap.exists ? snap.data().count : 0;
    if (count >= LIMITS[service]) return false;
    tx.set(ref, {
      uid,
      service,
      count: count + 1,
      // Lets you enable a Firestore TTL policy on this field to auto-clean.
      expireAt: admin.firestore.Timestamp.fromMillis((hour + 2) * 3600000),
    });
    return true;
  });
}

async function relay(res, upstream) {
  const text = await upstream.text();
  res.status(upstream.status);
  res.set('Content-Type', upstream.headers.get('content-type') || 'application/json');
  res.send(text);
}

exports.api = onRequest(
  {
    region: 'us-central1',
    secrets: [GROQ_API_KEY, PLANTID_API_KEY, WEATHER_API_KEY],
    timeoutSeconds: 60,
    memory: '256MiB',
    maxInstances: 20,
  },
  async (req, res) => {
    const target = route(req.method, req.path);
    if (!target) return res.status(404).json({ error: 'Not found' });

    const user = await authenticate(req);
    if (!user) return res.status(401).json({ error: 'Sign in required' });

    if (!(await allow(user.uid, target.service))) {
      return res.status(429).json({ error: 'Too many requests. Try again later.' });
    }

    try {
      if (target.service === 'groq') {
        const body = buildGroqBody(req.body);
        if (!body) return res.status(400).json({ error: 'Invalid request' });
        return relay(
          res,
          await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${GROQ_API_KEY.value()}`,
            },
            body: JSON.stringify(body),
          })
        );
      }

      if (target.service === 'plantid') {
        const qs = new URLSearchParams(req.query).toString();
        const url = `https://api.plant.id/v3/${target.path}${qs ? `?${qs}` : ''}`;
        return relay(
          res,
          await fetch(url, {
            method: req.method,
            headers: {
              'Content-Type': 'application/json',
              'Api-Key': PLANTID_API_KEY.value(),
            },
            body: req.method === 'POST' ? JSON.stringify(req.body) : undefined,
          })
        );
      }

      if (target.service === 'weather') {
        const params = new URLSearchParams(req.query);
        params.set('key', WEATHER_API_KEY.value());
        return relay(
          res,
          await fetch(`https://api.weatherapi.com/v1/${target.path}?${params}`)
        );
      }

      return res.status(404).json({ error: 'Not found' });
    } catch (e) {
      console.error('Upstream error', target.service, e && e.message);
      return res.status(502).json({ error: 'Upstream service unavailable' });
    }
  }
);
