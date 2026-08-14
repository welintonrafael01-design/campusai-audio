# StudyBook AI Product Audit

Fecha: 2026-08-13  
Rama auditada: `fix/android-platform-compat-838084d`  
Repositorio: `/Users/welintonmejia/Desktop/campusai-audio`

## 1. Resumen Ejecutivo

StudyBook AI tiene mucho valor real: carga de PDFs, chat con documentos, resumen, AudioBook, flashcards, quizzes, biblioteca, recursos docentes, cursos, asistencia, calificaciones, acta final, billing y accesibilidad. El problema principal no es falta de funcionalidad; es exceso de superficie visible, deuda de navegación y demasiadas capas experimentales mezcladas con el producto core.

La app debe simplificarse hacia una experiencia AI-first:

1. Inicio con herramientas IA principales y un documento activo.
2. Biblioteca como centro de documentos/resultados.
3. Aprendizaje para progreso, historial y práctica.
4. Teacher Studio separado del Dashboard principal.
5. Cuenta para plan, ajustes, accesibilidad y sesión.

El Dashboard actual no debe seguir siendo un contenedor de todo. Hoy combina bienvenida, métricas, Panel Educator, herramientas AI, resumen, audio, búsqueda semántica, workspaces, recientes, chats e historial en una sola pantalla (`dashboard_screen.dart:1972-2122`). Eso crea fricción antes de llegar a lo valioso: usar IA con contenido.

## 2. Diagnóstico Actual

### Fortalezas

- Funciones core de IA ya existen en rutas reales: chat (`app_router.dart:163-194`), examen (`196-216`), flashcards (`217-238`), rúbrica (`239-257`), banco de preguntas (`258-279`), planificación (`280-298`) y AudioBook (`79-116`).
- Biblioteca consolida documentos, audiolibros, chats, flashcards y exámenes (`library_screen.dart:37-45`).
- Backend expone endpoints funcionales para documentos, RAG, recursos académicos, cloud, billing, exportaciones, audiobook y voice (`backend/app/main.py:78-88`).
- Cloud API usa `Authorization` para recursos de usuario (`cloud_api_service.dart:13-20`, `cloud.py:107-130`).
- Historial local ya está aislado por usuario (`history_service.dart:12-25`).
- Student Dashboard tiene un controller centralizado, aunque demasiado ambicioso (`student_dashboard_controller.dart:123-240`).

### Problema Sistémico

La app parece una suite institucional completa cuando debería sentirse, primero, como una herramienta clara de IA educativa. Hay 29 pantallas Dart reales, 185 servicios Dart y múltiples capas RC/Enterprise/Marketplace/Autonomous/QA coexistiendo en `lib/services`. Varias pantallas son grandes y difíciles de mantener:

- `teaching_plan_screen.dart`: 3016 líneas.
- `audiobook_studio_screen.dart`: 2695 líneas.
- `library_screen.dart`: 2456 líneas.
- `dashboard_screen.dart`: 2353 líneas.
- `courses_screen.dart`: 1913 líneas.
- `api_service.dart`: 1302 líneas.

## 3. Inventario Funcional

