# A23 — UUID Path Validation Canon (global invariant retrofit)

## Onda: 3.5 (cross-cutting) | Profile: bff/social_care_web | Depende de: A14
## Bloqueia: A15 (paused) — A15 só retoma quando A23 fechar

## Origem
Descoberta durante A15 Wave 3 (2026-04-28): a rota `/team/<id>` capturava
qualquer string 2-segmentos (incluindo URLs legadas como `/team/people`)
e gerava um round-trip inútil ao backend que retornava 500 sanitizado.

Investigação revelou que a falha é **global**, não específica de Team:
todos os intents path-only de A07-A14 aceitam qualquer string como ID
sem validação local. Decisão (usuário, 2026-04-28):

> "validação de UUID em path params" é regra global, não escolha por
> feature. Se vou estabelecer o invariante, faço uma vez para o repo
> inteiro.

## Evidência do contrato
Confirmado por inspeção de social-care (Swift/Vapor) e people-context
(TS/Bun):

- **Formato canônico:** UUID v4, 36 chars, lowercase com hífens, sem
  braces, sem URN, sem prefixos.
- **Backend Swift** (`PersonId.swift:38`, `LookupId.swift`,
  `ProfessionalId.swift:38`, etc): `UUID().uuidString.lowercased()`
  na geração; `trim → lowercase → Foundation.UUID parser` na validação.
- **Backend TS** (`routes/people.ts:10`, `routes/roles.ts:13`):
  `crypto.randomUUID()` na geração; regex
  `/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i`
  na validação.
- **Banco** (Postgres): `UUID PRIMARY KEY DEFAULT gen_random_uuid()` em
  ambos serviços.

Não há ULID, NanoID, UUIDv7, prefixos de tipo, braces ou URN.

## Escopo

### 1. Helper compartilhado
Criar `bff/social_care_web/lib/src/intents/_uuid_validation.dart`:

```dart
/// Validates that [raw] is a canonical UUID v4 string (36 chars,
/// lowercase, hyphenated). Trims surrounding whitespace and lowercases
/// the input before validating, matching the social-care Swift backend
/// normalization (trim → lowercase → UUID parser).
///
/// Returns Success(normalized) when [raw] is a valid v4 UUID.
/// Returns Failure([_UuidParseError]) otherwise — message NEVER echoes
/// [raw] (PII discipline; UUIDs themselves are not PII but path values
/// could be malformed CPF/email if a client mis-uses the route).
Result<String> validateUuidParam(String raw, {required String fieldName});
```

Regex: estrita RFC 4122 v4
`^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`

### 2. Retrofit nos intents path-typed (~26 intents fora de A15)

#### A08 — Registry Patient (5 intents, todos com `patientId`)
- `GetPatientIntent`
- `AdmitPatientIntent`
- `DischargePatientIntent`
- `ReadmitPatientIntent`
- `WithdrawPatientIntent`

#### A09 — Registry Family + Audit (5 intents)
- `AddFamilyMemberIntent` (patientId — P2 com path)
- `RemoveFamilyMemberIntent` (patientId, familyMemberId — path-only)
- `AssignPrimaryCaregiverIntent` (patientId, familyMemberId — P2)
- `UpdateSocialIdentityIntent` (patientId — P2)
- `GetAuditTrailIntent` (patientId — path-only)

#### A10 — Assessment 7 fichas (todos P2 com `patientId`)
- `UpdateHousingConditionIntent`
- `UpdateSocioEconomicSituationIntent`
- `UpdateWorkAndIncomeIntent`
- `UpdateEducationalStatusIntent`
- `UpdateHealthStatusIntent`
- `UpdateCommunitySupportNetworkIntent`
- `UpdateSocialHealthSummaryIntent`

#### A11 — Care (2 intents, P2 com `patientId`)
- `RegisterAppointmentIntent`
- `UpdateIntakeInfoIntent`

#### A12 — Protection (3 intents, P2 com `patientId`)
- `CreateReferralIntent`
- `ReportRightsViolationIntent`
- `UpdatePlacementHistoryIntent`

#### A13 — Lookup (4 intents UUID-typed; tableName NÃO é UUID)
- `UpdateLookupItemIntent` (itemId — P2-tolerant com path)
- `ToggleLookupItemIntent` (itemId — P2 com path)
- `ApproveLookupRequestIntent` (requestId — path-only)
- `RejectLookupRequestIntent` (requestId — path-only)

### 3. Cada intent atingido
- Adicionar factory `parseFromPath` (path-only) ou estender
  `parseFromBody(pathParam, body)` para validar `pathParam` como UUID
  ANTES do parse de body.
- Atualizar handler para chamar `parseFromPath`/`parseFromBody` em vez
  de construir o intent diretamente.
- Code 400 dedicado por endpoint: `INVALID_<INTENT_NAME>_PARAMS`.

### 4. Tests
- ~3-5 testes novos por intent (UUID válido, UUID maiúsculo
  normalizado, UUID malformado, não-UUID rejeitado).
- Substituir os 116 IDs sintéticos (`'m-1'`, `'p-1'`, `'r-1'`) nos 28
  test files por UUIDs reais. Sugestão: helper `kPatientUuid`,
  `kMemberUuid`, etc num `test/_test_uuids.dart`.
- Add ao handler test grupos novos de "rejects non-UUID path param →
  400 INVALID_*_PARAMS".

### 5. Coerência
- A15 retoma APÓS A23 fechar — adicionando o mesmo padrão aos 9 Team
  intents (memberId × 7, roleId × 2).
- A20 (doc Contract A) reflete o invariante.
- A21 (delete legacy) — nada muda; legado já foi deletado.

## Critérios
- [ ] Helper criado + 100% coberto por testes (UUID válido, malformado,
      uppercase, com whitespace, vazio, v1/v3/v5 rejeitados, etc)
- [ ] Os ~26 intents path-typed fora de A15 atualizados
- [ ] Cada handler retorna 400 `INVALID_*_PARAMS` com message PII-safe
- [ ] Todos os 28 test files com IDs sintéticos atualizados pra UUIDs
- [ ] `dart analyze bff/social_care_web` zero new errors
- [ ] `dart test bff/social_care_web` ≥ ~1100 GREEN (era 946 ao pausar
      A15; +~150 testes esperados)
- [ ] CONTRACT_A_PUBLIC_API.md atualizado com a regra "path params
      tipados como UUID são validados localmente no BFF; rejeições
      retornam 400 INVALID_*_PARAMS sem hit no upstream"
- [ ] STATE de A15 atualizado pra "ready to resume"

## Status
pending — opens after this is approved | A15 paused waiting for A23 to close

## Ondas internas (sugeridas)
- W0: Helper + tests (1 dia)
- W1: Retrofit A08-A09 (Patient + Family) — 10 intents (1 dia)
- W2: Retrofit A10 (Assessment) — 7 intents (0.5 dia)
- W3: Retrofit A11-A13 (Care + Protection + Lookup) — 9 intents (1 dia)
- W4: Substituir IDs sintéticos em handler tests (0.5 dia)
- W5: Quality gate + doc + close (0.5 dia)

Total estimado: 3.5-4.5 dias se cuidadoso.
