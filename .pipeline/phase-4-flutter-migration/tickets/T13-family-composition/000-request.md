# T13 — Family Composition Feature

## Onda: 2 | P0 | Profile: feature | Depende de: T04

## Escopo
Replicar template T04 para ficha **Family Composition** — **mais complexa** que as outras por ter modais, lookups dinâmicos e operações incrementais (add/remove/primary-caregiver).

## Arquivos envolvidos (6 violações hoje)
- `ui/family_composition/view_models/family_composition_view_model.dart` (4 imports de `shared/`)
- `ui/family_composition/view/components/add_member_modal.dart` (5 imports)
- `ui/family_composition/view/components/family_composition_specificities.dart` (3 imports)
- `ui/family_composition/view/components/hoverable_relationship_item.dart`
- `ui/family_composition/view/components/relationship_selection_list.dart`
- `logic/use_case/family/add_family_member_use_case.dart` + `remove_family_member_use_case.dart`

## Endpoints Contract A
- `POST /api/patients/:id/family`
- `DELETE /api/patients/:id/family/:memberId`
- `PUT /api/patients/:id/family/:memberId/primary-caregiver`

## Critérios
- [ ] 0 imports de `shared/` em `ui/family_composition/**`
- [ ] UseCases em `ui/family_composition/use_cases/`
- [ ] Tests GREEN (incluir widget test do modal)
- [ ] Valida em staging