| Módulo | Archivo principal | Ruta | Usuario | Importancia | Uso probable | Decisión UI | Riesgo |
|---|---|---|---|---|---|---|---|
| Auth | `auth_screen.dart` | `/auth` | Todos | CORE | Alta | Permanecer | Alto |
| Dashboard actual | `dashboard_screen.dart` | `/dashboard` | Todos | CORE, pero sobrecargado | Alta | Rediseñar/fusionar | Alto |
| Biblioteca | `library_screen.dart` | `/library` | Todos | CORE | Alta | Permanecer | Alto |
| Chat documento | `chat_screen.dart` | `/chat/:documentId` | Todos | CORE | Alta | Permanecer como herramienta AI | Alto |
| Upload PDF | `dashboard_screen.dart`, `api_service.dart` | Acción | Todos | CORE | Alta | Permanecer como CTA primario | Alto |
| Resumen | `dashboard_screen.dart` | Dashboard | Todos | CORE | Alta | Convertir en herramienta explícita | Medio |
| AudioBook Studio | `audiobook_studio_screen.dart` | `/audiobook-studio` | Student/Accessibility/Teacher | CORE | Alta | Permanecer, simplificar | Alto |
| Voice Tutor | `voice_tutor_screen.dart` | `/voice-tutor` | Student/Accessibility | IMPORTANTE | Media | Mantener en AI Tools | Medio |
| Flashcards | `flashcards_screen.dart` | `/flashcards/:documentId` | Student | CORE | Alta | Permanecer | Medio |
| Quiz/Exam | `exam_screen.dart` | `/exam/:documentId` | Student/Teacher | CORE | Alta | Permanecer; nomenclatura clara | Medio |
| Banco de preguntas | `question_bank_screen.dart` | `/question-bank/:documentId` | Teacher/Student avanzado | IMPORTANTE | Media | Mantener como AI avanzado | Medio |
| Rúbricas | `rubric_screen.dart` | `/rubric/:documentId` | Teacher | IMPORTANTE | Media | Mover a Teacher Studio | Medio |
| Teaching Plan | `teaching_plan_screen.dart` | `/teaching-plan/:documentId` | Teacher | IMPORTANTE | Media | Mover a Teacher Studio | Alto |
| Unit Workspace | `unit_workspace_screen.dart` | `/unit-workspace` | Teacher | AVANZADO | Baja/media | Ocultar detrás de planificación | Medio |
| Cursos | `courses_screen.dart` | `/courses` | Teacher | IMPORTANTE | Media | Teacher Studio | Medio |
| Estudiantes | `students_screen.dart` | `/students` | Teacher | IMPORTANTE | Media | Teacher Studio | Medio |
| Asistencia | `attendance_screen.dart` | `/attendance` | Teacher | IMPORTANTE | Media | Teacher Studio | Medio |
| Calificaciones | `gradebook_screen.dart` | `/gradebook` | Teacher | IMPORTANTE | Media | Teacher Studio | Medio |
| Ponderaciones | `assessment_weights_screen.dart` | `/assessment-weights` | Teacher | SECUNDARIO | Baja/media | Teacher Studio avanzado | Bajo |
| Acta final | `final_report_screen.dart` | `/final-report` | Teacher | SECUNDARIO | Baja | Teacher Studio avanzado | Medio |
| Academic Dashboard | `academic_dashboard_screen.dart` | `/academic-dashboard` | Teacher | AVANZADO | Baja | Ocultar avanzado | Bajo |
| Reconocimientos | `academic_recognition_screen.dart` | `/academic-recognition` | Teacher/Admin | AVANZADO | Baja | Ocultar | Bajo |
| Transcript | `student_transcript_screen.dart` | `/student-transcript` | Teacher | AVANZADO | Baja | Ocultar bajo reportes | Bajo |
| Student Profile | `student_profile_screen.dart` | `/student-profile` | Teacher | SECUNDARIO | Baja | Fusionar con estudiantes | Bajo |
| Student Dashboard | `student_dashboard_screen.dart` | `/student-dashboard` | Student | IMPORTANTE pero pesado | Media | Fusionar con Aprendizaje | Medio |
| Planes | `plans_screen.dart` | `/plans` | Todos | CORE comercial | Media | Cuenta/Upgrade | Medio |
| Settings | `settings_screen.dart` | `/settings` | Todos | CORE | Media | Cuenta | Bajo |
| Admin Analytics | `admin_analytics_screen.dart` | `/admin` | Admin | AVANZADO | Baja | Oculto/Admin only | Alto |
| Financial Dashboard | `admin/financial_dashboard_screen.dart` | `/admin/financial-dashboard` | Admin | AVANZADO | Baja | Oculto/Admin only | Alto |
| Certificate Verify | `certificate_verify_screen.dart` | `/verify/:certificateId` | Público | SECUNDARIO | Baja | Mantener público | Bajo |
| Reset Password | `reset_password_screen.dart` | `/reset-password` | Público | CORE | Baja | Mantener | Bajo |

Clasificación global:

- A CORE: Auth, Inicio IA, Biblioteca, Chat, Upload, Resumen, AudioBook, Flashcards, Quiz, Planes/Cuenta.
- B IMPORTANTE: Voice Tutor, Teacher Studio, Banco, Rúbrica, Planificación, Cursos, Gradebook.
- C SECUNDARIO: Asistencia, Acta final, Transcript, Ponderaciones.
- D AVANZADO: Academic Dashboard, Recognition, Admin, Enterprise analytics.
- E REDUNDANTE: Dashboard actual vs Student Dashboard; Audio Libro vs Audiolibro; Panel Educator vs Teacher Studio.
- F OBSOLETO: backups `.bak`, RC/QA widgets visibles o importables en producto final si no están detrás de flags.
- G OCULTO/BACKGROUND: Learning Engine, Academic Engine, cloud sync, storage, billing backend, usage limits.

