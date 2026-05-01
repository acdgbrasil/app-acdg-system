# T02 — Mappers Migration

## Onda: 1 | Prioridade: P1 | Profile: `data-layer` (mappers only)
## Depende de: T01 (domain models)

## Escopo
Reorganizar mappers para `data/mappers/` — 1 arquivo por endpoint do Contract A, retornando `Result<T>` com switch exhaustivo.

## Arquivos a migrar

**De `logic/mappers/` (4 arquivos, monolíticos):**
- `assessment_mapper.dart` → dividir em: `housing_condition_mapper.dart`, `socioeconomic_mapper.dart`, `work_and_income_mapper.dart`, `educational_status_mapper.dart`, `health_status_mapper.dart`, `community_support_mapper.dart`, `social_health_summary_mapper.dart`, `intake_info_mapper.dart`, `social_identity_mapper.dart`
- `family_mapper.dart` → `family_member_mapper.dart` (add/remove/primary-caregiver)
- `intervention_mapper.dart` → `violation_report_mapper.dart` + `referral_mapper.dart` + `placement_history_mapper.dart`
- `registry_mapper.dart` → `patient_register_mapper.dart` + `patient_detail_mapper.dart` + `patient_list_mapper.dart`

**De `ui/home/mappers/` (9 arquivos, já granulares):**
- Mover todos para `data/mappers/` mantendo nomes (`*_detail_mapper.dart` → `*_detail_mapper.dart`).
- Corrigir `throw StateError` em `intervention_mapper.dart:91` → `Result.error(...)`.

## Waves
- Wave 1: flutter-mapper-engineer (único agente)
- Wave 5: flutter-code-reviewer + flutter-quality-checker

## Critérios de aceitação
- [ ] Todos os mappers em `packages/social_care/lib/src/data/mappers/`.
- [ ] 1 arquivo = 1 endpoint Contract A.
- [ ] Todos retornam `Result<T>` (nunca `throw`, nunca `value!`).
- [ ] Switch exhaustivo para unwrap.
- [ ] Pastas antigas `logic/mappers/` e `ui/home/mappers/` eliminadas.
- [ ] `dart analyze` verde.
- [ ] Imports atualizados nos consumidores (UseCases, ViewModels de home).

## Non-Regression
Este ticket só **move** arquivos e **divide** monolíticos. Comportamento idêntico; só muda a localização/granularidade.
