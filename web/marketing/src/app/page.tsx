import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, CheckCircle2 } from "lucide-react";
import { BookyPlaceholder } from "@/components/booky-placeholder";
import { FeatureGrid } from "@/components/feature-grid";
import { PricingGrid } from "@/components/pricing-grid";
import { ProductPreview } from "@/components/product-preview";
import { siteConfig } from "@/config/site";
import {
  learningFeatures,
  studentBenefits,
  teacherTools,
  workflowSteps,
} from "@/content/site-content";

export const metadata: Metadata = {
  alternates: { canonical: "/" },
};

export default function HomePage() {
  return (
    <>
      <section className="home-hero" aria-labelledby="home-title">
        <Image
          className="hero-background"
          src="/product/voice-tutor.png"
          alt=""
          fill
          sizes="100vw"
          priority
        />
        <div className="hero-shade" aria-hidden="true" />
        <div className="container home-hero-content">
          <p className="eyebrow">Aprendizaje conectado con IA</p>
          <h1 id="home-title">
            Un documento.
            <span>Todo tu aprendizaje.</span>
          </h1>
          <p className="hero-copy">
            Convierte tus documentos en experiencias de aprendizaje con
            inteligencia artificial. Resume, pregunta, escucha, practica y
            evalúa tu conocimiento desde un solo lugar.
          </p>
          <div className="hero-actions">
            <a className="button" href={`${siteConfig.urls.app}/auth?mode=signup`}>
              Comenzar gratis
              <ArrowRight aria-hidden="true" size={18} />
            </a>
            <Link className="button button-secondary" href="#como-funciona">
              Ver cómo funciona
            </Link>
          </div>
          <p className="microcopy">
            <CheckCircle2 aria-hidden="true" size={17} />
            Empieza gratis. Sin tarjeta de crédito.
          </p>
        </div>
      </section>

      <section className="section section-tight" aria-labelledby="tools-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Un espacio, varias formas de aprender</p>
            <h2 id="tools-title">Elige la herramienta que necesitas ahora.</h2>
            <p>
              Mantén el documento como punto de partida y cambia entre lectura,
              audio, conversación y práctica.
            </p>
          </div>
          <FeatureGrid features={learningFeatures} />
        </div>
      </section>

      <section className="section product-section" aria-labelledby="product-title">
        <div className="container">
          <div className="section-heading section-heading-wide">
            <p className="eyebrow">Producto real</p>
            <h2 id="product-title">Booky convierte intención en una siguiente acción clara.</h2>
            <p>
              Pregunta por texto o voz, recibe apoyo contextual y continúa en el
              mismo entorno de aprendizaje.
            </p>
          </div>
          <ProductPreview />
        </div>
      </section>

      <section className="section" id="como-funciona" aria-labelledby="workflow-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Cómo funciona</p>
            <h2 id="workflow-title">De contenido a comprensión, paso a paso.</h2>
          </div>
          <ol className="workflow-grid">
            {workflowSteps.map((step) => (
              <li key={step.number}>
                <span>{step.number}</span>
                <h3>{step.title}</h3>
                <p>{step.text}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="section audience-band" aria-labelledby="audience-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Dos experiencias, una plataforma</p>
            <h2 id="audience-title">Estudia mejor. Enseña con más tiempo.</h2>
          </div>
          <div className="audience-grid">
            <article>
              <p className="card-label">Estudiantes</p>
              <h3>Aprende de una forma diferente.</h3>
              <ul className="check-list">
                {studentBenefits.map((benefit) => (
                  <li key={benefit}>
                    <CheckCircle2 aria-hidden="true" size={19} />
                    {benefit}
                  </li>
                ))}
              </ul>
              <Link href="/students">Explorar Student Pro</Link>
            </article>
            <article>
              <p className="card-label">Docentes</p>
              <h3>Menos tiempo preparando. Más tiempo para enseñar.</h3>
              <p className="tool-list">{teacherTools.join(" · ")}</p>
              <Link href="/teachers">Explorar Teacher Pro</Link>
            </article>
          </div>
        </div>
      </section>

      <section className="section booky-section" aria-labelledby="booky-title">
        <div className="container booky-grid">
          <div>
            <p className="eyebrow">Tu compañero de aprendizaje</p>
            <h2 id="booky-title">Conoce a Booky</h2>
            <p className="lede-small">
              Booky organiza la experiencia para ayudarte a comprender,
              practicar y continuar. Te explica, te escucha, te pregunta y te
              acompaña.
            </p>
            <div className="booky-actions" aria-label="Lo que Booky puede hacer">
              <span>Te explica</span>
              <span>Te escucha</span>
              <span>Te pregunta</span>
              <span>Te acompaña</span>
            </div>
          </div>
          <BookyPlaceholder />
        </div>
      </section>

      <section className="section" aria-labelledby="plans-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Planes claros</p>
            <h2 id="plans-title">Empieza donde estás. Avanza cuando lo necesites.</h2>
            <p>El catálogo comercial vive en una sola configuración verificable.</p>
          </div>
          <PricingGrid />
        </div>
      </section>

      <section className="final-cta" aria-labelledby="final-cta-title">
        <div className="container final-cta-inner">
          <div>
            <p className="eyebrow">Tu próximo documento puede ser distinto</p>
            <h2 id="final-cta-title">Convierte contenido en aprendizaje.</h2>
          </div>
          <a className="button button-light" href={`${siteConfig.urls.app}/auth?mode=signup`}>
            Comenzar gratis
            <ArrowRight aria-hidden="true" size={18} />
          </a>
        </div>
      </section>
    </>
  );
}
