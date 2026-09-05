import { describe, expect, it, vi } from "vitest";
import { validateContactPayload } from "@/lib/contact";

const validPayload = {
  name: "Persona QA",
  email: "qa@example.com",
  reason: "support",
  message: "Necesito ayuda con mi biblioteca de estudio.",
  company: "",
  startedAt: 0,
};

describe("contact protection", () => {
  it("accepts a human-shaped payload after the minimum delay", () => {
    vi.spyOn(Date, "now").mockReturnValue(5000);
    expect(validateContactPayload(validPayload)).toBeNull();
    vi.restoreAllMocks();
  });

  it("rejects the honeypot and submissions that are too fast", () => {
    vi.spyOn(Date, "now").mockReturnValue(1000);
    expect(validateContactPayload({ ...validPayload, company: "spam" })).toMatch(/validar/i);
    expect(validateContactPayload({ ...validPayload, startedAt: 500 })).toMatch(/Espera/i);
    vi.restoreAllMocks();
  });
});
