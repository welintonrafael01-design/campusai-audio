"use client";

import { FormEvent, useRef, useState } from "react";
import { Send } from "lucide-react";
import {
  contactReasons,
  submitContactForm,
  type ContactPayload,
} from "@/lib/contact";

export function ContactForm({ defaultReason = "support" }: { defaultReason?: string }) {
  const startedAt = useRef<number | null>(null);
  const [status, setStatus] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setStatus("");
    const form = new FormData(event.currentTarget);
    const payload: ContactPayload = {
      name: String(form.get("name") ?? ""),
      email: String(form.get("email") ?? ""),
      reason: String(form.get("reason") ?? ""),
      message: String(form.get("message") ?? ""),
      company: String(form.get("company") ?? ""),
      startedAt: startedAt.current ?? Date.now(),
    };

    try {
      await submitContactForm(payload);
      setStatus("Mensaje enviado.");
      event.currentTarget.reset();
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "No se pudo validar el mensaje.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form
      className="contact-form"
      onFocusCapture={() => {
        startedAt.current ??= Date.now();
      }}
      onSubmit={handleSubmit}
      noValidate
    >
      <div className="form-grid">
        <label>
          Nombre
          <input name="name" autoComplete="name" maxLength={100} required />
        </label>
        <label>
          Correo electrónico
          <input name="email" type="email" autoComplete="email" required />
        </label>
      </div>
      <label>
        Motivo
        <select name="reason" defaultValue={defaultReason}>
          {contactReasons.map((reason) => (
            <option value={reason.value} key={reason.value}>
              {reason.label}
            </option>
          ))}
        </select>
      </label>
      <label>
        Mensaje
        <textarea name="message" minLength={10} maxLength={2000} rows={7} required />
      </label>
      <label className="honeypot" aria-hidden="true">
        Empresa
        <input name="company" tabIndex={-1} autoComplete="off" />
      </label>
      <div className="form-footer">
        <button className="button" type="submit" disabled={isSubmitting}>
          <Send aria-hidden="true" size={18} />
          {isSubmitting ? "Enviando..." : "Enviar mensaje"}
        </button>
        <p className="form-note">
          El endpoint permanecerá desactivado hasta completar su revisión de
          seguridad y privacidad.
        </p>
      </div>
      <p className="form-status" aria-live="polite">
        {status}
      </p>
    </form>
  );
}
