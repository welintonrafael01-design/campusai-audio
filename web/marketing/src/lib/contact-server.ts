import type { ContactPayload } from "./contact";
import { validateContactPayload } from "./contact";

const DEFAULT_LIMIT = 5;
const DEFAULT_WINDOW_MS = 10 * 60 * 1000;
const MAX_BUCKETS = 5000;

export class ContactProviderUnavailableError extends Error {}

export type ContactDeliveryContext = {
  requestId: string;
  receivedAt: string;
};

export interface ContactDeliveryProvider {
  deliver(
    payload: ContactPayload,
    context: ContactDeliveryContext,
  ): Promise<void>;
}

export class ContactRateLimiter {
  private readonly buckets = new Map<string, number[]>();

  constructor(
    private readonly limit = DEFAULT_LIMIT,
    private readonly windowMs = DEFAULT_WINDOW_MS,
  ) {}

  consume(key: string, now = Date.now()): {
    allowed: boolean;
    retryAfterSeconds: number;
  } {
    this.prune(now);
    const safeKey = key.slice(0, 256) || "unknown";
    const attempts = (this.buckets.get(safeKey) ?? []).filter(
      (timestamp) => now - timestamp < this.windowMs,
    );

    if (attempts.length >= this.limit) {
      const retryAfterMs = this.windowMs - (now - attempts[0]);
      this.buckets.set(safeKey, attempts);
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, Math.ceil(retryAfterMs / 1000)),
      };
    }

    attempts.push(now);
    this.buckets.set(safeKey, attempts);
    return { allowed: true, retryAfterSeconds: 0 };
  }

  private prune(now: number) {
    for (const [key, attempts] of this.buckets) {
      if (attempts.every((timestamp) => now - timestamp >= this.windowMs)) {
        this.buckets.delete(key);
      }
    }
    while (this.buckets.size > MAX_BUCKETS) {
      const oldestKey = this.buckets.keys().next().value as string | undefined;
      if (!oldestKey) break;
      this.buckets.delete(oldestKey);
    }
  }
}

class DisabledContactProvider implements ContactDeliveryProvider {
  async deliver(): Promise<void> {
    throw new ContactProviderUnavailableError(
      "El proveedor de contacto no está configurado.",
    );
  }
}

class WebhookContactProvider implements ContactDeliveryProvider {
  constructor(
    private readonly endpoint: URL,
    private readonly secret: string,
    private readonly fetcher: typeof fetch,
  ) {}

  async deliver(payload: ContactPayload, context: ContactDeliveryContext) {
    const response = await this.fetcher(this.endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-StudyBook-Contact-Secret": this.secret,
      },
      body: JSON.stringify({
        name: payload.name.trim(),
        email: payload.email.trim(),
        reason: payload.reason,
        message: payload.message.trim(),
        requestId: context.requestId,
        receivedAt: context.receivedAt,
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) {
      throw new Error("El proveedor de contacto rechazó la entrega.");
    }
  }
}

export function parseContactPayload(value: unknown): ContactPayload | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const record = value as Record<string, unknown>;
  if (
    typeof record.name !== "string" ||
    typeof record.email !== "string" ||
    typeof record.reason !== "string" ||
    typeof record.message !== "string" ||
    typeof record.company !== "string" ||
    typeof record.startedAt !== "number"
  ) {
    return null;
  }
  return {
    name: record.name,
    email: record.email,
    reason: record.reason,
    message: record.message,
    company: record.company,
    startedAt: record.startedAt,
  };
}

export function contactPayloadError(
  payload: ContactPayload,
  now = Date.now(),
): string | null {
  return validateContactPayload(payload, now);
}

export function isAllowedContactOrigin(request: Request): boolean {
  const origin = request.headers.get("origin");
  if (!origin) return false;
  try {
    const parsedOrigin = new URL(origin).origin;
    const requestUrl = new URL(request.url);
    const forwardedHost = request.headers.get("x-forwarded-host")?.split(",")[0].trim();
    const host = forwardedHost || request.headers.get("host")?.trim();
    const forwardedProtocol = request.headers
      .get("x-forwarded-proto")
      ?.split(",")[0]
      .trim()
      .replace(/:$/, "");
    const protocol = forwardedProtocol || requestUrl.protocol.replace(/:$/, "");
    const expectedOrigin = host ? `${protocol}://${host}` : requestUrl.origin;
    if (parsedOrigin !== expectedOrigin) return false;
  } catch {
    return false;
  }
  const fetchSite = request.headers.get("sec-fetch-site");
  return !fetchSite || fetchSite === "same-origin";
}

export function contactClientKey(request: Request): string {
  const forwarded =
    request.headers.get("x-vercel-forwarded-for") ||
    request.headers.get("x-forwarded-for") ||
    "unknown";
  return forwarded.split(",")[0].trim() || "unknown";
}

export function createContactProvider(
  environment: Record<string, string | undefined> = process.env,
  fetcher: typeof fetch = fetch,
): ContactDeliveryProvider {
  if (environment.CONTACT_DELIVERY_PROVIDER?.trim() !== "webhook") {
    return new DisabledContactProvider();
  }

  const rawEndpoint = environment.CONTACT_DELIVERY_WEBHOOK_URL?.trim();
  const secret = environment.CONTACT_DELIVERY_WEBHOOK_SECRET?.trim();
  if (!rawEndpoint || !secret) return new DisabledContactProvider();

  try {
    const endpoint = new URL(rawEndpoint);
    if (endpoint.protocol !== "https:" || endpoint.username || endpoint.password) {
      return new DisabledContactProvider();
    }
    return new WebhookContactProvider(endpoint, secret, fetcher);
  } catch {
    return new DisabledContactProvider();
  }
}

export const contactRateLimiter = new ContactRateLimiter();
