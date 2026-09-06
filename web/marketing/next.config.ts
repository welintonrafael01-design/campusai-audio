import type { NextConfig } from "next";
import {
  buildContentSecurityPolicy,
  isPublicIndexingApproved,
} from "./src/config/security-policy";

const publicIndexingApproved = isPublicIndexingApproved({
  vercelEnvironment: process.env.VERCEL_ENV,
  explicitApproval: process.env.ENABLE_PUBLIC_INDEXING,
});
const indexingHeaders = publicIndexingApproved
  ? []
  : [{ key: "X-Robots-Tag", value: "noindex, nofollow, noarchive" }];
const contentSecurityPolicy = buildContentSecurityPolicy({
  development: process.env.NODE_ENV !== "production",
});

const nextConfig: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Content-Security-Policy", value: contentSecurityPolicy },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          {
            key: "Strict-Transport-Security",
            value: "max-age=63072000; includeSubDomains; preload",
          },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          {
            key: "Permissions-Policy",
            value: "camera=(), microphone=(), geolocation=()",
          },
          ...indexingHeaders,
        ],
      },
    ];
  },
};

export default nextConfig;
