// EMULATOR integration tests: tutor application resubmission, catalog publication, HTTP and watcher.
import assert from 'node:assert/strict';
import { after, afterEach, before, beforeEach, describe, test } from 'node:test';
import { createApp } from '../src/app.js';
import { startWorkflowWatcher } from '../src/watcher.js';
import { auth, createUser, db, idToken, makeServices, resetEmulators } from './support/harness.js';

const silent = { info() {}, warn() {}, error() {} };

const applicationDoc = (overrides = {}) => ({
  name: 'Nguyen Linh Dan', email: 'tutor@beewise.test', phone: '0387871708',
  qualification: 'Cử nhân Đại học Ngoại thương', introduction: '3 năm kinh nghiệm dạy học cấp 2.',
  subjects: ['Toán', 'Lý'], grades: ['6', '7'], hourlyFee: 180_000, areas: ['Quận 7'],
  teachingModes: ['online'], availability: 'Tối thứ 2, 4, 6',
  status: 'pending', verified: false, active: false, consentAccepted: true,
  ...overrides,
});

const resubmission = (overrides = {}) => ({
  name: 'Nguyen Linh Dan', phone: '0387871708', qualification: 'Cử nhân Ngoại thương, IELTS 7.5',
  introduction: 'Đã bổ sung bằng cấp và 3 năm kinh nghiệm dạy cấp 2.',
  subjects: ['Toán'], grades: ['6'], hourlyFee: 200_000, areas: ['Quận 7', 'HCM'],
  teachingModes: ['online', 'in_person'], availability: 'Tối thứ 3, 5',
  ...overrides,
});

const waitFor = async (check, label, timeoutMs = 10_000) => {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await check()) return;
    await new Promise((resolve) => { setTimeout(resolve, 100); });
  }
  assert.fail(`timed out waiting for ${label}`);
};

let services; let tutor;
before(() => { services = makeServices(); });
beforeEach(async () => {
  await resetEmulators();
  tutor = await createUser('tutor@beewise.test');
});

describe('resubmission', () => {
  test('needs_info goes back to pending, keeps the old reason and never self-approves', async () => {
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'needs_info', rejectionReason: 'Bổ sung bằng cấp' }));
    const result = await services.tutorApplications.resubmit(tutor.uid, resubmission());
    assert.equal(result.status, 'pending');
    const data = (await db.doc(`tutorApplications/${tutor.uid}`).get()).data();
    assert.equal(data.status, 'pending');
    assert.equal(data.verified, false);
    assert.equal(data.active, false);
    assert.equal(data.hourlyFee, 200_000);
    assert.deepEqual(data.teachingModes, ['online', 'in_person']);
    assert.equal(data.previousRejectionReason, 'Bổ sung bằng cấp');
    assert.equal(data.rejectionReason, undefined);
    assert.equal(data.email, 'tutor@beewise.test', 'email is never editable here');
  });

  test('only needs_info can be resubmitted; rejected, pending and approved are refused untouched', async () => {
    for (const status of ['rejected', 'pending', 'approved']) {
      await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status, verified: status === 'approved', active: status === 'approved' }));
      await assert.rejects(services.tutorApplications.resubmit(tutor.uid, resubmission()), (error) => error.status === 409);
      assert.equal((await db.doc(`tutorApplications/${tutor.uid}`).get()).data().hourlyFee, 180_000, `${status} unchanged`);
    }
  });

  test('missing application is 404 and invalid fields are 400 without writing', async () => {
    await assert.rejects(services.tutorApplications.resubmit(tutor.uid, resubmission()), (error) => error.status === 404);
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'needs_info' }));
    for (const bad of [{ hourlyFee: -5 }, { subjects: [] }, { teachingModes: ['hybrid'] }, { introduction: 'ngắn' }, { phone: '12' }]) {
      await assert.rejects(services.tutorApplications.resubmit(tutor.uid, resubmission(bad)), (error) => error.status === 400);
    }
    assert.equal((await db.doc(`tutorApplications/${tutor.uid}`).get()).data().status, 'needs_info');
  });
});

