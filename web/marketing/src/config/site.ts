import { isPublicIndexingApproved } from "./security-policy";

const normalizeUrl = (value: string | undefined, fallback: string) =>
  (value?.trim() || fallback).replace(/\/$/, "");

export const isPreviewDeployment = process.env.VERCEL_ENV === "preview";
export const isPublicIndexingEnabled = isPublicIndexingApproved({
  vercelEnvironment: process.env.VERCEL_ENV,
  explicitApproval: process.env.ENABLE_PUBLIC_INDEXING,
});
export const shouldBlockIndexing = !isPublicIndexingEnabled;

export const siteConfig = {
  name: "StudyBook AI",
  description:
    "Convierte tus documentos en experiencias de aprendizaje con inteligencia artificial.",
  urls: {
    web: normalizeUrl(
      process.env.NEXT_PUBLIC_WEB_URL,
      "https://studybookai.com",
    ),
    app: normalizeUrl(
      process.env.NEXT_PUBLIC_APP_URL,
      "https://app.studybookai.com",
    ),
    api: normalizeUrl(
      process.env.NEXT_PUBLIC_API_URL,
      "https://api.studybookai.com",
    ),
  },
  contactEndpoint: "/api/contact",
} as const;

export const primaryNavigation = [
  { href: "/", label: "Inicio" },
  { href: "/features", label: "Funciones" },
  { href: "/students", label: "Para estudiantes" },
  { href: "/teachers", label: "Para docentes" },
  { href: "/pricing", label: "Planes" },
  { href: "/faq", label: "FAQ" },
  { href: "/contact", label: "Contacto" },
] as const;

export const accountLinks = {
  login: `${siteConfig.urls.app}/auth`,
  signup: `${siteConfig.urls.app}/auth?mode=signup`,
  studentSignup: `${siteConfig.urls.app}/auth?mode=signup&plan=student`,
  teacherPlans: `${siteConfig.urls.app}/plans?plan=teacher`,
} as const;

export const publicRoutes = [
  "/",
  "/features",
  "/students",
  "/teachers",
  "/pricing",
  "/faq",
  "/contact",
  "/security",
  "/privacy",
  "/terms",
  "/account-deletion",
] as const;
