# C07 — CLI Protection Commands

## Onda: 4 | Profile: feature | Depende de: C06

## Escopo

```bash
acdg protection violation <patient-id> --type=X --reported-at=ISO8601 --description=Y
acdg protection referral <patient-id> --institution=X --reason=Y --referred-at=ISO8601
acdg protection placement-history <patient-id> --history-yaml=path/to/history.yaml
```

### Sub-contracts BFF consumidos
- `ProtectionContract` (reportViolation, createReferral, updatePlacementHistory)

### Detalhes

- **placement-history** é payload complexo (lista de eventos) — exigir `--from-yaml` por padrão.
- **violation** captura código de violação + descrição estruturada.
- **referral** registra encaminhamento para outra instituição/serviço.

## Pipeline

W0 → W1 → W2 → W3

## Critérios

- [ ] 3 comandos funcionais
- [ ] YAML parser para placement history tested
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C06
