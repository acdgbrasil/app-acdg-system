# A06 Wave 1 REPORT — Implementer (Fakes)

## Status: COMPLETED (tests GREEN)

## Arquivos criados (11 fakes)
`bff/shared/lib/src/testing/`:
- `fake_analytics_bff.dart`
- `fake_assessment_bff.dart`
- `fake_audit_bff.dart`
- `fake_auth_bff.dart`
- `fake_care_bff.dart`
- `fake_health_bff.dart`
- `fake_lookup_bff.dart`
- `fake_people_bff.dart`
- `fake_protection_bff.dart`
- `fake_registry_bff.dart`
- `fake_team_bff.dart`

## Arquivo deletado
- `bff/shared/lib/src/testing/fake_social_care_bff.dart` (legado — importava contract deletado em A05)

## shared.dart
- 1 export removido (`src/testing/fake_social_care_bff.dart`)
- 11 exports adicionados (seção `// Testing — Fakes per sub-contract`)

## Decisões técnicas

### Geração de IDs
`DateTime.now().microsecondsSinceEpoch.toString()` em todos os fakes que criam entidades.

### Estratégia para métodos não cobertos por smoke tests
Implementação mínima funcional (preferido sobre stubs de erro): cada fake mantém estado in-memory coerente, permitindo que tickets downstream (A07-A18) façam testes mais profundos sem precisar reinventar fakes.

### Fakes com CRUD completo (state-preserving)
- `FakeLookupBff`: `Map<String, List<LookupItemResponse>>` por tableName; governance requests com status mutável (pending/approved/rejected)
- `FakePeopleBff`: `Map<String, PersonResponse>` + `Map<String, List<PersonRoleResponse>>`; filtros por nome/CPF; reativação/desativação de roles
- `FakeRegistryBff`: duas tabelas espelhadas — `_summaries` (lista) e `_patients` (agregado). `registerPatient` constrói `PatientSummaryResponse` a partir de `personalData` e `initialDiagnoses.first.description`
- `FakeTeamBff`: `Map<String, TeamMemberResponse>` com toggle active/inactive e roles por memberId
- `FakeAuditBff`: trail vazio por padrão + método `seed()` opcional para tests futuros
- `FakeCareBff` / `FakeProtectionBff`: guardam requests por id gerado

### Fake stateless (passthrough)
- `FakeHealthBff`: só retorna `Success(null)`
- `FakeAnalyticsBff`: retorna datasets vazios
- `FakeAssessmentBff`: todos os 7 updates retornam `Success(null)`
- `FakeAuthBff`: `MeResponse` default injetável via construtor + `setMe()` opcional

### Correção detectada
`ToggleLookupItemRequest` — o contract pede o DTO (com campo `active`), não `bool activate`. Wave 1 usou o DTO correto (corrigido do legado).

## Resultado dos testes

```
dart test test/testing/fakes/
→ 00:00 +25: All tests passed!
```

25 testes passam (11 implements-contract + 14 smoke operations CRUD).

Suite completa do bff/shared: **336 testes GREEN**.

## Resultado dart analyze

```
cd bff/shared && dart analyze lib
→ Analyzing lib...
  No issues found!
```

## Observações para tickets A07-A18
- Fakes state-preserving permitem testes mais profundos sem subclassificar
- Zero import cruzado entre fakes — cada um importa apenas seu sub-contract + DTOs
- `FakeAuthBff` e `FakeAuditBff` têm API extra (construtor com `me`, método `seed`) para tests que precisam variar

## Onda 2 — FECHADA
A01 ✅ · A02 ✅ · A03 ✅ · A04 ✅ · A05 ✅ · A06 ✅
