# ADR-006: Adaptive Design — 3 Pages por Feature

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído — corpo materializado em 2026-05-12 durante reorganização do handbook)

## Contexto

Frontend Flutter ACDG roda em **três contextos distintos** com perfis de uso muito diferentes:

| Contexto | Perfil de uso |
|---|---|
| **Desktop nativo** | Consultório / sala fechada, luz controlada, tempo disponível, teclado, mouse, sessões longas. |
| **Web (WASM)** | Hospital / multitarefa, dual monitor, conexão potencialmente instável. |
| **Mobile** | Visita domiciliar / luz solar / uma mão / conectividade ruim. Frequentemente em situação de carga cognitiva alta. |

Tentar resolver os três contextos com **uma única Page responsiva** ("camaleão") historicamente leva a interfaces que ficam ruins em todas as plataformas — Steve Krug, *Não Me Faça Pensar, Revisitado (3ª ed.)*, p. 184: *"O canto da sereia de um design que serve para todos os tamanhos de tela tem uma longa história de esperanças brilhantes, promessas quebradas e designers e desenvolvedores cansados."*

## Decisão

Cada feature do app tem **três Pages** distintas e uma **ViewModel única** compartilhada:

```text
ui/<feature>/
├── <feature>_view_model.dart        ← ViewModel única (compartilhada)
└── pages/
    ├── <feature>_desktop_page.dart  ← Desktop nativo
    ├── <feature>_web_page.dart      ← Web (WASM)
    └── <feature>_mobile_page.dart   ← Mobile
```

- A **ViewModel** é agnóstica de plataforma — recebe o estado e expõe `Commands`.
- A **Page** é específica de contexto — escolhe widgets e layout adequados (`NavigationRail` no Desktop, `NavigationBar` no Mobile, etc.).
- O Shell decide qual Page renderizar via `LayoutBuilder` + breakpoints Material 3.

### Breakpoints (Material 3)

| Breakpoint | Largura (dp) | Page usada |
|---|---|---|
| Compact | < 600 | Mobile |
| Medium | 600–839 | Mobile ou Web (decisão do designer) |
| Expanded | 840–1199 | Web |
| Large+ | ≥ 1200 | Desktop |

### Regras

1. **Mobile First** ao projetar — definir o conjunto mínimo de recursos primeiro; Desktop e Web adicionam funcionalidades, não removem (Krug, p. 182).
2. **Labels e ordem de navegação consistentes** nas 3 Pages — Tamosauskas (*Arquitetura da Informação e UX*, p. 25) sobre rótulos.
3. **Decisão de qual Page renderizar fica no Shell**, não dentro de cada Page (anti-padrão "Page-camaleão").
4. **Atomic Design** ([ADR-017](ADR-017-atomic-design.md)) aplica em cada Page; átomos e moléculas são compartilhados, organismos podem ser específicos por Page.

## Consequências

- **Custo:** três Pages por feature em vez de uma.
- **Ganho:** cada contexto recebe uma UI desenhada deliberadamente para ele.
- **Manutenção:** ViewModel única evita drift de comportamento entre plataformas.
- **Onboarding:** novo dev sabe exatamente onde mexer para alterar uma plataforma específica.

## Status atual (2026-05-12)

- **Dormente** — UI Flutter foi removida em D1.C delete (commit `33626f0`, 2026-05-01). Phase 4 (Flutter migration) substituída por Phase 5 CLI-first.
- Volta ao escopo em Phase 6+ quando UI Flutter ressuscitar.
- A skill [`flutter-ux-designer`](../../../.claude/skills/flutter-ux-designer/SKILL.md) (criada 2026-05-12) tem módulo [`adaptive-acdg.md`](../../../.claude/skills/flutter-ux-designer/modules/adaptive-acdg.md) operacionalizando esta decisão.

## Partial supersession por ADR-024 (2026-05-12)

[ADR-024](ADR-024-web-app-stack-and-topology.md) retira o **contexto Web** do escopo desta decisão. Quando Phase 6+ começar, **Web não será mais Flutter** — será SPA Vite + React 19 + TS 6 servida pelo BFF Shelf. A regra "3 Pages compartilhando uma ViewModel" passa a valer **apenas** entre Desktop nativo e Mobile (que ainda serão Flutter).

Redefinição prática para Phase 6+:

```text
ui/<feature>/
├── <feature>_view_model.dart        ← ViewModel única (Desktop + Mobile Flutter)
└── pages/
    ├── <feature>_desktop_page.dart  ← Desktop nativo
    └── <feature>_mobile_page.dart   ← Mobile
```

O Web App passa a viver em `apps/conecta_web/` como SPA TS independente, consumindo o mesmo BFF Dart via OpenAPI contract (ADR-025). Personas Web (Acolhimento, Coordenação, Indicadores) e Native (Visitas, Atendimento) são tratadas como **dois produtos distintos** com sitemap próprio, alinhado ao princípio Newman de stream-aligned teams (ver §Contexto de ADR-024).

**Por que apenas parcial e não supersession total:** entre Desktop e Mobile Flutter, a justificativa original de ADR-006 segue válida (3 contextos com perfis muito distintos, ViewModel única evita drift de comportamento). Web foi removido do trio porque a stack mudou — não porque o princípio falhou.

## Mecânica Flutter de referência

- `https://docs.flutter.dev/ui/adaptive-responsive` — distinção responsive vs adaptive.
- `https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery` — APIs `MediaQuery`, `SafeArea`.
- `https://docs.flutter.dev/ui/adaptive-responsive/large-screens` — Desktop / tablet / foldables.
- `https://docs.flutter.dev/ui/adaptive-responsive/best-practices`.

## Relacionado

- [ADR-001](ADR-001-flutter-stack.md) — stack Flutter como base.
- [ADR-003](ADR-003-mvvm-logic-layer.md) — ViewModel única é viável porque MVVM separa estado de view.
- [ADR-017](ADR-017-atomic-design.md) — átomos / moléculas compartilhadas entre as 3 Pages.

## Superseded by

Nenhum.
