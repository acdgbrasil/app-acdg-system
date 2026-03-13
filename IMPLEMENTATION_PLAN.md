# 🎯 Plano Central de Implementação — ACDG (Conecta Raros)

Este documento é o **Dashboard Central**. Ele rastreia o progresso macro e serve como índice para os planos detalhados de cada fase.

---

## 📊 Progresso Geral

| Fase | Título | Status | Progresso | Link |
| :--- | :--- | :--- | :--- | :--- |
| **Fase 1** | **Foundation** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_1_FOUNDATION.md) |
| **Fase 2** | **Shell + Auth** | ✅ CONCLUÍDO | 100% | [Ver Detalhes](./handbook/implementation_plans/PHASE_2_SHELL_AUTH.md) |
| **Fase 3** | **BFF Social Care** | 🏗️ EM ANDAMENTO | 90% | [Ver Detalhes](./handbook/implementation_plans/PHASE_3_BFF.md) |
| **Fase 4** | **Offline Engine** | 📅 AGUARDANDO | 0% | [Ver Detalhes](./handbook/implementation_plans/PHASE_4_OFFLINE.md) |
| **Fase 5** | **Features Core** | 📅 AGUARDANDO | 0% | [Ver Detalhes](./handbook/implementation_plans/PHASE_5_FEATURES.md) |
| **Fase 6** | **Polish + CI/CD** | 📅 AGUARDANDO | 0% | [Ver Detalhes](./handbook/implementation_plans/PHASE_6_POLISH.md) |

**Progresso Total Estimado:** `~38%`

---

## 🛠️ Decisões de Re-estruturação Recentes

### 2026-03-13 — Consolidação e Conectividade
- **Refatoração do Network**: O `ConnectivityService` foi elevado para um padrão de produção, realizando validação real de internet (Dual-Check) com testes unitários robustos.
- **Testes de Integração**: Estabelecido o padrão de testes reais contra o servidor de homologação (`social-care-hml`) com injeção segura de segredos.
- **Dependências**: Sincronização global para versões estáveis compatíveis.

---

## 📝 Documentos de Referência
- [Guia de Arquitetura](./handbook/architecture/ARCHITECTURE.md)
- [Padrões de Teste](./handbook/references/flutter_archteture/tests.md)
- [Guia OIDC/Auth Real](./handbook/architecture/OIDC_IMPLEMENTATION_GUIDE.md)
