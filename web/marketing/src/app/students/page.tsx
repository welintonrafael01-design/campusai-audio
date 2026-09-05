import type { Metadata } from "next";
import { ArrowRight, CheckCircle2, Headphones, Library, Sparkles } from "lucide-react";
import { PageHero } from "@/components/page-hero";
import { ProductPreview } from "@/components/product-preview";
import { accountLinks } from "@/config/site";
import { studentBenefits } from "@/content/site-content";

export const metadata: Metadata = {
  title: "Para estudiantes",
  description: "Estudia a tu ritmo con documentos, AudioBook, preguntas y práctica.",
  alternates: { canonical: "/students" },
};

export default function StudentsPage() {
  return (
    <>
      <PageHero
        eyebrow="StudyBook AI para estudiantes"
        title="Estudia de una forma diferente."
        description="Convierte cada documento en explicaciones, audio y práctica para comprender mejor y avanzar a tu propio ritmo."
        actions={
          <a className="button" href={accountLinks.studentSignup}>
            Comenzar como estudiante
            <ArrowRight aria-hidden="true" size={18} />
          </a>
        }
        visual={<ProductPreview compact />}
      />
      <section className="section" aria-labelledby="student-benefits-title">
        <div className="container split-grid">
          <div>
            <p className="eyebrow">Tu manera de aprender importa</p>
            <h2 id="student-benefits-title">Combina lectura, escucha y práctica.</h2>
            <p className="lede-small">
              Elige el formato que mejor funcione para el momento, conserva tus
              documentos organizados y vuelve a ellos cuando lo necesites.
            </p>
          </div>
          <ul className="check-list large-check-list">
            {studentBenefits.map((benefit) => (
              <li key={benefit}><CheckCircle2 aria-hidden="true" />{benefit}</li>
            ))}
          </ul>
        </div>
      </section>
      <section className="section surface-band" aria-labelledby="student-flow-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Todo conectado</p>
            <h2 id="student-flow-title">Una biblioteca que también te ayuda a estudiar.</h2>
          </div>
          <div className="three-column-grid student-experience-grid">
            <article><span className="icon-box"><Library aria-hidden="true" /></span><h3>Organiza</h3><p>Reúne el material que quieres comprender.</p></article>
            <article><span className="icon-box"><Headphones aria-hidden="true" /></span><h3>Escucha</h3><p>Transforma contenido en una experiencia AudioBook.</p></article>
            <article><span className="icon-box"><Sparkles aria-hidden="true" /></span><h3>Practica</h3><p>Usa preguntas, flashcards y quizzes para continuar.</p></article>
          </div>
        </div>
      </section>
    </>
  );
}
