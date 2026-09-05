import { existsSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import robots from "@/app/robots";
import sitemap from "@/app/sitemap";
import { primaryNavigation, publicRoutes, siteConfig } from "@/config/site";

const root = join(process.cwd(), "src", "app");

describe("public routes and SEO", () => {
  it.each(publicRoutes)("has an implementation for %s", (route) => {
    const page = route === "/" ? join(root, "page.tsx") : join(root, route.slice(1), "page.tsx");
    expect(existsSync(page)).toBe(true);
  });

  it("keeps every internal primary navigation link valid", () => {
    for (const item of primaryNavigation) {
      expect(publicRoutes).toContain(item.href);
    }
  });

  it("publishes canonical sitemap entries and protects legal drafts", () => {
    const urls = sitemap().map((entry) => entry.url);
    expect(urls).toContain(siteConfig.urls.web);
    expect(urls).toContain(`${siteConfig.urls.web}/features`);
    expect(urls).not.toContain(`${siteConfig.urls.web}/privacy`);
    expect(robots().rules).toMatchObject({
      disallow: ["/privacy", "/terms", "/account-deletion"],
    });
  });

  it("includes a custom not-found route", () => {
    expect(existsSync(join(root, "not-found.tsx"))).toBe(true);
  });
});
