import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import robots, { buildRobots } from "@/app/robots";
import sitemap from "@/app/sitemap";
import { primaryNavigation, publicRoutes, siteConfig } from "@/config/site";

const root = join(process.cwd(), "src", "app");

describe("public routes and SEO", () => {
  it("blocks indexing throughout Vercel Preview deployments", () => {
    expect(buildRobots(true)).toEqual({
      rules: { userAgent: "*", disallow: "/" },
    });
    expect(buildRobots(false)).toMatchObject({
      rules: { userAgent: "*", allow: "/" },
      host: "https://studybookai.com",
    });
  });

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

  it("keeps motion optional and avoids fabricated social proof", () => {
    const css = readFileSync(join(root, "globals.css"), "utf8");
    const home = readFileSync(join(root, "page.tsx"), "utf8");

    expect(css).toContain("@media (prefers-reduced-motion: reduce)");
    expect(home).not.toMatch(/50,000|1M documents|4\.9\/5|universidades aliadas/i);
  });
});
