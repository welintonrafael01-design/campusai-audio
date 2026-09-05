import type { Metadata } from "next";
import { ArrowRight, FileText, Headphones, MessagesSquare } from "lucide-react";
import { FeatureGrid } from "@/components/feature-grid";
import { PageHero } from "@/components/page-hero";
import { ProductPreview } from "@/components/product-preview";
import { siteConfig } from "@/config/site";
import { learningFeatures, workflowSteps } from "@/content/site-content";

export const metadata: Metadata = {
  title: "Funciones",
  description: "Resumen, chat, AudioBook, Voice Tutor y práctica desde tus documentos.",
  alternates: { canonical: "/features" },
};

export default function FeaturesPage() {
  return (
    <>
      <PageHero
        eyebrow="Funciones conectadas"
        title="Tu documento no termina cuando lo subes."
        description="Úsalo para comprender, escuchar, conversar, practicar y evaluar lo aprendido sin perder el contexto."
        actions={
          <a className="button" href={`${siteConfig.urls.app}/auth?mode=signup`}>
            Probar StudyBook AI
            <ArrowRight aria-hidden="true" size={18} />
          </a>
        }
      />
      <section className="section" aria-labelledby="feature-list-title">
        <div className="container">
          <h2 className="visually-hidden" id="feature-list-title">
            Herramientas de StudyBook AI
          </h2>
          <FeatureGrid features={learningFeatures} />
        </div>
      </section>
      <section className="section surface-band" aria-labelledby="connected-title">
        <div className="container split-grid">
          <div>
            <p className="eyebrow">Una experiencia continua</p>
            <h2 id="connected-title">Del texto a una sesión de aprendizaje completa.</h2>
            <p className="lede-small">
              Cada herramienta parte del contenido seleccionado. Puedes cambiar
              de formato sin reconstruir manualmente tu contexto.
            </p>
          </div>
          <ul className="process-list">
            <li><FileText aria-hidden="true" />Selecciona el documento.</li>
            <li><MessagesSquare aria-hidden="true" />Pregunta y comprende.</li>
            <li><Headphones aria-hidden="true" />Escucha y repasa.</li>
          </ul>
        </div>
      </section>
      <section className="section" aria-labelledby="feature-workflow-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Flujo sencillo</p>
            <h2 id="feature-workflow-title">Sube, transforma, aprende y domina.</h2>
          </div>
          <ol className="workflow-grid">
            {workflowSteps.map((step) => (
              <li key={step.number}>
                <span>{step.number}</span><h3>{step.title}</h3><p>{step.text}</p>
              </li>
            ))}
          </ol>
          <ProductPreview />
        </div>
      </section>
    </>
  );
}
