# D03 — DesktopAssembler (Builder) + AutoDrainObserver (Observer) — REPORT

## Status: GREEN
Closed: 2026-05-02
**Encerra a Onda 1.5 (D01+D02+D03) — refactor débito do Desktop facade.**

## Pipeline executada (4 waves, 4 dispatches sem rejection rounds)

| Wave | Agent | Resultado |
|------|-------|-----------|
| W0 — Baseline | Bash direct | 471 GREEN +1 skip (pós-D02) |
| W0.5 — RED | test-writer | 29 RED tests em 4 arquivos (1407 LoC) |
| W1 — Refactor | flutter-bff-implementer | DesktopAssembler + AutoDrainObserver + DesktopRuntime; 500 GREEN |
| W2 — Review | flutter-code-reviewer | **APPROVED Round 1/3** (zero MUST_FIX, 2 SHOULD_FIX deferred) |
| W3 — Quality | flutter-quality-checker | **PASSED** — analyze 0, format clean, 2172 GREEN total BFF |

## Padrões GoF aplicados

- **Builder** — `DesktopAssembler` com 7 setters fluent (`withLocalCache`, `withSyncQueue`, `withDio`, `withClock`, `withStaleAfter`, `withConnectivity`, `withExecutorFactory`) + `build()` orquestrando 8 fases. Cada `with*()` retorna `this` (chainable). `build()` reusable — chamadas múltiplas produzem runtimes independentes.
- **Observer** — `AutoDrainObserver.watch()` se inscreve em `connectivity_plus.onConnectivityChanged`; só dispara `engine.triggerDrain()` em offline→online edge. `dispose()` idempotente via `_disposed` guard. Engine privado (`_engine` field).

## Files

### Produção (criados)
- `apps/social_care_bff/desktop/lib/src/facade/composition/desktop_runtime.dart` (65L) — data class const, 12 final fields
- `apps/social_care_bff/desktop/lib/src/facade/composition/desktop_assembler.dart` (301L) — Builder GoF com 8-fase build()
- `apps/social_care_bff/desktop/lib/src/sync/connectivity/auto_drain_observer.dart` (105L) — Observer GoF; engine privado

### Produção (modificado)
- `apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart`: **364L → 184L (-180L, -49.5%)**
  - Constructor reduziu 14 named params → 1 (`DesktopRuntime`)
  - 7 sub-facade fields → getters delegating to runtime
  - **`late SocialCareDesktop desktop` self-reference ELIMINADO**
  - `create()` reduzido ~170L de composition inline → ~30L delegando para `DesktopAssembler`
  - Surface pública 100% preservada (10 named params em `create()`)

### Tests (criados — 29 RED por W0.5)
- `apps/social_care_bff/desktop/test/facade/composition/desktop_runtime_test.dart` (433L, 4 tests)
- `apps/social_care_bff/desktop/test/facade/composition/desktop_assembler_test.dart` (509L, 14 tests)
- `apps/social_care_bff/desktop/test/sync/connectivity/auto_drain_observer_test.dart` (420L, 11 tests)
- `apps/social_care_bff/desktop/test/sync/connectivity/_d03_test_helpers.dart` (45L, helpers re-export)

## Architectural choices APROVADAS (W2)

1. ✅ **Mutable Builder + return `this`** — spec-aligned; immutable variant falharia tests #2-#8
2. ✅ **`late observer` closure-local em `watch()`** — não é field; só vive durante o método estático; window fecha sincronamente
3. ✅ **`identical(_executorFactory, DriftExecutorFactory.inMemory)`** — pointer identity em `static const` singleton; custom factories caem no path normal
4. ✅ **DesktopRuntime data class pura** — sem `==`/`hashCode`/`copyWith`, só const constructor + final fields
5. ✅ **Constructor ordering em `build()` mirroring D02 builder ordering** — Cascade order preservada
6. ✅ **SocialCareDesktop constructor 14 params → 1** (`_runtime`)

## REGRA #2 4-point analysis honored (W1)

Path-resolution gate: quando `_executorFactory == DriftExecutorFactory.inMemory` AND no path set, short-circuit `:memory:` antes de chamar `defaultDesktopFilePath()` (que precisa de `path_provider`). Inicial impl quebrava 4 tests; W1 fez análise REGRA #2:

1. **Intenção**: tests provam que `withExecutorFactory(inMemory)` mantém `build()` plugin-free
2. **Falha**: `MissingPluginException` de `path_provider` — impl alcançava path_provider mesmo com factory inMemory
3. **Veredicto**: bug de implementação. Test contract correto.
4. **Escolha**: option (A) — gate `defaultDesktopFilePath()` atrás de `!isInMemory`. Sem alterar tests.

