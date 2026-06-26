# StudyBook AI RC1 Release Candidate Checklist

## Flujos Criticos

- Login y logout.
- Dashboard principal.
- Teacher Studio: crear curso, generar plan docente, abrir Unit Workspace.
- Academic Engine: Banco IA, Examen IA, Rubrica IA, Guia IA y Assessment Report.
- Student Studio: Student Dashboard, Learning Pack, Mini Quiz y progreso.
- AudioBook Studio: generacion, reproduccion y progreso.
- Voice Tutor: modo texto y microfono.
- CampusAI Dashboard.
- Gamification.
- Marketplace local.
- Institution local.
- Billing basico sin pagos reales.

## Comandos De Validacion

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
python3 -m py_compile $(find backend/app -name "*.py")

cd /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile
flutter analyze
```

## QA Manual

- Confirmar que no hay pantallas rotas en mobile y desktop.
- Revisar que los flujos criticos no muestren excepciones visibles.
- Validar persistencia local despues de recargar Flutter.
- Confirmar que los recursos generados siguen apareciendo en sus vistas.

## Smoke Testing

- Abrir app.
- Iniciar sesion.
- Abrir Dashboard.
- Crear o abrir curso existente.
- Abrir Teacher Studio.
- Abrir Student Dashboard.
- Abrir Voice Tutor texto.
- Abrir Marketplace local.
- Abrir Institution local.

## Seguridad

- Ejecutar revision de patrones de secretos.
- No imprimir tokens completos.
- Revisar archivos `.env`.
- No incluir datos personales reales en ejemplos.
- No escanear `.venv`.

## Performance

- Revisar carga del Dashboard.
- Validar uso de cache local para snapshots pesados.
- Mantener CampusAI, Voice e Institution bajo demanda.
- Evitar refactors masivos antes de RC.

## Release Checklist

- Backend OK.
- Flutter analyze con 0 errores.
- Solo 25 infos historicos conocidos.
- QA foundation generada.
- Documentacion RC actualizada.
- Rollback documentado.
- No cambios en Billing, Stripe, Auth ni APIs existentes.

## Rollback

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
git status --short
git log --oneline -5
```

Para revertir un commit RC especifico, usar solo si se confirma el hash:

```bash
git revert <commit_hash>
```

## Criterios RC1

- Producto estable para demo y validacion controlada.
- Sin errores nuevos de backend o Flutter.
- Flujos principales disponibles.
- Modulos foundation claramente marcados como local-first.
- Riesgos conocidos documentados.
