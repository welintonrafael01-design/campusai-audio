# USER DATA ISOLATION AUDIT — StudyBook AI v1.0

## Estado

Security Sprint aplicado para corregir aislamiento local y backend de documentos.

## Origen del bug

Durante QA manual, Biblioteca y Dashboard mostraron documentos que el usuario actual no había cargado.

El origen principal fue el uso de claves globales en SharedPreferences/local storage para historial, documentos recientes, study results, favoritos, workspaces, audiobooks, chats y datos docentes.

## Riesgo

Riesgo crítico de privacidad:
- Un usuario podía ver historial local de otro usuario en el mismo navegador/dispositivo.
- El documento activo podía leerse desde una clave global.
- Algunos registros backend sin user_id podían considerarse accesibles.

## Correcciones frontend

Se creó:

- mobile/campusai_mobile/lib/services/security/user_scoped_storage.dart

Se corrigieron:

- HistoryService
- RecentDocumentsService
- StudyResultService
- LibraryFavoritesService
- WorkspaceService
- AudiobookLibraryService
- ChatHistoryService
- EducatorSyncService

## Cambios clave

Las claves locales ahora quedan separadas por usuario autenticado:

- active_document_<user>
- recent_documents_<user>
- study_results_<document>_<type>_<user>
- studybook_library_favorites_<user>
- ai_workspaces_<user>
- studybook_audiobook_library_<user>
- chat_history_<document>_<user>
- claves docentes locales por usuario

No se migraron automáticamente claves globales antiguas para evitar arrastrar datos de otra sesión.

## Correcciones backend

Se corrigieron:

- backend/app/services/document_registry_service.py
- backend/app/services/documents_cloud_service.py

Reglas aplicadas:

- Los documentos reales requieren user_id.
- Los documentos sin propietario ya no son considerados públicos.
- La creación cloud incluye user_id en payload.
- Las consultas de descarga filtran por document_id y user_id.

## Endpoints relacionados

Revisados:

- /cloud/documents
- /cloud/audiobooks
- /cloud/chats
- /cloud/study-results
- /billing/subscription/me
- /billing/usage/me

Billing y Stripe ya fueron validados previamente con planes Student y Teacher.

## QA recomendado

Probar manualmente:

1. Usuario nuevo sin documentos.
2. Usuario A con documentos.
3. Usuario B sin documentos.
4. Usuario B no ve documentos de Usuario A.
5. Usuario A no ve documentos de Usuario B.
6. Logout/login.
7. Refresh navegador.
8. Plan Free.
9. Plan Student.
10. Plan Teacher.
11. Plan Accessibility.
12. Biblioteca.
13. Dashboard.
14. Chats.
15. AudioBooks.
16. StudyResults.
17. Favoritos.
18. Workspaces.

## Validaciones técnicas

Ejecutadas:

- python3 -m py_compile $(find backend/app -name "*.py")
- flutter analyze

Resultado:

- Backend OK.
- Flutter 0 errores.
- 25 infos históricos.

## Pendientes

- QA manual con dos usuarios reales.
- Limpieza opcional de claves globales antiguas desde herramienta controlada.
- Migrar servicios docentes secundarios a UserScopedStorage en fase posterior.
- No avanzar a Release Sprint 8 hasta confirmar QA básico de aislamiento.
