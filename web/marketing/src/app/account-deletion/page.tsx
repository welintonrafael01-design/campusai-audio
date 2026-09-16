import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Eliminar cuenta — borrador final",
  description: "Proceso de eliminación de cuentas de StudyBook AI pendiente de publicación final.",
  alternates: { canonical: "/account-deletion" },
  robots: { index: false, follow: false },
};

export default function AccountDeletionPage() {
  return (
    <>
      <PageHero
        eyebrow="Borrador final para aprobación"
        title="Eliminar tu cuenta de StudyBook AI"
        description="Puedes iniciar la eliminación autenticada desde la aplicación. También existe un correo monitoreado para solicitar asistencia si no puedes acceder."
      />
      <article className="section legal-page">
        <div className="container prose">
          <aside className="draft-notice" role="note">
            <strong>La publicación final sigue pendiente.</strong>
            <span>No envíes contraseñas, códigos de acceso ni documentos privados por correo. La fecha efectiva se fijará al aprobar la publicación.</span>
          </aside>

          <p><strong>Operador:</strong> Welinton Rafael Mejía González.</p>
          <p><strong>Contacto monitoreado:</strong> <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.</p>

          <h2>Eliminar desde la aplicación</h2>
          <ol>
            <li>Inicia sesión en StudyBook AI.</li>
            <li>Abre Cuenta.</li>
            <li>Selecciona “Eliminar mi cuenta”.</li>
            <li>Reautentícate cuando se solicite e introduce la frase de confirmación.</li>
            <li>Confirma la eliminación permanente.</li>
          </ol>
          <p>La aplicación muestra finalización únicamente cuando concluye el flujo del backend. Si una etapa falla, se informa que es necesario reintentar y no se presenta la eliminación como completa.</p>

          <h2>Si no puedes acceder</h2>
          <p>
            Escribe a <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a> para solicitar asistencia. El correo debe enviarse desde la dirección asociada a la cuenta cuando sea posible, pero un mensaje o una dirección por sí solos no autorizan la eliminación. Antes de ejecutar la solicitud será necesario verificar razonablemente el control de la cuenta.
          </p>

          <h2>Datos contemplados</h2>
          <ul>
            <li>Identidad de autenticación y mapeo interno de suscripción.</li>
            <li>Documentos cargados y objetos privados asociados.</li>
            <li>Texto extraído, fragmentos de recuperación y contenido generado.</li>
            <li>Conversaciones, AudioBooks y archivos de audio vinculados.</li>
            <li>Certificados, registros docentes y eventos de uso inventariados.</li>
          </ul>

          <h2>Plazos y copias residuales</h2>
          <p>
            Tras una solicitud válida, el objetivo operativo es eliminar o anonimizar los datos personales y el contenido del usuario en sistemas activos en un máximo de 30 días. El proceso técnico autenticado puede completarse antes, pero no prometemos eliminación instantánea de todos los sistemas o respaldos.
          </p>
          <p>
            Las copias residuales en respaldos pueden permanecer hasta 90 días antes de su sobrescritura o eliminación normal. Podrán conservarse registros estrictamente necesarios para seguridad, prevención de fraude, obligaciones legales, contabilidad, impuestos, disputas o defensa de derechos durante el periodo legítimamente requerido.
          </p>

          <h2>Facturación externa</h2>
          <p>
            Eliminar la cuenta de StudyBook AI no cancela por sí solo una suscripción administrada por Stripe, Google Play u otro proveedor. Debes cancelar o administrar la suscripción en el canal donde fue adquirida para evitar una renovación futura.
          </p>

          <h2>Contacto y vigencia</h2>
          <p>Las consultas de privacidad, soporte y eliminación se reciben en <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>. La dirección publicable continúa pendiente de revisión jurídica y la fecha efectiva se fijará únicamente al aprobar la publicación final.</p>
        </div>
      </article>
    </>
  );
}
