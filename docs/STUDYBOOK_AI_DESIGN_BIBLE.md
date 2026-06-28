# StudyBook AI Design Bible

## Identidad oficial

- Producto: **StudyBook AI**.
- Mascota: **Booky**.
- Rol de Booky: **Chief Learning Companion**.
- Slogan principal: **Lee menos. Aprende más.**
- Filosofía: **Aprende mejor.**
- Promesa: **Transformamos cualquier contenido en conocimiento.**

StudyBook AI no se presenta como un conjunto de herramientas aisladas. Es una
experiencia de aprendizaje acompañada que convierte contenido, voz y práctica en
progreso comprensible.

## Booky

Booky es cercano, claro, sereno y competente. Acompaña sin infantilizar, explica
sin condescendencia y propone un siguiente paso concreto sin saturar la pantalla.

### Voz

- Habla en primera persona cuando ofrece acompañamiento.
- Usa frases cortas, humanas y orientadas a la acción.
- Reconoce el esfuerzo y propone una recuperación amable.
- Evita tecnicismos internos, estados de infraestructura y lenguaje punitivo.

### Microcopy recomendada

- "Pregúntame lo que quieras repasar. Estoy aquí para ayudarte."
- "Puedo convertir este contenido en un audiolibro inteligente."
- "Sube tu primer contenido y yo te ayudo a transformarlo en conocimiento."
- "Probemos de nuevo."
- "Booky está preparando tu experiencia..."

### Microcopy prohibida

Booky nunca muestra como mensaje de producto las palabras "Error",
"Incorrecto", "Fallaste" o "No entendiste". Las fallas técnicas se traducen en
una explicación breve y una acción de recuperación.

## Dirección visual

La interfaz es académica, contemporánea y contenida. La jerarquía debe surgir de
tipografía, espaciado, contraste y contenido; no de decoración excesiva.

### Tokens existentes

- Fondo oscuro: `#0B1120`.
- Superficie: `#111827`.
- Tarjeta: `#1E293B`.
- Primario: `#6366F1`.
- Secundario: `#8B5CF6`.
- Acento: `#22D3EE`.
- Éxito: `#22C55E`.
- Advertencia: `#F59E0B`.
- Texto principal: blanco.
- Texto secundario: `#CBD5E1`.
- Texto tenue: `#94A3B8`.

Usar el gradiente principal únicamente en acciones o momentos de marca. Las
tarjetas premium usan radio de 8 px, borde sutil y sombra contenida.

## Componentes base

Los componentes compartidos viven en `lib/widgets/studybook/`:

- `BookyCard`: presencia contextual de Booky y hasta dos acciones.
- `PremiumSectionCard`: contenedor premium reutilizable.
- `StudyBookPrimaryButton`: acción principal.
- `StudyBookSecondaryButton`: acción secundaria.
- `StudyBookEmptyState`: estado vacío humano y accionable.
- `StudyBookLoadingState`: espera con contexto de producto.
- `StudyBookBadge`: estado breve o logro.
- `StudyBookChip`: filtro o atributo compacto.
- `StudyBookMetricCard`: métrica principal legible.

No anidar tarjetas. En pantallas densas, priorizar una acción principal y como
máximo una secundaria por bloque. Los controles familiares conservan iconos de
Material y requieren texto cuando su significado no sea universal.

## Jerarquía de producto 1.0

### Student

El dashboard prioriza: continuar aprendiendo, Booky, plan inteligente, acciones
del día, progreso y recomendaciones. Analítica avanzada e historial aparecen
después de las acciones inmediatas.

### Teacher

Teacher Studio conserva su arquitectura académica aprobada. Booky puede orientar
o explicar, pero no sustituye los flujos de Academic Engine, Gradebook o Acta
Final.

### Free

La experiencia gratuita comunica valor antes que límites. Las restricciones se
explican con claridad y una alternativa útil, sin presión comercial agresiva.

### Instituciones

Durante la versión 1.0, el foco visible es estudiantes y docentes. La única
comunicación necesaria es: "Próximamente para instituciones, colegios y
universidades." Las capacidades Enterprise no deben dominar la navegación ni el
dashboard principal.

## Pantallas prioritarias

### Student Dashboard

- Booky aparece cerca del inicio con acciones hacia AudioBook y Tutor IA.
- El estado de carga se resuelve una vez y no se recalcula en `build()`.
- Los datos avanzados son secundarios frente al próximo paso del estudiante.

## Dashboard Excellence

El dashboard v1.0 debe contar una historia breve y accionable. Su orden es:

1. Saludo y orientación de Booky.
2. Resumen del día.
3. Siguiente mejor acción.
4. Continuar aprendiendo.
5. Acciones principales de AudioBook, Booky, creación y progreso.
6. Plan y acciones inteligentes.
7. Progreso, logros y recursos recomendados.
8. Capacidades avanzadas bajo demanda.
9. Instituciones y lanzamiento como información secundaria.

### Reglas finales

- Booky orienta primero; los indicadores explican después.
- La primera pantalla visible ofrece un siguiente paso, no un reporte técnico.
- Si no hay contenido, mostrar: "Sube tu primer documento y Booky lo
  convertirá en conocimiento."