describe('catalog publication', () => {
  test('a fully approved application is published once and refreshed idempotently', async () => {
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'approved', verified: true, active: true }));
    const first = await services.tutorApplications.publish(tutor.uid);
    assert.equal(first.created, true);
    await db.doc(`tutors/${tutor.uid}`).update({ rating: 4.8, reviewCount: 3 });
    const second = await services.tutorApplications.publish(tutor.uid);
    assert.equal(second.created, false);
    const profile = (await db.doc(`tutors/${tutor.uid}`).get()).data();
    assert.equal(profile.active, true);
    assert.equal(profile.verified, true);
    assert.equal(profile.credential, 'Cử nhân Đại học Ngoại thương');
    assert.equal(profile.rating, 4.8, 'ratings are never overwritten');
    assert.equal(profile.reviewCount, 3);
    assert.equal(profile.applicationUid, tutor.uid);
  });

  test('anything short of approved + verified + active is refused', async () => {
    for (const patch of [{ status: 'pending' }, { status: 'approved', verified: false, active: true }, { status: 'approved', verified: true, active: false }, { status: 'rejected', verified: true, active: true }]) {
      await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc(patch));
      await assert.rejects(services.tutorApplications.publish(tutor.uid), (error) => error.status === 409);
      assert.equal((await db.doc(`tutors/${tutor.uid}`).get()).exists, false);
    }
  });

  test('a catalog document that did not come from this application is never overwritten', async () => {
    await db.doc(`tutors/${tutor.uid}`).set({ name: 'Hồ sơ khác', active: true, verified: true });
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'approved', verified: true, active: true }));
    await assert.rejects(services.tutorApplications.publish(tutor.uid), (error) => error.status === 409);
    assert.equal((await db.doc(`tutors/${tutor.uid}`).get()).data().name, 'Hồ sơ khác');
    await services.tutorApplications.sync(tutor.uid).catch(() => {});
    await db.doc(`tutorApplications/${tutor.uid}`).update({ active: false });
    assert.equal((await services.tutorApplications.unpublish(tutor.uid)).changed, false, 'foreign profile is not hidden either');
  });

  test('revoking approval hides the published profile', async () => {
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'approved', verified: true, active: true }));
    await services.tutorApplications.publish(tutor.uid);
    await db.doc(`tutorApplications/${tutor.uid}`).update({ status: 'rejected' });
    assert.equal((await services.tutorApplications.sync(tutor.uid)).changed, true);
    const profile = (await db.doc(`tutors/${tutor.uid}`).get()).data();
    assert.equal(profile.active, false);
    assert.equal(profile.verified, false);
  });
});

describe('HTTP API', () => {
  let server; let base; let consultant;
  before(async () => {
    const app = createApp({ auth, consultants: services.consultants, payments: services.payments, tutorApplications: services.tutorApplications, logger: silent });
    await new Promise((resolve) => { server = app.listen(0, resolve); });
    base = `http://127.0.0.1:${server.address().port}`;
  });
  after(() => new Promise((resolve) => server.close(resolve)));
  beforeEach(async () => { consultant = await createUser('consultant@beewise.test', { consultant: true }); });

  const call = async (path, { token, body } = {}) => {
    const response = await fetch(`${base}${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
      body: JSON.stringify(body ?? {}),
    });
    return { status: response.status, body: await response.json().catch(() => null) };
  };

  test('resubmit requires sign-in, acts only on the caller and ignores a client-sent owner or status', async () => {
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'needs_info' }));
    const other = await createUser('other@beewise.test');
    await db.doc(`tutorApplications/${other.uid}`).set(applicationDoc({ status: 'needs_info', name: 'Người khác' }));

    assert.equal((await call('/v1/tutor-applications/resubmit', { body: resubmission() })).status, 401);
    const token = await idToken('tutor@beewise.test');
    const ok = await call('/v1/tutor-applications/resubmit', {
      token, body: { ...resubmission(), uid: other.uid, status: 'approved', verified: true, active: true, email: 'evil@x.test' },
    });
    assert.equal(ok.status, 200);
    const mine = (await db.doc(`tutorApplications/${tutor.uid}`).get()).data();
    assert.equal(mine.status, 'pending');
    assert.equal(mine.verified, false);
    assert.equal(mine.email, 'tutor@beewise.test');
    const theirs = (await db.doc(`tutorApplications/${other.uid}`).get()).data();
    assert.equal(theirs.status, 'needs_info', 'another applicant is untouched');
    assert.equal(theirs.name, 'Người khác');
    const invalid = await call('/v1/tutor-applications/resubmit', { token, body: resubmission({ hourlyFee: 'rẻ' }) });
    assert.equal(invalid.status, 400, 'malformed fields are rejected before any state is read');
    const again = await call('/v1/tutor-applications/resubmit', { token, body: resubmission() });
    assert.equal(again.status, 409, 'now pending, so no further resubmission');
  });

  test('publish is staff-only', async () => {
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc({ status: 'approved', verified: true, active: true }));
    const path = `/v1/staff/tutor-applications/${tutor.uid}/publish`;
    assert.equal((await call(path)).status, 401);
    assert.equal((await call(path, { token: await idToken('tutor@beewise.test') })).status, 403, 'the tutor cannot publish themselves');
    assert.equal((await db.doc(`tutors/${tutor.uid}`).get()).exists, false);
    const ok = await call(path, { token: await idToken('consultant@beewise.test') });
    assert.equal(ok.status, 200);
    assert.equal((await db.doc(`tutors/${tutor.uid}`).get()).data().active, true);
    assert.equal(consultant.uid.length > 0, true);
  });
});

describe('watcher', () => {
  let stop;
  afterEach(() => stop?.());

  test('manual console approval publishes the profile and revoking it hides it', async () => {
    stop = startWorkflowWatcher({ db, auth, ...services, logger: silent });
    await db.doc(`tutorApplications/${tutor.uid}`).set(applicationDoc());
    await new Promise((resolve) => { setTimeout(resolve, 500); });
    assert.equal((await db.doc(`tutors/${tutor.uid}`).get()).exists, false, 'pending stays private');

    await db.doc(`tutorApplications/${tutor.uid}`).update({ status: 'approved', verified: true, active: true });
    await waitFor(async () => (await db.doc(`tutors/${tutor.uid}`).get()).data()?.active === true, 'catalog publication');

    await db.doc(`tutorApplications/${tutor.uid}`).update({ active: false });
    await waitFor(async () => (await db.doc(`tutors/${tutor.uid}`).get()).data()?.active === false, 'catalog hide');
  });
});
