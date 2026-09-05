const normalizeUrl = (value: string | undefined, fallback: string) =>
  (value?.trim() || fallback).replace(/\/$/, "");

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
  contactEndpoint: process.env.NEXT_PUBLIC_CONTACT_ENDPOINT?.trim() || null,
} as const;

export const primaryNavigation = [
  { href: "/features", label: "Funciones" },
  { href: "/students", label: "Estudiantes" },
  { href: "/teachers", label: "Docentes" },
  { href: "/pricing", label: "Planes" },
  { href: "/faq", label: "Preguntas" },
] as const;

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
