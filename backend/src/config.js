const int = (value, fallback, { min = 1, max = Number.MAX_SAFE_INTEGER } = {}) => {
  const parsed = Number.parseInt(value ?? '', 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(parsed, min), max);
};

/** Reads configuration from the environment. Secrets are never logged. */
export function loadConfig(env = process.env) {
  const publicBaseUrl = (env.PUBLIC_BASE_URL ?? `http://localhost:${env.PORT ?? 8787}`).replace(/\/+$/, '');
  return {
    port: int(env.PORT, 8787, { max: 65535 }),
    publicBaseUrl,
    checkoutTtlMinutes: int(env.CHECKOUT_TTL_MINUTES, 15, { min: 5, max: 24 * 60 }),
    invoiceDueDays: int(env.INVOICE_DUE_DAYS, 3, { max: 30 }),
    payos: {
      clientId: env.PAYOS_CLIENT_ID ?? '',
      apiKey: env.PAYOS_API_KEY ?? '',
      checksumKey: env.PAYOS_CHECKSUM_KEY ?? '',
    },
  };
}

export const payosConfigured = (config) =>
  Boolean(config.payos.clientId && config.payos.apiKey && config.payos.checksumKey);
