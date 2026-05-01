# A15 — Resume Plan (post-A23)

**Created:** 2026-04-29 (after A23 W4 close)
**Status:** ready to execute

A23 W4 fechou e estabeleceu o canon V2 (`map`/`flatMap`/`combineWith`,
Templates A/B/C). A15 estava paused at Wave 4.5 desde 2026-04-28
aguardando exatamente isso. Este doc é o plano de retomada concreto.

---

## Pré-condições verificadas (✓ todas atendidas)

- [x] A23 W0 helper `validateUuidPathParam` em `bff/social_care_web/lib/src/intents/uuid_validation.dart` ✅
- [x] §P5 publicado em `handbook/architecture/PATTERN_MATCHING_POLICY.md` ✅
- [x] `core_contracts.Result.map`/`flatMap` e
      `core_contracts.combineWith` 2-ary/3-ary disponíveis ✅
- [x] Lint `acdg_lints/no_sealed_class_downcast` wireado em
      `bff/social_care_web/analysis_options.yaml` ✅
- [x] Script `scripts/check_no_sealed_cast.sh` no CI ✅
- [x] Templates V2 (A/B/C) documentados em
      `phase-3-bff-contract-a/tickets/A23-uuid-path-validation/STATE.md` ✅
- [x] `_test_uuids.dart` carrega `kMemberUuid`, `kMemberUuidAlt`,
      `kRoleUuid`, `kRoleUuidAlt`, `kNonUuid` ✅
- [x] Wave 1-4 do A15 estruturalmente em pé (946 tests GREEN no
      pause) — atingem-se via `git status` (nenhuma regressão
      pendente sob `bff/social_care_web/lib/src/intents/`
      relacionada a Team) ✅

---

## Mapa dos 9 endpoints — qual template aplicar

Dos 9 endpoints listados no `000-request.md`, **7 têm path UUID**
(precisam UUID gate); 2 não têm (`ListTeam`, `RegisterWorker`) e ficam
inalterados.

| # | Endpoint | Intent file | Template | UUIDs no path |
|---|---|---|---|---|
| 1 | `GET /api/team` | `list_team_intent.dart` | — (query-only) | 0 |
| 2 | `POST /api/team` | `register_worker_intent.dart` | — (body-only) | 0 |
| 3 | `GET /api/team/:id` | `get_team_member_intent.dart` | **A** V2 | 1 (`memberId`) |
| 4 | `PUT /api/team/:id/deactivate` | `deactivate_worker_intent.dart` | **A** V2 | 1 (`memberId`) |
| 5 | `PUT /api/team/:id/reactivate` | `reactivate_worker_intent.dart` | **A** V2 | 1 (`memberId`) |
| 6 | `POST /api/team/:id/reset-password` | `reset_password_intent.dart` | **A** V2 | 1 (`memberId`) |
| 7 | `POST /api/team/:id/roles` | `assign_role_intent.dart` | **C-P2** V2 | 1 (`memberId`) + body |
| 8 | `PUT /api/team/:id/roles/:roleId/deactivate` | `deactivate_role_intent.dart` | **B** V2 | 2 (`memberId`, `roleId`) |
| 9 | `PUT /api/team/:id/roles/:roleId/reactivate` | `reactivate_role_intent.dart` | **B** V2 | 2 (`memberId`, `roleId`) |

**Distribuição:** 4 × Template A · 1 × Template C-P2 · 2 × Template B.

---

## Forma canônica de cada template (referência rápida — `as` proibido)

### Template A V2 (path-only, 1 UUID)

```dart
import 'package:core_contracts/core_contracts.dart';
import 'uuid_validation.dart';

final class GetTeamMemberIntent with Equatable {
  const GetTeamMemberIntent({required this.memberId});
  final String memberId;
  @override
  List<Object?> get props => [memberId];

  static Result<GetTeamMemberIntent> parseFromPath(String rawMemberId) =>
      validateUuidPathParam(rawMemberId, fieldName: 'memberId')
          .map((id) => GetTeamMemberIntent(memberId: id));
}
```

