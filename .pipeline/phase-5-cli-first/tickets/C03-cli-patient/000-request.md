# C03 — CLI Patient Commands

## Onda: 3 | Profile: feature | Depende de: C02

## Escopo

Implementar `acdg patient ...` para 11 ações do Contract A Registry:

```bash
# Leitura
acdg patient list [--search=X] [--status=Y] [--cursor=Z] [--limit=N]
acdg patient get <patient-id>
acdg patient audit <patient-id> [--event-type=X]

# Escrita
acdg patient register --cpf=X --first-name=Y --last-name=Z [--cns=N] [...]
acdg patient admit <patient-id> --reason=X --admitted-at=ISO8601
acdg patient discharge <patient-id> --reason=X --discharged-at=ISO8601
acdg patient readmit <patient-id> [--reason=X]
acdg patient withdraw <patient-id> [--reason=X]
```

### Sub-contracts BFF consumidos
- `RegistryContract` (registerPatient, fetchPatients, fetchPatient, admit, discharge, readmit, withdraw)
- `AuditContract` (getAuditTrail)

### Detalhes

- **register** é o endpoint composto B1 — payload "gordo" com personal + civil + address + family + intake + socialIdentity + diagnoses. CLI aceita flags simples + `--from-yaml=path/to/payload.yaml` para casos complexos.
- **list** com cursor pagination — output formatável (table | json | yaml).
- **get** retorna `PatientDetailResponse` enriquecido (família + analytics).
- **audit** filtra por `--event-type` opcional.

### Output formatters

- table (default) — colunas truncadas, cores ANSI
- json — `--output=json`
- yaml — `--output=yaml`

## Pipeline

W0 (test-writer) → W1 (flutter-bff-implementer) → W2 (flutter-code-reviewer) → W3 (flutter-quality-checker)

## Critérios

- [ ] 8 comandos funcionais via Bearer auth
- [ ] Tests: parsing args, formatador outputs, error mapping (BackendErrorResponse)
- [ ] Golden tests via `package:test` `expect(stdout, equals(goldenString))`
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C02
