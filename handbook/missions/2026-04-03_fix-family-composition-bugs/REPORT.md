---
date: 2026-04-03
executor: claude
duration: ~20min
status: done
---

# Relatorio — Correcao de Bugs Composicao Familiar

## Resumo

4 bugs corrigidos no fluxo de composicao familiar. Todos os testes de regressao passando, analise estatica limpa.

## Decisoes Tomadas

- Dirty state (`canSave`) implementado via comparacao de `_selectedSpecificityId` vs `_originalSpecificityId` (snapshot do estado original)
- Especificidade como selecao unica (`updateSpecificity` substitui valor, nao acumula)
- `memberPersonId` adicionado como campo extra no JSON do `familyMemberToJson` — mantem `personId` por retrocompatibilidade
- IDs de teste corrigidos para formato UUID valido (o dominio exige UUIDs)

## Resultados

- [x] **Task 1: canSave (Dirty State)** — Adicionados `_selectedSpecificityId`, `_originalSpecificityId`, e getter `canSave` no ViewModel
- [x] **Task 2: updateSpecificity (Single Choice)** — Metodo `updateSpecificity(id)` com selecao unica + carregamento do lookup `dominio_especificidade_familia`
- [x] **Task 3: Reatividade handleModalSave** — Flow ja funcionava corretamente (addMember -> loadPatient). Nenhuma alteracao necessaria.
- [x] **Task 4: memberPersonId no JSON** — Adicionado `'memberPersonId': m.personId.value` em `RegistryMapper.familyMemberToJson`

## Arquivos Modificados

| Arquivo | Mudanca |
|---------|---------|
| `packages/social_care/.../family_composition_view_model.dart` | +canSave, +updateSpecificity, +selectedSpecificityId, +specificityLookup |
| `bff/shared/.../registry_mapper.dart` | +memberPersonId no familyMemberToJson |
| `packages/social_care/test/.../family_composition_bugs_test.dart` | IDs corrigidos para UUID |
