import type { MetadataRoute } from "next";
import { siteConfig } from "@/config/site";

export default function robots(): MetadataRoute.Robots {
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
