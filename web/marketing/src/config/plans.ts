export type PlanId = "free" | "student" | "teacher" | "institution";

export type CommercialPlan = {
  id: PlanId;
  name: string;
  price: string;
  cadence?: string;
  description: string;
  audience: string;
  features: readonly string[];
  cta: string;
  href: string;
  featured?: boolean;
};

export const commercialPlans: readonly CommercialPlan[] = [
  {
    id: "free",
    name: "Free",
    price: "USD 0",
    description: "Conoce StudyBook AI con un uso mensual esencial.",
    audience: "Para conocer StudyBook AI",
    features: [
      "Biblioteca personal limitada",
      "3 documentos y 3 resúmenes al mes",
      "10 mensajes de Chat IA al mes",
      "1 set de flashcards y 1 quiz al mes",
    ],
    cta: "Comenzar gratis",
    href: "/auth?mode=signup&plan=free",
  },
  {
    id: "student",
    name: "Student Pro",
    price: "USD 6.99",
    cadence: "/mes",
    description: "Acceso ampliado a las herramientas de aprendizaje con IA.",
    audience: "Para estudiantes",
    features: [
      "AudioBook y Voice Tutor",
      "Resúmenes, flashcards y quizzes",
      "Banco de preguntas y generación de exámenes",
    ],
    cta: "Elegir Student Pro",
    href: "/plans?plan=student",
    featured: true,
  },
  {
    id: "teacher",
    name: "Teacher Pro",
    price: "USD 13.99",
    cadence: "/mes",
    description: "Herramientas docentes conectadas de principio a fin.",
    audience: "Para docentes",
    features: [
      "Todo Student Pro para aprender con IA",
      "Cursos, planificación y recursos",
      "Rúbricas, bancos y exámenes",
      "Asistencia y calificaciones",
    ],
    cta: "Descubrir Teacher Pro",
    href: "/plans?plan=teacher",
  },
  {
    id: "institution",
    name: "Institution",
    price: "Contacto",
    description: "Preparado para conversaciones con instituciones educativas.",
    audience: "Para instituciones",
    features: [
      "Evaluación de necesidades",
      "Acompañamiento de implementación",
      "Alcance definido con cada institución",
    ],
    cta: "Hablar con el equipo",
    href: "/contact?reason=institution",
  },
] as const;