- Las acciones principales deben ser visibles, familiares y consistentes.
- El refresh conserva el contenido anterior y evita cargas duplicadas.
- Analítica avanzada y beta permanecen accesibles, pero colapsadas inicialmente.
- La experiencia institucional se comunica como futuro y nunca domina el foco
  Student, Free o Teacher.
- Los estados vacíos explican qué ocurrirá al avanzar; no muestran mensajes como
  "Sin datos" o "No disponible".

## First Time User Experience

El FTUE debe explicar el valor y conducir a una primera acción útil en menos de
cinco minutos. La promesa visible es: "Sube cualquier contenido. Booky lo
convierte en una experiencia de aprendizaje."

### Reglas FTUE

- Presentar una acción sencilla antes de explicar todas las capacidades.
- No completar pasos únicamente por abrir una pantalla.
- Usar actividad real para reconocer AudioBook, quiz, conversación y progreso.
- Mostrar la ruta completa solo a usuarios nuevos.
- Compactar la guía después de los primeros avances y ocultarla al terminar.
- Permitir descartar la guía y conservar esa decisión localmente.
- Nunca otorgar XP, monedas o badges por acciones de onboarding.
- Mantener Free, Student, Teacher y Accessibility como rutas claras.
- No forzar preferencias de accesibilidad durante la bienvenida.
- Booky guía con tono humano: "Empecemos por algo sencillo" y "Puedes hacerlo
  en menos de 2 minutos".

Los componentes oficiales son `FtueWelcomeCard`, `FtueStepCard`,
`FtueQuickStartCard`, `BookyWelcomeCard` y `TimeToValueCard`. El contrato de
persistencia y QA está documentado en `docs/FTUE_V1.md`.

### Voice Tutor

- Se presenta como "Tutor IA con Booky".
- El primer bloque invita a preguntar o repasar.
- Micrófono, TTS, memoria y contexto mantienen su comportamiento técnico.
- Los estados de recuperación evitan lenguaje punitivo o técnico.

### AudioBook

- La promesa visible es aprendizaje escuchable, no generación técnica.
- Booky conecta contenido, audio, actividades y práctica.
- Las acciones explican el beneficio: escuchar, recordar mejor o preguntarle a
  Booky.

### Onboarding

- Booky se presenta desde el primer contacto.
- El recorrido empieza con una acción concreta: subir el primer contenido.
- La opción docente y la posibilidad de omitir se mantienen disponibles.

## Accesibilidad y responsive

- Mantener contraste AA como mínimo para texto y controles.
- No depender solo del color para comunicar estado.
- Permitir ajuste y salto de línea antes de reducir tipografía.
- Conservar áreas táctiles cómodas y foco visible.
- Verificar móvil y escritorio sin recortes, desbordes ni cambios de layout al
  cargar.

## Accessibility & Inclusive Learning

La accesibilidad es un pilar de StudyBook AI v1.0 junto a Free, Student y
Teacher. Booky comunica el principio: "No todos aprendemos igual. Yo puedo
ayudarte a estudiar de la forma que mejor funcione para ti."

### Reglas inclusivas

- Ofrecer audio, texto y práctica como rutas equivalentes de aprendizaje.
- Mostrar estado mediante texto o icono además de color.
- Usar `Semantics` en controles y componentes reutilizables cuando sea seguro.
- Mantener labels visibles y específicos en botones y switches.
- Permitir explicaciones simples, pasos cortos y preguntas breves.
- Evitar lenguaje punitivo y ofrecer siempre una recuperación clara.
- Guardar preferencias localmente y pedir consentimiento antes de sincronizar.
- Validar teclado, lector de pantalla, escalado de texto y responsive.

Los componentes oficiales son `AccessibilityCard`,
`AccessibilityToggleTile`, `AccessibleEmptyState` y `AccessibleTipCard`. Las
preferencias y límites de v1.0 se detallan en `docs/ACCESSIBILITY_V1.md`.

## Recurso visual oficial de Booky

Hasta recibir el arte oficial, Booky usa `Icons.auto_stories_rounded`. El código
incluye un TODO localizado para reemplazarlo sin cambiar la API de `BookyCard`.

Cuando el recurso esté aprobado:

1. Guardar variantes en `assets/branding/booky/`.
2. Incluir PNG o WebP con fondo transparente en resoluciones 1x, 2x y 3x.
3. Preparar variantes para fondos claros y oscuros si el contraste lo requiere.
4. Declarar los assets en `pubspec.yaml`.
5. Mantener proporciones, zona segura y expresión consistentes.
6. No usar poses infantiles, decorativas o sin relación con la acción.

## Criterio de revisión

Una experiencia está alineada cuando el estudiante entiende qué puede hacer,
por qué le ayuda y cuál es el siguiente paso sin conocer la arquitectura interna.
Cada nueva pantalla debe reutilizar estos componentes y pasar una revisión de
microcopy, accesibilidad, responsive y carga antes de ampliar el sistema.
