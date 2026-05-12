# ADR-001: Stack Flutter como Plataforma Cliente

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído — corpo original nunca foi materializado em `DECISIONS.md`; ver "Histórico documental").

## Contexto

Necessidade de cliente único capaz de rodar em Desktop nativo (macOS / Windows / Linux), Web e Mobile, evitando duplicação de código entre 3 stacks separadas e mantendo entrega visual consistente para profissionais que cuidam de pacientes com doenças genéticas raras.

## Decisão

Adotar **Flutter 3.x** (Dart 3.x) como stack cliente única do frontend:

- Flutter Desktop nativo (sem webview).
- Flutter Web com renderer **WASM** quando aplicável.
- Flutter Mobile via canais nativos.

Um único codebase, multi-target via build flags + `MediaQuery` / `LayoutBuilder` (ver [ADR-006](ADR-006-adaptive-design-3-pages.md)).

## Consequências

- Equipe única operando o mesmo ecossistema (`flutter`, `dart`, `pub`, `melos`).
- Performance previsível em Desktop (sem webview).
- Web roda em WASM com perfil de performance próximo ao nativo onde suportado.
- Migrações entre plataformas-alvo são incrementais — não exigem reescrita.

## Status atual (2026-05-12)

- BFF Dart-puro (`apps/social_care_bff/`) e CLI Dart-puro (`apps/cli/`, Phase 5) em produção / construção.
- UI Flutter (`apps/social_care_ui/` futura) está **dormente** até Phase 5 CLI estabilizar. Phase 4 (Flutter migration) foi superseded por Phase 5 CLI-first em 2026-05-01.

## Histórico documental

Esta decisão foi consagrada antes de ADR-015 (2026-03-13). Por convenção tácita, ADR-001 a ADR-014 nunca tiveram corpo expandido em `DECISIONS.md` — o conteúdo aqui é reconstituição **mínima** baseada em referências de `frontend/CLAUDE.md`. Em caso de dúvida sobre detalhes históricos, consultar git log + `archive/`.

## Superseded by

Nenhum.
