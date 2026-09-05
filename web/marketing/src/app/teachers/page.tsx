import type { Metadata } from "next";
import {
  ArrowRight,
  BookOpenCheck,
  CheckCircle2,
  ClipboardCheck,
  GraduationCap,
  Users,
} from "lucide-react";
import { PageHero } from "@/components/page-hero";
import { accountLinks } from "@/config/site";
import { teacherTools } from "@/content/site-content";

export const metadata: Metadata = {
  title: "Para docentes",
  description: "Cursos, planificación, rúbricas, evaluaciones y seguimiento docente.",
  alternates: { canonical: "/teachers" },
};

export default function TeachersPage() {
  return (
    <>
      <PageHero
        eyebrow="StudyBook AI para docentes"
        title="Menos tiempo preparando. Más tiempo para enseñar."
        description="Organiza el curso, transforma el programa de clase y conecta planificación, recursos y seguimiento en un mismo flujo."
        actions={
          <a className="button" href={accountLinks.teacherPlans}>
            Descubrir Teacher Pro
            <ArrowRight aria-hidden="true" size={18} />
          </a>
        }
        tone="violet"
        visual={
          <div className="teacher-hero-visual" aria-label="Flujo de herramientas para docentes">
            <div><GraduationCap aria-hidden="true" /><span>Curso</span></div>
            <div><BookOpenCheck aria-hidden="true" /><span>Planificación</span></div>
            <div><ClipboardCheck aria-hidden="true" /><span>Evaluación</span></div>
            <div><Users aria-hidden="true" /><span>Seguimiento</span></div>
          </div>
        }
      />
      <section className="section" aria-labelledby="teacher-tools-title">
        <div className="container">
          <div className="section-heading">
            <p className="eyebrow">Del curso al aula</p>
            <h2 id="teacher-tools-title">Herramientas docentes con continuidad.</h2>
            <p>
              Prepara y administra los recursos principales sin dispersar el
              trabajo entre múltiples espacios.
            </p>
          </div>
          <ul className="teacher-tool-grid teacher-tool-grid-premium">
            {teacherTools.map((tool) => (
              <li key={tool}><CheckCircle2 aria-hidden="true" size={19} />{tool}</li>
            ))}
          </ul>
        </div>
      </section>
      <section className="section surface-band" aria-labelledby="teacher-flow-title">
        <div className="container split-grid">
          <div>
            <p className="eyebrow">Flujo docente</p>
            <h2 id="teacher-flow-title">El siguiente paso siempre está visible.</h2>
          </div>
          <ol className="plain-steps">
            <li><strong>1. Curso y unidad</strong><span>Define el contexto académico.</span></li>
            <li><strong>2. Material y planificación</strong><span>Convierte contenido en una ruta de clase.</span></li>
            <li><strong>3. Recursos y evaluación</strong><span>Prepara rúbricas, bancos y exámenes.</span></li>
            <li><strong>4. Seguimiento</strong><span>Registra asistencia y calificaciones.</span></li>
          </ol>
        </div>
      </section>
    </>
  );
}
