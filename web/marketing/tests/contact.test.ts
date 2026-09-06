import { describe, expect, it } from "vitest";
import { validateContactPayload } from "@/lib/contact";

const validPayload = {
  name: "Persona QA",
  email: "qa@example.com",
  reason: "support",
  message: "Necesito ayuda con mi biblioteca de estudio.",
  company: "",
  startedAt: 1000,
};

describe("contact protection", () => {
  it("accepts a human-shaped payload after the minimum delay", () => {
    expect(validateContactPayload(validPayload, 5000)).toBeNull();
  });

  it("rejects the honeypot and submissions that are too fast", () => {
    expect(
      validateContactPayload({ ...validPayload, company: "spam" }, 5000),
    ).toMatch(/validar/i);
    expect(
      validateContactPayload({ ...validPayload, startedAt: 3000 }, 5000),
    ).toMatch(/Espera/i);
  });

  it("rejects missing and expired form sessions", () => {
    expect(
      validateContactPayload({ ...validPayload, startedAt: 0 }, 5000),
    ).toMatch(/validar/i);
    expect(validateContactPayload(validPayload, 3_602_000)).toMatch(/expiró/i);
  });
});
