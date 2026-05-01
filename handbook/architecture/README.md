# Arquitetura — frontend (Conecta Raros)

Este diretorio contem as decisoes arquiteturais, diagramas e ADRs (Architecture Decision Records) do ecossistema frontend.

## Documentos

| Documento | Descricao |
|-----------|-----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visao geral da arquitetura completa |
| [DECISIONS.md](DECISIONS.md) | Registro de decisoes arquiteturais (ADRs) |
| [DIAGRAMS.md](DIAGRAMS.md) | Diagramas de fluxo, camadas e comunicacao |
| [CONTRACT_A_PUBLIC_API.md](CONTRACT_A_PUBLIC_API.md) | Contrato publico Flutter ↔ BFF — racional, exemplos e §14 retrospectiva pos-implementacao (Phase 3 fechada 2026-05-01) |
| [CONTRACT_A_SPEC.md](CONTRACT_A_SPEC.md) | Especificacao formal das 35 acoes + sub-contracts; secao final lista discrepancias spec vs codigo real |
| [BFF_ALIGNMENT_SPEC.md](BFF_ALIGNMENT_SPEC.md) | Alinhamento BFF Web/Desktop com sub-contracts |
| [BFF_IMPLEMENTATION_PLAN.md](BFF_IMPLEMENTATION_PLAN.md) | Plano de execucao da fase BFF |
| [ENCAPSULATION_POLICY.md](ENCAPSULATION_POLICY.md) | Politicas H1-H9 (composition, Equatable, extension type, SRP) |
| [PATTERN_MATCHING_POLICY.md](PATTERN_MATCHING_POLICY.md) | Politicas P1-P5 (state matrix, if-case, tear-offs, Never) |
| [CONCURRENCY_AND_PERFORMANCE_POLICY.md](CONCURRENCY_AND_PERFORMANCE_POLICY.md) | Politicas de concorrencia e performance |
| [AGENT_TESTING_POLICY.md](AGENT_TESTING_POLICY.md) | Politica de TDD agente-driven |
| [OIDC_IMPLEMENTATION_GUIDE.md](OIDC_IMPLEMENTATION_GUIDE.md) | Guia de implementacao OIDC (Zitadel) |
| [STAGING_INTEGRATION_GUIDE.md](STAGING_INTEGRATION_GUIDE.md) | Guia de integracao em staging |
| [IMPLEMENTATION_REFERENCE.md](IMPLEMENTATION_REFERENCE.md) | Referencia tecnica de implementacao |
