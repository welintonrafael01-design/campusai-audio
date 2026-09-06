import type { MetadataRoute } from "next";
import { shouldBlockIndexing, siteConfig } from "@/config/site";

export function buildRobots(blockIndexing: boolean): MetadataRoute.Robots {
  if (blockIndexing) {
    return {
      rules: {
        userAgent: "*",
        disallow: "/",
      },
    };
  }

  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/privacy", "/terms", "/account-deletion"],
    },
    sitemap: `${siteConfig.urls.web}/sitemap.xml`,
    host: siteConfig.urls.web,
  };
}

export default function robots(): MetadataRoute.Robots {
  return buildRobots(shouldBlockIndexing);
}
