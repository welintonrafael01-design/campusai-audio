# StudyBook AI FTUE v1.0

## Objetivo

El First Time User Experience permite comprender el valor de StudyBook AI en
menos de cinco minutos:

> Sube cualquier contenido. Booky lo convierte en una experiencia de
> aprendizaje.

FTUE complementa el onboarding y Launch Readiness existentes. No los reemplaza.
El onboarding presenta el producto; FTUE acompaña hasta una primera acción con
valor verificable.

## Persistencia

El progreso se guarda localmente como `StudyResult` con type `ftue_progress`.
Cada ruta usa un documento independiente y un modelo tipado `FtueProgress`.

Los pasos se completan usando actividad real cuando está disponible. Abrir una
pantalla no cuenta como logro. AudioBooks, quiz, sesiones y conversaciones con
Booky se detectan desde los servicios existentes.

## Free path

1. Pegar un contenido breve.
2. Convertirlo en AudioBook.
3. Hacer la primera pregunta a Booky.

## Student path

1. Subir o pegar contenido.
2. Crear el primer AudioBook.
3. Completar un mini quiz.
4. Preguntar a Booky.
5. Consultar el progreso.

El Dashboard muestra "Comienza con Booky" durante los primeros pasos. Después
de alcanzar actividad suficiente, la experiencia se reduce a "Tu primer logro"
y desaparece al completar o descartar la ruta.

## Teacher path

1. Crear el primer curso.
2. Generar una planificación en minutos.
3. Crear rúbricas y exámenes con ayuda de Booky.

La ruta y sus widgets están listos en `FtueService`. La inserción visual en
Teacher Studio se aplaza para no alterar Academic Engine durante el cierre de
v1.0.

## Accessibility path

1. Elegir preferencias en "Aprende a tu manera".
2. Probar aprendizaje con audio.
3. Usar lenguaje simple y práctica paso a paso con Booky.

La configuración es opcional y nunca bloquea el acceso al contenido.

## Time to First Value

El primer valor puede alcanzarse creando un AudioBook, conversando con Booky,
completando un quiz o generando un recurso docente. FTUE solo guía y registra
progreso; no concede XP, monedas ni logros de gamificación.

## Widgets

- `FtueWelcomeCard` para la primera acción contextual.
- `FtueStepCard` para representar un paso y su estado.
- `FtueQuickStartCard` para la ruta inicial completa.
- `BookyWelcomeCard` para la primera conversación.
- `TimeToValueCard` para el siguiente logro compacto.

## QA manual

1. Limpiar solo `ftue_progress` y verificar "Comienza con Booky".
2. Abrir una ruta y confirmar que navegar no completa el paso por sí solo.
3. Crear un AudioBook y actualizar el Dashboard.
4. Completar un mini quiz y revisar la sincronización del paso.
5. Enviar una pregunta a Booky y verificar la conversación real.
6. Confirmar que la guía se compacta y luego desaparece.
7. Descartar la guía y reiniciar la app para validar persistencia.
8. Probar la primera experiencia de AudioBook con teclado y lector de pantalla.
9. Comprobar que Voice Tutor no envía mensajes al abrir la pantalla.
10. Revisar móvil y escritorio sin desbordes ni controles recortados.

## Próximos pasos

- Integrar la ruta Teacher después de QA con cursos reales.
- Detectar carga de documentos previa a la creación de AudioBook.
- Medir tiempo anónimo hasta primer valor con consentimiento.
- Unificar FTUE con el shell de preferencias globales de accesibilidad.
- Validar los textos con estudiantes y docentes.
