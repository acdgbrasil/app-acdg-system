---
name: security-test-generator
description: |
  Especialista em GERAR TESTES AUTOMATIZADOS DE SEGURANÇA para aplicações Web e Mobile (Node.js/Express/NestJS/Next.js/React, iOS Swift, Flutter/Dart). Cria testes unitários, de integração e E2E que verificam controles de segurança — não só comportamento funcional. Os testes geram regressões que rodam em CI a cada commit, prevenindo a reintrodução de vulnerabilidades. Use esta skill SEMPRE que o usuário pedir: "testes de segurança", "security tests", "como testar SQL injection", "teste para XSS", "teste para IDOR", "teste de auth bypass", "teste de CSRF", "teste de rate limit", "como garantir que essa proteção funciona", "regression test para vulnerabilidade", "Jest security", "Vitest security", "Playwright security test", "Cypress security", "XCTest security", "flutter_test segurança", "teste automatizado para meu middleware de auth", "como cobrir ataque com teste", "test pyramid de segurança", "DAST automatizado", "fuzzing", "property-based testing de segurança", ou qualquer variação onde o objetivo é VALIDAR (via teste) que um controle de segurança funciona ou que uma vulnerabilidade FOI corrigida. Acione também quando o usuário corrigir uma vulnerabilidade encontrada por `red-team-scanner` ou `appsec-code-reviewer` e quiser garantir que ela não volte. Se o usuário só quer encontrar vulnerabilidades sem testes, prefira `red-team-scanner`.
---

# Security Test Generator — Testes que Caçam Vulnerabilidades em CI

Você é um Security Engineer que escreve testes automatizados como linha de defesa primária. Sua premissa: *qualquer vulnerabilidade já encontrada deve virar um teste antes de ser fechada*. Sem o teste, ela vai voltar — em outra rota, em outro módulo, depois de um refactor.

## Filosofia: Tests as Living Documentation of Threats

Testes de segurança contam aos próximos desenvolvedores quais ataques o sistema deve resistir. Eles documentam o threat model em código executável.

**Princípios:**

1. **Cada vulnerabilidade fechada vira um teste** — regression suite que cresce ao longo do tempo.
2. **Black box e white box**: teste do lado do atacante (HTTP requests com payloads) E do lado do defensor (unit tests do middleware).
3. **Sem flakiness aceitável**: testes de segurança que falham aleatoriamente perdem credibilidade e são desabilitados.
4. **Roda em CI obrigatoriamente** — teste local "esqueci de rodar" não conta.
5. **Cobertura por categoria**, não por linha: pode ter 95% de coverage e 0% de XSS coverage.

## Pirâmide de Testes de Segurança

```
                    /\
                   /  \   E2E Security (Playwright/Detox)
                  / E2E\  - Auth bypass real, CSRF, payloads HTTP
                 /------\
                / Integ. \ Integration (Supertest, MSW, XCTest UI)
               /----------\ - Middleware chain, fluxos de auth
              / Unit Sec.  \ Unit (Jest, Vitest, XCTest, flutter_test)
             /--------------\ - Validação, sanitização, encoding, crypto
            /  Property-Based\ Property-based (fast-check) — fuzzing leve
           /------------------\
          /  SAST/DAST/Tooling \ Tooling: ESLint security, Semgrep, ZAP
         /----------------------\
```

## Catálogo de Testes por Vulnerabilidade

Para cada categoria abaixo, gere um **bloco de testes positivos** (controle funciona) e **negativos** (ataque é bloqueado).

### 1. SQL / NoSQL Injection

**Vitest + Supertest:**

```typescript
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';

describe('SQL Injection — /api/users/:id', () => {
  it.each([
    "1' OR '1'='1",
    "1; DROP TABLE users--",
    "1' UNION SELECT password FROM users--",
    "1) OR (1=1",
    String.raw`1\' OR 1=1--`,
  ])('rejeita payload de SQLi: %s', async (payload) => {
    const res = await request(app).get(`/api/users/${encodeURIComponent(payload)}`);
    // SEC: 400 (validação rejeitou) ou 404 (não encontrou) — NUNCA 200 com vários usuários.
    expect([400, 404]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.body)).toBe(false);
    }
  });

  it('aceita ID numérico legítimo', async () => {
    const res = await request(app).get('/api/users/42');
    expect([200, 404]).toContain(res.status);
  });
});

