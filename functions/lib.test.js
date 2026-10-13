'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { route, buildGroqBody } = require('./lib');

test('routes only the endpoints the app uses', () => {
  assert.deepStrictEqual(route('POST', '/groq'), { service: 'groq' });
  assert.strictEqual(route('GET', '/groq'), null);
  assert.deepStrictEqual(route('POST', '/plantid/identification'), { service: 'plantid', path: 'identification' });
  assert.deepStrictEqual(route('GET', '/plantid/identification/abc123'), { service: 'plantid', path: 'identification/abc123' });
  assert.deepStrictEqual(route('GET', '/plantid/usage_info'), { service: 'plantid', path: 'usage_info' });
  assert.strictEqual(route('GET', '/plantid/../admin'), null);
  assert.strictEqual(route('DELETE', '/plantid/identification'), null);
  assert.deepStrictEqual(route('GET', '/weather/forecast.json'), { service: 'weather', path: 'forecast.json' });
  assert.strictEqual(route('GET', '/weather/history.json'), null);
  assert.strictEqual(route('GET', '/'), null);
});

test('groq body is validated and capped', () => {
  assert.strictEqual(buildGroqBody(null), null);
  assert.strictEqual(buildGroqBody({ model: 'm', messages: [] }), null);
  assert.strictEqual(buildGroqBody({ model: 'm', messages: [{}], stream: true }), null);
  assert.strictEqual(buildGroqBody({ model: 'm', messages: new Array(41).fill({}) }), null);
  assert.strictEqual(buildGroqBody({ model: 'm', messages: [{}], max_tokens: 99999 }).max_tokens, 2048);
  assert.strictEqual(buildGroqBody({ model: 'm', messages: [{}] }).max_tokens, 1024);
});