## 4. Arquitectura Actual

### Flutter

- `app_router.dart` define muchas rutas sin `redirect` global visible (`app_router.dart:35-483`). Esto hace que la protección dependa de UI/servicios o backend, no de navegación.
- `DashboardScreen` concentra demasiada lógica de carga, generación, navegación, audio y presentación (`dashboard_screen.dart:145-156`, `1811-1952`, `1972-2122`).
- `DashboardStats` ejecuta múltiples llamadas cloud/backend desde un `FutureBuilder` dentro del widget (`dashboard_stats.dart:83-97`, `168-170`).
- `DashboardAcademicActivity` vuelve a llamar `ApiService.getUsageSummary()` desde otro `FutureBuilder` (`dashboard_academic_activity.dart:36-38`), duplicando carga ya usada por `DashboardStats`.
- `StudentDashboardController` centraliza mucho, pero mezcla core learning con enterprise, marketplace, institution, RC readiness y autonomous actions (`student_dashboard_controller.dart:248-345`).

### Backend

- `main.py` monta rutas de documentos, cloud, export, certificates, analytics, billing, educator, audiobook y voice (`backend/app/main.py:78-88`).
- `documents.py` es un monolito de endpoints: upload, chat, teaching-plan, rubric, study-guide, resources, question-bank, exam, flashcards, streaming, files, semantic search, audio, audiobook y workspace (`documents.py:591-1963`).
- `cloud.py` está bien orientado a usuario autenticado con `require_current_user` en endpoints como workspaces (`cloud.py:107-130`).
- Hay datos generados dentro de `backend/app/audio` y `backend/app/uploads` que deben excluirse del artefacto release.

## 5. Problemas UX/UI

### Críticos / Altos

1. **Dashboard demasiado largo y competido.**  
   Evidencia: `buildDashboardBody` incluye más de 10 bloques consecutivos (`dashboard_screen.dart:1978-2122`).  
   Impacto: el usuario no entiende cuál es la acción principal.

2. **Duplicación Audio Libro / Audiolibro.**  
   Evidencia: Dashboard Tools muestra `Audio Libro` y `Audiolibro` como tarjetas separadas (`dashboard_tools.dart:92-113`). Educator Center también añade `Audio Libro` (`dashboard_educator_center.dart:80-87`).  
   Impacto: parece bug de producto.

3. **Teacher/Educator compite con usuario general.**  
   Evidencia: `DashboardEducatorCenter` vive dentro del Dashboard principal (`dashboard_screen.dart:2012-2022`) y se basa solo en plan Teacher (`dashboard_educator_center.dart:31-36`).  
   Impacto: Teacher Studio domina el inicio y el usuario Student se confunde si hay leaks de plan/estado.

4. **Sidebar demasiado pobre para la cantidad de producto.**  
   Evidencia: solo Dashboard, Biblioteca, Planes, Finanzas, Mi Cuenta (`sidebar.dart:60-99`).  
   Impacto: muchas pantallas quedan escondidas y se accede a ellas por rutas laterales o botones contextuales.

5. **Hero ocupa espacio de decisión.**  
   Evidencia: DashboardHero incluye saludo, plan, pills, métricas y CTA (`dashboard_hero.dart:31-241`).  
   Impacto: bonito, pero retrasa las herramientas AI.

### Medios

- Mensajes alternan “Audio Libro”, “Audiolibro” y “AudioBook”.
- Hay muchas métricas antes de resultados útiles.
- Student Dashboard tiene demasiados conceptos para un usuario nuevo: Campus Intelligence, Marketplace, Autonomous Actions, RC readiness, digital twin.
- Biblioteca es potente pero densa: documentos, audiobooks, chats, flashcards, exams, favoritos, local/cloud, filtros y orden en una pantalla (`library_screen.dart:37-70`).

## 6. Problemas Técnicos

