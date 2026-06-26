# Production Cache

```mermaid
flowchart LR
  EnterpriseCacheService --> TtlCacheService
```

## Dependencias

- `TtlCacheService`

## Flujo

1. Guardar snapshots por dominio.
2. Leer con TTL común.
3. Mantener contrato local-first.

## TODO

- Invalidación por tenant.
- Métricas de hit rate.
