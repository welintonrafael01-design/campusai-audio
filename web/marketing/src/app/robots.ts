import type { MetadataRoute } from "next";
import { isPreviewDeployment, siteConfig } from "@/config/site";

export function buildRobots(isPreview: boolean): MetadataRoute.Robots {
  if (isPreview) {
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
  return buildRobots(isPreviewDeployment);
}
