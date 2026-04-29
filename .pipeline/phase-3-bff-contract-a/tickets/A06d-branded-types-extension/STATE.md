# Ticket State: A06d-branded-types-extension

phase: implementation
agent: implementer (Wave 1) — completed
status: A06d COMPLETED 2026-04-16 — Wave 0 RED → Wave 1 GREEN

## Wave 1 summary (2026-04-16)
- 11 VOs migrated to `extension type const X._(...)` with `trusted` zero-cost constructor
- `BaseUuid` DELETED (no descendants)
- `_validateUuid` global helper REMOVED — each ID validates inline (H2 composition)
- CNS edge case RESOLVED: collapsed to pure `String` wrapper; added
  `CivilDocuments.cnsQrCode` for QR preservation; JSON wire shape unchanged
- Suite bff/shared: **545 tests GREEN** (11 new Wave 0 + 534 pré-existentes)
- `dart analyze bff/shared` → **zero issues**

## Motivação recap
- Eliminar `BaseUuid` (porta compartilhada que disfarça acoplamento)
- 13+ branded types viram `extension type` zero-cost
- Cada VO com sua própria validação (H1/H2 + H8 aplicados no caso limite)

## Wave 0 — test-writer (COMPLETED)

### Arquivos criados (11)
- `bff/shared/test/domain/kernel/branded_types/patient_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/person_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/professional_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/lookup_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/appointment_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/referral_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/violation_report_id_test.dart`
- `bff/shared/test/domain/kernel/branded_types/cpf_test.dart`
- `bff/shared/test/domain/kernel/branded_types/cns_test.dart`
- `bff/shared/test/domain/kernel/branded_types/nis_test.dart`
- `bff/shared/test/domain/kernel/branded_types/cep_test.dart`

### Estado atual dos testes
`dart test test/domain/kernel/branded_types/` → **RED na compilação**.
Todos os 11 arquivos falham em `loading` com `Error: Member not found: 'X.trusted'`.
Pre-existing tests (cpf_test, cep_test, ids_test, nis_test na raiz) continuam GREEN — nada foi alterado.

### Shape esperado (contrato que Wave 1 deve satisfazer)

Para cada ID (UUID v4):
```dart
extension type PatientId._(String value) {
  static Result<PatientId> create(String? raw) { /* UUID v4 validation inline */ }
  const PatientId.trusted(String value) : this._(value);

  @override
  String toString() => value;
}
```

Error codes por ID:
- `PatientId` → PAI-001
- `PersonId` → PID-001
- `ProfessionalId` → PRI-001
- `LookupId` → LID-001
- `AppointmentId` → AI-001
- `ReferralId` → RI-001
- `ViolationReportId` → VRI-001

Para VOs de formato:
- `Cpf` — extension type `String`, invalid mod11 → CPF-004
- `Cns` — extension type `String`, invalid DV → CNS-005. **Breaking change:** colapsar `{ number, cpf, qrCode }` em um único wrapper de `String` (cpf/qrCode devem viver em outro lugar — `CivilDocuments` já tem campo `cpf` próprio). O teste assume `Cns.create({required number})` e `Cns.trusted(String)`.
- `Nis` — extension type `String`, invalid → NIS-002
- `Cep` — extension type `String`, invalid chars → CEP-002

## Notes para Wave 1 implementer

1. Migrar cada VO de `final class X extends BaseUuid` (IDs) ou `final class X with Equatable` (CPF/CNS/NIS/CEP) → `extension type X._(String value)`.
2. Adicionar `const X.trusted(String value) : this._(value)` em cada um.
3. Manter `X.create(...)` com mesma validação (inline, copiar de `_validateUuid` para os IDs; manter lógica atual de CPF/CNS/NIS/CEP).
4. **Deletar `BaseUuid`** quando todos os descendentes estiverem migrados.
5. **Avaliar `_validateUuid`:** cada ID com validação inline (H2 composition over inheritance). Se mantida como função top-level reutilizável, OK — mas não é obrigatória.
6. **CNS é especial:** se Wave 1 manter o shape `{ number, cpf, qrCode }`, o teste `cns_test.dart` exige que `Cns.create(number: validCns)` e `Cns.trusted(validCns)` funcionem e que `toString()` retorne o número de 15 dígitos. Recomendação: extrair `cpf`/`qrCode` para o agregado chamador e deixar `Cns` como puro wrapper de String. Escalar se não for possível.
7. **Callers que usam `.value` em CPF/NIS/CEP** continuam funcionando (extension type expõe o getter implícito `value`).
8. **Callers do `Cns` que lêem `.number` / `.cpf` / `.qrCode`** vão quebrar — ajustar quando houver a migração (provavelmente em `CivilDocuments` / `patient_translator.dart` / `registry_mapper.dart`).
