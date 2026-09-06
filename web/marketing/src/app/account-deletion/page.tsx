import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Eliminar cuenta — borrador",
  description: "Borrador del proceso público de eliminación de cuentas de StudyBook AI.",
  alternates: { canonical: "/account-deletion" },
  robots: { index: false, follow: false },
};

export default function AccountDeletionPage() {
  return (
    <>
      <PageHero
        eyebrow="Borrador de proceso"
        title="Eliminar tu cuenta de StudyBook AI"
        description="La eliminación autenticada ya existe en la aplicación. La alternativa pública aún requiere un flujo de verificación y contactos aprobados."
      />
      <article className="section legal-page">
        <div className="container prose">
          <aside className="draft-notice" role="note">
            <strong>Flujo público todavía no habilitado.</strong>
            <span>No envíes contraseñas ni documentos privados mediante formularios o mensajes no verificados.</span>
          </aside>
          <h2>Eliminar desde la aplicación</h2>
          <ol>
            <li>Inicia sesión en StudyBook AI.</li>
            <li>Abre Configuración.</li>
            <li>Selecciona “Eliminar mi cuenta”.</li>
            <li>Introduce tu contraseña actual y la frase de confirmación solicitada.</li>
            <li>Confirma la eliminación permanente.</li>
          </ol>
          <p>La aplicación muestra finalización únicamente cuando el flujo del backend concluye. Si una etapa falla, la cuenta permanece disponible para un reintento seguro.</p>
          <h2>Si no puedes acceder a la aplicación</h2>
          <p>
            La alternativa Web debe verificar el control de la cuenta mediante un desafío temporal por correo u otro método aprobado. Un correo, identificador o mensaje por sí solo no constituye autorización suficiente para eliminar una cuenta.
          </p>
          <p>El contacto monitorizado y el flujo verificado siguen pendientes. Esta página no acepta todavía solicitudes de eliminación.</p>
          <h2>Datos contemplados</h2>
          <ul>
            <li>Identidad de autenticación y mapeo interno de suscripción.</li>
            <li>Documentos cargados y objetos privados asociados.</li>
            <li>Fragmentos de recuperación y recursos de aprendizaje generados.</li>
            <li>Conversaciones, AudioBooks y archivos de audio vinculados.</li>
            <li>Certificados, registros docentes y eventos de uso asociados a la cuenta.</li>
          </ul>
          <h2>Retención y facturación externa</h2>
          <p>
            Las categorías, motivos y periodos de posible retención legal todavía requieren aprobación. La eliminación de la cuenta no afirma cancelar suscripciones administradas por Stripe o Google Play; deben gestionarse con el proveedor original.
          </p>
          <h2>Proceso, plazo y contacto</h2>
          <p>
            El procedimiento público, el plazo de respuesta y los contactos de privacidad y soporte deben completarse y verificarse antes de publicar esta página como mecanismo activo.
          </p>
        </div>
      </article>
    </>
  );
}
