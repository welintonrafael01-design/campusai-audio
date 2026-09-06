import { siteConfig } from "@/config/site";

export const contactReasons = [
  { value: "support", label: "Soporte" },
  { value: "sales", label: "Ventas" },
  { value: "institution", label: "Institución" },
  { value: "privacy", label: "Privacidad" },
  { value: "other", label: "Otro" },
] as const;

export type ContactPayload = {
  name: string;
  email: string;
  reason: string;
  message: string;
  company: string;
  startedAt: number;
};

export function validateContactPayload(
  payload: ContactPayload,
  now = Date.now(),
): string | null {
  if (payload.company.trim()) return "No se pudo validar el formulario.";
  const elapsed = now - payload.startedAt;
  if (!Number.isFinite(payload.startedAt) || payload.startedAt <= 0) {
    return "No se pudo validar el formulario.";
  }
  if (elapsed < 2500) {
    return "Espera un momento antes de enviar el formulario.";
  }
  if (elapsed > 60 * 60 * 1000) {
    return "La sesión del formulario expiró. Recarga la página e inténtalo de nuevo.";
  }
  const name = payload.name.trim();
  const email = payload.email.trim();
  const message = payload.message.trim();
  if (name.length < 2 || name.length > 100) {
    return "Escribe un nombre válido.";
  }
  if (
    email.length > 254 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  ) {
    return "Escribe un correo válido.";
  }
  if (!contactReasons.some((reason) => reason.value === payload.reason)) {
    return "Selecciona un motivo válido.";
  }
  if (message.length < 10 || message.length > 2000) {
    return "El mensaje debe tener entre 10 y 2000 caracteres.";
  }
  return null;
}

type ContactApiResponse = {
  ok?: boolean;
  message?: string;
  error?: { message?: string };
};

export async function submitContactForm(payload: ContactPayload): Promise<string> {
  const validationError = validateContactPayload(payload);
  if (validationError) throw new Error(validationError);

  const response = await fetch(siteConfig.contactEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: payload.name.trim(),
      email: payload.email.trim(),
      reason: payload.reason,
      message: payload.message.trim(),
      company: payload.company,
      startedAt: payload.startedAt,
    }),
  });
  const result = (await response.json().catch(() => null)) as ContactApiResponse | null;
  if (!response.ok) {
    throw new Error(
      result?.error?.message ||
        "No pudimos enviar el mensaje. Inténtalo más tarde.",
    );
  }
  return result?.message || "Mensaje recibido.";
}
