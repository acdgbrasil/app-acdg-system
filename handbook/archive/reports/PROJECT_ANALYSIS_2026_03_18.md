# Relatório de Análise do Projeto — 18 de Março de 2026

Este documento detalha a análise técnica do ecossistema ACDG (Frontend), identificando pontos de melhoria em arquitetura, qualidade de código, dependências e processos.

---

## 1. Visão Geral
O projeto utiliza uma arquitetura robusta de Monorepo com Melos, seguindo princípios de Micro-Frontends e DDD no BFF. A separação em packages (`core`, `auth`, `design_system`, `social_care`) está bem estruturada, mas existem vazamentos de dependências e inconsistências de análise estática.

---

## 2. Pontos Críticos e Melhorias

### A. Dependências e Análise Estática (Prioridade Alta)
A análise via Melos revelou diversos erros de `depend_on_referenced_packages`.
- **Problema:** Vários packages utilizam dependências (como `meta`, `mocktail`, `social_care`, `dio`) sem declará-las em seus respectivos `pubspec.yaml`. Eles funcionam apenas por estarem no mesmo workspace ou serem dependências transitivas.
- **Melhoria:** 
    - Adicionar explicitamente as dependências faltantes em cada package.
    - Limpar imports não utilizados (`unused_import`) em `shared`, `social_care` e `acdg_system`.
    - Corrigir o `directives_ordering` (ordenação de imports) para seguir o padrão idiomático do Dart.

### B. Consistência de Arquitetura (BFF & Shared)
- **Problema:** O package `shared` (dentro de `bff/`) contém lógica de domínio e kernels que são importados pelo frontend. Notei alguns warnings de imports circulares ou mal configurados.
- **Melhoria:** Garantir que o `shared` seja estritamente um package de contratos e modelos puros, sem dependências pesadas de infraestrutura.

### C. Qualidade de Código (Linting)
- **Problema:** Uso de `print()` em código de produção (especialmente em `core` e testes de integração).
- **Melhoria:** Implementar um logger centralizado no `package:core` (ex: usando `logging` ou `logger`) e proibir o uso de `print` via regras de lint customizadas no `analysis_options.yaml`.
- **Melhoria:** Padronizar o uso de blocos em estruturas de controle (`if`, `for`) para evitar erros de leitura (faltam `curly_braces`).

### D. Testes e Cobertura
- **Observação:** O projeto possui uma boa estrutura de testes (`integration_test`, `testing/` packages), mas a análise mostrou erros em arquivos de teste devido a imports quebrados.
- **Melhoria:** Criar uma suite de "Golden Tests" para o `design_system` para garantir consistência visual entre Web e Desktop.
- **Melhoria:** Automatizar a verificação de cobertura de testes via Melos script.

### E. Documentação e Onboarding
- **Observação:** O `ARCHITECTURE.md` está excelente e bem detalhado.
- **Melhoria:** O arquivo `CLAUDE.md` e os manuais em `handbook/` precisam ser atualizados para refletir o status atual da Fase 4 (Offline) que parece estar em progresso avançado.

---

## 3. Plano de Ação Sugerido

1.  **Saneamento de Dependências:** Rodar um ciclo de correção em todos os `pubspec.yaml` para eliminar erros de análise.
2.  **Centralização de Log:** Criar `AcdgLogger` no `core` e substituir todos os `print()`.
3.  **Refatoração de Imports:** Limpar os barrel files (`.dart` que exportam outros arquivos) para evitar sobrecarga de contexto e warnings de ordenação.
4.  **CI/CD Guardrails:** Configurar o Melos para falhar o build se houver qualquer `info` ou `warning` de análise (atualmente `--fatal-infos` está ativo, o que é bom, mas o build está quebrado).

---

## 4. Notas Técnicas Específicas
- **Package `network`:** Possui warnings de falha de inferência de tipos (`inference_failure_on_function_invocation`). Isso pode causar bugs silenciosos em tempo de execução. Precisa de tipagem explícita.
- **Package `social_care_desktop`:** Tem o maior número de dependências não declaradas (24 issues). É o ponto mais frágil no momento em termos de configuração.
