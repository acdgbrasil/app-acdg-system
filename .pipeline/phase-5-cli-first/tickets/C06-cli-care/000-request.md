# C06 — CLI Care Commands

## Onda: 4 | Profile: feature | Depende de: C05

## Escopo

```bash
acdg care appointment <patient-id> --type=X --date=ISO8601 [--notes=Y]
acdg care intake <patient-id> --reason=X --intake-at=ISO8601 [--notes=Y]
```

### Sub-contracts BFF consumidos
- `CareContract` (registerAppointment, updateIntake)

## Pipeline

W0 → W1 → W2 → W3

## Critérios

- [ ] 2 comandos funcionais
- [ ] Tests cobrindo error mapping
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C05