| Severidad | Problema | Evidencia | Recomendación |
|---|---|---|---|
| CRÍTICO | `ADMIN_API_KEY` puede llegar al frontend por `dart-define`. | `analytics_service.dart:5-14` | Eliminar uso frontend; analytics admin solo backend/auth role. |
| ALTO | `ApiService.baseUrl` hardcodeado a `http://localhost:8000`. | `api_service.dart:10-12` | Usar `String.fromEnvironment('API_BASE_URL')` con default seguro. |
| ALTO | Router sin guard global visible. | `app_router.dart:35-483` | Agregar redirect por auth/rol/plan o shell protegido. |
| ALTO | Dashboard llama datos duplicados. | `dashboard_stats.dart:83-97`, `dashboard_academic_activity.dart:36-38` | Crear controller único para Inicio. |
| MEDIO | Servicios duplican HTTP directo. | `billing_service.dart:25-34`, `cloud_api_service.dart:13-20` | Unificar cliente HTTP autenticado. |
| MEDIO | Monolitos de pantalla/servicio. | `wc -l` muestra pantallas de 2k-3k líneas | Extraer controllers y view models. |
| MEDIO | Backups `.bak` dentro de `lib` y backend. | 84 archivos `.bak*` | Sacarlos del árbol fuente/release. |
| MEDIO | Datos generados en backend app dir. | 137 mp3 en `backend/app/audio` | Mover a storage externo o ignorar en release. |

## 7. Problemas de Rendimiento

- `DashboardStats` carga usage, flashcards, exams y audiobooks en cada build del `FutureBuilder` si el widget se reconstruye (`dashboard_stats.dart:83-97`, `168-170`).
- `DashboardAcademicActivity` hace otra llamada a usage summary (`dashboard_academic_activity.dart:36-38`).
- `StudentDashboardController` ejecuta core + enterprise + marketplace + institution + RC en la carga de Student Dashboard (`student_dashboard_controller.dart:248-345`).
- `AudioBookStudioScreen` carga progreso por cada AudioBook en serie dentro de un loop (`audiobook_studio_screen.dart:99-110`).
- Dashboard escucha streams de audio y hace `setState` frecuente (`dashboard_screen.dart:121-136`).

Riesgo percibido: skipped frames, cold start lento, jank en scroll y navegación lenta en móvil.

## 8. Riesgos de Seguridad

| Severidad | Riesgo | Evidencia | Acción recomendada |
|---|---|---|---|
| CRÍTICO | Admin key en Flutter. | `analytics_service.dart:6-14` | Remover del cliente. Usar sesión + claim admin server-side. |
| ALTO | Rutas privadas sin redirect global. | `app_router.dart:35-483` | Guard central de auth/plan/rol. |
| ALTO | Plan local puede habilitar funciones si UI confía en `PlanGuardService`. | `plan_guard_service.dart:47-61` | Backend debe ser autoridad en límites y roles. |
| MEDIO | Logs de Supabase config en main. | `main.dart:21-23`, `31` | Reducir logs en release. |
| MEDIO | Backend usa defaults localhost en billing success/cancel. | `billing.py:221-228`, `312-317` | Requerir env explícito en producción. |
| BAJO | Datos locales guest/anonymous pueden quedar compartidos en dispositivo. | `UserScopedStorage.currentUserScope` fallback `guest` (`user_scoped_storage.dart:7-22`) e History fallback `anonymous` (`history_service.dart:12-25`) | Limpiar al login/logout o migrar explícitamente. |

## 9. Funciones Redundantes

- Dashboard principal y Student Dashboard tienen objetivos solapados.
- Panel Educator, Teacher Studio y herramientas docentes aparecen como bloques distintos.
- Audio Libro/Audiolibro/AudioBook se presentan como acciones diferentes.
- Academic Dashboard, Student Dashboard, Dashboard principal, Enterprise Dashboard widgets y RC widgets compiten conceptualmente.
- Biblioteca y Dashboard duplican recientes/historial/chats.

## 10. Funciones Esenciales

1. Subir documento.
2. Chat con documento.
3. Resumir.
4. AudioBook.
5. Voice Tutor.
6. Flashcards.
7. Quiz/Examen.
8. Biblioteca.
9. Historial/resultados generados.
10. Teacher Studio agrupado para usuarios Teacher.
11. Plan/Cuenta/Accesibilidad.

## 11. Propuesta de Nueva Arquitectura

### Navegación Recomendada

1. **Inicio**
   - Documento activo.
   - Herramientas AI principales.
   - Últimos 3 resultados.
   - CTA subir documento.

2. **Biblioteca**
   - Documentos.
   - Resultados generados.
   - AudioBooks.
   - Chats.

3. **Aprendizaje**
   - Continuar.
   - Progreso.
   - Flashcards/Quiz recientes.
   - Voice Tutor.

4. **Teacher Studio** solo si Teacher/Admin
   - Cursos.
   - Planificación.
   - Recursos.
   - Evaluación.
   - Calificaciones.
   - Reportes.

5. **Cuenta**
   - Plan.
   - Billing.
   - Accesibilidad.
   - Idioma/tema.
   - Sesión.

