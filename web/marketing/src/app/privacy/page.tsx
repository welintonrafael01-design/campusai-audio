import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Privacidad — borrador final",
  description: "Borrador final de la política de privacidad de StudyBook AI.",
  alternates: { canonical: "/privacy" },
  robots: { index: false, follow: false },
};

export default function PrivacyPage() {
  return (
    <>
      <PageHero
        eyebrow="Borrador final para aprobación"
        title="Política de privacidad"
        description="Este texto integra las decisiones aprobadas para el lanzamiento controlado. La fecha de vigencia será la fecha real del despliegue legal autorizado."
      />
      <article className="section legal-page">
        <div className="container prose">
          <aside className="draft-notice" role="note">
            <strong>Todavía no es una política vigente.</strong>
            <span>No se ha realizado el despliegue legal autorizado. La fecha efectiva será la fecha real de ese despliegue y esta página permanece excluida de indexación.</span>
          </aside>

          <p><strong>Operador:</strong> Welinton Rafael Mejía González.</p>
          <p>
            <strong>Domicilio de contacto profesional:</strong><br />
            Bufete Jurídico “MULTISERVICIOS ZORRILLA”,<br />
            Avenida Sabana Larga, núm. 148,<br />
            Ensanche Ozama, Santo Domingo Este,<br />
            República Dominicana.
          </p>
          <p>Este domicilio se publica únicamente como dirección profesional de contacto de StudyBook AI. MULTISERVICIOS ZORRILLA no es propietario, operador, responsable del tratamiento, entidad jurídica detrás ni titular de StudyBook AI.</p>
          <p><strong>Contacto de privacidad y soporte:</strong> <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.</p>
          <p><strong>Fecha de vigencia:</strong> será la fecha real del despliegue legal autorizado; no se aplicará retroactivamente.</p>

          <h2>1. Datos que procesamos</h2>
          <p>
            StudyBook AI puede procesar correo electrónico, identificador de cuenta, rol, estado de suscripción y preferencias. Según las funciones utilizadas, también puede procesar documentos cargados, texto extraído, instrucciones, conversaciones, resúmenes, flashcards, quizzes, AudioBooks, transcripciones derivadas de voz y registros académicos docentes como cursos, estudiantes, asistencia y calificaciones.
          </p>
          <p>
            También procesamos información operativa limitada, como eventos de uso, estado de límites, identificadores de solicitud y datos técnicos necesarios para autenticación, seguridad, prevención de abuso y confiabilidad.
          </p>

          <h2>2. Para qué usamos la información</h2>
          <p>
            Usamos estos datos para autenticar la cuenta, prestar las funciones solicitadas, transformar contenido en recursos educativos, operar voz y AudioBook, aplicar suscripciones y límites, mantener la seguridad, atender solicitudes y mejorar la confiabilidad del servicio.
          </p>

          <h2>3. Inteligencia artificial, documentos y voz</h2>
          <p>
            Fragmentos de documentos, instrucciones, preguntas, texto reconocido por voz y contenido necesario para una solicitud pueden enviarse desde el backend a OpenAI para generación, representaciones vectoriales o texto a voz. Voice Tutor usa servicios de reconocimiento de la plataforma o dispositivo. StudyBook AI no está diseñado para conservar la grabación cruda del micrófono como historial de la cuenta, aunque el texto reconocido puede procesarse o guardarse en resultados asociados al usuario.
          </p>
          <p>
            El contenido generado por IA puede contener errores, omisiones o información inexacta. Debe revisarse antes de utilizarse en decisiones académicas, profesionales, legales, médicas, financieras u otras decisiones de alto impacto.
          </p>

          <h2>4. Contenido aportado por el usuario</h2>
          <p>
            Las personas usuarias conservan los derechos que legítimamente posean sobre su contenido. Al solicitar una función, autorizan de forma limitada y no exclusiva a StudyBook AI a almacenar, procesar, analizar, transformar y transmitir ese contenido únicamente en la medida razonablemente necesaria para prestar el servicio solicitado. La persona o institución que aporta el material debe contar con autorización para utilizarlo.
          </p>

          <h2>5. Proveedores técnicos</h2>
          <ul>
            <li>Supabase para autenticación, base de datos y almacenamiento privado.</li>
            <li>OpenAI para funciones seleccionadas de IA, embeddings y texto a voz.</li>
            <li>Render para alojar la API de producción.</li>
            <li>Vercel para alojar las superficies Web públicas y la aplicación Flutter Web.</li>
            <li>Stripe cuando se utiliza el canal de facturación Web.</li>
            <li>Google Play únicamente cuando una compra Android se ofrece y procesa mediante ese canal.</li>
            <li>Servicios de voz del dispositivo o plataforma cuando se usa reconocimiento de voz.</li>
          </ul>
          <p>Estos proveedores pueden procesar datos conforme a sus propias condiciones, ubicaciones y salvaguardas aplicables. La descripción contractual y de transferencias queda sujeta a la revisión jurídica final.</p>

          <h2>6. Pagos y suscripciones</h2>
          <p>
            StudyBook AI conserva el estado de suscripción y los identificadores necesarios para aplicar accesos. El proveedor de pago procesa la información de cobro correspondiente. Eliminar una cuenta de StudyBook AI no cancela por sí solo una suscripción administrada externamente; debe gestionarse con el proveedor donde fue adquirida.
          </p>

          <h2>7. Retención</h2>
          <p>
            Mientras la cuenta esté activa, podemos conservar la información necesaria para prestar el servicio. Tras una solicitud válida de eliminación, el objetivo operativo es eliminar o anonimizar los datos personales y el contenido del usuario en los sistemas activos en un máximo de 30 días.
          </p>
          <p>
            Las copias residuales en respaldos pueden permanecer hasta 90 días antes de su sobrescritura o eliminación normal. Podremos conservar registros estrictamente necesarios para seguridad, prevención de fraude, obligaciones legales, contabilidad, impuestos, resolución de disputas o defensa de derechos durante el periodo legítimamente requerido para esos fines.
          </p>

          <h2>8. Eliminación de cuenta</h2>
          <p>
            Una persona autenticada puede iniciar el flujo desde Cuenta, reautenticarse cuando corresponda y confirmar la solicitud. El backend intenta eliminar objetos privados, documentos, fragmentos de recuperación, contenido generado, conversaciones, AudioBooks, certificados, registros docentes, eventos inventariados y finalmente la identidad. Una falla parcial se comunica para permitir un reintento seguro; no prometemos eliminación instantánea de todos los respaldos.
          </p>
          <p>Quien no pueda acceder a la aplicación puede solicitar asistencia mediante <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>. Un correo por sí solo no autoriza la eliminación: será necesario verificar el control de la cuenta.</p>

          <h2>9. Derechos y solicitudes</h2>
          <p>
            Las personas pueden solicitar acceso, corrección o eliminación y ejercer otros derechos que les reconozca la normativa aplicable. Para proteger la cuenta, podremos pedir información razonable de verificación. Las solicitudes se reciben en <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.
          </p>

          <h2>10. Edad mínima y uso educativo</h2>
          <p>
            Durante el lanzamiento controlado, una persona debe tener al menos 18 años para crear y contratar de manera independiente una cuenta individual. Las personas menores de 18 años no pueden crear ni contratar una cuenta individual por sí solas. Un futuro acceso para menores requerirá una institución educativa autorizada o un padre, madre o tutor legal y un mecanismo específico de consentimiento que todavía no está implementado.
          </p>

          <h2>11. Seguridad</h2>
          <p>
            La configuración de producción utiliza autenticación, autorización en servidor, aislamiento por propietario, almacenamiento privado y HTTPS. Aplicamos medidas técnicas y organizativas para reducir riesgos, pero ningún servicio puede garantizar seguridad absoluta, ausencia total de fallos o riesgo cero.
          </p>

          <h2>12. Ley aplicable, cambios y vigencia</h2>
          <p>
            Esta Política se regirá e interpretará conforme a las leyes de la República Dominicana. Toda controversia relacionada con StudyBook AI será sometida a los tribunales competentes de la República Dominicana, conforme a las reglas de competencia aplicables, sin perjuicio de los derechos irrenunciables que correspondan a los consumidores y usuarios conforme a la legislación vigente.
          </p>
          <p>
            La fecha de vigencia se fijará inmediatamente antes del despliegue legal autorizado y deberá coincidir con la fecha real de publicación. Los cambios futuros deberán indicar su fecha y comunicarse de forma apropiada según su relevancia.
          </p>
        </div>
      </article>
    </>
  );
}
