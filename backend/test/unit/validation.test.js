import assert from 'node:assert/strict';
import { test } from 'node:test';
import { loadConfig, payosConfigured } from '../../src/config.js';
import { classRevisionPayload, docId, trialPayload, vnd } from '../../src/validation.js';

const revision = {
  subject: 'Toán', tutorName: 'A', schedule: 'Thứ 3', time: '19:00', mode: 'Tại nhà', location: 'Q1',
  startDate: '01/12/2026', lessonDuration: '90 phút', fee: 200_000, totalFee: 1_600_000,
};

test('document ids reject paths and oversized values', () => {
  assert.equal(docId('chat_1-A'), 'chat_1-A');
  for (const bad of ['', 'a/b', '..', 'x'.repeat(129), 12, null]) assert.throws(() => docId(bad));
});

test('VND amounts must be safe whole numbers in range', () => {
  assert.equal(vnd(2_000_000, 'amount'), 2_000_000);
  for (const bad of [999, 12.5, -1, '2000', Number.MAX_SAFE_INTEGER, NaN]) assert.throws(() => vnd(bad, 'amount'));
});

test('payloads keep only known fields and validate mode', () => {
  const parsed = classRevisionPayload({ ...revision, parentId: 'attacker', status: 'confirmed' });
  assert.equal(parsed.parentId, undefined);
  assert.equal(parsed.status, undefined);
  assert.equal(parsed.goal, null);
  assert.throws(() => classRevisionPayload({ ...revision, mode: 'Ngoài trời' }));
  assert.throws(() => trialPayload({}));
});

test('config defaults are safe and payOS requires all three secrets', () => {
  const config = loadConfig({ PORT: '9000', PUBLIC_BASE_URL: 'https://x.test/', CHECKOUT_TTL_MINUTES: '1' });
  assert.equal(config.port, 9000);
  assert.equal(config.publicBaseUrl, 'https://x.test');
  assert.equal(config.checkoutTtlMinutes, 5, 'clamped to a minimum');
  assert.equal(payosConfigured(config), false);
  assert.equal(payosConfigured(loadConfig({ PAYOS_CLIENT_ID: 'a', PAYOS_API_KEY: 'b', PAYOS_CHECKSUM_KEY: 'c' })), true);
});
