import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Términos — borrador",
  description: "Borrador estructural de términos de StudyBook AI pendiente de revisión jurídica.",
  alternates: { canonical: "/terms" },
  robots: { index: false, follow: false },
};

export default function TermsPage() {
  return (
    <>
      <PageHero
        eyebrow="Borrador legal"
        title="Términos del servicio"
        description="Estructura pendiente de revisión jurídica. No representa todavía términos vigentes ni una oferta contractual final."
      />
      <article className="section legal-page">
        <div className="container prose">
          <aside className="draft-notice" role="note">
            <strong>Revisión jurídica obligatoria.</strong>
            <span>Faltan entidad legal, jurisdicción, vigencia, contactos, reglas de facturación y lenguaje contractual aprobado.</span>
          </aside>
          <h2>Áreas que deberán cubrir los términos finales</h2>
          <ul>
            <li>Elegibilidad, registro y protección de la cuenta.</li>
            <li>Licencia de uso y límites de las funciones disponibles.</li>
            <li>Responsabilidad sobre documentos y contenido proporcionado.</li>
            <li>Naturaleza asistiva de las respuestas generadas por IA.</li>
            <li>Planes, pagos, renovación, cancelación y reembolsos.</li>
            <li>Uso aceptable, suspensión y finalización de cuentas.</li>
            <li>Propiedad intelectual y tratamiento de comentarios.</li>
            <li>Disponibilidad, garantías, responsabilidad y resolución de disputas.</li>
          </ul>
          <h2>Lo que este borrador no establece</h2>
          <p>
            Este documento no fija jurisdicción, edad mínima, periodos de retención, políticas de reembolso, límites de responsabilidad ni entidad contratante. Esas decisiones deben ser aprobadas por responsables legales y de producto.
          </p>
          <h2>Uso educativo</h2>
          <p>
            StudyBook AI es una herramienta de apoyo. Las personas usuarias y las instituciones siguen siendo responsables de revisar el contenido, tomar decisiones académicas y contar con autorización para utilizar los materiales aportados.
          </p>
        </div>
      </article>
    </>
  );
}
