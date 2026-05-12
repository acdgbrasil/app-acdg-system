# ADR-010: Models Imutáveis (Schemas Puros)

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)

## Contexto

Models que carregam estado mutável + lógica de negócio criam três problemas:

1. **Concorrência** — mutação compartilhada exige locks ou cuidado manual.
2. **Reatividade quebrada** — `ChangeNotifier` / `ValueNotifier` precisa de identidade nova para disparar rebuild.
3. **Lógica de negócio espalhada** — em vez de no BFF ([ADR-002](ADR-002-bff-backend-for-frontend.md)), fica em todos os models.

## Decisão

**Models são schemas puros:** imutáveis, sem lógica de negócio.

- Todos os campos `final`.
- `copyWith()` para "mutações" (cria nova instância).
- Equatable / Records para igualdade por valor.
- Lógica de negócio **fica no BFF**; cliente apenas serializa / desserializa.

### Estrutura

- **`data/model/`** — modelos de API (`fromJson` / `toJson`). Acoplados ao Contract A.
- **`domain/models/`** — modelos de domínio puros (sem JSON). Imutáveis, sem dependência de framework.

### Anti-padrão

```dart
// ❌ Errado — mutável + lógica de negócio
class Patient {
  String name;
  void rename(String n) { name = n; }  // mutável + regra de negócio
}

// ✅ Certo — imutável + sem lógica
final class Patient with Equatable {
  const Patient({required this.id, required this.name});
  final String id;
  final String name;
  Patient copyWith({String? name}) => Patient(id: id, name: name ?? this.name);
}
```

## Consequências

- Models passam thread boundaries trivialmente (Isolates).
- Reatividade dispara em `copyWith` (identidade nova).
- Lógica de negócio centralizada no BFF — cliente fino.
- Custo: `copyWith` boilerplate (mitigado por `freezed` ou geração).

## Status atual (2026-05-12)

- Aplicado em todos os DTOs / Models de `kernel/contracts/`, `apps/social_care_bff/contracts/`, `apps/social_care_bff/web/`, `apps/social_care_bff/desktop/`.
- Verificado por code review automático ([flutter-expert](../../../../skills_base/flutter-expert/SKILL.md)) — `class Foo { ... }` sem `final class` é rejeitado.

## Superseded by

Nenhum.
