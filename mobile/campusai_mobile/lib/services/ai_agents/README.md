# AI Agents Enterprise

```mermaid
flowchart LR
  UserTask --> AgentOrchestrator
  AgentOrchestrator --> LearningAgent
  AgentOrchestrator --> PlannerAgent
  AgentOrchestrator --> PredictionAgent
  AgentOrchestrator --> MarketplaceAgent
  AgentOrchestrator --> VoiceAgent
  AgentOrchestrator --> InstitutionAgent
```

## Dependencias

- `BaseAgent`
- `AgentTask`
- `AgentResponse`

## Flujo

1. Recibir tarea.
2. Enrutar por agente o capacidad.
3. Ejecutar colaboración entre agentes ordenada por prioridad.

## TODO

- Conectar métricas reales por agente.
- Persistir historiales completos de colaboración.