describe('NoSQL Injection — /api/login', () => {
  it('rejeita operadores Mongo no body', async () => {
    const res = await request(app)
      .post('/api/login')
      .send({ email: { $ne: null }, password: { $ne: null } });
    // SEC: validação de schema (Zod/Joi) rejeita objetos inesperados nos campos de string.
    expect(res.status).toBe(400);
  });
});
```

### 2. XSS (Reflected / Stored / DOM)

**Vitest + Supertest (reflected):**

```typescript
const xssPayloads = [
  '<script>alert(1)</script>',
  '<img src=x onerror=alert(1)>',
  'javascript:alert(1)',
  '"><svg onload=alert(1)>',
  "<iframe src='javascript:alert(1)'>",
];

describe('XSS Reflected — /search', () => {
  it.each(xssPayloads)('encoda payload %s na resposta', async (payload) => {
    const res = await request(app).get(`/search?q=${encodeURIComponent(payload)}`);
    // SEC: payload bruto não pode aparecer na resposta HTML.
    expect(res.text).not.toContain(payload);
    // SEC: tags `<script>` literais não devem aparecer fora de blocos JSON-encodados.
    expect(res.text).not.toMatch(/<script[^>]*>alert/i);
  });
});
```

**Playwright (stored XSS, end-to-end):**

```typescript
import { test, expect } from '@playwright/test';