Production semantics preserved (production factory + null path → path_provider como antes).

## Q1 + Q3 do W0.5 — honored

- **Q1 (build reusable)**: cada `build()` produz runtime independente. Test #14 GREEN.
- **Q3 (dispose listener)**: `AutoDrainObserver.dispose()` chama `_subscription.cancel()` + `_disposed = true`. `FakeConnectivity.hasListener` flips para false. Tests #10-#11 GREEN.

## Test counts

- Antes D03: 2143 GREEN +1 skip (pós-D02: 535 contracts + 1137 web + 471 desktop)
- Após D03: **2172 GREEN +1 skip** (535 + 1137 + **500** desktop)
- Delta: **+29 desktop tests**

## Self-reference circular ELIMINATION (audit final)

```bash
grep -rn "late SocialCareDesktop" apps/social_care_bff/desktop/lib/  # ZERO matches
```

Único `late` restante: `late AutoDrainObserver observer` dentro de `watch()` static method (closure-local, não escapa, captura só `engine` + `_wasOnline` — não a fachada inteira).

## Surface pública (CRITICAL — 100% intacta)

W2 confirmou:
- `create()` mantém todos os 10 named params (D02 + D01's `executorFactory`)
- `startSync/stopSync/close/triggerDrain/drainStream` signatures unchanged
- Sub-facade fields → getters; type signatures iguais do POV do caller
- `lib/social_care_desktop.dart` (barrel) — sem mudanças (zero diff)
- `close()` ordering byte-identical: connectivityObserver → engine → cacheDb → syncDb → drainController

## D01 SHOULD_FIX status

- ✅ Cross-link em `social_care_desktop.dart` library docstring para `pumping_sync_engine.dart` — D03 addressed (linhas 37-40)
- ⏸️ Move `_ProbeDb` para `test/_test_helpers/probe_db.dart` — STILL pending (D03 não tocou; deferred para ticket futuro)

## SHOULD_FIX restantes (D03 W2)

1. ⏸️ Magic string `':memory:'` duplicada em `desktop_assembler.dart:167,172` — referenciar `_inMemoryMarker` constant em `db_executor.dart:9` (currently private)
2. ⏸️ `_ProbeDb` migration ainda pendente (D01 carry-over)

## NICE_TO_HAVE catalogados

1. Build-failure cleanup em `DesktopAssembler.build()` (pre-existing gap herdado de D02)
2. Barrel re-export de `DesktopAssembler` para advanced consumers
3. Initial-online → no-drain case verification

## Compromises / REGRA #2 exceptions

**Zero.** Zero tests modificados, zero impl wrapped in try/catch silencioso, zero skips. Single root-cause fix (path-resolution gate) foi correção de impl surfaceada pelo test contract.

## Onda 1.5 — Retrospectiva final

| Ticket | Δ facade | Tests | Padrão GoF |
|--------|---------:|------:|-----------|
| D01 | 718L → 637L (-81L) | +24 | Factory Method |
| D02 | 637L → 364L (-273L) | +21 | (SRP per BC) |
| **D03** | **364L → 184L (-180L)** | **+29** | **Builder + Observer** |
| **Total** | **-534L (-74.4%)** | **+74** | **3 padrões GoF formalizados** |

**Resultado:** 1 god-file de 718L com 6 responsabilidades → 14 arquivos pequenos com SRP cada, padrões GoF formalizados (Factory Method, Builder, Observer), self-reference circular eliminado, surface pública 100% intacta, baseline preservado em todas as 3 etapas.

## Padrões reservados (Rule of Three — sem demanda real)

- **Decorator (D6 reserved)** — quando aparecer demanda transversal real (telemetria/retry/audit cross-cutting). Hoje 0 cross-cuttings.
- **Strategy (D7 reserved)** — quando aparecer 2ª drain mode. Hoje 1 estratégia.

## Próximo

**C01 — CLI Scaffold (`apps/cli/`)** — destrava agora que Onda 1.5 fechou. Pipeline 4-wave (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker).

## Comandos de verificação

```bash
dart analyze apps/social_care_bff/desktop/lib/  # No issues found!
dart format --output=none --set-exit-if-changed apps/social_care_bff/desktop/lib/  # exit 0
cd apps/social_care_bff/desktop && flutter test  # 500 GREEN +1 skip
cd apps/social_care_bff/contracts && flutter test  # 535 GREEN
cd apps/social_care_bff/web && flutter test         # 1137 GREEN

# Confirma elimination de self-reference
grep -rn "late SocialCareDesktop" apps/social_care_bff/desktop/lib/  # zero matches
```
