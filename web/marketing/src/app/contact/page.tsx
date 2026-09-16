import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Contacto",
  description: "Canal de contacto monitoreado de StudyBook AI.",
  alternates: { canonical: "/contact" },
};

export default function ContactPage() {
  return (
    <>
      <PageHero
        eyebrow="Contacto"
        title="Estamos para ayudarte."
        description="Utiliza nuestro correo monitoreado para soporte, privacidad, eliminación de cuenta, facturación, asuntos legales o instituciones."
      />
      <section className="section" aria-labelledby="contact-channel-title">
        <div className="container narrow-container prose">
          <h2 id="contact-channel-title">Canal monitoreado</h2>
          <p>
            Escribe a <a href="mailto:studybookaiapp@gmail.com"><strong>studybookaiapp@gmail.com</strong></a>. No incluyas contraseñas, códigos de acceso ni documentos privados.
          </p>
          <p>Este canal atiende inicialmente solicitudes de soporte, privacidad, eliminación, reembolsos, propiedad intelectual y consultas institucionales.</p>
          <aside className="draft-notice" role="note">
            <strong>Formulario Web no habilitado.</strong>
            <span>El formulario automatizado continúa desactivado hasta configurar y verificar un proveedor de entrega. Ningún mensaje se descarta silenciosamente.</span>
          </aside>
          <p><strong>Operador:</strong> Welinton Rafael Mejía González.</p>
          <p>
            <strong>Domicilio de contacto profesional:</strong><br />
            Bufete Jurídico “MULTISERVICIOS ZORRILLA”,<br />
            Avenida Sabana Larga, núm. 148,<br />
            Ensanche Ozama, Santo Domingo Este,<br />
            República Dominicana.
          </p>
          <p>El bufete proporciona únicamente el domicilio profesional de contacto. No es propietario, operador, responsable del tratamiento, entidad jurídica detrás ni titular de StudyBook AI.</p>
        </div>
      </section>
    </>
  );
}