### Nuevo Dashboard

Debe ser AI-first:

```
Inicio
  [Subir PDF / elegir documento]
  Herramientas AI
    Chat
    Resumir
    AudioBook
    Voice Tutor
    Flashcards
    Quiz
    Banco de preguntas
    Generar examen
  Documento activo
  Recientes
```

Eliminar del Dashboard principal:

- Estadísticas extensas.
- Panel Educator.
- Actividad académica.
- Workspaces completos.
- Cloud chats completos.
- Historial completo.
- Métricas institucionales.
- Widgets RC/Enterprise.

Mover:

- Estadísticas a Aprendizaje.
- Workspaces a Biblioteca o Avanzado.
- Teacher tools a Teacher Studio.
- Billing a Cuenta.
- Admin/Finanzas a Admin oculto.

## 12. Arquitectura Teacher

Teacher no debe vivir dentro del Dashboard general. Debe ser una sección separada:

```
Teacher Studio
  Mis cursos
  Subir programa
  Planificación
  Recursos
  Rúbricas
  Banco de preguntas
  Exámenes
  Estudiantes
  Asistencia
  Calificaciones
  Acta final
  Reportes avanzados
```

Funciones docentes valiosas:

- Planificación por unidad.
- Banco de preguntas.
- Examen.
- Rúbrica.
- Curso/roster.
- Gradebook.

Funciones docentes que deben quedar avanzadas/ocultas:

- Reconocimientos.
- Transcript.
- Academic Dashboard.
- Unit Workspace directo.
- Ponderaciones si no hay curso/gradebook activo.

## 13. Arquitectura Student

Student debe centrarse en aprender, no en métricas enterprise:

```
Aprendizaje
  Continuar AudioBook / documento
  Practicar Quiz
  Repasar Flashcards
  Hablar con Voice Tutor
  Progreso simple
  Recomendaciones breves
```

Ocultar o degradar a avanzado:

- Digital Twin.
- Predictive Success.
- Campus Intelligence.
- Marketplace.
- RC readiness.
- Autonomous plans.

## 14. Simplificación de Planes

Planes actuales: Free, Student, Accessibility, Teacher, Ultra (`app_plans.dart:1-7`).

Recomendación:

- Mantener **Free** como entrada.
- Mantener **Student** como plan principal.
- Fusionar **Accessibility** como modo incluido en Student/Free, no como plan separado. Accesibilidad se percibe como derecho/valor humano, no upsell complejo.
- Mantener **Teacher** como plan profesional.
- Convertir **Ultra** en add-on de límites o “Pro”, no en experiencia propia.

Funciones vendibles:

- Más documentos.
- Más minutos AudioBook.
- Exportaciones.
- Teacher Studio.
- Evaluaciones avanzadas.
- Voz premium.

Funciones que deben ser gratuitas:

- Accesibilidad básica.
- Chat limitado.
- Resumen limitado.
- Flashcards básicas.

## 15. Simplificación: Antes / Después

### Dashboard

ANTES: Hero + stats + actividad + Educator + tools + resumen + audio + search + workspaces + recientes + chats + historial.  
DESPUÉS: Documento activo + herramientas AI + recientes.  
BENEFICIO: reduce carga cognitiva y tiempo a valor.  
RIESGO: usuarios avanzados pueden sentir pérdida si no se comunica navegación secundaria.

### AudioBook

ANTES: Audio Libro en varias tarjetas, Studio muy largo con creación, player, progreso, guardados y recientes.  
DESPUÉS: una acción “AudioBook” y pantalla con tres pasos: origen, generar, escuchar.  
BENEFICIO: menos confusión.  
RIESGO: ocultar opciones avanzadas de capítulos/progreso.

### Teacher

ANTES: Panel Educator dentro de Dashboard + rutas docentes dispersas.  
DESPUÉS: Teacher Studio como sección dedicada.  
BENEFICIO: Student no ve complejidad docente; Teacher tiene flujo claro.  
RIESGO: cambiar hábitos de acceso actuales.

### Biblioteca

ANTES: todo en una sola pantalla con muchas categorías/filtros.  
DESPUÉS: pestañas simples: Documentos, Generados, AudioBooks, Chats.  
BENEFICIO: búsquedas más claras.  
RIESGO: migrar filtros existentes sin romper favoritos.

## 16. Quick Wins

