# ADR-008: Dart AOT para BFF (Produção)

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-002](ADR-002-bff-backend-for-frontend.md), [ADR-007](ADR-007-bff-edge-deployment.md)

## Contexto

BFF roda **server-side**. Em produção, precisamos:

- Startup rápido (Edge cold-start crítico).
- Memória baixa (containers densos).
- Performance previsível (sem JIT warmup).
- Binário standalone (sem SDK runtime no container).

## Decisão

BFF Dart é compilado em **AOT** (`dart compile exe`) para produção. Dev usa JIT (`dart run`) para feedback rápido.

```bash
# Dev (JIT)
dart run bin/server.dart

# Build prod (AOT)
dart compile exe bin/server.dart -o social-care-bff
```

## Consequências

- Container final tem ~15-25 MB (binário + libc), sem precisar do SDK Dart.
- Startup < 100ms tipicamente.
- Performance estável (sem warmup).
- Custo: build AOT é mais lento (~30s vs `dart run` < 1s).

## Status atual (2026-05-12)

- BFF Web e BFF Desktop ambos AOT-compiled em produção.
- CLI (`apps/cli/`) também compilada AOT para distribuição.
- Dockerfile multi-stage builda AOT e copia binário para imagem `distroless`.

## Superseded by

Nenhum.
