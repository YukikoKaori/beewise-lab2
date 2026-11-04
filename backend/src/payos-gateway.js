import { PayOS } from '@payos/node';

/**
 * Thin boundary around the official payOS SDK so business code depends on four
 * operations only. Tests inject a fake `fetch`; the SDK request/response
 * signing and webhook verification code still runs unchanged.
 */
export function createPayosGateway({ clientId, apiKey, checksumKey, fetch, timeoutMs = 15000 }) {
  const client = new PayOS({
    clientId,
    apiKey,
    checksumKey,
    timeout: timeoutMs,
    maxRetries: 0, // Retries are handled by reconciliation, never by blind re-POST.
    logLevel: 'off',
    ...(fetch ? { fetch } : {}),
  });
  return {
    createPaymentLink: (request) => client.paymentRequests.create(request),
    getPaymentLink: (orderCode) => client.paymentRequests.get(orderCode),
    cancelPaymentLink: (orderCode, reason) => client.paymentRequests.cancel(orderCode, reason),
    /** Throws when the signature does not match the server-held checksum key. */
    verifyWebhook: (body) => client.webhooks.verify(body),
    confirmWebhook: (url) => client.webhooks.confirm(url),
  };
}

/** Gateway used when payOS credentials are absent: every call fails closed. */
export function createUnconfiguredGateway() {
  const fail = async () => {
    const error = new Error('payOS credentials are not configured on this server.');
    error.code = 'payos_not_configured';
    throw error;
  };
  return {
    createPaymentLink: fail,
    getPaymentLink: fail,
    cancelPaymentLink: fail,
    verifyWebhook: fail,
    confirmWebhook: fail,
  };
}
