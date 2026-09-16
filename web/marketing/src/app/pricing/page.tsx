import type { Metadata } from "next";
import { PageHero } from "@/components/page-hero";
import { PricingGrid } from "@/components/pricing-grid";

export const metadata: Metadata = {
  title: "Planes",
  description: "Planes Free, Student Pro, Teacher Pro e Institution de StudyBook AI.",
  alternates: { canonical: "/pricing" },
};

export default function PricingPage() {
  return (
    <>
      <PageHero
        eyebrow="Planes"
        title="Un plan para cada forma de aprender y enseñar."
        description="Precios claros desde una única fuente comercial. Los límites y condiciones finales se muestran en la aplicación antes de contratar."
      />
      <section className="section" aria-labelledby="pricing-list-title">
        <div className="container">
          <h2 className="visually-hidden" id="pricing-list-title">Catálogo de planes</h2>
          <PricingGrid />
          <p className="pricing-disclaimer">
            No existe una prueba de US$1 ni otra prueba aprobada. Student Pro y
            Teacher Pro pueden cancelarse antes de la siguiente renovación; el
            acceso continúa hasta el final del periodo pagado, sujeto al proveedor.
            El primer pago puede solicitarse en reembolso dentro de 7 días calendario.
            Consulta los <a href="/terms">Términos</a> o escribe a{" "}
            <a href="mailto:studybookaiapp@gmail.com">studybookaiapp@gmail.com</a>.
            Impuestos, disponibilidad y condiciones pueden variar según plataforma
            y país y se muestran antes de confirmar una compra.
          </p>
        </div>
      </section>
    </>
  );
}
