# Phase 1 UI Simplification Report — StudyBook AI

Fecha: 2026-08-13  
Rama: `fix/android-platform-compat-838084d`  
Tag de respaldo: `pre-ui-simplification-v1`

## Objetivo

Ejecutar únicamente la Fase 1 de simplificación visual: hacer que el Inicio se sienta simple, moderno y AI-first, sin borrar funcionalidades, sin tocar backend, sin modificar billing y sin iniciar la Fase 2.

## Archivos modificados

- `mobile/campusai_mobile/lib/screens/dashboard_screen.dart`
- `mobile/campusai_mobile/lib/widgets/dashboard/dashboard_tools.dart`
- `mobile/campusai_mobile/lib/widgets/sidebar.dart`
- `docs/audit/PHASE_1_UI_SIMPLIFICATION_REPORT.md`

## Bloques ocultos del Dashboard principal

Se retiraron del render principal de `DashboardScreen`, sin borrar archivos ni rutas:

- Hero/saludo anterior.
- Estadísticas completas del Dashboard.
- Actividad académica.
- Panel Educator.
- Workspaces completos.
- Chats cloud completos.
- Historial completo.
- Búsqueda semántica como bloque principal.
- Mini player como bloque competitivo.
- Resumen/audio embebidos como secciones largas.

Los archivos originales se preservan para reutilización posterior:

- `dashboard_hero.dart`
- `dashboard_stats.dart`
- `dashboard_academic_activity.dart`
- `dashboard_educator_center.dart`

## Nueva estructura del Dashboard

El Inicio ahora prioriza:

1. Acción principal: subir PDF o seleccionar documento.
2. Documento activo con estado claro y acción para cambiarlo.
3. Herramientas AI dominantes.
4. Recientes limitados a máximo 3 documentos.

## Herramientas AI mostradas

`dashboard_tools.dart` quedó como el componente dominante del Inicio con estas acciones:

- Chat
- Resumir
- AudioBook
- Voice Tutor
- Flashcards
- Quiz
- Banco de preguntas
- Generar examen

También se unificó la nomenclatura visual a `AudioBook`, eliminando la duplicación visible `Audio Libro` / `Audiolibro` / `AudioBook`.

## Cambios en Sidebar

La navegación se simplificó a:

- Inicio
- Biblioteca
- Aprendizaje
- Teacher Studio, solo si el plan local es Teacher
- Cuenta

Se retiraron de la navegación principal:

- Finanzas para usuarios normales.
- Planes como ruta competitiva principal.

## Resultado de navegación

- `Inicio` mantiene `/dashboard`.
- `Biblioteca` mantiene `/library`.
- `Aprendizaje` usa la ruta existente `/student-dashboard`.
- `Teacher Studio` usa `/courses` como entrada conservadora porque esta rama no tiene un hub docente único consolidado.
- `Cuenta` mantiene `/settings`.

Pendiente para Fase 2: crear o consolidar un route/hub único de Teacher Studio si producto lo requiere.

## Funciones preservadas

No se borraron servicios, rutas ni pantallas. Siguen disponibles por rutas o flujos existentes:

- Biblioteca.
- Chat con documento.
- AudioBook Studio.
- Voice Tutor.
- Flashcards.
- Quiz/Examen.
- Banco de preguntas.
- Rúbricas.
- Planificación docente.
- Cursos.
- Workspaces.
- Chats cloud.
- Historial completo.
- Billing/planes.

## Riesgos

- Teacher Studio se muestra por `CampusPlan.teacher`, no por rol admin, porque en esta rama no hay un `AccountContext`/role guard consolidado en el sidebar.
- Algunas funciones avanzadas quedan ocultas del Inicio, pero siguen accesibles por rutas existentes y flujos contextuales.
- `flutter analyze` aún reporta 4 infos históricos en `courses_screen.dart` por `BuildContext` across async gaps.
- No se realizó QA visual en dispositivo físico Android desde este sprint.

## Pendiente para Fase 2

- Guard global de rutas por auth/plan/rol.
- Cuenta como centro de planes, preferencias y accesibilidad.
- Teacher Studio consolidado como hub dedicado.
- Limpieza de backups y módulos RC/Enterprise fuera de superficie final.
- Controller único para el Inicio.
- QA visual con capturas en Chrome y Android.

## Instrucciones para probar Android

```bash
cd /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile
flutter devices
flutter run -d <android-device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Validar:

- Inicio carga sin overflow.
- Botón `Subir PDF` visible.
- `Seleccionar documento` abre Biblioteca.
- Herramientas AI caben en pantalla móvil.
- Sidebar muestra solo navegación esencial.

## Instrucciones para probar Chrome

```bash
cd /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile
flutter run -d chrome --web-port=3001 \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Validar:

- Inicio no muestra Panel Educator.
- Inicio no muestra estadísticas antiguas.
- No aparecen duplicados de AudioBook.
- Recientes muestra máximo 3 entradas.
- Teacher Studio aparece solo en plan Teacher.

## Validaciones ejecutadas

```bash
dart format lib/screens/dashboard_screen.dart lib/widgets/dashboard/dashboard_tools.dart lib/widgets/sidebar.dart
git diff --check
flutter analyze
grep -RIn "DashboardEducatorCenter" lib/screens/dashboard_screen.dart || true
grep -RIn "DashboardHero" lib/screens/dashboard_screen.dart || true
grep -RIn "DashboardStats" lib/screens/dashboard_screen.dart || true
grep -RIn "DashboardAcademicActivity" lib/screens/dashboard_screen.dart || true
```

Resultado:

- `dart format`: OK.
- `git diff --check`: OK.
- `flutter analyze`: 0 errores, 0 warnings, 4 infos históricos en `courses_screen.dart`.
- Greps de bloques ocultos en `dashboard_screen.dart`: sin resultados.
