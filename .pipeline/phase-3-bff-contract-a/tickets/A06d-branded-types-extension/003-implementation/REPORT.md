# A06d Wave 1 REPORT — Implementer (Extension Types)

## Status: COMPLETED (tests GREEN)

## Resultado
- `dart test` (bff/shared full) → **545 GREEN** / 0 RED
  - 11 novos tests `test/domain/kernel/branded_types/*` → GREEN
  - 534 pre-existentes → GREEN (inclusive `patient_translator_test.dart` adaptado)
- `dart analyze bff/shared` → **No issues found!**

## 11 VOs migrados

### IDs (7) — UUID v4 validation inline
`bff/shared/lib/src/domain/kernel/ids.dart`:
PersonId, ProfessionalId, PatientId, LookupId, AppointmentId, ReferralId, ViolationReportId.

Error codes preservados: PID-001, PRI-001, PAI-001, LID-001, AI-001, RI-001, VRI-001.

### VOs de formato (4) — domain-specific validation
- `Cpf` (CPF-004, mod 11) — `cpf.dart`
- `Cns` (CNS-005, DV do SUS) — `cns.dart`
- `Nis` (NIS-002, mod 11) — `nis.dart`
- `Cep` (CEP-002, UF range) — `cep.dart`

## Pattern final

```dart
extension type const X._(String value) {
  static Result<X> create(String? raw) { /* inline validation */ }
  const X.trusted(String value) : this._(value);
  // domain-specific getters mantidos quando relevantes (ex: Cpf.fiscalRegion, Cep.distributionKind)
}
```

### Notas importantes
- `extension type const` é necessário para o `const X.trusted(v) : this._(v)` redirecting constructor ser const.
- **Sem override explícito de `toString()`** — extension types proíbem shadow de Object members. O `String.toString()` subjacente já retorna o valor cru, satisfazendo os testes Wave 0.

## BaseUuid: DELETADO
`abstract class BaseUuid with Equatable` removida. `_validateUuid` helper global removido — cada ID valida inline (H2 composition over inheritance).

`_uuidRegex` + `_uuidError(...)` permanecem como helpers top-level em `ids.dart` apenas por conveniência de legibilidade (7 IDs usam formato UUID v4 por coincidência — não é uma porta compartilhada).

## CNS edge case: COLAPSADO

### Decisão
Domain `Cns` virou **pure String wrapper**. Shape antigo `{ number, cpf, qrCode }` foi decomposto:

1. **`cpf`** → `CivilDocuments.cpf` (campo já existente — same person, same document). Regra `CNS-006` (cross-check CNS-CPF) removida pois se tornou impossível pela refatoração.
2. **`qrCode`** → novo campo opcional `CivilDocuments.cnsQrCode`.
3. **Wire JSON preservado** — `RegistryMapper` continua emitindo/lendo `cns: { number, cpf, qrCode }` (compatibilidade com Swift/Vapor). Mapper popula `cns.cpf` a partir de `CivilDocuments.cpf.value`; `cns.qrCode` a partir de `CivilDocuments.cnsQrCode`. Na desserialização, se `cns.cpf` vier no JSON mas `civilDocuments.cpf` não, o `cpf` interno é hidratado do `cns.cpf`.
4. **DTOs externos `CnsResponse` e `CnsDraftDto` NÃO mudaram** — Contract A/B preservados.

### Callers ajustados (5 arquivos)
- `bff/shared/lib/src/infrastructure/mappers/registry_mapper.dart` — `civilDocumentsToJson`/`civilDocumentsFromJson` reescritos para novo domain shape
- `bff/shared/lib/src/domain/registry/registry_vos.dart` — adicionado `final String? cnsQrCode`; removido CNS-006
- `bff/shared/test/infrastructure/patient_translator_test.dart` — asserts `cns!.value / cpf?.value / cnsQrCode` (JSON wire asserts intactos)
- `packages/social_care/lib/src/data/mappers/patient_register_mapper.dart` — `Cns.create(number: intent.cns!)`
- `packages/social_care/test/logic/mappers/mappers_test.dart` — `cns?.value` em vez de `cns?.number`

## Outros pacotes
`packages/social_care`, `bff/social_care_desktop`, `bff/social_care_web` têm **erros pré-existentes** da phase-2-api-clients WIP (undefined `SocialCareContract`, missing `FakeSocialCareBff`, etc.). **Nenhum novo introduzido por A06d** — verificado via `git stash` do baseline.

## Política aplicada
- **H8**: extension type para primitivos zero-cost ✅
- **H2**: composition over inheritance (BaseUuid eliminado) ✅
- **Parse, don't validate** (Alexis King): factory `create` retorna `Result<X>` ✅
- **Information hiding** (Parnas): wire format preservado, domain internals mudaram ✅