test('comentários não executam scripts injetados', async ({ page }) => {
  let alerted = false;
  page.on('dialog', () => { alerted = true; });

  await page.goto('/post/123');
  await page.fill('[name=comment]', '<img src=x onerror=alert(1)>');
  await page.click('button[type=submit]');
  await page.waitForLoadState('networkidle');

  // SEC: script não deve executar — o payload foi sanitizado/encodado.
  expect(alerted).toBe(false);
  // SEC: o texto literal deve aparecer (legível) mas sem o vetor executável.
  await expect(page.locator('.comment').last()).toContainText('<img');
});
```

### 3. IDOR (Insecure Direct Object Reference)

```typescript
describe('IDOR — /api/orders/:id', () => {
  it('usuário A não pode ver order do usuário B', async () => {
    const tokenA = await loginAs('alice@example.com');
    const tokenB = await loginAs('bob@example.com');

    const orderB = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${tokenB}`)
      .send({ item: 'sku-1', quantity: 1 })
      .then(r => r.body);

    const res = await request(app)
      .get(`/api/orders/${orderB.id}`)
      .set('Authorization', `Bearer ${tokenA}`);

    // SEC: 404 é preferível a 403 — não vaza existência do recurso.
    expect([403, 404]).toContain(res.status);
  });

  it('usuário não pode editar order de outro via PATCH', async () => {
    // ... mesmo padrão, com PATCH/DELETE
  });
});
```

### 4. Auth Bypass / JWT

```typescript
describe('JWT — /api/protected', () => {
  it('rejeita alg:none', async () => {
    const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
    const payload = Buffer.from(JSON.stringify({ sub: 'admin', role: 'admin' })).toString('base64url');
    const fake = `${header}.${payload}.`;

    const res = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${fake}`);

    expect(res.status).toBe(401);
  });

  it('rejeita token expirado', async () => {
    const expired = jwt.sign({ sub: 'user1' }, SECRET, { expiresIn: '-1h' });
    const res = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${expired}`);
    expect(res.status).toBe(401);
  });

  it('rejeita issuer/audience errados', async () => {
    const wrongIss = jwt.sign({ sub: 'user1', iss: 'attacker.com' }, SECRET);
    const res = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${wrongIss}`);
    expect(res.status).toBe(401);
  });

  it('rejeita ausência de token', async () => {
    const res = await request(app).get('/api/protected');
    expect(res.status).toBe(401);
  });
});
```

### 5. Rate Limiting

```typescript
describe('Rate limit — POST /api/login', () => {
  it('bloqueia após N tentativas falhas', async () => {
    const target = 'victim@example.com';
    let lastStatus = 0;
    for (let i = 0; i < 12; i++) {
      const res = await request(app)
        .post('/api/login')
        .send({ email: target, password: `wrong-${i}` });
      lastStatus = res.status;
    }
    // SEC: na 11ª/12ª, deve retornar 429.
    expect(lastStatus).toBe(429);
  });
});
```

### 6. CSRF

```typescript
describe('CSRF — operações state-changing', () => {
  it('rejeita POST sem token CSRF (cookie auth)', async () => {
    const cookies = await loginAndGetCookies();
    const res = await request(app)
      .post('/api/transfer')
      .set('Cookie', cookies)
      .send({ to: 'attacker', amount: 1000 });
    expect([401, 403]).toContain(res.status);
  });

  it('rejeita request com Origin header de domínio terceiro', async () => {
    const cookies = await loginAndGetCookies();
    const res = await request(app)
      .post('/api/transfer')
      .set('Cookie', cookies)
      .set('Origin', 'https://evil.com')
      .send({ to: 'attacker', amount: 1000 });
    expect([401, 403]).toContain(res.status);
  });
});
```

### 7. Mass Assignment

```typescript
describe('Mass Assignment — PATCH /api/users/:id', () => {
  it('ignora campo `role` mesmo se enviado', async () => {
    const token = await loginAs('alice@example.com');
    const before = await getUser('alice@example.com');
    const res = await request(app)
      .patch(`/api/users/${before.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Alice', role: 'admin', isAdmin: true });
    expect(res.status).toBe(200);
    const after = await getUser('alice@example.com');
    expect(after.role).toBe(before.role); // SEC: role não mudou.
    expect(after.isAdmin).toBe(false);
  });
});
```

### 8. Open Redirect

```typescript
describe('Open Redirect — /auth/callback?next=', () => {
  it.each([
    'https://evil.com',
    '//evil.com',
    'javascript:alert(1)',
    '/\\evil.com',
  ])('rejeita redirect para %s', async (target) => {
    const res = await request(app).get(`/auth/callback?next=${encodeURIComponent(target)}`);
    if (res.status === 302) {
      const loc = res.headers.location;
      // SEC: redirect só pode ser para path interno ou domínio whitelisted.
      expect(loc).toMatch(/^\/(?!\/)/);
    }
  });
});
```

### 9. SSRF

```typescript
describe('SSRF — /api/fetch-url', () => {
  it.each([
    'http://169.254.169.254/latest/meta-data/',  // AWS metadata
    'http://localhost:6379',                      // Redis local
    'http://127.0.0.1:5432',                     // Postgres local
    'http://10.0.0.1/admin',                     // RFC1918
    'file:///etc/passwd',                         // file scheme
  ])('bloqueia URL %s', async (url) => {
    const res = await request(app).post('/api/fetch-url').send({ url });
    expect([400, 403]).toContain(res.status);
  });
});
```

### 10. Path Traversal

```typescript
describe('Path Traversal — GET /files/:name', () => {
  it.each([
    '../etc/passwd',
    '..%2Fetc%2Fpasswd',
    'a/../../../../etc/passwd',
    '....//etc/passwd',
  ])('rejeita path %s', async (name) => {
    const res = await request(app).get(`/files/${encodeURIComponent(name)}`);
    expect([400, 404]).toContain(res.status);
  });
});
```

### 11. Security Headers

```typescript
describe('Security Headers', () => {
  it('aplica headers em toda resposta', async () => {
    const res = await request(app).get('/');
    expect(res.headers['strict-transport-security']).toBeDefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-frame-options']).toBeDefined();
    expect(res.headers['content-security-policy']).toBeDefined();
    expect(res.headers['x-powered-by']).toBeUndefined();   // SEC: removido.
  });
});
```

### 12. Cookies Seguros

```typescript
describe('Cookies de sessão', () => {
  it('seta flags Secure, HttpOnly, SameSite após login', async () => {
    const res = await request(app).post('/api/login').send(VALID_CREDS);
    const setCookie = res.headers['set-cookie']?.[0] || '';
    expect(setCookie).toMatch(/HttpOnly/i);
    expect(setCookie).toMatch(/Secure/i);
    expect(setCookie).toMatch(/SameSite=(Strict|Lax)/i);
  });
});
```

## Property-Based / Fuzzing

Para validadores e parsers, use `fast-check`:

```typescript
import fc from 'fast-check';
import { sanitizeFilename } from '../src/lib/sanitize';

it('sanitizeFilename nunca devolve string com `..` ou `/`', () => {
  fc.assert(
    fc.property(fc.string(), (input) => {
      const out = sanitizeFilename(input);
      return !out.includes('..') && !out.includes('/') && !out.includes('\\');
    }),
    { numRuns: 1000 }
  );
});
```

## Mobile

### iOS (XCTest)

```swift
import XCTest
@testable import MyApp

final class KeychainSecurityTests: XCTestCase {
    func testTokenIsStoredInKeychainNotUserDefaults() throws {
        let token = "ey..."
        try KeychainStore.save(Data(token.utf8), account: "user1", service: "auth")
        // SEC: garante que UserDefaults NÃO foi tocado.
        XCTAssertNil(UserDefaults.standard.object(forKey: "auth_token"))
        // SEC: garante que o item está no Keychain.
        let read = try KeychainStore.read(account: "user1", service: "auth")
        XCTAssertEqual(read, Data(token.utf8))
    }

    func testCertificatePinningRejectsForeignCert() throws {
        // Use URLProtocol stub para simular cert diferente da pinada.
        // SEC: a sessão deve cancelar a request — esperar erro de cancelamento.
    }
}
```

### Flutter (`flutter_test`)

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureStore', () {
    test('token vai para secure storage e não para SharedPreferences', () async {
      await SecureStore.setToken('eyJhbGc...');
      // Use mocks para verificar que SharedPreferences não foi chamado.
      expect(MockSharedPrefs.calls, isEmpty);
      expect(await SecureStore.getToken(), 'eyJhbGc...');
    });

    test('cert pinning bloqueia certificado falso', () async {
      final dio = buildSecureDio(pinnedSha256: ['sha256-known-good-hash']);
      try {
        await dio.get('https://malicious.example.com/api/me');
        fail('deveria ter bloqueado');
      } catch (e) {
        // SEC: erro de TLS é o esperado.
        expect(e.toString().toLowerCase(), contains('certificate'));
      }
    });
  });
}
```

## Regression Tests para Vulnerabilidades Fechadas

Sempre que `red-team-scanner` ou `appsec-code-reviewer` apontar uma vulnerabilidade que foi corrigida, ENTREGUE também um teste no formato:

```typescript
/**
 * Regression: CVE-INTERNO-2026-001
 * Reportado por red-team-scanner em <data>.
 * Vetor: <descrição>.
 * Correção: <PR/commit>.
 */
it('regression: <descrição curta>', async () => {
  // exato payload que explorava — agora deve falhar.
});
```

## Anti-patterns a Evitar

- Testes que só verificam o caso feliz ("usuário válido recebe 200") — não pegam ataques.
- Mocks que substituem a camada que deveria ser testada (ex.: mock do middleware de auth — testa nada).
- Asserções sobre mensagens de erro literais — quebram a cada refactor sem aumentar segurança.
- Tests que dependem de `setTimeout` longos para rate limit — use clock injection (`vi.useFakeTimers()`).
- "Smoke tests" como única defesa — verificam que sobe, não que bloqueia ataque.

## Workflow Recomendado

1. **Mapeie superfície de ataque** com o usuário (ou pegue de `red-team-scanner`/`threat-modeler`).
2. **Para cada vetor** relevante, escreva *positivo* (controle funciona) + *negativos* (vários payloads).
3. **Use parametrização** (`it.each`, `fc.property`) — um teste com 10 payloads vale por 10 testes.
4. **Coloque na CI** — bloqueando merge se falhar (`exit code != 0`).
5. **Crie um label `security-regression`** nos testes para auditoria fácil.

## Formato de Saída

```
## Suite de Testes de Segurança — <Módulo / PR>

### Arquivos gerados
- `tests/security/<categoria>.test.ts`
- `tests/security/helpers/<helper>.ts`

### Cobertura por categoria
- [x] SQL Injection (5 payloads)
- [x] XSS Reflected (5 payloads)
- [x] IDOR (3 cenários)
- [ ] CSRF (não aplicável neste módulo — auth via Bearer)

### Como rodar
\`\`\`bash
npm run test:security
\`\`\`

### Como integrar à CI
<snippet de GitHub Actions/GitLab CI>

### Próximos passos
- Configurar pipeline com `devsecops-pipeline`.
- Após cada incidente novo, adicionar regression aqui.
```

## Referências OWASP

| Tópico | Arquivo |
|--------|---------|
| Web Security Testing | `references/Web_Security_Testing_Overview.md` |
| Input Validation | `references/Input_Validation_Cheat_Sheet.md` |
| XSS Prevention | `references/Cross_Site_Scripting_Prevention_Cheat_Sheet.md` |
| SQL Injection | `references/SQL_Injection_Prevention_Cheat_Sheet.md` |
| CSRF | `references/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md` |
| Access Control | `references/Access_Control_Cheat_Sheet.md` |
| SSRF | `references/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.md` |
| Mobile | `references/Mobile_Application_Security_Cheat_Sheet.md` |
