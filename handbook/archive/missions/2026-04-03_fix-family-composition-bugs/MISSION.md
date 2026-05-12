---
date: 2026-04-03
author: gemini
executor: claude
reviewer: human
status: done
tags: [bug, ui-logic, sync, family-composition]
priority: P1
---

# Correcao de Bugs — Composicao Familiar

## Contexto

Bugs identificados no fluxo de composicao familiar do modulo social_care.
Testes de regressao criados em `family_composition_bugs_test.dart` documentam cada bug.

## Tasks

- [ ] **Task 1: UI Logic — Estado "Sujo" (Dirty State)**
  Implementar no `FamilyCompositionViewModel` a logica para habilitar o botao "Salvar" apenas quando houver mudancas (comparando com o estado original carregado).
  Ref: Teste BUG 1

- [ ] **Task 2: UI Logic — Especificidades da Familia**
  Refatorar para selecao unica (Single Choice). Implementar `updateSpecificity` e `selectedSpecificityId`. Carregar todas as opcoes do `LookupRepository`.
  Ref: Teste BUG 2

- [ ] **Task 3: Reatividade — Adicao de Membros**
  Garantir que o `handleModalSave` recarregue a lista de membros chamando `loadPatientCommand.execute()` e aguardando a conclusao.
  Ref: Teste BUG 3

- [ ] **Task 4: Contrato de Sincronizacao — memberPersonId**
  No `bff/shared/lib/src/infrastructure/mappers/registry_mapper.dart`, atualizar `familyMemberToJson` para incluir a chave `memberPersonId` contendo o valor do `personId`. O servidor exige esta chave para acoes de `ADD_FAMILY_MEMBER`.
  Ref: Teste BUG 4

- [ ] **Task 13: Alinhamento Total do Contrato (Sync Fix)**
  No `RegistryMapper.familyMemberToJson`, atualizar os nomes dos campos para baterem EXATAMENTE com o contrato do BFF:
  - `residesWithPatient` -> `isResiding`
  - `isPrimaryCaregiver` -> `isCaregiver`
  - Manter `relationship` e `memberPersonId`.
  Ref: Teste BUG 4 & 7

- [ ] **Task 14: Reatividade Cirúrgica (UI Performance)**
  - Remover o `ListenableBuilder` global de `FamilyCompositionPage.dart`.
  - Mover a escuta para dentro de `FamilyCompositionSpecificities.dart` e `FamilyCompositionActionBar.dart`.
  - Aplicar o Pattern **Selectors & Connectors**.

- [ ] **Task 15: Memoização e Higiene de Componentes**
  - Implementar cache real para o `ageProfile` no ViewModel (calcular apenas no load/change).
  - Proibição de métodos `_build...`: Extrair para `StatelessWidgets`.

- [ ] **Task 16: Correção do Nome da Tabela de Domínio**
  Mudar `dominio_especificidade_familia` para `dominio_tipo_identidade` no ViewModel.

- [ ] **Task 17: Robustez no RegistryMapper (Sync Recovery)**
  No `familyMemberFromJson`, aceitar as chaves `relationship` OU `relationshipId`. Isso evita que o Sync Engine quebre ao ler o cache.

- [ ] **Task 18: Proteção contra Stale Data (Offline-First)**
  No `OfflineFirstRepository`, logar um aviso se o Remote retornar menos membros que o Local, indicando possível dessincronização.

- [ ] **Task 19: Transparência de Erros (UX)**
  - Se `_loadLookups` falhar, notificar o usuário via `errorMessage` no ViewModel.
  - Na `FamilyCompositionPage`, exibir um indicador de erro se `loadPatientCommand.error` for true. **NUNCA ficar em silêncio.**

- [ ] **Task 24: Inversão da Fonte de Verdade (Read Policy)**
  No `OfflineFirstRepository.fetchPatient`: Se `hasPendingActions` for true, retornar o dado **LOCAL** e ignorar o Remote. O Remote só volta a ser fonte de verdade quando a fila zerar. Isso resolve o membro sumindo.

- [ ] **Task 25: UI — Travamento de Interação (Documentos)**
  Desabilitar cliques nos checkboxes de documentos na tabela de membros (definir `onChanged: null`).

- [ ] **Task 26: Robustez de Inicialização (Lookups)**
  Garantir que a UI não tente renderizar antes dos lookups terminarem, ou que o ViewModel notifique corretamente quando a lista de 11 itens chegar.

## Definition of Done (V6 - Final)
1. Adicionar membro e dar reload traz o membro novo (mesmo com sync em andamento).
2. Especificidades salvam e o valor persiste após reload.
3. Checkboxes da tabela estão travadas (Read-Only).
4. TDD validando a nova política de leitura: "Pending actions? Return Local".
5. Código segue Selectors & Connectors e não tem build methods privados.
