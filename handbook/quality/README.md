# Qualidade — frontend (Conecta Raros)

> Estrategia de testes, cobertura, acessibilidade e performance.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Estrategias de Widget tests, Atoms/Cells/Pages e performance Web/Desktop reservadas para Phase 6+ quando UI Flutter ressuscitar. Hoje vale o canon de BFF + CLI.

---

## 1. Estrategia de Testes

### 1.1 Piramide (canon BFF + CLI)

```
         /\
        /  \       Golden tests (CLI Phase 5 — C10)
       /    \      ~50 snapshots, validam comando -> stdout
      /------\
     /        \    Integration / Handler tests (BFF)
    /          \   Validam rota Shelf -> Response completo
   /------------\
  /              \  Unit tests
 /                \ Intents, UseCases, Caches, Remotes, Mappers
/==================\
```

**Sem widget tests** ate UI Flutter (Phase 6+) ressuscitar.

### 1.2 O Que Testar

#### BFF (apps/social_care_bff/*)
| Camada | Tipo de Teste | Cobertura Alvo | Status atual |
|--------|--------------|----------------|--------------|
| **Sub-contracts (DTOs)** | Round-trip + Equatable | 100% | ~535 GREEN |
| **Intents** | parseFromBody/Query/Path | 95%+ | included |
| **UseCases** | Orquestracao com Fakes | 95%+ | included |
| **Handlers** | Shelf integration | 90%+ | included |
| **Caches (Drift)** | CRUD + FTS5 + version | 90%+ | included |
| **Remotes (Dio)** | HTTP edge cases | 85%+ | included |
| **SyncEngine + Outbox** | State machine + retry | 95%+ | included |
| **Use cases Desktop** | 3 patterns canonicos | 95%+ | included |
| **TOTAL** | — | — | **2036 GREEN baseline** |

#### CLI (apps/cli/ — Phase 5)
| Camada | Tipo de Teste | Cobertura Alvo |
|--------|--------------|----------------|
| **Args parsing** | Unit | 100% |
| **Commands** | Unit (BffClient mocked) | 95%+ |
| **Formatters** | Unit + golden | 100% (3 formats x N comandos) |
| **Session/PKCE** | Unit + integration | 95%+ |
| **End-to-end** | Golden snapshots | ~50 fixtures |

### 1.3 Naming Convention

```dart
group('RegisterPatientIntent', () {
  test('parseFromBody returns Success when body matches schema', () { ... });
  test('parseFromBody returns Failure(INVALID_REGISTER_PATIENT_BODY) when cpf missing', () { ... });
  test('parseFromBody returns Failure(INVALID_JSON) when body is malformed', () { ... });
});
```

### 1.4 Fakes vs Mocks

- **Preferir Fakes** (testing/ folder) — tem comportamento real, mais resistentes a refactor
- **Mocks (mocktail)** so quando inevitavel — ex: testar quando algo NAO foi chamado

### 1.5 REGRA #2 — No test cheating
Diante de teste vermelho, verbalizar 4 pontos antes de tocar em qualquer codigo (CLAUDE.md REGRA #2). Anti-patterns proibidos:
- Mover teste para outro caso onde passe
- Trocar `expect(404)` por `expect(anyOf(404, 500))` sem entender por que 500
- Comentar/skipar sem comentario explicito documentando debt
- Adicionar `try/catch` na impl so para fazer teste passar

---

## 2. Cobertura

- **Meta global:** >= 85% de cobertura de linhas
- **BFF Domain (kernel + sub-contracts):** >= 95%
- **BFF Use cases / Handlers:** >= 90%
- **CLI Commands:** >= 90%
- **Enforcement:** CI (apos C10) bloqueia PR abaixo da meta

Hoje (2026-05-01) o BFF baseline e **2036 testes** distribuidos:
- 535 contracts (apps/social_care_bff/contracts/)
- 1075 web (apps/social_care_bff/web/)
- 426 desktop +1 skip (apps/social_care_bff/desktop/)

---

## 3. Pipeline TDD 4-agent

Aplica para todo trabalho nao-trivial em BFF e CLI:

| Wave | Agent | Output |
|------|-------|--------|
| **W0 — RED** | test-writer | Tests falhando descrevendo contrato esperado |
| **W1 — GREEN** | flutter-bff-implementer | Implementacao ate GREEN; nao toca em tests |
| **W2 — REVIEW** | flutter-code-reviewer | Audit read-only contra Non-Negotiable Rules; max 3 rounds |
| **W3 — QUALITY** | flutter-quality-checker | `dart analyze` zero + `dart format` + `dart test` GREEN |

Detalhes: [../process/README.md §3](../process/README.md).

---

## 4. Performance

### BFF metrics (target)
| Metrica | Target |
|---------|--------|
| `apps/social_care_bff/web` p95 latency | < 200ms (excluindo backend) |
| `apps/social_care_bff/desktop` cache read p99 | < 5ms |
| Drift FTS5 search p99 | < 50ms (large datasets) |
| SyncEngine batch drain | < 1s para 10 mutations |

### CLI metrics (target — Phase 5)
| Metrica | Target |
|---------|--------|
| Cold start `acdg --help` | < 100ms |
| `acdg patient list` (50 patients) | < 500ms (BFF + render) |
| Binary size | < 15MB stripped |

### Future UI Flutter metrics (Phase 6+)
Reservado. Quando UI ressuscitar, target Web + Desktop voltam ao escopo.

---

## 5. Acessibilidade

Nao aplicavel para BFF e CLI (sem UI). Reservado para Phase 6+:
- WCAG AA contrast
- Semantics em widgets interativos
- Keyboard navigation
- Screen reader support
- Font scaling

---

## 6. Observabilidade

### BFF (atual)
- **Logs estruturados** no BFF (apps/social_care_bff/*/lib/.../observability/)
- **`ObservabilityContext`** middleware injetado em handlers
- **`obs?.logError(e, st)`** em adapter boundary parses (P2b try/catch)
- **PII-safe error responses** — toString() retorna structural string fixo, nunca concatenam variavel

### CLI (Phase 5 — projetado)
- Logs locais em `~/.config/acdg/logs/<date>.log` (futuro)
- `--verbose` flag para debug output
- Erros nao tratados reportados como exit code 1 + stderr message

---

## 7. Referencia cruzada

- [../process/README.md](../process/README.md) — pipeline TDD 4-agent
- [../principles/README.md](../principles/README.md) — Non-Negotiable Rules
- [../architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md](../architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md)
