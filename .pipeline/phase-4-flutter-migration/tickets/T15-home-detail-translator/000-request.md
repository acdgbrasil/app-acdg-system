# T15 — Home Detail Translator Migration

## Onda: 2 | P0 | Profile: `data-layer` (mappers only)
## Depende de: T02

## Escopo
Mover `packages/social_care/lib/src/ui/home/models/patient_detail_translator.dart` → `packages/social_care/lib/src/data/mappers/patient_detail_mapper.dart`.

Tradução: este arquivo é um **mapper em camada UI com import de `shared/`** (violação clara do Contract A + responsabilidade mal-colocada).

## Arquivos afetados
- Mover: `ui/home/models/patient_detail_translator.dart` → `data/mappers/patient_detail_mapper.dart`
- Mover: os 9 arquivos em `ui/home/mappers/*_detail_mapper.dart` → `data/mappers/` (se não foram em T02)
- Ajustar: `ui/home/view_models/home_view_model.dart` para consumir do novo path.

## Critérios
- [ ] `ui/home/models/patient_detail_translator.dart` **deletado**.
- [ ] `ui/home/mappers/` **vazia** e deletada.
- [ ] `data/mappers/patient_detail_mapper.dart` retorna `Result<PatientDetail>`.
- [ ] ViewModel de home consome o novo mapper via Repository/UseCase (não direto).
- [ ] 0 imports de `shared/` em `ui/home/**`.
