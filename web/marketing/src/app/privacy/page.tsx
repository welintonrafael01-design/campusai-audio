import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Privacidad — borrador",
  description: "Borrador público de la política de privacidad de StudyBook AI.",
  alternates: { canonical: "/privacy" },
  robots: { index: false, follow: false },
};

export default function PrivacyPage() {
  return (
    <>
      <PageHero
        eyebrow="Borrador legal"
        title="Política de privacidad"
        description="Documento de preparación. Requiere revisión humana y jurídica antes de su publicación como política vigente."
      />
      <article className="section legal-page">
        <div className="container prose">
          <aside className="draft-notice" role="note">
            <strong>No es una política vigente.</strong>
            <span>Faltan fecha efectiva, entidad responsable, contactos, jurisdicciones y calendario de retención aprobados.</span>
          </aside>
          <h2>1. Datos que puede procesar el servicio</h2>
          <p>
            StudyBook AI puede procesar identificadores de cuenta, rol y estado de suscripción. Según las herramientas utilizadas, también puede procesar documentos cargados, texto extraído, preguntas, conversaciones, recursos de aprendizaje, quizzes, flashcards, AudioBooks, transcripciones derivadas de voz y registros académicos docentes.
          </p>
          <h2>2. Uso de la información</h2>
          <p>
            La información se utiliza para ofrecer aprendizaje basado en documentos, generación asistida, voz, AudioBook, herramientas docentes, seguridad de la cuenta, límites de uso y confiabilidad del servicio.
          </p>
          <h2>3. Inteligencia artificial, documentos y voz</h2>
          <p>
            Fragmentos de documentos, instrucciones y texto de transcripciones pueden enviarse desde el backend a proveedores de inteligencia artificial para generar respuestas, representaciones vectoriales o audio. Voice Tutor usa reconocimiento de voz de la plataforma y no está diseñado para guardar la grabación cruda como historial de la cuenta.
          </p>
          <h2>4. Proveedores técnicos</h2>
          <p>
            La arquitectura actual contempla Supabase para autenticación, base de datos y almacenamiento privado; OpenAI para funciones seleccionadas de IA y voz; Stripe para pagos Web; Google Play para compras Android; y servicios de voz del dispositivo cuando se usa reconocimiento.
          </p>
          <p>Los roles contractuales, ubicaciones, transferencias y salvaguardas requieren revisión jurídica.</p>
          <h2>5. Pagos</h2>
          <p>
            StudyBook AI conserva el estado de suscripción y los identificadores necesarios para aplicar accesos. Eliminar una cuenta de StudyBook AI no implica por sí solo cancelar una suscripción administrada por un proveedor externo.
          </p>
          <h2>6. Retención</h2>
          <p>
            Todavía no existe un calendario universal aprobado. Deben definirse los criterios aplicables a cuentas, documentos, contenido generado, registros operativos, facturación y excepciones legales o de seguridad.
          </p>
          <h2>7. Eliminación de cuenta</h2>
          <p>
            Una persona autenticada puede iniciar el flujo desde Configuración, reautenticarse y confirmar. El backend intenta eliminar documentos privados, fragmentos de recuperación, contenido generado, conversaciones, AudioBooks, certificados y registros académicos inventariados antes de eliminar la identidad. Una falla parcial se comunica para permitir un reintento seguro.
          </p>
          <h2>8. Derechos, menores y uso educativo</h2>
          <p>
            Las jurisdicciones, derechos aplicables, edad mínima, alcance familiar y modelo de consentimiento deben aprobarse antes del lanzamiento. Este borrador no afirma que el servicio esté dirigido a menores.
          </p>
          <h2>9. Seguridad</h2>
          <p>
            La configuración de producción está diseñada con autenticación, aislamiento por propietario, almacenamiento privado y HTTPS. Ningún servicio puede garantizar seguridad absoluta.
          </p>
          <h2>10. Contacto y vigencia</h2>
          <p>
            El contacto de privacidad, el contacto de soporte, la entidad responsable y la fecha de vigencia están pendientes de aprobación. El formulario público no debe considerarse un canal de privacidad activo hasta que su proveedor monitorizado sea configurado y verificado.
          </p>
        </div>
      </article>
    </>
  );
}
