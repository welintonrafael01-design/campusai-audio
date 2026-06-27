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
- Prueba Empecemos, Explicame, Hazme un quiz, Repasar debilidad y Plan de hoy.
- Envia una pregunta escrita.
- Prueba un turno de microfono, detener y cancelar.
- Genera y reproduce audio de una respuesta.
- Verifica fallback legible si backend o TTS no estan disponibles.

Resultado esperado: no hay doble envio y el contexto se mantiene resumido.

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
