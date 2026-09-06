import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { POST } from "@/app/api/contact/route";

function contactRequest(
  body: string,
  {
    origin = "https://studybookai.com",
    contentType = "application/json",
    ip = "203.0.113.10",
  }: { origin?: string; contentType?: string; ip?: string } = {},
) {
  return new Request("https://studybookai.com/api/contact", {
    method: "POST",
    headers: {
      origin,
      "content-type": contentType,
      "sec-fetch-site": origin === "https://studybookai.com" ? "same-origin" : "cross-site",
      "x-forwarded-for": ip,
    },
    body,
  });
}

describe("POST /api/contact", () => {
  beforeEach(() => {
    vi.stubEnv("CONTACT_DELIVERY_PROVIDER", "disabled");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("rejects cross-origin submission with a structured response", async () => {
    const response = await POST(
      contactRequest("{}", { origin: "https://attacker.invalid" }),
    );
    const result = await response.json();

    expect(response.status).toBe(403);
    expect(result).toMatchObject({
      ok: false,
      error: { code: "origin_denied" },
    });
    expect(result.requestId).toBeTruthy();
  });

  it("rejects malformed JSON without exposing internals", async () => {
    const response = await POST(contactRequest("{", { ip: "203.0.113.11" }));
    const result = await response.json();

    expect(response.status).toBe(400);
    expect(result).toMatchObject({
      ok: false,
      error: { code: "payload_invalid" },
    });
  });

  it("reports unavailable honestly when no delivery provider exists", async () => {
    const now = Date.now();
    const response = await POST(
      contactRequest(
        JSON.stringify({
          name: "Persona QA",
          email: "qa@example.com",
          reason: "support",
          message: "Necesito ayuda con mi biblioteca de estudio.",
          company: "",
          startedAt: now - 3000,
        }),
        { ip: "203.0.113.12" },
      ),
    );
    const result = await response.json();

    expect(response.status).toBe(503);
    expect(result).toMatchObject({
      ok: false,
      error: { code: "contact_unavailable" },
    });
    expect(result.error.message).toMatch(/no está habilitado/i);
  });
});
