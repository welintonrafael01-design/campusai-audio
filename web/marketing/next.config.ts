import type { NextConfig } from "next";

const previewHeaders =
  process.env.VERCEL_ENV === "preview"
    ? [{ key: "X-Robots-Tag", value: "noindex, nofollow, noarchive" }]
    : [];

const nextConfig: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          {
            key: "Permissions-Policy",
            value: "camera=(), microphone=(), geolocation=()",
          },
          ...previewHeaders,
        ],
      },
    ];
  },
};

export default nextConfig;
