# C00 — Bearer Auth Middleware no BFF Web

## Onda: 1 | Profile: middleware | Depende de: nada (gate de entrada da Phase 5)

## Motivação

D3.C γ híbrido — BFF aceita ambos: `__Host-session` cookie (browser) + `Authorization: Bearer <jwt>` (CLI / outros clientes não-browser). Hoje o BFF Web só tem session cookie middleware. CLI precisa de Bearer.

## Escopo

### Criar `bff/social_care_web/lib/src/middleware/bearer_auth_middleware.dart`

Middleware Shelf que:
1. Lê header `Authorization: Bearer <token>` do request.
2. Se ausente, passa adiante (deixa session cookie middleware tentar).
3. Se presente, valida JWT contra JWKS do Zitadel (mesma config do session cookie path).
4. Se válido: popula `request.context['session']` com objeto Session-equivalent (claims extraídas: `sub`, `email`, roles).
5. Se inválido (expirado, signature inválida, audience mismatch): retorna `401 Unauthorized` com `BackendErrorResponse` estruturado.

### Modificar `app_router.dart`

Wire o novo middleware ANTES do session middleware (ordem: bearer → session → auth_guard). Bearer popula context primeiro; se não houver token, session cookie tenta; se nenhum tem token válido, auth_guard rejeita.

### Tests

- Bearer válido → 200 com context populado
- Bearer expirado → 401
- Bearer com signature inválida → 401
- Bearer com audience errada → 401
- Sem Authorization header → middleware passa adiante (session cookie path)
- Authorization header malformado (sem "Bearer ") → 400

### Compatibilidade

- Browser flow (cookie) intocado — testes existentes devem continuar GREEN.
- Bearer flow novo — adiciona ~40 testes específicos.

## Pipeline

W0 (test-writer) → W1 (flutter-bff-implementer) → W2 (flutter-code-reviewer) → W3 (flutter-quality-checker)

## Critérios

- [ ] Middleware criado e wired
- [ ] ~40 testes Bearer GREEN
- [ ] ~1115 testes BFF Web total (1075 atuais + ~40)
- [ ] Cookie path 100% intocado (1075 atuais GREEN)
- [ ] `dart analyze bff/social_care_web/lib/` zero issues

## Status
pending — kickoff target
