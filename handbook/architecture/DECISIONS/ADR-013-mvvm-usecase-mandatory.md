# ADR-013: MVVM Estrito + UseCase Obrigatório + Pastas Padronizadas

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-003](ADR-003-mvvm-logic-layer.md) (estabelece padrão), [ADR-016](ADR-016-usecase-orchestration.md) (UseCase mandatório no nível de feature)

## Contexto

ADR-003 estabeleceu MVVM + Logic Layer mas deixou aberto:

- Quando UseCase é opcional vs obrigatório?
- Como organizar pastas dentro de um micro-app?
- Como compartilhar fakes / fixtures entre testes?
- Como separar modelos de API de modelos de domínio?

## Decisão

### 1. UseCase obrigatório em **todas** as features

Sem exceção. Mesmo features com 1 chamada de Repository têm um UseCase. Isso impede ViewModel de acumular orquestração.

### 2. Estrutura padronizada de pastas

**UI por feature, Data por tipo, Domain compartilhado.**

```
<micro-app>/
├── ui/
│   └── <feature>/
│       ├── pages/                    ← Pages (ADR-006: 3 Pages)
│       ├── widgets/                  ← Atomic Design (ADR-017)
│       ├── <feature>_view_model.dart
│       └── use_cases/
├── data/
│   ├── repositories/                 ← Compartilhadas entre features
│   ├── services/                     ← Compartilhados entre features
│   └── model/                        ← Modelos de API (fromJson/toJson)
├── domain/
│   └── models/                       ← Modelos de domínio puros
└── testing/                          ← Fakes e fixtures compartilhados
```

### 3. Modelos: API ≠ Domínio

- **`data/model/`** — DTOs / API models com `fromJson` / `toJson`. Acoplados ao Contract A.
- **`domain/models/`** — Modelos de domínio puros, sem JSON. Imutáveis ([ADR-010](ADR-010-immutable-models.md)).

Mappers fazem `ApiModel → DomainModel` no Repository, mantendo a UI desacoplada do schema da API.

### 4. Testes: **Fakes** em `testing/`, nunca mocks mágicos

- `testing/` é shared library importável por testes de qualquer feature.
- Cada Repository abstrato tem um `Fake<X>Repository` em `testing/`.
- **Sem mockito / sem mocks gerados por code-gen** — Fakes são código real, legível.

## Consequências

- Onboarding rápido — toda feature tem mesma forma.
- Refactor de Service / Repository não toca ViewModel (orquestração isolada no UseCase).
- Testes simples e robustos com Fakes.
- Custo: boilerplate adicional para features triviais.

## Status atual (2026-05-12)

- **Dormente** (UI Flutter removida em D1.C). Volta em Phase 6+.
- BFF Dart (`apps/social_care_bff/`) aplica versão adaptada (sem ViewModel: Handler → Intent → UseCase → Repository → Service).
- CLI (`apps/cli/`) aplica versão adaptada (sem ViewModel: Command → UseCase → Repository → Service).

## Superseded by

Nenhum.
