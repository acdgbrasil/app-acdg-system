# C10 — CLI Golden Tests

## Onda: 5 | Profile: integration | Depende de: C03–C09

## Escopo

Snapshot tests dos ~35 comandos contra fixtures BFF:

```
apps/cli/test/golden/
├── auth/
│   ├── login_success.golden
│   └── login_state_mismatch.golden
├── patient/
│   ├── list_empty.golden
│   ├── list_2_patients.golden
│   ├── get_full_detail.golden
│   ├── register_success.golden
│   └── register_validation_error.golden
├── family/, assessment/, care/, protection/, lookup/, team/
└── _fixtures/
    ├── patient_response.json
    ├── lookups_batch_response.json
    └── ...
```

### Mecanismo

- Fixture BFF response = file `_fixtures/X.json`
- Test setup: `MockBffServer` (Dio interceptor) retorna fixture
- Test execution: `acdg patient list ...` → captura stdout
- Compare: `expect(stdout, equals(goldenFile.readAsString()))`
- Update mode: `dart test --update-goldens`

### Coverage targets

- Happy path: 100% dos comandos (~35)
- Error paths: pelo menos 1 por sub-contract (BackendErrorResponse + auth expired + network failure)
- Output formats: table, json, yaml — golden por formato

## Pipeline

W0 (test-writer) → W1 (implementer fixtures) → W2 (reviewer) → W3 (quality)

## Critérios

- [ ] ~50 golden tests (35 happy + 15 error/format)
- [ ] CI roda goldens em cada PR
- [ ] `dart analyze` zero issues

## Status
pending — blocked by C03–C09
