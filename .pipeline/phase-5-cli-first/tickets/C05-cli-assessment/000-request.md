# C05 — CLI Assessment Commands

## Onda: 3 | Profile: feature | Depende de: C04

## Escopo

7 fichas de avaliação do Contract A:

```bash
acdg assessment housing <patient-id>             [--rooms=N --type=X --bedrooms=N ...]
acdg assessment socioeconomic <patient-id>       [--income-range=X ...]
acdg assessment work-income <patient-id>         [--employment-status=X ...]
acdg assessment education <patient-id>           [--level=X --status=Y ...]
acdg assessment health <patient-id>              [--condition=X ...]
acdg assessment community-support <patient-id>   [--network-size=N ...]
acdg assessment social-health-summary <patient-id> [--summary=X ...]
```

### Sub-contracts BFF consumidos
- `AssessmentContract` (updateHousing, updateSocioeconomic, updateWorkIncome, updateEducation, updateHealth, updateCommunitySupport, updateSocialHealthSummary)

### Detalhes

- Cada subcomando aceita `--from-yaml=path` para payloads complexos.
- Validação client-side mínima (apenas args malformados); domain validation no BFF.
- Error mapping de `BackendErrorResponse` (códigos `INVALID_*`).

## Pipeline

W0 → W1 → W2 → W3

## Critérios

- [ ] 7 sub-comandos funcionais
- [ ] Tests parametrizados (1 test factory rodando 7 fichas)
- [ ] `--from-yaml` parsing tested
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C04
