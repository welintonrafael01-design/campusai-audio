# 01 — Repository Inventory

## Mobile Flutter

Root: `mobile/campusai_mobile`

| Área | Cantidad | Estado | Decisión |
|---|---:|---|---|
| `lib/screens/*_screen.dart` | 29 | Funcional pero monolítico | Refactor selectivo |
| `lib/services/**/*.dart` | 185 | Exceso de servicios, mezcla core/experimental | Clasificar y ocultar |
| `lib/widgets/**/*.dart` | 54 | Reutilizables, algunos duplican UI | Reusar con limpieza |
| `lib/providers/*.dart` | 5 | Riverpod mínimo | Expandir para estado core |
| `lib/models/*.dart` | 7 | Modelos limitados | Tipar más dominio |
| `test/*.dart` | 1 | Cobertura mínima | Reconstruir test suite |

## Backend FastAPI

Root: `backend`

| Área | Estado | Decisión |
|---|---|---|
| `backend/app/main.py` | App central, CORS, routers, static audio | Reuse with fix |
| `backend/app/routes/documents.py` | Monolito AI/RAG/import/export workspace | Refactor posterior |
| `backend/app/routes/cloud.py` | Cloud sync usuario-scoped | Reuse with tests |
| `backend/app/routes/billing.py` | Stripe real | Reuse with hardening |
| `backend/app/routes/audiobook.py` | AudioBook v2 separado | Reuse with integration cleanup |
| `backend/app/routes/voice.py` | Voice coach/TTS | Partial |
| `backend/app/services/*` | Core AI/RAG/storage/export | Reuse with boundaries |
| `backend/tests` | Solo `__pycache__`, sin tests fuente visibles | Rebuild |

## Configuración y plataformas

| Plataforma | Archivos | Hallazgo |
|---|---|---|
| Android | `AndroidManifest.xml`, Gradle KTS | `INTERNET`, cleartext permitido; falta matriz prod/dev |
| iOS | Runner, Podfile, assets | Existe scaffold; requiere QA real |
| Web | `web/index.html`, manifest, icons | Existe; base URL hardcoded afecta deploy |
| Assets | `assets/branding/*.png` | Branding básico; suficiente para v1 |

## Artefactos sensibles o candidatos a limpieza

- `backend/.env`
- `backend/.env.supabase`
- `backend/.env.save`
- `backend/.env.bak_*`
- `backend/.venv/**` (local ignored environment; no longer tracked after W5.1)
- `backups/**/*.bak`
- `backend/tests/__pycache__/**`
- `backend/app/audio/**` y uploads generados si contienen datos reales.

No se eliminaron por instrucción explícita.
