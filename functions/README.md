# AgriGuard API proxy (Cloud Functions)

Keeps the Groq, Plant.id and WeatherAPI keys on the server so they are not
inside the APK. The app sends the user's Firebase ID token; the function
verifies it, limits each user per hour and forwards the request.

| Route | Upstream | Limit / user / hour |
|---|---|---|
| `POST /groq` | Groq chat completions | 120 |
| `GET/POST /plantid/{usage_info, identification, identification/<token>}` | Plant.id v3 | 30 |
| `GET /weather/forecast.json` | WeatherAPI | 120 |

Change limits in `lib.js`.

## One-time setup

Cloud Functions need the Firebase **Blaze** (pay-as-you-go) plan. Usage for an
app this size is normally within the free tier, but set a budget alert.

```bash
npm install -g firebase-tools
firebase login
cd functions && npm install && cd ..

# store the NEW (rotated) keys as secrets - you will be prompted for each value
firebase functions:secrets:set GROQ_API_KEY
firebase functions:secrets:set PLANTID_API_KEY
firebase functions:secrets:set WEATHER_API_KEY

firebase deploy --only functions,firestore:rules,storage
```

The deploy output prints the function URL, e.g.
`https://us-central1-agriguard-867e6.cloudfunctions.net/api`.

## Point the app at it

In the app's `.env`:

```env
API_PROXY_URL=https://us-central1-agriguard-867e6.cloudfunctions.net/api
```

**Then delete `GROQ_API_KEY`, `PLANTID_API_KEY` and `WEATHER_API_KEY` from `.env`**
(and rebuild) - otherwise they are still packed into the APK. `GROQ_MODEL`
and `GROQ_VISION_MODEL` are not secret and stay in `.env`.

With `API_PROXY_URL` empty the app talks to the providers directly using the
keys in `.env` (development only).

## Optional hardening

* Enable **Firebase App Check** and call `admin.appCheck().verifyToken` here so only your real app can use the proxy.
* Enable a Firestore **TTL policy** on `rateLimits.expireAt` so counters clean themselves up.
* Add Cloud Billing budget alerts for Groq/Plant.id spend.

## Tests

```bash
cd functions && npm test
```
