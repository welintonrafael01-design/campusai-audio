import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowRight,
  BookOpenCheck,
  CheckCircle2,
  GraduationCap,
  ShieldCheck,
  Sparkles,
  UploadCloud,
} from "lucide-react";
import { BookyStage } from "@/components/booky-stage";
import { FaqList } from "@/components/faq-list";
import { FeatureGrid } from "@/components/feature-grid";
import { PricingGrid } from "@/components/pricing-grid";
import { ProductPreview } from "@/components/product-preview";
import { accountLinks } from "@/config/site";
import {
  frequentlyAskedQuestions,
  learningFeatures,
  studentBenefits,
  teacherTools,
  workflowSteps,
} from "@/content/site-content";

export const metadata: Metadata = {
  alternates: { canonical: "/" },
};

const workflowIcons = [UploadCloud, Sparkles, BookOpenCheck, GraduationCap];

const heroCapabilities = learningFeatures.map((feature) => feature.title);

export default function HomePage() {
  return (
    <>
      <section className="home-hero" aria-labelledby="home-title">
        <div className="hero-ambient" aria-hidden="true" />
        <div className="container home-hero-grid">
          <div className="home-hero-content">
            <p className="eyebrow">Tu compañero inteligente de aprendizaje</p>
            <h1 id="home-title">
              Un documento.
              <span>Todo tu aprendizaje.</span>
            </h1>
            <p className="hero-copy">
              Convierte tus documentos en experiencias de aprendizaje con
              inteligencia artificial. Resume, pregunta, escucha, practica y
              evalúa tu conocimiento desde un solo lugar.
            </p>
            <div className="hero-capabilities" aria-label="Herramientas disponibles">
              {heroCapabilities.map((capability) => (
                <span key={capability}>{capability}</span>
              ))}
            </div>
            <div className="hero-actions">
              <a className="button" href={accountLinks.signup}>
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
          <BookyStage />
        </div>
      </section>

      <section className="section section-tight" aria-labelledby="tools-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Un espacio, muchas posibilidades</p>
            <h2 id="tools-title">
              Un documento. <span className="gradient-text">Muchas formas de aprender.</span>
            </h2>
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
            <p className="eyebrow">Así se siente StudyBook AI</p>
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
            {workflowSteps.map((step, index) => {
              const Icon = workflowIcons[index];
              return (
              <li key={step.number}>
                <div className="workflow-topline">
                  <span>{step.number}</span>
                  <Icon aria-hidden="true" size={22} />
                </div>
                <h3>{step.title}</h3>
                <p>{step.text}</p>
              </li>
              );
            })}
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
            <article className="audience-student">
              <span className="audience-icon" aria-hidden="true"><BookOpenCheck /></span>
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
            <article className="audience-teacher">
              <span className="audience-icon" aria-hidden="true"><GraduationCap /></span>
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
          <BookyStage
            message="Estoy aquí para ayudarte a comprender, practicar y avanzar paso a paso."
          />
        </div>
      </section>

      <section className="section trust-section" aria-labelledby="trust-title">
        <div className="container">
          <div className="trust-heading">
            <div>
              <p className="eyebrow">Confianza por diseño</p>
              <h2 id="trust-title">Tu espacio de aprendizaje sigue siendo tuyo.</h2>
            </div>
            <Link href="/security">Conocer nuestra arquitectura de seguridad</Link>
          </div>
          <div className="trust-grid">
            {[
              "Documentos privados",
              "Acceso autenticado",
              "Aislamiento entre usuarios",
              "Eliminación de cuenta",
            ].map((item) => (
              <div key={item}>
                <ShieldCheck aria-hidden="true" size={20} />
                <span>{item}</span>
              </div>
            ))}
          </div>
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

      <section className="section home-faq" aria-labelledby="home-faq-title">
        <div className="container faq-home-grid">
          <div>
            <p className="eyebrow">Preguntas frecuentes</p>
            <h2 id="home-faq-title">Antes de comenzar, lo esencial.</h2>
            <p className="lede-small">
              Respuestas directas sobre documentos, planes y privacidad.
            </p>
            <Link className="text-link" href="/faq">Ver todas las preguntas</Link>
          </div>
          <FaqList items={frequentlyAskedQuestions.slice(0, 4)} />
        </div>
      </section>

      <section className="final-cta" aria-labelledby="final-cta-title">
        <div className="container final-cta-inner">
          <div>
            <p className="eyebrow">Empieza a aprender de otra manera</p>
            <h2 id="final-cta-title">Convierte lo que estudias en lo que sabes.</h2>
            <p>Empieza con StudyBook AI y descubre una forma diferente de aprender.</p>
          </div>
          <a className="button button-light" href={accountLinks.signup}>
            Comenzar gratis
            <ArrowRight aria-hidden="true" size={18} />
          </a>
        </div>
      </section>
    </>
  );
}
