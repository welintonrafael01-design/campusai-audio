import { describe, expect, it } from "vitest";
import {
  buildContentSecurityPolicy,
  isPublicIndexingApproved,
} from "@/config/security-policy";

describe("public web security policy", () => {
  it("enforces a production CSP without development eval or sockets", () => {
    const policy = buildContentSecurityPolicy({ development: false });

    expect(policy).toContain("default-src 'self'");
    expect(policy).toContain("frame-ancestors 'none'");
    expect(policy).toContain("object-src 'none'");
    expect(policy).not.toContain("'unsafe-eval'");
    expect(policy).not.toContain("ws:");
  });

  it("permits only the development capabilities required by Next HMR", () => {
    const policy = buildContentSecurityPolicy({ development: true });

    expect(policy).toContain("'unsafe-eval'");
    expect(policy).toContain("ws:");
  });

  it("requires both production and explicit approval before indexing", () => {
    expect(
      isPublicIndexingApproved({
        vercelEnvironment: "production",
        explicitApproval: "true",
      }),
    ).toBe(true);
    expect(
      isPublicIndexingApproved({
        vercelEnvironment: "preview",
        explicitApproval: "true",
      }),
    ).toBe(false);
    expect(
      isPublicIndexingApproved({
        vercelEnvironment: "production",
        explicitApproval: "false",
      }),
    ).toBe(false);
  });
});
