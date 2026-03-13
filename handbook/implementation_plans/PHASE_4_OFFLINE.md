# 📦 Fase 4 — Offline Engine

Implementação do motor de persistência local e sincronização.

## Status: 📅 AGUARDANDO

### Entregáveis
- [ ] **Isar Database**:
  - [ ] Schemas para `CachedPatient` e `CachedLookup`.
  - [ ] Registro de `SyncAction`.
- [ ] **SyncQueue**: Fila ordenada de ações pendentes.
- [ ] **SyncEngine**:
  - [ ] Integração com `ConnectivityService` (auto-sync ao voltar online).
  - [ ] Mecanismo de Retry com backoff.
- [ ] **Conflict Resolution**: Lógica de merge de campos e flags para resolução manual.
