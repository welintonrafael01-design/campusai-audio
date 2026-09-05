export const learningFeatures = [
  {
    icon: "message",
    title: "Chat IA",
    description: "Pregunta sobre el contenido que has elegido estudiar.",
  },
  {
    icon: "summary",
    title: "Resumen",
    description: "Identifica ideas principales y puntos de apoyo.",
  },
  {
    icon: "audio",
    title: "AudioBook",
    description: "Escucha tu material en capítulos y retoma donde quedaste.",
  },
  {
    icon: "voice",
    title: "Voice Tutor",
    description: "Practica hablando y recibe explicaciones de Booky.",
  },
  {
    icon: "cards",
    title: "Flashcards",
    description: "Repasa conceptos clave en sesiones breves.",
  },
  {
    icon: "quiz",
    title: "Quiz",
    description: "Comprueba lo aprendido con práctica guiada.",
  },
  {
    icon: "bank",
    title: "Banco de preguntas",
    description: "Organiza preguntas relacionadas con cada tema.",
  },
  {
    icon: "exam",
    title: "Exámenes",
    description: "Prepara evaluaciones a partir del material docente.",
  },
] as const;

export const studentBenefits = [
  "Comprende documentos con explicaciones y resúmenes.",
  "Aprende a tu propio ritmo con lectura, audio y práctica.",
  "Reúne tus materiales en una biblioteca personal.",
  "Convierte conceptos en flashcards, preguntas y quizzes.",
] as const;

export const teacherTools = [
  "Cursos",
  "Estudiantes",
  "Planificación",
  "Rúbricas",
  "Banco de preguntas",
  "Exámenes",
  "Asistencia",
  "Calificaciones",
  "Ponderaciones",
] as const;

export const workflowSteps = [
  { number: "01", title: "Sube", text: "Añade el documento que quieres trabajar." },
  { number: "02", title: "Transforma", text: "Elige el recurso de aprendizaje que necesitas." },
  { number: "03", title: "Aprende", text: "Lee, escucha, pregunta y practica a tu ritmo." },
  { number: "04", title: "Domina", text: "Evalúa tu comprensión y continúa avanzando." },
] as const;

export const frequentlyAskedQuestions = [
  {
    question: "¿Qué puedo hacer con un documento?",
    answer:
      "Puedes resumirlo, hacer preguntas sobre su contenido, escucharlo como AudioBook y crear recursos de práctica según las opciones disponibles en tu plan.",
  },
  {
    question: "¿Necesito una tarjeta para comenzar?",
    answer:
      "No. El plan Free permite comenzar sin tarjeta de crédito. Los límites y capacidades de cada plan se muestran antes de contratar.",
  },
  {
    question: "¿StudyBook AI reemplaza a un docente?",
    answer:
      "No. StudyBook AI ayuda a estudiar y preparar materiales, pero las decisiones académicas y la orientación profesional siguen correspondiendo a las personas responsables.",
  },
  {
    question: "¿Mis documentos son públicos?",
    answer:
      "La arquitectura de producción está diseñada para acceso autenticado, aislamiento por usuario y almacenamiento privado. Ningún sistema puede prometer seguridad absoluta.",
  },
  {
    question: "¿Puedo eliminar mi cuenta?",
    answer:
      "La aplicación incluye un flujo autenticado de eliminación. La página pública explica el proceso y las alternativas que deben completarse antes del lanzamiento.",
  },
  {
    question: "¿Existe una opción para instituciones?",
    answer:
      "Institution está disponible para conversación comercial. El alcance se define con cada institución y no se presenta como un producto activo sin acuerdo previo.",
  },
] as const;
