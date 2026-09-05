import type { Metadata } from "next";
import { ContactForm } from "@/components/contact-form";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Contacto",
  description: "Formulario de contacto de StudyBook AI.",
  alternates: { canonical: "/contact" },
};

export default async function ContactPage({
  searchParams,
}: {
  searchParams: Promise<{ reason?: string }>;
}) {
  const params = await searchParams;
  return (
    <>
      <PageHero
        eyebrow="Contacto"
        title="Cuéntanos qué necesitas."
        description="El formulario está preparado para soporte, ventas, instituciones y privacidad. No transmitirá información hasta habilitar un endpoint revisado."
      />
      <section className="section" aria-labelledby="contact-form-title">
        <div className="container narrow-container">
          <h2 id="contact-form-title">Prepara tu mensaje</h2>
          <p className="section-intro">
            No incluyas contraseñas, documentos privados ni datos sensibles.
          </p>
          <ContactForm defaultReason={params.reason} />
        </div>
      </section>
    </>
  );
}
