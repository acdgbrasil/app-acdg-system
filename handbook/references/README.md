# Referencias — frontend (Conecta Raros)

Material de apoio, links externos e **snapshots locais** de documentação relevante.

---

## Snapshots locais (offline-ready, LLM-ingestible)

Pastas com cópia integral da doc oficial das libs adotadas pelo monorepo. Útil para: onboarding offline, contexto para AI assistants, garantia de versão (snapshot congelado evita drift silencioso quando upstream lança nova versão).

| Pasta | Lib | Arquivos | Tamanho | Versão capturada |
|---|---|---|---|---|
| [`react/`](react/README.md) | React 19 (core, DOM, RSC, Compiler, ESLint plugin) | 177 `.md` | 3.2 MB | 2026-05-12 (react.dev/llms.txt) |
| [`tanstack/`](tanstack/README.md) | TanStack Router + Query + Table (variant React) | 1023 `.md` | 5.4 MB | 2026-05-12 (GitHub `main`) |
| [`zod/`](zod/README.md) | Zod 4 (TypeScript validation) | 1 `.md` único + índice | 280 KB | 2026-05-12 (zod.dev/llms-full.txt) |

Cada README na pasta tem o script de re-pull para atualizar quando upstream lançar nova versão.

## Arquitetura

- [Flutter Architecture Guide (Google)](https://docs.flutter.dev/app-architecture)
- [MVVM in Flutter](https://docs.flutter.dev/app-architecture/guide)
- [Atomic Design by Brad Frost](https://bradfrost.com/blog/post/atomic-web-design/)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Building Microservices (Sam Newman)](https://www.oreilly.com/library/view/building-microservices-2nd/9781492034018/) — BFF pattern canônico, citado em ADR-024.

## Flutter (Native — Desktop + Mobile, Phase 6+)

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/language)
- [Flutter Desktop](https://docs.flutter.dev/platform-integration/desktop)

## Web App stack (Phase 6+, ADR-024)

- [React 19](https://react.dev/) — snapshot local em [`react/`](react/)
- [TanStack (Router/Query/Table)](https://tanstack.com/) — snapshot local em [`tanstack/`](tanstack/)
- [Zod](https://zod.dev/) — snapshot local em [`zod/`](zod/)
- [Vite](https://vitejs.dev/) — bundler (sem llms.txt oficial em 2026-05)
- [Bun](https://bun.com/) — runtime de build (apenas CI)
- [TypeScript](https://www.typescriptlang.org/) — versão 6.x
- [React Hook Form](https://react-hook-form.com/) — forms; integra com Zod
- [oidc-client-ts](https://github.com/authts/oidc-client-ts) — OIDC PKCE flow no browser

## Packages Dart (BFF + Native)

- [Provider](https://pub.dev/packages/provider) — DI no app Native (ADR-009)
- [GoRouter](https://pub.dev/packages/go_router) — roteamento Native
- [Dio](https://pub.dev/packages/dio) — HTTP client
- [Drift](https://pub.dev/packages/drift) — offline storage (ADR-021, supersede ADR-005 Isar)
- [Shelf + shelf_router](https://pub.dev/packages/shelf) — HTTP server do BFF (ADR-002)
- [Melos](https://melos.invertase.dev/) — monorepo manager

## Autenticacao

- [Zitadel Documentation](https://zitadel.com/docs)
- [OIDC PKCE Flow (RFC 7636)](https://oauth.net/2/pkce/)
- [Split-Token Pattern](../architecture/DECISIONS/ADR-011-split-token-pattern.md) — ADR-011

## Design Patterns

- [Design Patterns: Elements of Reusable Object-Oriented Software (GoF)](https://en.wikipedia.org/wiki/Design_Patterns)
- [Dart Design Patterns](https://dart.dev/language/patterns)

## Segurança (Web App — ADR-026)

- [OWASP ASVS 4.0](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Top 10](https://owasp.org/Top10/)
- [MDN — CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [Mozilla Observatory](https://observatory.mozilla.org/)
- [securityheaders.com](https://securityheaders.com/)

## ACDG

- [Figma Conecta Raros](https://www.figma.com/design/O6mlUfok8SciPsnVhqtt5z/Conecta---raros--%3E-Passando-para-Atomic-Desing)
- [ACDG Profile](https://github.com/acdgbrasil)
