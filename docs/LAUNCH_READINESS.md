# StudyBook AI Launch Readiness

## Objetivo

Preparar una beta cerrada controlada sin confundir readiness de producto con
readiness comercial. La beta puede iniciar cuando los flujos criticos son
estables, existe feedback local y no hay bloqueos de seguridad o datos.

## Checklist Beta Cerrada

- Backend compila con `py_compile`.
- Flutter analyze termina con 0 errores y solo los infos historicos aceptados.
- Login, logout y recuperacion de acceso funcionan.
- Student Dashboard carga, refresca y conserva contenido durante refresh.
- Teacher Studio crea curso, plan y recursos por unidad.
- AudioBook genera, reproduce, guarda progreso y abre Learning Pack.
- Voice Tutor funciona por texto y por turnos de microfono.
- CampusAI genera snapshot, recomendaciones y acciones explicables.
- Marketplace e Institution operan en modo local-first.
- Onboarding puede completarse o saltarse.
- Feedback beta se guarda sin identidad, tokens ni datos personales.
- Existe una persona responsable de revisar feedback y bloqueos.

## Checklist Beta Publica

- Todos los criterios de beta cerrada estan verificados en desktop y mobile.
- Los bloqueos de severidad alta de la beta cerrada estan resueltos.
- Existe canal de soporte publicado y tiempo de respuesta definido.
- Politica de privacidad y terminos estan revisados.
- Metricas de activacion, retencion y errores estan definidas.
- Landing, pricing y limites de producto estan aprobados.
- Plan de rollback y comunicacion de incidentes estan ensayados.

## Flujos Criticos

1. Usuario nuevo completa o salta onboarding.
2. Estudiante genera AudioBook, escucha un capitulo y completa un mini quiz.
3. Estudiante abre Tutor IA, usa texto y prueba una pregunta por voz.
4. Student Dashboard muestra progreso, plan y siguiente mejor accion.
5. Docente crea curso, genera plan y abre Unit Workspace.
6. Docente genera banco, examen, rubrica, guia y assessment report.
7. Gradebook importa recursos y Final Report consolida calificaciones.
8. Marketplace e Institution cargan datos locales sin errores visibles.

## Criterios De Aceptacion

- No hay excepciones visibles ni pantallas en blanco.
- Las operaciones largas explican que estan procesando.
- Los botones evitan doble ejecucion.
- El contenido persiste tras recargar Flutter.
- Las acciones autonomas son locales, reversibles y no modifican notas.
- Los estados vacios conducen a una accion real.
- El feedback puede listarse, resumirse y marcarse como revisado.

## Criterios De Bloqueo

- Error de compilacion backend o Flutter.
- Perdida o corrupcion reproducible de datos locales.
- Exposicion de API keys, tokens, secretos o datos personales.
- Login bloqueado o navegacion principal inaccesible.
- Generacion academica o AudioBook inutilizable.
- Voice Tutor envia mensajes sin accion del usuario.
- Cobros reales, cambios de plan o Stripe ejecutados desde la beta.

## Feedback

- Clasificar por categoria y prioridad.
- Reproducir bugs antes de marcarlos como revisados.
- No solicitar nombres, correos, documentos ni credenciales.
- Tratar prioridad `critical` como posible bloqueo de lanzamiento.
- Revisar el resumen de feedback diariamente durante la beta cerrada.

## Soporte

- Definir responsable primario y respaldo.
- Publicar horario y canal antes de beta publica.
- Preparar respuestas para acceso, AudioBook, Voice y Teacher Studio.
- Mantener registro de incidentes sin datos personales.

## Metricas

- Activacion: onboarding y primera sesion completada.
- Aprendizaje: minutos, sesiones, capitulos, quiz y flashcards.
- Producto: carga de Dashboard, acciones ejecutadas y feedback recibido.
- Calidad: errores bloqueantes, reportes abiertos y tiempo de resolucion.
- Voice: sesiones por texto/voz y fallbacks locales.

## Antes Del Lanzamiento

1. Ejecutar `docs/BETA_TESTING_GUIDE.md` con al menos un estudiante y docente.
2. Resolver bloqueos y documentar riesgos aceptados.
3. Ejecutar validaciones tecnicas finales.
4. Revisar secretos, `.env`, certificados y datos generados.
5. Confirmar soporte, metricas, rollback y responsables.
6. Aprobar explicitamente el paso de beta cerrada a publica.

## Validacion Tecnica

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
python3 -m py_compile $(find backend/app -name "*.py")

cd mobile/campusai_mobile
flutter analyze
git status --short
```
