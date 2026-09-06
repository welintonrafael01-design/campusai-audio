type PublicIndexingEnvironment = {
  vercelEnvironment?: string;
  explicitApproval?: string;
};

export function isPublicIndexingApproved({
  vercelEnvironment,
  explicitApproval,
}: PublicIndexingEnvironment): boolean {
  return (
    vercelEnvironment?.trim().toLowerCase() === "production" &&
    explicitApproval?.trim().toLowerCase() === "true"
  );
}

export function buildContentSecurityPolicy({
  development,
}: {
  development: boolean;
}): string {
  const scriptSources = ["'self'", "'unsafe-inline'"];
  const connectSources = ["'self'"];

  if (development) {
    scriptSources.push("'unsafe-eval'");
    connectSources.push("ws:", "wss:");
  }

  return [
    "default-src 'self'",
    "base-uri 'self'",
    `connect-src ${connectSources.join(" ")}`,
    "font-src 'self' data:",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "frame-src 'none'",
    "img-src 'self' data: blob:",
    "manifest-src 'self'",
    "media-src 'self' blob:",
    "object-src 'none'",
    `script-src ${scriptSources.join(" ")}`,
    "script-src-attr 'none'",
    "style-src 'self' 'unsafe-inline'",
    "worker-src 'self' blob:",
  ].join("; ");
}
