import type { Metadata } from "next";
import Link from "next/link";
import { FaqList } from "@/components/faq-list";
import { PageHero } from "@/components/page-hero";
import { frequentlyAskedQuestions } from "@/content/site-content";

export const metadata: Metadata = {
  title: "Preguntas frecuentes",
  description: "Respuestas claras sobre StudyBook AI, sus planes, documentos y seguridad.",
  alternates: { canonical: "/faq" },
};

export default function FaqPage() {
  return (
    <>
      <PageHero
        eyebrow="Preguntas frecuentes"
        title="Lo esencial, explicado con claridad."
        description="Conoce cómo funciona StudyBook AI y qué puedes esperar antes de comenzar."
      />
      <section className="section" aria-labelledby="faq-title">
        <div className="container narrow-container">
          <h2 className="visually-hidden" id="faq-title">Respuestas frecuentes</h2>
          <FaqList items={frequentlyAskedQuestions} />
          <div className="inline-cta">
            <p>¿Tu pregunta no aparece aquí?</p>
            <Link href="/contact">Ir a contacto</Link>
          </div>
        </div>
      </section>
    </>
  );
}