### Template B V2 (path-only, 2 UUIDs)

```dart
final class DeactivateRoleIntent with Equatable {
  const DeactivateRoleIntent({required this.memberId, required this.roleId});
  final String memberId;
  final String roleId;
  @override
  List<Object?> get props => [memberId, roleId];

  static Result<DeactivateRoleIntent> parseFromParams({
    required String rawMemberId,
    required String rawRoleId,
  }) {
    final m = validateUuidPathParam(rawMemberId, fieldName: 'memberId');
    final r = validateUuidPathParam(rawRoleId, fieldName: 'roleId');
    return (m, r).combineWith(
      (memberId, roleId) =>
          DeactivateRoleIntent(memberId: memberId, roleId: roleId),
    );
  }
}
```

### Template C-P2 V2 (path UUID + body parser manual)

```dart
final class AssignRoleIntent with Equatable {
  const AssignRoleIntent({required this.memberId, required this.request});
  final String memberId;
  final AssignRoleRequest request;
  @override
  List<Object?> get props => [memberId, request];

  static Result<AssignRoleIntent> parseFromBody(
    String rawMemberId,
    Map<String, dynamic> body,
  ) =>
      validateUuidPathParam(rawMemberId, fieldName: 'memberId')
          .flatMap((memberId) => _parseBody(memberId, body));

  static Result<AssignRoleIntent> _parseBody(
    String memberId,
    Map<String, dynamic> body,
  ) {
    if (body case {'roleId': final String roleId} when roleId.isNotEmpty) {
      return Success(
        AssignRoleIntent(
          memberId: memberId,
          request: AssignRoleRequest(roleId: roleId),
        ),
      );
    }
    return Failure(
      const _AssignRoleParseError(
        'Invalid assign-role body: missing or empty [roleId]',
      ),
    );
  }
}

final class _AssignRoleParseError with Equatable implements Exception { … }
```

---

## Plano de execução (waves)

### Wave 4.5 — Intent retrofit (7 files)

Ordem sugerida (mais simples → mais complexo, todos independentes):

1. `get_team_member_intent.dart` — Template A V2 (lib + test)
2. `deactivate_worker_intent.dart` — Template A V2 (lib + test)
3. `reactivate_worker_intent.dart` — Template A V2 (lib + test)
4. `reset_password_intent.dart` — Template A V2 (lib + test)
5. `deactivate_role_intent.dart` — Template B V2 (lib + test)
6. `reactivate_role_intent.dart` — Template B V2 (lib + test)
7. `assign_role_intent.dart` — Template C-P2 V2 (lib + test)

Cada intent test ganha:
- Import de `_test_uuids.dart` + `uuid_validation.dart`
- Sweep dos synthetic ids (`'m-1'`, `'m-2'`, `'r-1'`) → `kMemberUuid`,
  `kMemberUuidAlt`, `kRoleUuid`
- 1 novo test de UUID-rejection (Template A: `parseFromPath(kNonUuid)`;
  Template B: rejection em ambos slots; Template C: rejection no
  path antes do body)

### Wave 4.6 — Handler routing (1 file)

`lib/src/handlers/team_handler.dart`:

- Para cada uma das 7 rotas com UUID: chamar `parseFromPath` /
  `parseFromParams` / `parseFromBody`, e mapear `Failure` para
  `_badRequest(code: 'INVALID_<X>_PARAMS', message: error.toString())`.
- Para `parseFromBody` de `AssignRole`, manter o código existente:
  `INVALID_ASSIGN_ROLE_BODY` cobre tanto path quanto body via prefix
  `Invalid path parameter [...]` na mensagem (canon Template D).
- Rotas `/api/team` (list) e `POST /api/team` (register) NÃO mudam.

### Wave 4.7 — Test cheat fix (REGRA #2)

`test/handlers/team_handler_test.dart` group `topology hiding`:

