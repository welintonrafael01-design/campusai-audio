import type { Metadata } from "next";
import { DatabaseZap, KeyRound, ShieldCheck, Trash2 } from "lucide-react";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Seguridad",
  description: "Principios de acceso, aislamiento y almacenamiento de StudyBook AI.",
  alternates: { canonical: "/security" },
};

const securityPrinciples = [
  {
    icon: KeyRound,
    title: "Acceso autenticado",
    text: "Las áreas personales requieren una sesión válida y controles de autorización en el servidor.",
  },
  {
    icon: ShieldCheck,
    title: "Aislamiento por usuario",
    text: "La arquitectura aplica propiedad y alcance de usuario para documentos y recursos asociados.",
  },
  {
    icon: DatabaseZap,
    title: "Almacenamiento privado",
    text: "Los documentos y artefactos privados están diseñados para permanecer en almacenamiento no público.",
  },
  {
    icon: Trash2,
    title: "Eliminación de cuenta",
    text: "Existe un flujo autenticado que coordina la eliminación de los datos inventariados de una cuenta.",
  },
] as const;

export default function SecurityPage() {
  return (
    <>
      <PageHero
        eyebrow="Seguridad"
        title="Privacidad y acceso forman parte de la arquitectura."
        description="StudyBook AI aplica controles técnicos para reducir riesgos y separar los datos de cada cuenta. Ningún sistema puede prometer seguridad absoluta."
      />
      <section className="section" aria-labelledby="security-principles-title">
        <div className="container">
          <h2 className="visually-hidden" id="security-principles-title">Principios de seguridad</h2>
          <div className="security-grid">
            {securityPrinciples.map(({ icon: Icon, title, text }) => (
              <article key={title}>
                <Icon aria-hidden="true" />
                <h2>{title}</h2>
                <p>{text}</p>
              </article>
            ))}
          </div>
        </div>
      </section>
      <section className="section surface-band" aria-labelledby="shared-security-title">
        <div className="container split-grid">
          <div>
            <p className="eyebrow">Responsabilidad compartida</p>
            <h2 id="shared-security-title">Tú también proteges tu espacio.</h2>
          </div>
          <div className="prose compact-prose">
            <p>Usa una contraseña única, protege el acceso a tu correo y cierra sesión en dispositivos compartidos.</p>
            <p>Sube únicamente contenido que tengas autorización para utilizar y evita incluir secretos innecesarios.</p>
            <p>La información pública de contacto para reportes de seguridad debe aprobarse antes del lanzamiento.</p>
          </div>
        </div>
      </section>
    </>
  );
}
