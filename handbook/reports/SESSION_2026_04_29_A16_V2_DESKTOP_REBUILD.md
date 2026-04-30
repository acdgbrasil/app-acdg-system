# Sessão 2026-04-29 — A16-v2: Desktop Remote Rebuild (BREAK CHANGE)

> **Ticket:** A16-v2 (Onda 4 / Fase 3 BFF Contract A)
> **Pipeline:** 3-agent BFF (test-writer → flutter-bff-implementer → flutter-code-reviewer)
> **Commit:** `4bda87f` — `feat(bff/desktop): A16-v2 — desktop remote rebuild (BREAK CHANGE)`
> **Resultado:** APPROVED Round 1, zero MUST_FIX, 153/153 tests GREEN, dart analyze 0 issues.
> **Próximo:** A17-v2 (cache Drift DAOs) → A18-v2 (sync + use_cases + facade)

## O que foi feito

### 1. Re-baseline: A16 → A16-v2 (refactor → break-change rebuild)

O ticket A16 original era escopado como refactor incremental do `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` para parar de implementar a `SocialCareContract` (deletada em A05) e passar a usar sub-contracts. Após análise inicial, ficou claro que um refactor incremental ia preservar o anti-pattern de god-class — exatamente o que a Onda 2 limpou no `bff/shared/`.

**Decisão arquitetural do usuário (2026-04-29):**
> "Vamos marcar o DESKTOP como BREAK CHANGING e fazer igual ao WEB. Vamos considerar que tudo do desktop estava ERRADO e vamos RE-IMPLEMENTAR tudo. Claro temos que manter as vantagens do DESKTOP."

A Onda 4 foi re-baselineada como três tickets break-change sequenciais, espelhando o pattern web (A07-A15) menos a camada HTTP:

| Ticket | Escopo |
|---|---|
| **A16-v2** (este) | `remote/` — 7 thin remotes + RemoteBase implementando sub-contracts via Dio |
| A17-v2 | `cache/` — schema Drift rebuild + 7 DAO-backed cache impls por bounded context |
| A18-v2 | `sync/` + `use_cases/` + `facade/` — SyncQueue tipado, SyncEngine, ~40 use cases, facade público pra APP |

**Vantagens do desktop preservadas:**

| Vantagem | Onde mora antes (god-class) | Onde mora depois (rebuild) |
|---|---|---|
| In-process (sem HTTP entre APP↔BFF) | Package Dart importado direto | Mesmo — `facade/` exporta API tipada |
| Offline-first (ADR-005) | `OfflineFirstRepository` (god) | `cache/` + `sync/` como camadas dedicadas (A17/A18) |
| Storage relacional | Drift no `LocalSocialCareRepository` | Drift em DAOs por bounded context (A17) |
| Sync com timestamp/CRDT | `SyncEngine` (god mock) | `SyncQueue` tipado + `SyncEngine` per-context (A18) |
| Single binary | Package Dart | Mesmo |

A vantagem do desktop é **a arquitetura** (in-process + offline-first), não a implementação. O rebuild preserva tudo.

### 2. Decisão Drift-stays (override do ADR-005)

`handbook/architecture/DECISIONS.md` ADR-005 prescreve **Isar** como engine de offline storage. O usuário decidiu **manter Drift** com base em pesquisa atualizada do ecossistema Flutter:

1. **Manutenção do Isar colapsou.** O autor original (Simon Leier) abandonou o pacote. Forks comunitários (`isar_community`, `isar_plus`) estão instáveis para produção. Threads recentes em r/FlutterDev e GitHub mostram desenvolvedores migrando ativamente *de volta* para Drift.

