#!/usr/bin/env node
// Operator CLI for a trusted machine holding Admin credentials.
// Consultant actions still re-check the consultant claim on every call.
import { readFileSync } from 'node:fs';
import { CONSULTANT_CLAIM, requireConsultant } from '../src/auth.js';
import { createRuntime } from '../src/runtime.js';

try {
  process.loadEnvFile('.env');
} catch {
  // optional
}

const usage = `Usage: node scripts/staff.js <command> [...args]
  grant <email|uid>                     Give the consultant role (custom claim)
  revoke <email|uid>                    Remove the role and revoke sessions immediately
  claim <staffEmail> <chatId>           Assign the consultant to a waiting chat
  trial <staffEmail> <chatId> <file>    Publish a trial proposal from a JSON payload file
  revision <staffEmail> <chatId> <file> Publish a class revision from a JSON payload file
  process <staffEmail> <chatId> <proposalId>  Consume the parent response
  reconcile <orderCode>                 Re-check one payOS order with the provider
  confirm-webhook <https-url>           Register the payOS webhook URL`;

const runtime = createRuntime();
const { auth, consultants, payments, gateway } = runtime;
const user = (idOrEmail) => (idOrEmail.includes('@') ? auth.getUserByEmail(idOrEmail) : auth.getUser(idOrEmail));
const consultant = async (idOrEmail) => requireConsultant(auth, (await user(idOrEmail)).uid);
const json = (file) => JSON.parse(readFileSync(file, 'utf8'));

const [command, ...args] = process.argv.slice(2);
const commands = {
  async grant([target]) {
    const record = await user(target);
    await auth.setCustomUserClaims(record.uid, { ...(record.customClaims ?? {}), [CONSULTANT_CLAIM]: true });
    return { uid: record.uid, consultant: true, note: 'User must sign in again to receive the claim.' };
  },
  async revoke([target]) {
    const record = await user(target);
    const claims = { ...(record.customClaims ?? {}) };
    delete claims[CONSULTANT_CLAIM];
    await auth.setCustomUserClaims(record.uid, claims);
    await auth.revokeRefreshTokens(record.uid);
    return { uid: record.uid, consultant: false, sessionsRevoked: true };
  },
  claim: async ([staff, chatId]) => consultants.claimChat(await consultant(staff), chatId),
  trial: async ([staff, chatId, file]) => consultants.proposeTrial(await consultant(staff), chatId, json(file)),
  revision: async ([staff, chatId, file]) => consultants.proposeClassRevision(await consultant(staff), chatId, json(file)),
  process: async ([staff, chatId, proposalId]) => consultants.processResponse(await consultant(staff), chatId, proposalId),
  reconcile: async ([orderCode]) => payments.settleOrder(Number(orderCode), { source: 'operator' }),
  'confirm-webhook': async ([url]) => {
    if (!/^https:\/\//.test(url ?? '')) throw new Error('Webhook URL must be HTTPS.');
    return gateway.confirmWebhook(url);
  },
};

if (!commands[command]) {
  console.error(usage);
  process.exit(2);
}
try {
  console.log(JSON.stringify(await commands[command](args), null, 2));
  process.exit(0);
} catch (error) {
  console.error(`${error.code ?? error.name}: ${error.message}`);
  process.exit(1);
}
