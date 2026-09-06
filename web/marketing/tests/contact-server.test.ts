import { describe, expect, it, vi } from "vitest";
import {
  ContactProviderUnavailableError,
  ContactRateLimiter,
  contactClientKey,
  createContactProvider,
  isAllowedContactOrigin,
  parseContactPayload,
} from "@/lib/contact-server";

const validPayload = {
  name: "Persona QA",
  email: "qa@example.com",
  reason: "support",
  message: "Necesito ayuda con mi biblioteca de estudio.",
  company: "",
  startedAt: 1000,
};

describe("server-side contact protection", () => {
  it("parses only the expected typed payload", () => {
    expect(parseContactPayload(validPayload)).toEqual(validPayload);
    expect(parseContactPayload({ ...validPayload, startedAt: "1000" })).toBeNull();
    expect(parseContactPayload(null)).toBeNull();
  });

  it("accepts same-origin requests and rejects cross-origin requests", () => {
    const sameOrigin = new Request("https://studybookai.com/api/contact", {
      headers: {
        origin: "https://studybookai.com",
        "sec-fetch-site": "same-origin",
        "x-forwarded-for": "203.0.113.4, 10.0.0.1",
      },
    });
    const crossOrigin = new Request("https://studybookai.com/api/contact", {
      headers: { origin: "https://attacker.invalid" },
    });

    expect(isAllowedContactOrigin(sameOrigin)).toBe(true);
    expect(isAllowedContactOrigin(crossOrigin)).toBe(false);
    expect(contactClientKey(sameOrigin)).toBe("203.0.113.4");
  });

  it("accepts the public host preserved by a reverse proxy", () => {
    const proxied = new Request("http://localhost:3000/api/contact", {
      headers: {
        origin: "https://studybookai.com",
        host: "localhost:3000",
        "x-forwarded-host": "studybookai.com",
        "x-forwarded-proto": "https",
        "sec-fetch-site": "same-origin",
      },
    });

    expect(isAllowedContactOrigin(proxied)).toBe(true);
  });

  it("blocks requests after the configured window limit", () => {
    const limiter = new ContactRateLimiter(2, 1000);
    expect(limiter.consume("client", 1000).allowed).toBe(true);
    expect(limiter.consume("client", 1100).allowed).toBe(true);
    expect(limiter.consume("client", 1200)).toMatchObject({ allowed: false });
    expect(limiter.consume("client", 2101).allowed).toBe(true);
  });

  it("fails closed when no provider is configured", async () => {
    const provider = createContactProvider({});
    await expect(
      provider.deliver(validPayload, {
        requestId: "request-1",
        receivedAt: "2026-09-06T00:00:00.000Z",
      }),
    ).rejects.toBeInstanceOf(ContactProviderUnavailableError);
  });

  it("uses an HTTPS webhook only when its server secret is complete", async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(null, { status: 202 }),
    );
    const provider = createContactProvider(
      {
        CONTACT_DELIVERY_PROVIDER: "webhook",
        CONTACT_DELIVERY_WEBHOOK_URL: "https://contact.example.test/intake",
        CONTACT_DELIVERY_WEBHOOK_SECRET: "server-only-placeholder",
      },
      fetcher,
    );

    await provider.deliver(validPayload, {
      requestId: "request-2",
      receivedAt: "2026-09-06T00:00:00.000Z",
    });

    expect(fetcher).toHaveBeenCalledOnce();
    expect(fetcher.mock.calls[0][0].toString()).toBe(
      "https://contact.example.test/intake",
    );
    expect(fetcher.mock.calls[0][1]).toMatchObject({ method: "POST" });
  });
});