2. **Incompatibilidade com Swift Package Manager.** Flutter está adotando SPM como padrão (depreciando CocoaPods). O Isar depende de binários Rust pré-compilados que falham sob hooks de build do SPM (Issue #1750 do repo Isar). Drift usa sqlite3 nativo que se adapta cleanly aos hooks modernos.

3. **Isolates e performance.** Drift é a única biblioteca de persistência embarcada robusta no Flutter com suporte multithread testado para Isolates — fit perfeito pra `SyncEngine` rodando em background sem travar UI.

**Ação de follow-up:** ADR-005 será atualizado para v2 declarando o pivot Isar → Drift, citando abandono do upstream e exigências de SPM como drivers. O handbook é registro histórico, não escritura sagrada — atualiza quando a realidade diverge.

### 3. Estrutura final do `lib/src/remote/`

```
bff/social_care_desktop/lib/src/remote/
├── _shared/
│   └── remote_base.dart        — Dio + interceptors + helpers (137 LoC)
├── registry_remote.dart         — RegistryContract (282 LoC, 11 métodos)
├── assessment_remote.dart       — AssessmentContract (113 LoC, 7 fichas)
├── care_remote.dart             — CareContract (51 LoC, 2 métodos)
├── protection_remote.dart       — ProtectionContract (72 LoC, 3 métodos)
├── audit_remote.dart            — AuditContract (47 LoC, 1 método)
├── lookup_remote.dart           — LookupContract (235 LoC, 8 métodos com fan-out batch)
└── health_remote.dart           — HealthContract (35 LoC, 2 métodos)
```

**Total:** 8 arquivos, 972 LoC, 7 sub-contracts, 34 métodos.

### 4. RemoteBase — composição via herança fina

Cada remote `extends RemoteBase implements <Sub>Contract`. RemoteBase é helper-only, sem conhecimento per-context:

- `Dio buildDio({baseUrl, actorId, tokenProvider})` — factory de produção com Bearer interceptor + X-Actor-Id header.
- `Options passthroughStatus` — `validateStatus: (_) => true`. Setado uma vez e reusado em todo endpoint para que non-2xx surfaceie como `Response`, nunca throw.
- `Failure<T> backendFailure<T>(response, fallbackMessage)` — non-2xx com `error` key → `Failure(BackendErrorResponse)`; fallback UNKNOWN para bodies não-estruturados; status code preservado em `http`.
- `StandardResponse<T> wrapResponse<T>(data)` — wrap com `ResponseMeta(timestamp: now)`.
- `StandardResponse<void> wrapVoid()` — síntese de resposta para 204 No Content.
- `StandardIdResponse extractIdResponse(responseData)` — extrai `{"data":{"id":"..."}, "meta":{...}}`.

**Não há per-context state em RemoteBase.** Não é template-method, é cluster compartilhável.

### 5. Padrão Result<T> + try/catch só na boundary de adapter

Cada método público é shape:

```dart
@override
Future<Result<T>> someMethod(...) async {
  try {
    final response = await dio.<verb>(<path>, ..., options: passthroughStatus);
    if (response.statusCode == 2xx) return Success(parse(response));
    return backendFailure(response, 'Failed to ...');
  } catch (e, stackTrace) {
    return Failure<T>(e, stackTrace: stackTrace);
  }
}
```

`stackTrace` capture é intencional (debuggability conforme flutter-expert skill). Nenhum try/catch aninhado, nenhum swallow em helpers privados. **Remote é a ÚNICA camada do BFF onde try/catch é permitido** (boundary de adapter).

### 6. Helpers privados internos por remote (anti-duplicação)

Três helpers privados eliminam ~30 LoC de duplicação cada:

- `RegistryRemote._postLifecycle(patientId, slug, body, fallbackMessage)` — admit/discharge/readmit/withdraw.
- `AssessmentRemote._putFicha(patientId, slug, body, fallbackMessage)` — todas as 7 fichas viram one-liners.
- `LookupRemote._governanceTransition(requestId, action, fallbackMessage)` — approve/reject.

A variação por método é **uma path/slug** por API pública. Tudo mais é compartilhado.

### 7. Resolução de 3 ambiguidades REGRA #2 (pre-resolvidas pelo test-writer)

**(a) `LookupContract.getLookupsBatch` — backend não tem endpoint batch.** Implementado como **fan-out paralelo** via `Future.wait(tables.map(getLookupTable))`. Per-table `Failure` short-circuita o agregado, preservando erro original + stackTrace. Mesmo padrão que o BFF web Hono usa.

**(b) `addFamilyMember`'s parâmetro `cpf` é vestigial.** Aceito na assinatura (preserva contract) mas inerte no wire — nunca aparece em body ou query. Docstring inline documenta a decisão. Se backend futuro precisar, `RegistryContract` muda primeiro.

**(c) Síntese de `StandardResponse<void>` em 204 No Content.** Para os 4 métodos lookup admin/governance (`updateLookupItem`, `toggleLookupItem`, `approveLookupRequest`, `rejectLookupRequest`) que retornam `Future<Result<StandardResponse<void>>>`. Em 204 com body vazio, `wrapVoid()` sintetiza com `ResponseMeta(timestamp: now)`. Tests são timestamp-agnostic (só `isA<Success<StandardResponse<void>>>`).

### 8. Limpeza completa (option a — clean break)

Foram **deletados 11 arquivos legados**:

- `lib/src/remote/social_care_bff_remote.dart` (917 LoC god-class)
- `lib/src/storage/local_cache_contract.dart` — abstract que implementava SocialCareContract
- `lib/src/storage/local_social_care_repository.dart` — Drift legado
- `lib/src/storage/offline_first_repository.dart` — god-class de cache+remote
- `lib/src/sync/sync_engine.dart` — SyncEngine acoplado a SocialCareContract
- `test/social_care_bff_remote_test.dart` — testava god-class deletada
- `test/storage/local_social_care_repository_test.dart`
- `test/storage/offline_first_repository_test.dart`
- `test/sync/sync_engine_test.dart`
- 2 dirs vazios (`storage/`, `sync/`)

`A17-v2` e `A18-v2` reconstroem essas camadas do zero. Estado limpo > dívida acumulada.

### 9. Pubspec — `core_contracts` como dep direta

`bff/social_care_desktop/pubspec.yaml`:

```yaml
dependencies:
  core_contracts:
    path: ../../packages/core_contracts
```

Era transitiva via `shared`. Tornar direta elimina os 7 info lints `depend_on_referenced_packages` e alinha com o pattern de `bff/shared/` e `bff/social_care_web/`.

### 10. Testes — 153 RED → 153 GREEN (axes 5x por método)

```
flutter test bff/social_care_desktop/test/remote/
00:00 +153: All tests passed!
```

Por arquivo: health 5/5 · audit 6/6 · care 11/11 · protection 13/13 · assessment 30/30 · lookup 36/36 · registry 52/52.

Cada método é testado em até 5 axes:
1. **HTTP path correctness** — verb e URL com path params interpolados.
2. **Body / query mapping** — `request.toJson()` corresponde ao body; query params asseridos em endpoints paginados/filtrados.
3. **Success response parsing** — `Result<T>` correto (`StandardResponse<...>`, `PaginatedList<...>`, `StandardIdResponse`, `Success(null)`).
4. **BackendError propagation** — non-2xx com `error` key → `Failure(BackendErrorResponse)`.
5. **Network failure** — Dio throwing → `Failure(e)`.

**MockDio** é hand-rolled em `test/remote/_mock_dio.dart` (204 LoC) usando `noSuchMethod` para evitar boilerplate de mocktail. Expõe `lastPath`, `lastBody`, `lastQueryParameters`, `lastResponseData`. Lifted do test legado e estendido pelas necessidades reais.

**UUID fixtures** em `test/_test_uuids.dart` (64 LoC) — cópia das fixtures canônicas RFC 4122 v4 estabelecidas pelo A23 (`bff/social_care_web/test/_test_uuids.dart`). Mesmas constantes (`kPatientUuid`, `kFamilyMemberUuid`, `kMemberUuid`, etc.). Não duplicar lógica, só os literais.

## Out-of-scope autorizado

`apps/acdg_system/` consumers (DI providers em `lib/logic/di/`, `sync_detail_panel.dart`, `staging_integration_test.dart`) **vão falhar de compilar** contra os novos exports. Isto é explicitamente autorizado no master STATE.md:

> "Desktop não está em produção — pode quebrar. Zero teste por enquanto. Breaking changes livres."

A18-v2 reconstrói a `facade/` pública do desktop e o shell volta a compilar. Não é blocker do A16-v2.

## Decisões pinadas (consequência operacional)

1. **Onda 4 = 3 break-change tickets sequenciais.** A16-v2 → A17-v2 → A18-v2 fecham antes da Onda 5 (gate final A19-A21).
2. **Drift é a engine de storage do desktop.** ADR-005 será atualizado para v2 (follow-up). Não recomendar Isar em novos contextos.
3. **`_test_uuids.dart` é canônico em todos os profiles BFF.** Cópia local em cada profile (não dep entre testes). Estabelecido por A23.
4. **MockDio é o padrão de teste para Dio adapters.** Hand-rolled, sem mocktail, fixture-friendly. Reusável em `bff/social_care_bff/` se algum dia precisar.
5. **Sub-contracts são portas estáveis.** Implementadas tanto pelo BFF web Hono quanto pelos remotes desktop. Mudança em sub-contract afeta os 2 profiles + APP — alteração com peso de quebra de contrato.

## Pipeline 3-agent — performance

| Wave | Agente | Saída | Tempo aprox. |
|---|---|---|---|
| W0 | test-writer | 153 RED tests, MockDio, fixtures, REGRA #2 ambiguities pre-resolvidas | ~15 min |
| W1 | flutter-bff-implementer | RemoteBase + 7 thin remotes + library exports + pubspec + 11 deletions | ~10 min |
| W2 | flutter-code-reviewer | Auditoria 9 checks, APPROVED Round 1 | ~3 min |

**Round 1 sem rejeição** — segundo ticket consecutivo (depois de A15) que fecha sem necessidade de re-rolagem. O preset de briefing dos agentes (sub-contracts, fixtures, REGRA #2 ambiguities) está convergindo.

## Próximos passos (Onda 4 — em andamento)

- **A17-v2 (cache):** schema Drift rebuild com DAOs por bounded context. 7 cache contracts + impls. Bloqueia A18.
- **A18-v2 (sync + use_cases + facade):** SyncQueue como sealed-class de mutações tipadas; SyncEngine drena por context; ~40 use cases orquestrando cache+remote+queue; facade público que o `apps/acdg_system/` vai consumir. Fecha a Onda 4.
- **A19-A21 (Onda 5 — gate final):** dart analyze bff/ zero, atualizar handbook/architecture/CONTRACT_A_PUBLIC_API.md, deletar resto de código legado.

Após Onda 5, Fase 4 (Flutter migration) começa — e A24 (débito Flutter dos 13 arquivos retrofitted ao canon V2 do A23) vira o primeiro ticket dela.
