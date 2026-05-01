# T19 — Activate Shared Lint + Delete Legacy

## Onda: 4 | P0 (final) | Profile: custom
## Depende de: T16, T17, T18 (todas as features migradas)

## Escopo
Garantia final contra regressão. Ativar lint que proíbe `package:shared/shared.dart` fora de `data/{model,services,mappers}` e deletar o god-interface legado.

## Ações

### 1. Custom lint rule
Adicionar em `packages/social_care/analysis_options.yaml`:
```yaml
analyzer:
  errors:
    # Custom rule via custom_lint + dart_code_metrics (ou plugin próprio)
    # Proíbe `import 'package:shared/shared.dart';` fora de:
    #   - lib/src/data/model/**
    #   - lib/src/data/services/**
    #   - lib/src/data/mappers/**
```

Se lint custom for complexo, alternativa: script em `tool/check_contract_a.dart` rodado no CI que falha se encontrar violações.

### 2. Delete legacy
- [ ] `packages/social_care/lib/src/data/services/http_social_care_client.dart` (643 linhas)
- [ ] Todas as referências ao `PatientTranslator` (se algum sobrou)
- [ ] `SocialCareContract` como interface consumida por Flutter (se ainda estiver sendo usada fora do `bff/shared/`)

### 3. Atualizar provider chain em `apps/acdg_system/lib/logic/di/`
- [ ] `socialCareContractProvider` — pode ser simplificado ou removido
- [ ] Substituir por `patientServiceProvider`, `assessmentServiceProvider`, etc.

## Critérios (final da fase)
- [ ] CI bloqueia PR com import violador
- [ ] `HttpSocialCareClient` deletado
- [ ] Score `COMPLIANCE_REPORT`: 100% Contract A + 100% Non-Negotiables
- [ ] `melos run analyze` verde
- [ ] `melos run test` verde
- [ ] Staging validado
- [ ] Documentar em `handbook/architecture/DECISIONS.md` ADR sobre Contract A

## Celebração
Após T19 merged, fase-3 está **COMPLETA**. Atualizar `STATE.md` da fase para `phase: done`.
