# A06d — Branded Types → `extension type` (eliminar BaseUuid)

## Onda: 2 (sub-ticket) | Profile: bff/shared | Depende de: A06c ✅

## Motivação
Brand types (IDs + VOs de formato) hoje são `final class extends BaseUuid` com Equatable. Isso tem 3 problemas:

1. **Alocação desnecessária** — cada `PatientId('uuid')` aloca objeto em runtime. Extension types são zero-cost (compilados para String direto).
2. **Porta compartilhada disfarça acoplamento** — `BaseUuid` + `_validateUuid` genérica sugere que IDs têm algo em comum; na verdade têm apenas formato UUID v4. CPF (validação de dígito verificador) e CEP (8 dígitos) não compartilham nada dessa base — **o compartilhamento é falso**.
3. **Herança viola H1/H2** da `ENCAPSULATION_POLICY.md` — `extends BaseUuid` é exatamente o "brittle base class" que queremos evitar.

Política aplicável: **H8 (extension type para primitivas)** + princípio de que cada VO deve lidar com sua própria validação.

## Escopo

### 1. Migrar 9 IDs (UUID v4) de `bff/shared/lib/src/domain/kernel/ids.dart`
- `PersonId`, `ProfessionalId`, `PatientId`, `LookupId`
- `AppointmentId`, `ReferralId`, `ViolationReportId`
- (+ outros que aparecerem na varredura)

### 2. Migrar 3 VOs de formato (validação custom)
- `CPF` (dígitos verificadores)
- `CNS` (algoritmo do SUS)
- `NIS` (formato)

### 3. Migrar 1 VO de formato simples
- `CEP` (8 dígitos)

### 4. Avaliar `TimeStamp`
- Se tem apenas `value: DateTime` + validação → extension type
- Se tem operações (addDuration, format, etc.) → manter classe

### 5. Deletar
- `BaseUuid` abstract class (sem descendentes)
- `_validateUuid` função top-level pode permanecer se reutilizada por múltiplos IDs, OU cada ID valida inline (avaliar redundância)

## Pattern alvo (Parse, don't validate — Alexis King)

```dart
extension type PatientId._(String value) {
  /// Create — valida UUID v4. Retorna Success ou Failure com AppError tipado.
  static Result<PatientId> create(String? raw) {
    final normalized = raw?.normalizedTrim().toLowerCase();
    if (normalized == null || !_uuidRegex.hasMatch(normalized)) {
      return Failure(AppError(
        code: 'PAI-001',
        message: 'Identificador inválido: "${raw ?? 'null'}"',
        module: 'social-care/patient-id',
        kind: 'invalidFormat',
        http: 422,
        observability: const Observability(
          category: ErrorCategory.domainRuleViolation,
          severity: ErrorSeverity.error,
        ),
      ));
    }
    return Success(PatientId._(normalized));
  }

  /// Trusted — origens garantidas (UUID.v4() generation, fixtures).
  /// Usar com parcimônia; comentar o motivo.
  const PatientId.trusted(String value) : this._(value);

  @override
  String toString() => value;
}
```

### Para CPF/CNS (validação diferente)
Cada VO tem **sua própria `_valida<Tipo>`** — não compartilha com os IDs. Isso é o ganho arquitetural: independência de regras.

## TDD

### Wave 0 — test-writer
Para cada VO/ID (13+ totais), testes que:
1. `X.create(validoParaX)` → `Success(X)`
2. `X.create(invalido)` → `Failure<AppError>` com code correto
3. `X.create(null)` → `Failure`
4. `X('raw') == X('raw')` → `true` (value equality nativa do extension type)
5. `void foo(X x)` não aceita `String` direto (compile-time check — verificar com `expectLater` compile)
6. `X.trusted('x')` funciona quando origem é garantida

Testes em `bff/shared/test/domain/kernel/` (provavelmente já existem — auditar/adaptar).

### Wave 1 — implementer
1. Criar cada VO como `extension type X._(Type value)` com factory `create` + `trusted`
2. Validação inline (copiar de `_validateUuid` para IDs; de `cpf.dart`/`cns.dart`/`nis.dart`/`cep.dart` para os VOs de formato)
3. Deletar `BaseUuid` (após todos os descendentes migrarem)
4. Deletar ou manter `_validateUuid` dependendo de reutilização
5. Ajustar consumidores — **apenas** se usaram herança de `BaseUuid` (deve ser zero); o uso `X.create(raw)` fica idêntico

## Critérios de aceitação
- [ ] 13+ branded types como `extension type`
- [ ] `BaseUuid` **deletado**
- [ ] Todos os testes (existentes e novos) GREEN
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `dart run build_runner build` (caso DTOs usem IDs internamente — conferir)

## Não faça
- NÃO altere DTOs que usam String no shape (IDs dos responses — são `String` no JSON, brand acontece só no domain layer se existir)
- NÃO mexa em sub-contracts (interfaces consomem os VOs como antes)
- NÃO quebre `TimeStamp` sem avaliar operações

## Impacto em consumidores
- `X.create(raw)` continua funcionando igual
- `X(raw)` (construtor canonical do extension type) **nunca** deve ser usado direto — usar `.create` ou `.trusted`
- Convenção: construtor default privado (`X._`) impede uso externo acidental

## Status
ready after A06c completes
