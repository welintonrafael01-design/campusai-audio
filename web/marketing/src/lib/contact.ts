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

export function validateContactPayload(payload: ContactPayload): string | null {
  if (payload.company.trim()) return "No se pudo validar el formulario.";
  if (Date.now() - payload.startedAt < 2500) {
    return "Espera un momento antes de enviar el formulario.";
  }
  if (payload.name.trim().length < 2 || payload.name.length > 100) {
    return "Escribe un nombre válido.";
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(payload.email.trim())) {
    return "Escribe un correo válido.";
  }
  if (!contactReasons.some((reason) => reason.value === payload.reason)) {
    return "Selecciona un motivo válido.";
  }
  if (payload.message.trim().length < 10 || payload.message.length > 2000) {
    return "El mensaje debe tener entre 10 y 2000 caracteres.";
  }
  return null;
}

export async function submitContactForm(payload: ContactPayload) {
  const validationError = validateContactPayload(payload);
  if (validationError) throw new Error(validationError);
  if (!siteConfig.contactEndpoint) {
    throw new Error(
      "El canal seguro de contacto aún no está habilitado. No se enviaron datos.",
    );
  }

  const response = await fetch(siteConfig.contactEndpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: payload.name.trim(),
      email: payload.email.trim(),
      reason: payload.reason,
      message: payload.message.trim(),
    }),
  });
  if (!response.ok) {
    throw new Error("No pudimos enviar el mensaje. Inténtalo más tarde.");
  }
}
