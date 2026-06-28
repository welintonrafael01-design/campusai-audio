# StudyBook AI Beta Testing Guide

## Preparacion

1. Usa contenido de prueba sin datos personales ni confidenciales.
2. Abre la app en desktop y en un viewport mobile.
3. Anota pasos exactos, resultado esperado y resultado observado.
4. No pegues contrasenas, tokens o API keys en feedback.

## Probar Como Estudiante

- Completa o salta el onboarding.
- Abre `Mi Aprendizaje` y revisa `Tu dia inteligente`.
- Ejecuta y descarta una accion inteligente.
- Confirma que el refresh conserva el contenido anterior.
- Revisa progreso, racha, mision, recursos y Estado Enterprise.
- Abre la guia inicial desde `Beta y lanzamiento`.

Resultado esperado: el Dashboard ofrece un siguiente paso claro, no duplica
acciones y no muestra errores visibles.

## Probar Como Docente

- Crea un curso de prueba.
- Genera una planificacion docente.
- Abre una unidad en Unit Workspace.
- Genera banco, examen, rubrica, guia y assessment report.
- Importa un recurso al Gradebook.
- Genera el Acta Final desde calificaciones de prueba.

Resultado esperado: cada recurso conserva metadata de unidad/curso y persiste
tras recargar.

## Teacher Productivity Flow

Valida la preparacion de una clase como un recorrido continuo:

- [ ] Abrir Teacher Studio y revisar la recomendacion de Booky.
- [ ] Crear un curso con nombre, codigo, seccion y periodo.
- [ ] Seleccionar el curso y confirmar el siguiente paso visible.
- [ ] Anadir el material o programa del curso.
- [ ] Generar la planificacion docente.
- [ ] Abrir una unidad y revisar sus materiales relacionados.
- [ ] Generar banco de preguntas y recursos para la clase.
- [ ] Crear la rubrica de la unidad.
- [ ] Crear el examen y revisar sus preguntas.
- [ ] Exportar la planificacion en PDF y Word.
- [ ] Revisar el recordatorio de version accesible del contenido.
- [ ] Abrir Seguimiento y confirmar que conserva el curso activo.

Resultado esperado: el profesor siempre ve el siguiente paso desde curso hasta
unidad, recursos, evaluacion, exportacion y seguimiento, sin perder metadata ni
duplicar artefactos.

## Probar AudioBook

- Genera un AudioBook desde texto no sensible.
- Genera o reproduce audio de un capitulo.
- Pausa, continua, cambia velocidad y marca completado.
- Genera actividades.
- Abre flashcards y mini quiz cuando esten disponibles.
- Abre Tutor IA por texto y por voz desde el capitulo.

Resultado esperado: progreso, respuestas y Learning Pack quedan disponibles al
volver a abrir el AudioBook.

## Probar Voice Tutor

- Verifica que la sugerencia inicial no se envie automaticamente.
- Prueba Repasar capitulo, Hazme un quiz corto, Explicalo simple, Resume lo
  importante y Leelo en voz alta.
- Envia una pregunta escrita.
- Prueba un turno de microfono, detener y cancelar.
- Genera y reproduce audio de una respuesta.
- Verifica fallback legible si backend o TTS no estan disponibles.

Resultado esperado: no hay doble envio y el contexto se mantiene resumido.

## Student Learning Flow

Valida el recorrido completo sin saltar directamente entre herramientas:

- [ ] Abrir `Mi Aprendizaje` desde el Dashboard.
- [ ] Probar el flujo sin contenido y usar `Crea tu primer AudioBook con Booky`.
- [ ] Pegar contenido no sensible y crear el primer AudioBook.
- [ ] Escuchar un capitulo, pausar y continuar donde se dejo.
- [ ] Abrir `Ver resumen` y confirmar contenido legible.
- [ ] Generar flashcards y mini quiz desde el capitulo.
- [ ] Repasar al menos una flashcard.
- [ ] Responder el mini quiz y verificar feedback comprensible.
- [ ] Usar `Preguntale a Booky sobre este tema` sin envio automatico previo.
- [ ] Probar Tutor IA por texto y por voz.
- [ ] Volver con `Ver progreso` y confirmar la sesion registrada.
- [ ] Revisar el estado vacio de progreso con una cuenta nueva.
- [ ] Activar preferencia de audio, lenguaje simple o quiz paso a paso.
- [ ] Verificar el mensaje amable para cuenta Free sin bloqueo agresivo.

Resultado esperado: el estudiante entiende siempre cual es el siguiente paso y
puede recorrer AudioBook, actividades, Booky y progreso sin perder el contexto.

## Probar CampusAI Y Acciones

- Confirma que snapshot, riesgo y recomendacion son consistentes.
- Ejecuta la siguiente mejor accion.
- Descarta otra accion y recarga.
- Verifica que no se otorgue XP solo por mostrar una accion.
- Confirma que Marketplace solo recomienda recursos locales existentes.

## Probar Marketplace E Institution

- Abre recursos locales y revisa titulos/categorias.
- Verifica estado vacio cuando no existen recursos.
- Revisa indicadores y alertas institucionales.
- Confirma que ninguna accion intenta pagos o sincronizacion cloud real.

## Reportar Bugs

Usa `Beta y lanzamiento > Enviar feedback` e incluye:

- Categoria correcta.
- Pasos breves para reproducir.
- Resultado esperado.
- Resultado observado.
- Dispositivo o navegador, sin identificadores personales.

No incluyas capturas con nombres reales, tokens, correos, notas o documentos
confidenciales.

## Checklist Manual

- [ ] Onboarding completar y saltar.
- [ ] Student Dashboard cargar y refrescar.
- [ ] Accion inteligente ejecutar y descartar.
- [ ] AudioBook generar, escuchar y continuar.
- [ ] Learning Pack, flashcards y mini quiz.
- [ ] Voice Tutor texto, microfono y audio de respuesta.
- [ ] Teacher Studio y recursos por unidad.
- [ ] CampusAI snapshot y recomendaciones.
- [ ] Marketplace local.
- [ ] Institution local.
- [ ] Feedback beta guardar y resumir.
- [ ] Persistencia despues de recargar.
- [ ] Sin errores visibles en desktop y mobile.

## Cierre De Sesion De Prueba

1. Registra feedback pendiente.
2. Marca el flujo como aprobado o bloqueado.
3. Elimina datos locales sensibles usados por error.
4. Comparte solo evidencia anonimizada.
