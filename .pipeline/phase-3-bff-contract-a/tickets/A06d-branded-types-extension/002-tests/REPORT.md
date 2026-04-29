# A06d Wave 0 REPORT — Test Writer (Branded Types)

## Status: COMPLETED (RED achieved)

## 11 files criados
`bff/shared/test/domain/kernel/branded_types/`:
- `patient_id_test.dart`, `person_id_test.dart`, `professional_id_test.dart`
- `lookup_id_test.dart`, `appointment_id_test.dart`, `referral_id_test.dart`, `violation_report_id_test.dart`
- `cpf_test.dart`, `cns_test.dart`, `nis_test.dart`, `cep_test.dart`

## Shape contratual (que Wave 1 deve satisfazer)

```dart
extension type PatientId._(String value) {
  static Result<PatientId> create(String? raw) { /* validação inline — H2 */ }
  const PatientId.trusted(String value) : this._(value);

  @override
  String toString() => value;
}
```

Testes verificam:
- `static Result<X> create(String? raw)` preservando error codes existentes
- `const X.trusted(String value) : this._(value)` — construtor zero-cost
- `toString()` retorna valor cru
- Value equality nativa (dois `.trusted(same)` iguais, hashCode idêntico)

## Error codes preservados
PAI-001, PID-001, PRI-001, LID-001, AI-001, RI-001, VRI-001, CPF-004, CNS-005, NIS-002, CEP-002

## Resultado dart test
```
dart test test/domain/kernel/branded_types/
→ RED (load failure):
  Error: Member not found: 'PatientId.trusted'.
  Error: Member not found: 'PersonId.trusted'.
  ... (11 total)
```

Pre-existing tests (`cpf_test`, `cep_test`, `ids_test`, `nis_test` na raiz) continuam GREEN — 18/18 intocados.

## Notes for Wave 1 implementer — CRITICAL

1. **Migrar VOs**: `final class X extends BaseUuid` (IDs) ou `with Equatable` (CPF/CNS/NIS/CEP) → `extension type X._(String value)`
2. **Adicionar `trusted`**: `const X.trusted(String value) : this._(value);`
3. **Manter `create`** com validação **inline por VO** (H2 composition — não depender de `_validateUuid` global)
4. **Deletar `BaseUuid`** quando todos os descendentes migrarem
5. **CNS é especial ⚠️:**
   - Shape atual: `{ number, cpf, qrCode }`
   - Contract do teste: `extension type Cns._(String value)` com `Cns.create({required number})` retornando wrapper
   - **Recomendação:** colapsar Cns para wrapper puro de String. Migrar `cpf`/`qrCode` para o agregado chamador (`CivilDocuments` já tem campo `cpf` próprio).
   - **Callers a ajustar:** `infrastructure/mappers/registry_mapper.dart`, `infrastructure/patient_translator.dart` que lêem `.number`/`.cpf`/`.qrCode`
   - Se inviável, escalar ao maestro — **não** ignorar o teste
6. **Callers `.value`** em CPF/NIS/CEP continuam OK (extension type expõe `value` implicitamente)

## Wave 1 checklist
- [ ] 11 VOs migrados para extension type
- [ ] BaseUuid deletado
- [ ] CNS shape colapsado (ou escalação justificada)
- [ ] Callers de Cns ajustados
- [ ] 11 novos tests GREEN
- [ ] 18 tests pre-existentes GREEN (regression)
- [ ] 479 tests da Onda 2 anterior GREEN
- [ ] `dart analyze bff/shared/lib` zero errors
