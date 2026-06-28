# StudyBook AI Accessibility v1.0

## Visión

StudyBook AI reconoce que no todas las personas aprenden de la misma forma.
Booky acompaña al estudiante con opciones claras para escuchar, leer, practicar y
avanzar a su propio ritmo.

La accesibilidad v1.0 es local-first, no requiere cuenta institucional y forma
parte de las experiencias Free, Student y Teacher.

## Principio de Booky

> No todos aprendemos igual. Yo puedo ayudarte a estudiar de la forma que mejor
> funcione para ti.

Booky usa lenguaje humano, evita mensajes punitivos y siempre propone una acción
de recuperación comprensible.

## Preferencias

Las preferencias se guardan localmente como `StudyResult` con type
`accessibility_preferences`:

- texto grande;
- alto contraste;
- lenguaje simple;
- reducir animaciones;
- preferir audio;
- quiz paso a paso;
- navegación simplificada.

El perfil derivado se guarda con type `accessibility_content_profile`. Este
perfil permite que experiencias futuras consuman las preferencias sin depender
de mapas dinámicos o del backend.

## Experiencia Student

El Student Dashboard incluye la sección "Aprende a tu manera", presenta el
estado de las preferencias con texto además de color y permite modificarlas sin
salir del dashboard.

AudioBook Studio explica que el contenido puede escucharse, resumirse con
lenguaje simple y estudiarse con quiz paso a paso.

Voice Tutor ofrece acciones rápidas para explicación simple, explicación paso a
paso, lectura en voz alta y preguntas cortas. La lectura reutiliza el servicio
TTS existente.

## Herramientas Teacher

`AccessibilityContentService.teacherAccessibilityActions()` deja preparados
los contratos de producto para:

- Generar versión accesible.
- Crear resumen simple.
- Crear actividad inclusiva.
- Crear rúbrica con criterio de accesibilidad.

La inserción de estos CTAs en Teacher Studio queda aplazada hasta validar cómo se
asocian a cada recurso académico. Esta decisión evita duplicar generación o
alterar Academic Engine durante el cierre de v1.0.

## Widgets reutilizables

- `AccessibilityCard`.
- `AccessibilityToggleTile`.
- `AccessibleEmptyState`.
- `AccessibleTipCard`.

Los widgets usan `Semantics`, labels visibles, controles familiares y estados
que no dependen únicamente del color.

## QA manual

1. Navegar por teclado y confirmar foco visible en botones, switches y enlaces.
2. Probar los siete switches y reiniciar la app para verificar persistencia.
3. Activar un lector de pantalla y revisar nombres y estados de los switches.
4. Verificar que cada estado por color también incluya texto o icono.
5. Revisar Dashboard, AudioBook y Voice Tutor en 390 px y 1440 px.
6. Aumentar el tamaño de texto del sistema y comprobar que no haya recortes.
7. Probar "Léelo en voz alta" y confirmar respuesta TTS.
8. Verificar mensajes de recuperación sin lenguaje punitivo.
9. Confirmar que STT, TTS, quiz, flashcards y learning packs mantienen su flujo.

## Límites de v1.0

Las preferencias se registran y están disponibles para los servicios de
producto. La aplicación global automática de escalado tipográfico, contraste,
reducción de movimiento y navegación simplificada requiere integración en el
shell y Theme de la app; se realizará después de QA transversal para evitar
regresiones visuales.

## Futuro

- Aplicación global de preferencias desde el shell.
- Perfiles sincronizados entre dispositivos con consentimiento.
- Subtítulos y transcripciones enriquecidas.
- Controles de velocidad y pausas adaptativas.
- Validación con usuarios y tecnologías asistivas.
- Institution Accessibility v2 con políticas y perfiles administrados.
