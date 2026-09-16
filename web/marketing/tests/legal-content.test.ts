import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const readPage = (route: string) =>
  readFileSync(join(process.cwd(), "src", "app", route, "page.tsx"), "utf8");

const legalRoutes = ["privacy", "terms", "account-deletion"] as const;

describe("W7-C5 public legal content", () => {
  it("keeps legal drafts non-indexed and free of resolved placeholders", () => {
    for (const route of legalRoutes) {
      const source = readPage(route);
      expect(source).toContain("robots: { index: false, follow: false }");
      expect(source).not.toMatch(/<[A-Z0-9_]+>|_REQUIRED/);
    }
  });

  it("keeps operator, contact, age and retention decisions consistent", () => {
    const privacy = readPage("privacy");
    const terms = readPage("terms");
    const deletion = readPage("account-deletion");

    for (const source of [privacy, terms, deletion]) {
      expect(source).toContain("Welinton Rafael Mejía González");
      expect(source).toContain("studybookaiapp@gmail.com");
      expect(source).toContain("30 días");
      expect(source).toContain("90 días");
      expect(source).toContain("pendiente de publicación final");
    }
    expect(privacy).toContain("18 años");
    expect(terms).toContain("18 años");
  });

  it("publishes the approved professional domicile without changing the operator", () => {
    const privacy = readPage("privacy");
    const terms = readPage("terms");
    const contact = readPage("contact");
    const deletion = readPage("account-deletion");

    for (const source of [privacy, contact]) {
      expect(source).toContain("Bufete Jurídico “MULTISERVICIOS ZORRILLA”");
      expect(source).toContain("Avenida Sabana Larga, núm. 148");
      expect(source).toContain("Ensanche Ozama, Santo Domingo Este");
    }
    for (const source of [privacy, terms, contact]) {
      expect(source).toContain("Welinton Rafael Mejía González");
      expect(source).not.toMatch(/dirección publicable.*pendiente/i);
    }
    expect(terms).toContain("Ese domicilio no convierte a MULTISERVICIOS ZORRILLA en propietario, operador, responsable del tratamiento");
    expect(deletion).toContain("no modifica la identidad del operador");
  });

  it("keeps approved billing, cancellation and refund wording aligned", () => {
    const terms = readPage("terms");
    const pricing = readPage("pricing");

    expect(terms).toContain("Student Pro: US$6.99 por mes");
    expect(terms).toContain("Teacher Pro: US$13.99 por mes");
    expect(terms).toContain("No existe una prueba de US$1");
    expect(terms).toContain("7 días calendario");
    expect(pricing).toContain("No existe una prueba de US$1");
    expect(pricing).toContain("7 días calendario");
  });

  it("publishes the monitored email without presenting the form as active", () => {
    const contact = readPage("contact");

    expect(contact).toContain("mailto:studybookaiapp@gmail.com");
    expect(contact).toContain("Formulario Web no habilitado");
    expect(contact).not.toContain("ContactForm");
    expect(contact).not.toContain("Enviar mensaje");
  });

  it("uses factual providers and non-absolute security language", () => {
    const privacy = readPage("privacy");
    const security = readPage("security");

    for (const provider of ["Supabase", "OpenAI", "Render", "Vercel"]) {
      expect(privacy).toContain(provider);
    }
    expect(privacy).toContain("Google Play únicamente cuando");
    expect(security).toContain("Ningún sistema puede prometer seguridad absoluta");
    expect(security).toContain("mailto:studybookaiapp@gmail.com");
  });
});
