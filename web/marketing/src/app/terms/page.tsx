import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";

export const metadata: Metadata = {
  title: "Términos",
  description: "Términos del servicio de StudyBook AI.",
  alternates: { canonical: "/terms" },
  robots: { index: false, follow: false },
};

export default function TermsPage() {
  return (
    <>
      <PageHero
        eyebrow="Información legal"
        title="Términos del servicio"
        description="Vigentes desde el 16 de septiembre de 2026."
      />
      <article className="section legal-page">
        <div className="container prose">
          <p><strong>Operador:</strong> Welinton Rafael Mejía González.</p>
          <p><strong>Contacto:</strong> <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.</p>
          <p><strong>Fecha de vigencia:</strong> 16 de septiembre de 2026.</p>

          <h2>1. Elegibilidad y cuenta</h2>
          <p>
            Durante el lanzamiento controlado debes tener al menos 18 años para crear y contratar de manera independiente una cuenta individual. Las personas menores de 18 años no pueden crear ni contratar una cuenta individual por sí solas. Un futuro acceso mediante institución educativa, padre, madre o tutor requerirá un mecanismo específico de autorización que todavía no está disponible.
          </p>
          <p>Eres responsable de proporcionar información correcta, proteger tus credenciales y mantener control sobre el correo asociado a tu cuenta.</p>

          <h2>2. Servicio educativo</h2>
          <p>
            StudyBook AI ofrece herramientas para transformar documentos en explicaciones, conversaciones, audio, flashcards, quizzes y recursos docentes. Es una herramienta de apoyo: la persona usuaria y, cuando corresponda, la institución mantienen la responsabilidad de revisar el resultado y tomar decisiones académicas.
          </p>

          <h2>3. Planes y precios</h2>
          <ul>
            <li>Free: US$0.</li>
            <li>Student Pro: US$6.99 por mes.</li>
            <li>Teacher Pro: US$13.99 por mes.</li>
            <li>Institution: precio y condiciones mediante contacto.</li>
          </ul>
          <p>No existe una prueba de US$1 ni otra prueba gratuita o pagada aprobada. El precio final, los impuestos que correspondan y las condiciones del proveedor se muestran antes de confirmar una compra.</p>

          <h2>4. Facturación, renovación y cancelación</h2>
          <p>
            Las condiciones de renovación deben coincidir con las mostradas por el proveedor de pago y el checkout activo. Una suscripción Student Pro o Teacher Pro puede cancelarse en cualquier momento mediante el proveedor donde fue adquirida. La cancelación evita la siguiente renovación, no termina inmediatamente un periodo ya pagado y permite usar las funciones pagadas hasta el final de ese periodo, sujeto al comportamiento real del proveedor. Después, la cuenta vuelve al plan Free salvo que se cierre.
          </p>
          <p>StudyBook AI no impone una penalidad separada por cancelar. Los planes Institution pueden regirse además por su acuerdo institucional. Eliminar la cuenta no cancela automáticamente una suscripción externa.</p>

          <h2>5. Reembolsos</h2>
          <p>
            Puede solicitarse el reembolso del primer pago de Student Pro o Teacher Pro dentro de los 7 días calendario posteriores a ese cargo inicial. Este beneficio comercial aplica una vez por usuario o cuenta.
          </p>
          <p>
            Las renovaciones ordinarias no son automáticamente reembolsables solo por falta de uso cuando el servicio estuvo disponible y la renovación ocurrió conforme a las condiciones informadas. Se revisarán solicitudes por cargos duplicados, errores de facturación atribuibles a StudyBook AI, cargos no autorizados sujetos a verificación, fallas materiales, imposibilidad de prestar el servicio o derechos exigidos por la ley aplicable.
          </p>
          <p>Las solicitudes se envían a <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.</p>

          <h2>6. Contenido del usuario</h2>
          <p>
            Conservas los derechos que legítimamente poseas sobre el contenido que subes. Declaras que tienes autorización para usarlo. Concedes a StudyBook AI una autorización limitada y no exclusiva para almacenar, procesar, analizar, transformar y transmitir ese contenido únicamente en la medida razonablemente necesaria para prestar las funciones que solicites. Esta autorización no transfiere la propiedad del contenido.
          </p>

          <h2>7. Inteligencia artificial</h2>
          <p>
            StudyBook AI utiliza inteligencia artificial para generar contenido educativo y de estudio. El resultado puede contener errores, omisiones o información inexacta. Debes revisar contenido importante antes de utilizarlo en decisiones académicas, profesionales, legales, médicas, financieras u otras decisiones de alto impacto. No garantizamos que el resultado sea exacto, completo o libre de errores.
          </p>

          <h2>8. Propiedad intelectual</h2>
          <p>
            Welinton Rafael Mejía González conserva, en la medida legalmente aplicable, los derechos sobre el software, diseño del producto, marca StudyBook AI y materiales originales de la plataforma. No se afirma que una marca, obra u otro derecho esté registrado salvo que esa inscripción haya sido verificada. Las consultas de propiedad intelectual pueden enviarse a <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.
          </p>

          <h2>9. Proveedores externos</h2>
          <p>
            El servicio utiliza Supabase, OpenAI, Render y Vercel para funciones de producción. Stripe se aplica cuando se utiliza facturación Web. Google Play se aplica únicamente cuando una compra Android está activa mediante ese canal. El reconocimiento de voz puede depender de servicios del dispositivo o plataforma. El uso de estos canales también queda sujeto a las condiciones aplicables del proveedor.
          </p>

          <h2>10. Disponibilidad y seguridad</h2>
          <p>
            Trabajamos para mantener el servicio disponible y proteger las cuentas, pero no prometemos disponibilidad del 100 %, funcionamiento sin errores, seguridad absoluta ni riesgo cero. Pueden existir mantenimiento, interrupciones, cambios razonables o fallos de proveedores externos.
          </p>

          <h2>11. Eliminación de cuenta</h2>
          <p>
            Puedes iniciar la eliminación desde Cuenta. El objetivo operativo es eliminar o anonimizar datos personales y contenido en sistemas activos dentro de un máximo de 30 días después de una solicitud válida. Los respaldos residuales pueden permanecer hasta 90 días. Podrán conservarse registros estrictamente necesarios para seguridad, facturación, obligaciones legales, reclamaciones o defensa de derechos durante el periodo legítimamente requerido.
          </p>

          <h2>12. Ley y jurisdicción</h2>
          <p>
            Estos Términos se regirán e interpretarán conforme a las leyes de la República Dominicana. Toda controversia relacionada con StudyBook AI será sometida a los tribunales competentes de la República Dominicana, conforme a las reglas de competencia aplicables, sin perjuicio de los derechos irrenunciables que correspondan a los consumidores y usuarios conforme a la legislación vigente.
          </p>

          <h2>13. Contacto y vigencia</h2>
          <p>
            Para soporte, privacidad, eliminación, reembolsos, asuntos legales o propiedad intelectual, escribe a <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>. El domicilio profesional de contacto autorizado se publica en <a href="/contact">Contacto</a> y <a href="/privacy">Privacidad</a>. Ese domicilio no convierte a MULTISERVICIOS ZORRILLA en propietario, operador, responsable del tratamiento, entidad jurídica detrás ni titular de StudyBook AI. Estos Términos entran en vigor el 16 de septiembre de 2026.
          </p>
        </div>
      </article>
    </>
  );
}
