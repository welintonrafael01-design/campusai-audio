import type { MetadataRoute } from "next";
import { publicRoutes, siteConfig } from "@/config/site";

const indexedRoutes = publicRoutes.filter(
  (route) => !["/privacy", "/terms", "/account-deletion"].includes(route),
);

export default function sitemap(): MetadataRoute.Sitemap {
  return indexedRoutes.map((route) => ({
    url: `${siteConfig.urls.web}${route === "/" ? "" : route}`,
    changeFrequency: route === "/" ? "weekly" : "monthly",
    priority: route === "/" ? 1 : 0.7,
  }));
}
