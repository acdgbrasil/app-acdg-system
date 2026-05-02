# D02 — UseCases Builders por Bounded Context — REPORT

## Status: GREEN
Closed: 2026-05-02

## Pipeline executada (4 waves, 4 dispatches sem rejection rounds)

| Wave | Agent | Resultado |
|------|-------|-----------|
| W0 — Baseline | Bash direct | 450 GREEN +1 skip confirmado (pós-D01) |
| W0.5 — RED | test-writer | 21 RED tests em 7 arquivos + helpers (1137 LoC) |
| W1 — Refactor | flutter-bff-implementer | 7 builders + 7 sub-facades adjusted; 471 GREEN |
| W2 — Review | flutter-code-reviewer | **APPROVED Round 1/3** (mechanical audit Python script: 42/42 use cases byte-identical, zero MUST_FIX) |
| W3 — Quality | flutter-quality-checker | **PASSED** — analyze 0, format clean, 2143 GREEN total BFF |

## Padrão arquitetural aplicado

**Composição + SRP por bounded context** — nenhum padrão GoF formal, mas princípio Composition Root quebrado em 7 partes alinhadas com Contract A.

## Files

### Produção (criados — 7 builders)
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/registry_use_cases.dart` (162L) — 13 use cases
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/assessment_use_cases.dart` (95L) — 7 use cases
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/care_use_cases.dart` (67L) — 3 use cases
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/protection_use_cases.dart` (89L) — 6 use cases
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/audit_use_cases.dart` (38L) — 1 use case
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/lookup_use_cases.dart` (130L) — 10 use cases
- `apps/social_care_bff/desktop/lib/src/facade/composition/builders/health_use_cases.dart` (29L) — 2 use cases

Total: **610 LoC** (data classes + factory `build()`).

### Produção (modificados)

| Arquivo | Antes | Depois | Δ |
|---------|------:|-------:|------:|
| `lib/src/facade/social_care_desktop.dart` | 637L | **364L** | **-273L (-42.9%)** |
| `lib/src/facade/sub_facades/registry_facade.dart` | 122L | 77L | -45L |
| `lib/src/facade/sub_facades/assessment_facade.dart` | 76L | 53L | -23L |
| `lib/src/facade/sub_facades/care_facade.dart` | 38L | 29L | -9L |
| `lib/src/facade/sub_facades/protection_facade.dart` | 61L | 42L | -19L |
| `lib/src/facade/sub_facades/audit_facade.dart` | 26L | 27L | +1L |
| `lib/src/facade/sub_facades/lookup_facade.dart` | 101L | 70L | -31L |
| `lib/src/facade/sub_facades/health_facade.dart` | 23L | 20L | -3L |

Sub-facades: -129L coletivos. Cada sub-facade agora aceita `XxxUseCases` data class agrupada em vez de N parâmetros individuais — todos os métodos públicos delegam para `_useCases.X`.

### Tests (criados)
- `test/facade/composition/builders/_builders_test_helpers.dart` (234L) — shared fakes
- 7 test files (3 tests cada × 7 = 21 tests)

## Key decision (W1 spec divergence — APPROVED por W2)

Spec original usava **concrete `RegistryRemote`** em `build()`. W1 usou **abstract `RegistryContract`** porque:
1. Use cases já declaram dependência via abstract type (`fetch_patient_use_case.dart:17` etc.)
2. Production passa concrete `RegistryRemote(dio:...)` que `implements RegistryContract` — type-safe
3. Tests podem passar `FakeRegistryBff` de `bff/contracts` sem instanciar `Dio()` real

W2 confirmou decisão como **correção de spec**, não deviação.

## Test counts

- Antes D02 (após D01): 2122 GREEN +1 skip (535 contracts + 1137 web + 450 desktop)
- Após D02: **2143 GREEN +1 skip** (535 contracts + 1137 web + **471** desktop)
- Delta: **+21 desktop tests**

## Behavior preservation (W2 mechanical audit)

W2 rodou Python script (`/tmp/audit_d02.py`) extraindo cada bloco `XxxUseCase(...)` do legacy `social_care_desktop.dart` (HEAD = D01 closure `06da0dd`) e dos 7 novos builders, normalizando renames de variável, e comparando.

**42/42 use cases byte-identical.** Zero discrepâncias.

Spot-checks confirmaram exotic deps:
- `UpdateIntakeInfoUseCase` usa `patientsCache:` (NÃO careCache)
- `UpdatePlacementHistoryUseCase` usa `patientsCache:` (NÃO protectionCache)
- `RegisterAppointmentUseCase` usa named `careCache:`
- Protection cache-only reads omitem `remote:`

## Surface pública (CRITICAL — 100% intact)

- `SocialCareDesktop.create()` — assinatura inalterada
- `SocialCareDesktop.{startSync, stopSync, close, triggerDrain, drainStream}` — inalteradas
- Sub-facade public methods — todos byte-identical (verificado via `grep "Future<Result"` diff)
- Public barrel `lib/social_care_desktop.dart` — zero diff
- Sub-facade `.internal()` constructor MUDOU shape mas é internal API (caller é `social_care_desktop.dart::create()` apenas)

## Mental smoke test — adicionar use case novo pós-D02

Adicionar `CancelAppointmentUseCase`:

1. Cria `lib/src/use_cases/care/cancel_appointment_use_case.dart`
2. Adiciona field + ctor param + factory line em `lib/src/facade/composition/builders/care_use_cases.dart`
3. Adiciona método delegator em `lib/src/facade/sub_facades/care_facade.dart`
4. **`social_care_desktop.dart` UNTOUCHED**

Pré-D02: tocaria 4 sites (entry point + sub-facade). Pós-D02: 3 sites (builder + sub-facade), entry point estável. **SRP per builder achieved.**

## Architectural choices APROVADAS (W2)

1. ✅ Abstract contract types em build() signatures (override do spec — fundamentado)
2. ✅ Health builder sem Clock parameter (passthrough — sem cache)
3. ✅ Protection builder sem `remote:` parameter (cache-only reads)
4. ✅ `library;` directive em cada builder file (matches D01 convention)
5. ✅ Per-context ordering preserved (registry → assessment → care → protection → audit → lookup → health)
6. ✅ No barrel re-export de builders (internal composition only)

## Compromises / REGRA #2 exceptions

**Zero.** Zero tests modificados, zero impl com try/catch silencioso, zero skips, zero deviation de constructor parameter names. Único spec divergence (abstract contracts) foi flagged e fundamentado pelo W0.5 + aprovado pelo W2.

## D01 SHOULD_FIX status (pendentes)

Mantidos como SHOULD_FIX para D03 ou tickets futuros:
1. Move `_ProbeDb` para `test/_test_helpers/probe_db.dart` (D02/D03 podem reusar)
2. Cross-link em `social_care_desktop.dart` library docstring para `pumping_sync_engine.dart`

## Próximo

**D03 — DesktopAssembler (Builder GoF) + AutoDrainObserver (Observer GoF).** Aplica Builder fluente (resolve constructor com 14 parâmetros) e Observer (resolve `late SocialCareDesktop desktop` self-reference circular). Reduz `social_care_desktop.dart` de 364L pra ~150L.

## Comandos de verificação

```bash
dart analyze apps/social_care_bff/desktop/lib/  # No issues found!
dart format --output=none --set-exit-if-changed apps/social_care_bff/desktop/lib/  # exit 0
cd apps/social_care_bff/desktop && flutter test  # 471 GREEN +1 skip
cd apps/social_care_bff/contracts && flutter test  # 535 GREEN
cd apps/social_care_bff/web && flutter test         # 1137 GREEN
```