- **Atualmente:** testa apenas URLs 4-segment (`/team/people/by-cpf/<cpf>`,
  `/team/people/<id>/roles`) — porque o teste original `GET /team/people →
  404` falhava com 500 (route bleed que A23 corrige).
- **Substituir por:** `expect(GET /team/people → 400
  INVALID_GET_TEAM_MEMBER_PARAMS)`. UUID gate rejeita `'people'` como
  path id. PII-safety: a mensagem do erro NÃO contém `'people'`.

Comentar inline a referência ao log da REGRA #2 (CLAUDE.md §REGRA #2,
incidente de 2026-04-28).

### Wave 5 — Quality gate

- [ ] `dart analyze bff/social_care_web` → 0 new issues
- [ ] `dart test` na suite BFF Web inteira — esperar ≥ 1026 GREEN
      (W4 close baseline) + delta novo do A15 retake (≈ 7 intent tests
      + 7 handler tests + 1 fix do test cheat = ~15 tests novos) →
      target ≥ 1041 GREEN
- [ ] `bash scripts/check_no_sealed_cast.sh` → 0 violations no BFF Web
- [ ] `dart run custom_lint --working-directory=bff/social_care_web` →
      0 issues
- [ ] As 2 falhas pre-existentes A21 (health_handler +
      social_care_api_client) seguem como únicas falhas

### Wave 6 — Close

- [ ] Update `A15-web-team/STATE.md` → phase: DONE com números finais
- [ ] Update phase-3 STATE.md (se houver)
- [ ] Commit `feat(a15): UUID path validation V2 — Team surface
      (7 intents + handler + test cheat fix)`

---

## Esforço estimado

| Wave | Tarefa | Tempo |
|---|---|---|
| 4.5 | 4× Template A (intents + tests) | ~25min |
| 4.5 | 2× Template B (intents + tests) | ~20min |
| 4.5 | 1× Template C-P2 (intent + test) | ~15min |
| 4.6 | TeamHandler — error code mapping | ~15min |
| 4.7 | Test cheat fix + restore `/team/people → 400` | ~10min |
| 5 | Quality gate (analyze + test + lint + script) | ~10min |
| 6 | Close STATE.md + commit | ~5min |
| | **Total** | **~100min (~1.5h)** |

A maior parte é mecânica (Templates A/B/C V2 já documentados, com
exemplos no §P5 e nos templates do A23). Não há decisões de design
novas — só replicação cuidadosa.

---

## Critérios de pronto (Definition of Done)

- [ ] 7 intents de Team usando V2 (zero `as Success`)
- [ ] TeamHandler emite `400 INVALID_<X>_PARAMS` para path inválido
- [ ] Test cheat de 2026-04-28 corrigido (REGRA #2 cumprida)
- [ ] Suite BFF Web ≥ 1041 GREEN / 2 FAIL pre-existentes
- [ ] `dart analyze` 0 new issues
- [ ] Lint custom + script CI sem regressão
- [ ] STATE.md A15 → DONE
- [ ] A22 backlog ainda aberto (4 rules restantes) — A15 não fecha A22

---

## Riscos catalogados

1. **Route bleed regression** — se ao corrigir o test cheat o
   shelf_router não rotear `/team/people` para `_handleGet`, o
   tested 400 pode chegar como 404 do framework. **Mitigação:**
   verificar que o router `r.get('/team/<id>', _handleGet)` casa
   `/team/people` (deve casar — `<id>` é greedy 1-seg). Test deve
   confirmar.
2. **Test cheat `if-case Success` em testes existentes** — alguns
   tests do A15 (W1-W3) podem ter switch defensivo; §P5 Armadilha 7
   diz para substituir por `as Success<T>` fail-fast. **Mitigação:**
   sweep dos 9 intent + 1 handler test files procurando
   `if (result case Success` e converter.
3. **Wiring A15 W4 já feito** — não tocar `apps/acdg_system/...`,
   `bff/social_care_web/lib/src/server.dart`, ou
   `core/lib/src/network/...`. Wave 4.6 SÓ mexe em `team_handler.dart`.
