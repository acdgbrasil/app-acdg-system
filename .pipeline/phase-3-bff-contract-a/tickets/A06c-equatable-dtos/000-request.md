# A06c — Equatable em todos os DTOs (value-equality)

## Onda: 2 (sub-ticket) | Profile: bff/shared | Depende de: A06b ✅

## Motivação
`handbook/architecture/ENCAPSULATION_POLICY.md` §"Value vs Reference semantics" estabelece:
> Se a classe tem semântica de VALOR (DTO, VO, domain model), `with Equatable` é OBRIGATÓRIO.

**Estado herdado da Phase 1:** 33 de 34 DTOs response e todos 35 DTOs request NÃO usam Equatable. Consequência: `RegisterPatientRequest(x) == RegisterPatientRequest(x)` é **false** — comparação por referência, não valor.

## Escopo

Adicionar `with Equatable` + `List<Object?> get props` em **todos os DTOs** de `bff/shared/lib/src/contract/dto/`:

| Categoria | Arquivos | Nota |
|-----------|:--------:|------|
| Requests (Phase 1 + A02) | 35 | nenhum tem Equatable hoje |
| Responses (Phase 1 + A03) | 33 | LookupItemResponse já tem (feito em A03) |
| Shared wrappers (`dto/shared/`) | 4 | StandardResponse, PaginatedList, etc. |
| **Total** | **~72** | mudança aditiva |

## Mudança típica

```dart
// Antes
@JsonSerializable()
class RegisterPatientRequest {
  const RegisterPatientRequest({required this.personId, this.notes});
  final String personId;
  final String? notes;
  factory RegisterPatientRequest.fromJson(Map<String, dynamic> json) => _$...;
  Map<String, dynamic> toJson() => _$...;
}

// Depois
@JsonSerializable()
class RegisterPatientRequest with Equatable {  // ← adicionado
  const RegisterPatientRequest({required this.personId, this.notes});
  final String personId;
  final String? notes;
  factory RegisterPatientRequest.fromJson(Map<String, dynamic> json) => _$...;
  Map<String, dynamic> toJson() => _$...;

  @override
  List<Object?> get props => [personId, notes];  // ← adicionado
}
```

## TDD

### Wave 0 — test-writer
Criar 1 arquivo de teste de equality por bounded context:
- `test/contract/dto/equality/request_equality_test.dart` (testa todos os 35 requests)
- `test/contract/dto/equality/response_equality_test.dart` (testa todos os 33 responses)
- `test/contract/dto/equality/shared_equality_test.dart` (testa 4 wrappers)

Cada teste instancia 2 DTOs com conteúdo idêntico e verifica `expect(a, equals(b))`.

**Testes devem falhar** no início — os DTOs não têm Equatable.

### Wave 1 — implementer
- Para cada arquivo DTO, adicionar `with Equatable` + `props`
- **Nested DTOs em props** — `List<X>` e `X?` com X Equatable → value equality é transitiva
- `@JsonSerializable` + Equatable coexistem sem conflito
- **Não alterar** fromJson/toJson (são gerados — build_runner)
- Todos os testes novos GREEN + 377 testes anteriores GREEN (não-regressão)
- `dart analyze bff/shared/lib` zero errors

## Regras especiais

### Para DTOs com lista/map em campos
Listas em `props` devem ser as próprias — Equatable usa `iterableEquals` (deep). Exemplo:
```dart
final List<DiagnosisDraftDto> initialDiagnoses;

@override
List<Object?> get props => [personId, initialDiagnoses, /* ... */];
// Funciona pq DiagnosisDraftDto também vira Equatable neste ticket.
```

### Para DTOs com Map (ex: LookupsBatchResponse, AuditEvent payload)
Map é tratado por Equatable como collection — `mapEquals` recursivo. Se o valor for primitivo (String, num), funciona. Se for `Map<String, dynamic>` com payload arbitrário, **não garante** equality profunda — documentar como limitação e aceitar.

### `StandardResponse<T>` genérico
```dart
class StandardResponse<T> with Equatable {
  const StandardResponse({required this.data, required this.meta});
  final T data;
  final ResponseMeta meta;

  @override
  List<Object?> get props => [data, meta];  // T deve ser Equatable para funcionar
}
```

Se `T` não for Equatable, comparação dos dados usa referência — documentar.

## Critérios de aceitação
- [ ] ~72 arquivos com `with Equatable` + `props`
- [ ] 3 arquivos de teste de equality criados
- [ ] Todos os testes novos GREEN
- [ ] 377 testes anteriores (A01-A06b) GREEN (não-regressão)
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `dart run build_runner build` roda sem conflito

## Não faça
- NÃO altere fromJson/toJson (gerados)
- NÃO adicione Equatable em classes de serviço/store/fake (são reference type)
- NÃO mude testes anteriores
- NÃO adicione campos em DTOs (só Equatable)

## Status
ready to dispatch Wave 0