1. Eliminar duplicado “Audio Libro” / “Audiolibro”; dejar “AudioBook”.
2. Mover Panel Educator fuera del Dashboard general.
3. Reducir Dashboard a herramientas AI + documento activo.
4. Ocultar Finanzas del sidebar para no-admin.
5. Mover Planes dentro de Cuenta.
6. Cambiar “Mi Aprendizaje” por “Aprendizaje”.
7. Unificar nomenclatura: Quiz vs Examen.
8. Quitar métricas del primer viewport.
9. Crear guard global de rutas.
10. Sacar `ADMIN_API_KEY` del Flutter.

## 17. Cambios de Mediano Plazo

- Crear `HomeController` único para Inicio.
- Extraer `DashboardScreen` en módulos simples o reemplazarlo.
- Dividir `AudioBookStudioScreen` en controller + secciones.
- Dividir `TeachingPlanScreen` por resource generation.
- Unificar HTTP en un cliente autenticado.
- Separar services experimentales de production code mediante feature flags.

## 18. Cambios de Largo Plazo

- Modularizar producto por dominios: `ai_tools`, `library`, `learning`, `teacher`, `account`.
- Mover almacenamiento de audio/uploads fuera de `backend/app`.
- Consolidar AI generation bajo un contrato backend común.
- Crear navegación adaptativa por rol/plan.
- Rediseñar monetización como Free / Student / Teacher / Pro Add-ons.

## 19. Roadmap de Implementación

### Fase 1: Simplificación visual

- Nuevo Dashboard AI-first.
- Sidebar nuevo.
- Mover Teacher Studio.
- Ocultar Enterprise/RC/advanced widgets.

### Fase 2: Seguridad y navegación

- Guard global.
- Remover admin key del frontend.
- API base por env.
- Role/plan desde backend.

### Fase 3: Performance

- Controller único de Inicio.
- Eliminar FutureBuilders duplicados.
- Cachear métricas.
- Lazy-load módulos avanzados.

### Fase 4: Arquitectura

- Separar dominios.
- Reducir monolitos.
- Mover data generada fuera del repo.
- Limpiar backups.

## 20. Riesgos

- Cambiar Dashboard puede afectar flujos Teacher si no existe entrada visible a Teacher Studio.
- Ocultar métricas puede ser percibido como pérdida para usuarios avanzados.
- Guard global mal configurado puede bloquear rutas públicas como `/verify`.
- Fusionar Accessibility como modo requiere cuidado legal/producto.
- Limpiar `.bak` y datos generados requiere revisar qué está versionado.

## 21. Dependencias

- Supabase Auth y sesión.
- Backend FastAPI.
- Stripe Checkout/Webhook.
- Storage/local SharedPreferences.
- RAG/document registry.
- Audio generation.
- Export services.

## 22. Lista de Archivos Probablemente a Modificar

### Flutter

- `mobile/campusai_mobile/lib/screens/dashboard_screen.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_tools.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_hero.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_stats.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_academic_activity.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_educator_center.dart`
- `mobile/campusai_mobile/lib/widgets/sidebar.dart`
- `mobile/campusai_mobile/lib/router/app_router.dart`
- `mobile/campusai_mobile/lib/services/api_service.dart`
- `mobile/campusai_mobile/lib/services/analytics_service.dart`
- `mobile/campusai_mobile/lib/services/billing_service.dart`
- `mobile/campusai_mobile/lib/services/cloud_api_service.dart`
- `mobile/campusai_mobile/lib/screens/audiobook_studio_screen.dart`
- `mobile/campusai_mobile/lib/screens/student_dashboard_screen.dart`
- `mobile/campusai_mobile/lib/services/student_dashboard_controller.dart`
- `mobile/campusai_mobile/lib/config/app_plans.dart`
- `mobile/campusai_mobile/lib/services/plan_guard_service.dart`

### Backend

- `backend/app/main.py`
- `backend/app/routes/documents.py`
- `backend/app/routes/billing.py`
- `backend/app/routes/analytics.py`
- `backend/app/security/admin_auth.py`

### Repo / Release Hygiene

- `.gitignore`
- `backend/app/audio`
- `backend/app/uploads`
- archivos `*.bak*`

## 23. Decisión Recomendada

Confirmo la preferencia de producto: el Dashboard principal debe ser extremadamente sencillo y centrado en **Herramientas AI**. La app no debe abrir como panel institucional; debe abrir como una mesa de trabajo clara:

> “Elige o sube un documento. ¿Qué quieres crear con IA?”

Teacher, Student analytics, Enterprise, Admin y Billing deben existir, pero no competir con el primer minuto de valor.

