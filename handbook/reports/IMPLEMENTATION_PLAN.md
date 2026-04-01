# 🎯 Plano Central de Implementação — ACDG (Conecta Raros)

Este documento é o **Dashboard Central**. Ele rastreia o progresso macro e serve como índice para os planos detalhados de cada fase.

---

## 📊 Progresso Geral

| Fase | Título | Status | Progresso | Link |
| :--- | :--- | :--- | :--- | :--- |
| **Fase 1** | **Foundation** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_1_FOUNDATION.md) |
| **Fase 2** | **Shell + Auth** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_2_SHELL_AUTH.md) |
| **Fase 3** | **BFF Social Care** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_3_BFF.md) |
| **Fase 4** | **Offline Engine** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_4_OFFLINE.md) |
| **Fase 5** | **Features Core** | 📅 AGUARDANDO | 0% | [Ver Detalhes](./handbook/implementation_plans/PHASE_5_FEATURES.md) |
| **Fase 6** | **Polish + CI/CD** | 📅 AGUARDANDO | 0% | [Ver Detalhes](./handbook/implementation_plans/PHASE_6_POLISH.md) |

**Progresso Total Estimado:** `~65%`

---

## 🛠️ Decisões de Re-estruturação Recentes

### 2026-03-18 — Implementação do Offline Engine (Fase 4)
- **Local-First Arquetecture**: Implementação do `OfflineFirstRepository` que orquestra gravações instantâneas locais e sincronização em background.
- **Sync Engine Robusto**: Motor de sincronização com suporte a 17 action types, retentativas com Exponential Backoff e detecção de conflitos (HTTP 409).
- **Persistência Evoluída**: Schemas Isar otimizados para controle de versão, estados de sincronização (`isDirty`) e cache eficiente de tabelas de domínio.
- **Feedback em Tempo Real**: Integração do widget `SyncIndicator` no AppBar, reagindo ao estado do motor de sincronização via `ValueNotifier`.
- **Idiomatismo Dart 3+**: Uso extensivo de **Pattern Matching**, **Sealed Classes** e o padrão **Fail First** com `Result` em toda a camada de dados.

### 2026-03-17 — Finalização do BFF e Validação de Staging
- **CRUD Completo**: Implementação real de todas as rotas de Assessment, Care e Protection.
- **Sincronia Técnica**: Padronização de enums em UPPERCASE e datas em ISO8601.

---

## 📝 Documentos de Referência
- [Guia de Arquitetura](./handbook/architecture/ARCHITECTURE.md)
- [Padrões de Teste](./handbook/references/flutter_archteture/tests.md)
- [Guia OIDC/Auth Real](./handbook/architecture/OIDC_IMPLEMENTATION_GUIDE.md)
