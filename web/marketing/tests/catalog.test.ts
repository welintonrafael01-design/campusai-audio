import { describe, expect, it } from "vitest";
import { commercialPlans } from "@/config/plans";
import { siteConfig } from "@/config/site";

describe("commercial catalog", () => {
  it("keeps the approved W1 plans and prices in one source", () => {
    expect(commercialPlans.map((plan) => plan.id)).toEqual([
      "free",
      "student",
      "teacher",
      "institution",
    ]);
    expect(commercialPlans.find((plan) => plan.id === "free")?.price).toBe("USD 0");
    expect(commercialPlans.find((plan) => plan.id === "student")?.price).toBe("USD 6.99");
    expect(commercialPlans.find((plan) => plan.id === "teacher")?.price).toBe("USD 13.99");
    expect(commercialPlans.find((plan) => plan.id === "institution")?.price).toBe("Contacto");
  });

  it("uses only the approved public, app and API origins", () => {
    expect(siteConfig.urls).toEqual({
      web: "https://studybookai.com",
      app: "https://app.studybookai.com",
      api: "https://api.studybookai.com",
    });
  });

  it("describes Free limits without promising premium generation", () => {
    const free = commercialPlans.find((plan) => plan.id === "free");
    const copy = free?.features.join(" ") ?? "";

    expect(copy).toContain("3 documentos");
    expect(copy).toContain("10 mensajes");
    expect(copy).toContain("1 set de flashcards");
    expect(copy).toContain("1 quiz");
    expect(copy).not.toContain("AudioBook");
    expect(copy).not.toContain("Voice Tutor");
    expect(copy.toLowerCase()).not.toContain("ilimitado");
  });
});
