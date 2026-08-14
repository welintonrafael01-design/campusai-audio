# StudyBook AI Master Audit — Executive Summary

Fecha: 2026-08-13  
Rama auditada: `fix/android-platform-compat-838084d`  
Repositorio: `/Users/welintonmejia/Desktop/campusai-audio`

## Conclusión principal

StudyBook AI ya contiene gran parte del producto comercial: upload PDF, RAG, chat, resumen, AudioBook, Voice Tutor, flashcards, quiz/examen, banco de preguntas, Academic Engine, Teacher Studio, Biblioteca, billing Stripe y Supabase Auth. El problema no es ausencia de capacidades. El problema es exceso de superficie visible, estado distribuido, roles/planes sin autoridad central en frontend, módulos enterprise/RC mezclados con v1 y deuda de QA automatizado.

## Decisión de producto

La reconstrucción definitiva debe reutilizar el core funcional y ocultar lo experimental:

- **REUSE WITH FIX:** upload, chat, resumen, AudioBook, flashcards, quiz, banco, rúbrica, planificación, Biblioteca, billing.
- **REFACTOR:** Dashboard, Sidebar, ApiService, LibraryScreen, AudioBookStudio, TeachingPlanScreen, CoursesScreen, StudentDashboard.
- **HIDE:** RC services, enterprise intelligence, autonomous agents, marketplace avanzado, admin analytics, academic recognition avanzado.
- **REBUILD:** route guard global, role/plan authority, Inicio controller, Teacher Studio hub, Biblioteca v2, test suite.

## Estado cuantitativo

- Pantallas reales: 29.
- Rutas GoRouter: 30.
- Servicios Dart: 185.
- Widgets Dart: 54.
- Providers Riverpod: 5.
- Backend endpoints detectados: 80, incluyendo endpoints multilínea de billing.
- Tests Flutter reales: 1.
- Backend tests fuente: 0 visibles; quedan `__pycache__`.
- Archivos `.env`/backups/pyc candidatos a limpieza: miles dentro de `.venv`, backups y env locales.

## Riesgos críticos

1. `mobile/campusai_mobile/lib/services/analytics_service.dart` lee `ADMIN_API_KEY` desde `String.fromEnvironment`; no debe existir secreto admin en Flutter.
2. `mobile/campusai_mobile/lib/services/api_service.dart` fija `baseUrl = 'http://localhost:8000'`, roto para Android físico, iOS y producción.
3. `mobile/campusai_mobile/lib/router/app_router.dart` no tiene guard global de auth/rol/plan; rutas privadas son navegables directamente.
4. `PlanGuardService` confía en storage local para capacidades; el backend debe ser autoridad.
5. Hay `.env` y backups sensibles en el árbol local; no borrar ahora, pero bloquear antes de release.

## Upload regression root cause

La regresión reportada “al subir un documento desde el Dashboard simplificado no ocurre nada” no se debe a endpoint ausente. El flujo existe:

`DashboardScreen.uploadPdf` -> `ApiService.uploadPdf` -> `FilePicker.platform.pickFiles` -> `POST /documents/upload` -> RAG/indexación -> `HistoryService`/`RecentDocumentsService`/provider.

La causa más probable es UX/estado en `DashboardScreen.uploadPdf`: se activa `isLoading` y se muestra un diálogo modal **antes** de abrir el file picker. Si el picker se cancela, queda oculto por el modal o la plataforma bloquea el selector detrás del diálogo, la percepción es “no pasó nada”. También `isLoading` deshabilita herramientas y el catch muestra mensaje genérico. Corrección recomendada para sprint siguiente: seleccionar archivo primero, luego mostrar diálogo/progreso; separar cancelación de error; exponer CTA de retry; usar `ApiService.pickPdfFile` o un `DocumentUploadController` explícito.

## Orden recomendado de implementación

1. Corregir upload UX sin tocar backend.
2. Introducir `API_BASE_URL` por environment y resolver Android `10.0.2.2`.
3. Crear route guard global auth/role/plan.
4. Eliminar `ADMIN_API_KEY` de Flutter.
5. Consolidar Inicio con controller.
6. Construir Biblioteca v2.
7. Construir Teacher Studio hub.
8. Reducir servicios experimentales de la UI.
9. Agregar tests de smoke para upload, chat, biblioteca, role guard y billing.
10. Limpieza de backups/env/artefactos antes de RC.

