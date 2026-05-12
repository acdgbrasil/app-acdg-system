# ADR-026 — Web App Security Hardening (defense in depth para `apps/conecta_web/`)

**Status:** Accepted
**Date:** 2026-05-12
**Deciders:** Phase 6+ Frontend Revival, AppSec
**Supersedes:** None
**Related:** ADR-011 (Split-Token), ADR-012 (OIDC PKCE), ADR-023 (Bearer forwarding), ADR-024 (Web App Stack), ADR-025 (API Contract)

---

## Contexto

ADR-024 estabelece **β topology** (Web servido pelo BFF Shelf no mesmo container, Caddy como edge reverse proxy). O atacante teórico tem dois caminhos:

1. **Comprometer o navegador do usuário interno** — extensão maliciosa, phishing, XSS, supply chain de uma dependência npm transitiva.
2. **Comprometer o canal ou o BFF** — TLS quebrado, header injection, RCE no Shelf, vulnerabilidade em `shelf_static`.

Adicionalmente, há **três restrições de domínio** que elevam a barra:

- **LGPD + dados de saúde:** CPF, NIS, RG, diagnóstico CID, prontuário social. Tratamento sujeito ao art. 11 da LGPD (dados sensíveis).
- **Persona vulnerável:** cuidador social pode usar tecnologia assistiva (leitor de tela, lupa). Comprometimento de UX por hardening over-engineering = problema de acessibilidade.
- **App interno autenticado:** sem usuário público anônimo. Mas "interno" não significa "confiável" — extensões de navegador corporativo, dispositivos pessoais (BYOD) e supply chain de IDE compartilhada são vetores reais.

Este ADR consolida **TODOS** os controles de segurança aplicáveis ao Web App, organizados por dimensão, com implementação concreta + mecânica de auditoria.

### Escopo

Cobre:
- `apps/conecta_web/` (Web App TS/React).
- Camada Shelf `apps/social_care_bff/web/` no que serve assets ou exporta surface ao Web.
- Edge Caddy no que tange headers e TLS.
- Pipeline de build (Bun) e supply chain (npm).

NÃO cobre (têm ADRs próprios):
- OIDC flow → ADR-012.
- Split-Token → ADR-011.
- Bearer forwarding outbound BFF → ADR-023.
- Backend Swift/Vapor → fora de escopo deste repo.

---

## Decisão

Aplicar **10 dimensões de hardening**. Cada dimensão tem: (a) controle, (b) implementação concreta, (c) mecânica de auditoria.

### Dimensão 1 — Transport Security (TLS + HSTS)

| Item | Decisão |
|---|---|
| TLS | TLS 1.3 obrigatório, TLS 1.2 aceito como fallback compatível, TLS ≤1.1 bloqueado |
| Cifras | Apenas suites AEAD (AES-GCM, ChaCha20-Poly1305). Sem CBC. Sem RC4. |
| HSTS | `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` |
| HSTS preload | Submeter `conecta.acdgbrasil.com.br` ao HSTS preload list após 1 mês de produção estável |
| Certificate management | Caddy auto-TLS via ACME (Let's Encrypt). Cert renew automático. |
| Redirect HTTP→HTTPS | 308 Permanent Redirect no Caddy edge |
| Mixed content | CSP `block-all-mixed-content` (legado) + `upgrade-insecure-requests` |

**Implementação:** todos no `Caddyfile.prod`. Snippet:

```caddy
conecta.acdgbrasil.com.br {
    header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    header X-Content-Type-Options "nosniff"
    # (demais headers detalhados nas próximas dimensões)
    encode zstd gzip
    reverse_proxy bff:8081
}
```

**Auditoria:** SSL Labs scan trimestral. Mínimo aceito: A+. Automatizar via `ssllabs-scan` no CI mensal.

---

### Dimensão 2 — Content Security Policy (CSP)

| Item | Decisão |
|---|---|
| Política base | `default-src 'self'` |
| Scripts | `script-src 'self' 'nonce-{random}' 'strict-dynamic'` — sem `unsafe-inline`, sem `unsafe-eval` |
| Styles | `style-src 'self' 'nonce-{random}'` — CSS Modules emitem CSS estático, sem inline |
| Imagens | `img-src 'self' data: blob:` — `data:` apenas para placeholders/icons inlinados pelo Vite |
| Fonts | `font-src 'self'` |
| Connect | `connect-src 'self'` — fetch apenas para mesma origem (BFF mesmo container) |
| Frame | `frame-ancestors 'none'` — equivalente a X-Frame-Options DENY |
| Form | `form-action 'self'` |
| Base | `base-uri 'none'` |
| Object | `object-src 'none'` |
| Reporting | `report-uri /csp-report` (BFF endpoint que loga sem persistir PII) |

**Nonce dinâmico por request:** Shelf middleware gera `crypto.getRandomValues(16 bytes)` por request e injeta no header CSP + no HTML do `index.html` antes de servir. Vite produz scripts/styles com placeholders de nonce que o BFF substitui em runtime.

**Implementação no BFF (Shelf):**

```dart
// apps/social_care_bff/web/lib/src/middleware/csp_middleware.dart (FUTURE)
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';

Middleware cspMiddleware() => (innerHandler) => (request) async {
  final nonce = base64Url.encode(_secureRandom(16));
  final updatedRequest = request.change(context: {
    ...request.context,
    'cspNonce': nonce,
  });
  final response = await innerHandler(updatedRequest);
  return response.change(headers: {
    ...response.headers,
    'Content-Security-Policy':
        "default-src 'self'; "
        "script-src 'self' 'nonce-$nonce' 'strict-dynamic'; "
        "style-src 'self' 'nonce-$nonce'; "
        "img-src 'self' data: blob:; "
        "font-src 'self'; "
        "connect-src 'self'; "
        "frame-ancestors 'none'; "
        "form-action 'self'; "
        "base-uri 'none'; "
        "object-src 'none'; "
        "report-uri /csp-report",
  });
};

List<int> _secureRandom(int bytes) {
  final rng = Random.secure();
  return List<int>.generate(bytes, (_) => rng.nextInt(256));
}
```

**Auditoria:**
- CSP report endpoint (`POST /csp-report`) loga violações em sistema de observabilidade. Spike de violations = code change que vazou `unsafe-inline` ou XSS ativo.
- Mozilla Observatory scan trimestral. Mínimo aceito: A+.
- Test E2E: tenta injetar `<script>alert(1)</script>` em campo livre — espera CSP block + log de violation.

**Não-objetivo desta fase:** Trusted Types API. Adoção custosa, ROI marginal sem XSS já mitigado por CSP strict. Considerar em iteração futura se XSS aparecer em CSP reports.

---

### Dimensão 3 — Cross-Origin Isolation (COEP/COOP/CORP)

| Item | Decisão |
|---|---|
| COEP | `Cross-Origin-Embedder-Policy: require-corp` — só carrega recursos com CORP explícito |
| COOP | `Cross-Origin-Opener-Policy: same-origin` — isola navegação cross-origin |
| CORP | `Cross-Origin-Resource-Policy: same-origin` — todos os recursos servidos pelo BFF |

**Por que:** isolamento de processo no Chromium (Site Isolation) + bloqueio de Spectre-class attacks que dependem de cross-origin sharing de memória.

**Custo:** se um dia o Web precisar embedar widget de terceiro (e.g., mapa, gráfico via iframe), COEP `require-corp` quebra. Para app interno sem terceiros externos, não há custo real.

**Implementação:** edge Caddy (`Caddyfile.prod`).

---

### Dimensão 4 — Static Asset Serving (shelf_static hardening)

| Item | Decisão |
|---|---|
| Directory raiz | `/app/static/` (path absoluto dentro do container, hard-coded) |
| `serveFilesOutsidePath` | `false` (default) — proibir |
| `defaultDocument` | `index.html` apenas para rotas que NÃO contenham `.` |
| MIME type | Derivado do `mime` package + override para `.wasm`, `.mjs`, `.js` (caso aplicável futuro) |
| Symlink following | Desabilitado |
| Path traversal | Validação dupla: shelf_static default + middleware de pre-validation que rejeita `..`, `%2e%2e`, null bytes |
| Cache headers | Assets com hash no nome (Vite emite `app.[hash].js`): `Cache-Control: public, max-age=31536000, immutable`. `index.html`, manifest: `Cache-Control: no-store, must-revalidate` |
| Hidden files | Bloquear `.env`, `.git`, `.DS_Store`, qualquer arquivo iniciado com `.` |

**Implementação no AppRouter:**

```dart
// apps/social_care_bff/web/lib/src/server/app_router.dart (TRECHO FUTURE)
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_router/shelf_router.dart';

final staticHandler = createStaticHandler(
  '/app/static',
  defaultDocument: 'index.html',
  serveFilesOutsidePath: false,
);

// Hardening adicional antes do shelf_static
Handler hardenedStatic(Handler base) => (request) async {
  final path = request.url.path;
  if (path.contains('..') ||
      path.contains('%2e%2e') ||
      path.contains('\x00') ||
      path.split('/').any((segment) => segment.startsWith('.'))) {
    return Response.notFound('Not Found');
  }
  return base(request);
};

router
  ..mount('/api/', _apiRouter.call)
  ..get('/csp-report', _cspReportHandler)
  ..get('/<ignored|.*>', hardenedStatic(_spaFallback(staticHandler)));

// SPA fallback: rotas client-side não-API + sem extensão → index.html
Handler _spaFallback(Handler staticHandler) => (request) async {
  final path = request.url.path;
  // Se tem extensão (.js, .css, .png, ...), tenta servir; se 404, deixa 404.
  // Se NÃO tem extensão, é rota SPA → serve index.html.
  if (!path.contains('.')) {
    return staticHandler(request.change(path: 'index.html'));
  }
  return staticHandler(request);
};
```

**Auditoria:**
- Test unitário: 20+ payloads de path traversal (`../etc/passwd`, `..%2fetc%2fpasswd`, `..;/etc/passwd`, etc) — todos esperam 404.
- Test E2E: `GET /.env`, `GET /.git/config`, `GET /package.json` → 404.
- CI lint: garantir `serveFilesOutsidePath: false` em todo uso de `createStaticHandler`.

---

### Dimensão 5 — Security Headers Completos

| Header | Valor | Onde aplicado |
|---|---|---|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Caddy edge |
| `Content-Security-Policy` | (Dimensão 2) | BFF middleware (precisa nonce dinâmico) |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Caddy edge |
| `Cross-Origin-Opener-Policy` | `same-origin` | Caddy edge |
| `Cross-Origin-Resource-Policy` | `same-origin` | Caddy edge |
| `X-Frame-Options` | `DENY` (redundante com CSP frame-ancestors, mantido para browsers legados) | Caddy edge |
| `X-Content-Type-Options` | `nosniff` | Caddy edge |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Caddy edge |
| `Permissions-Policy` | `accelerometer=(), camera=(), microphone=(), geolocation=(), payment=(), usb=(), bluetooth=(), serial=(), magnetometer=(), gyroscope=(), interest-cohort=()` | Caddy edge |
| `Cache-Control` | (Dimensão 4) | BFF + Caddy combinado |
| `Server` | Suprimir | Caddy edge (`header -Server`) |
| `X-Powered-By` | Não emitir | Shelf default não emite — verificar |

**Auditoria:**
- Mozilla Observatory + securityheaders.com (Scott Helme) — score A+ em todos.
- Test E2E em cada deploy: `curl -I https://conecta.acdgbrasil.com.br | grep -i 'security|x-|cross-'` confere presença e valores.

---

### Dimensão 6 — Authentication & Session

Já coberto em ADRs prévios; aqui consolido como **constraints aplicáveis ao Web App**:

| Item | Decisão | ADR origem |
|---|---|---|
| OIDC flow | PKCE (S256), code flow | ADR-012 |
| Access token storage | Memória JS (`useAuth` context) | ADR-011 |
| Refresh token storage | Cookie `__Host-session` (HttpOnly, Secure, SameSite=Strict, Path=/) | ADR-011 |
| Bearer forwarding inbound (Web → BFF) | `Authorization: Bearer ${accessToken}` em todo fetch | ADR-011 |
| Bearer forwarding outbound (BFF → backend) | tokenProvider closure (re-lê a cada request) | ADR-023 |
| Refresh trigger | 401 → `POST /auth/refresh` → retry once | ADR-011 |
| Session TTL | Refresh: 30 dias; Access: 15 min | ADR-012 |
| Logout | DELETE cookie + revoke no Zitadel + clear in-memory state | ADR-012 |
| Idle timeout | Access token expira → próxima request força refresh; se refresh falhar → logout | ADR-011 |
| Concurrent session limit | Não enforced no Phase 6. Avaliar em Phase 7+ se aparecer caso de uso. | — |
| Step-up auth (re-auth para ações sensíveis) | Não Phase 6. Avaliar para ações destrutivas (delete paciente, alterar role admin). | — |

**Reforços específicos do Web:**

- **`localStorage`, `sessionStorage` PROIBIDOS para tokens.** Lint CI: `eslint-plugin-no-restricted-syntax` bloqueia `localStorage`, `sessionStorage` em arquivos que tocam auth.
- **Token nunca em URL.** Lint CI: `Authorization` ou `Bearer` em template literal de URL → fail.
- **Token nunca em log.** ESLint rule custom: `console.log(token)`, `console.log(...accessToken...)` → fail. Em Sentry: scrubber configurado para mascarar `Authorization`, `Cookie`, `set-cookie`.
- **Sentry hardening:** se Sentry ativado, beforeSend scrubber redacta: `Authorization`, `Cookie`, `set-cookie`, `cpf`, `nis`, `rg`, `email` (PII).

---

### Dimensão 7 — Authorization (RBAC)

| Item | Decisão |
|---|---|
| Roles | `social_worker` (CRUD), `owner` (read-only), `admin` (read + gestão) — herdado de Zitadel |
| Source of truth | Zitadel claims no JWT |
| Web enforcement | Apenas UX (esconder botões para quem não tem role) |
| Authoritative enforcement | **BFF** (R2 de ADR-024) — cada handler valida role |
| Defense in depth | BFF retorna 403 a Web mesmo se UI permitiu clique (botão escondido pode ser burlado) |

**Implementação Web:**

```tsx
// apps/conecta_web/src/auth/RoleGuard.tsx (FUTURE)
import { useAuth } from './useAuth';

type Role = 'social_worker' | 'owner' | 'admin';

export function RoleGuard({ roles, children, fallback = null }: {
  roles: ReadonlyArray<Role>;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}) {
  const { user } = useAuth();
  const userRoles = user?.roles ?? [];
  const hasRole = roles.some(r => userRoles.includes(r));
  return hasRole ? <>{children}</> : <>{fallback}</>;
}
```

**Auditoria:** test E2E para cada role: navegar como `owner`, tentar `POST /api/patients` → 403.

---

### Dimensão 8 — CSRF & Origin Validation

| Item | Decisão |
|---|---|
| Modelo principal | **Origin/Sec-Fetch-Site validation** (não token CSRF) |
| Sec-Fetch-Site | Mutações (`POST/PUT/DELETE/PATCH`) em `/api/*` exigem `Sec-Fetch-Site: same-origin` |
| Sec-Fetch-Mode | Exigir `cors` ou `same-origin` |
| Origin header | Validação obrigatória: presente + bate com host |
| SameSite cookie | `Strict` (cobre 95%+ dos browsers) |
| Custom header | `X-Requested-With: XMLHttpRequest` exigido em mutações (camada extra; não pode ser setado cross-origin sem CORS preflight) |
| CSRF token | Não Phase 6. Defense in depth via Origin + SameSite é suficiente para o threat model atual. Reavaliar se app virar público. |

**Por que não token CSRF:**
- Modelo Origin + Sec-Fetch-Site é o moderno (suportado em 95%+ dos navegadores em 2026).
- SameSite=Strict bloqueia request cross-site com cookie.
- Token CSRF adiciona complexidade (rotação, sincronização Web↔BFF) sem mitigar vetor adicional dado o threat model.

**Implementação middleware BFF:**

```dart
// apps/social_care_bff/web/lib/src/middleware/fetch_metadata_middleware.dart (FUTURE)
Middleware fetchMetadataMiddleware() => (innerHandler) => (request) async {
  final isMutation = const {'POST', 'PUT', 'DELETE', 'PATCH'}.contains(request.method);
  final isApiPath = request.url.path.startsWith('api/');

  if (isMutation && isApiPath) {
    final fetchSite = request.headers['Sec-Fetch-Site'];
    final xRequestedWith = request.headers['X-Requested-With'];
    final origin = request.headers['Origin'];
    final host = request.headers['Host'];

    if (fetchSite != 'same-origin') {
      return Response.forbidden('Cross-site request blocked');
    }
    if (xRequestedWith != 'XMLHttpRequest') {
      return Response.forbidden('Missing X-Requested-With');
    }
    if (origin == null || !origin.endsWith(host ?? '')) {
      return Response.forbidden('Origin mismatch');
    }
  }
  return innerHandler(request);
};
```

**Auditoria:** test E2E: tentar `POST /api/patients` de origem cross-site (e.g., simulando atacante) → 403.

---

### Dimensão 9 — Supply Chain Security

#### Web (npm via Bun)

| Item | Decisão |
|---|---|
| Lockfile | `bun.lock` committed, verificado em CI (`bun install --frozen-lockfile`) |
| Audit | `bun audit` em CI a cada PR + diariamente no workflow scheduled |
| Vulnerable deps | CVSS ≥7.0 → bloqueia merge; <7.0 → log e ticket em backlog |
| Pinned versions | `package.json` usa versões **exatas** (`"react": "19.0.3"`), não ranges (`^19.0.0`) |
| Provenance | Quando disponível, validar npm provenance (`bun pm trust`) |
| Dependabot/Renovate | Renovate configurado: PR semanal de bumps, agrupados por tipo (security imediato; minor/patch agrupado) |
| SBOM | Gerar SBOM (CycloneDX) em cada build de release |
| New dep approval | Adicionar dep → label `dep-added` no PR → revisão obrigatória |
| Postinstall scripts | `bun install --ignore-scripts` exceto para deps allowlisted (`vite`, `@vitejs/plugin-react`, etc) |

**Configuração Renovate:**

```json
// .github/renovate.json
{
  "extends": ["config:recommended", ":pinAllExceptPeerDependencies"],
  "schedule": ["after 9pm on monday"],
  "vulnerabilityAlerts": { "enabled": true, "labels": ["security"] },
  "packageRules": [
    { "matchUpdateTypes": ["patch", "pin"], "automerge": true },
    { "matchUpdateTypes": ["minor"], "groupName": "minor updates" },
    { "matchUpdateTypes": ["major"], "groupName": "major updates", "labels": ["major-update"] }
  ]
}
```

#### BFF (pub via pubspec)

| Item | Decisão |
|---|---|
| Lockfile | `pubspec.lock` committed |
| Audit | `dart pub outdated --json` + cross-ref com OSV |
| Pinned | Versões exatas em `pubspec.yaml` |
| New dep approval | Mesma policy do Web |

#### Docker base image

| Item | Decisão |
|---|---|
| Base | `gcr.io/distroless/base-debian12:nonroot` (já em uso no `Dockerfile.bff`) |
| Pin | Por digest SHA256, não tag (`@sha256:...`) |
| Scan | Trivy/Grype em cada build, falha em CVE crítica |
| Non-root | UID 65532 (nonroot user padrão distroless) |
| Read-only filesystem | K8s SecurityContext `readOnlyRootFilesystem: true` (apenas `/tmp` writable se necessário) |
| Capabilities | Drop ALL, sem add |
| Seccomp | RuntimeDefault |

---

### Dimensão 10 — LGPD-Specific Hardening (Web)

| Vetor | Controle |
|---|---|
| **CPF/NIS/RG no V8 heap** | Mascarar em UI por default (`***.***.***-**`). Mostrar valor cleartext apenas quando usuário clicar "Revelar" — clique cria new state local que se auto-limpa após 30s. Reduz janela de exposição via DevTools/extensions. |
| **PII em logs do navegador** | `console.log` proibido em produção (Vite `drop_console` em build prod). |
| **PII em error reporting (Sentry)** | beforeSend scrubber redacta CPF/NIS/RG/email/telefone via regex antes de enviar. |
| **PII em URL** | Lint CI: identificadores como `cpf=`, `nis=` em URL → fail. Usar IDs opacos (UUID) nas rotas. |
| **Source maps em produção** | Build dist **não** publica source maps. Source maps gerados em build separado e armazenados em bucket privado (Sentry artifacts). |
| **DevTools deteção** | Não tentar bloquear DevTools (incoercível, falsa segurança). Apenas log telemetria: se janela é redimensionada por >100px de altura/largura em modo prod → log evento (proxy fraco de DevTools aberto). |
| **Print/Screenshot** | CSS `print:hidden` em campos sensíveis. Não previne screenshot OS, mas remove de impressão acidental. |
| **Idle timeout UX** | Após 10 min sem interação, mostrar modal "Sessão expira em 1 min. Continuar?". Após 11 min sem ack, logout automático + clear in-memory. |
| **Múltiplos tabs** | Cada tab tem in-memory token próprio (refresh é compartilhado via cookie). Logout em um tab → broadcast via BroadcastChannel API → outros tabs detectam e redirecionam para login. |
| **Auditoria de acesso** | Cada `GET` de dado sensível (paciente full record) gera log `audit_access` no BFF com `actorId`, `patientId`, `timestamp`, `route` (LGPD Art. 37). |

**Trade-off declarado:** Web App nunca é tão seguro quanto Native para dados sensíveis. V8 heap é inspecionável, extensions podem ter acesso a DOM (com permissão do usuário), screenshots OS são incoercíveis. **Mitigação real é processo, não código** — política de uso de dispositivos corporativos, treinamento, MDM em endpoints onde aplicável.

---

## Consequências

### Positivas

- **Defense in depth real e auditável.** Cada vetor de ataque mapeado tem ≥2 controles (Origin + SameSite, CSP + Sec-Fetch, lockfile + audit + provenance).
- **Compliance LGPD** documentável: ADR-026 é evidência de "medidas técnicas e organizacionais adequadas" (art. 46).
- **CI bloqueia regressões.** Lint + audit + headers test rodam em todo PR. Regression silenciosa é improvável.
- **Telemetria de violação** (CSP reports, audit logs) cria sinal para investigar comportamento anômalo.

### Negativas / Custos

| Custo | Detalhamento |
|---|---|
| **CSP strict requer disciplina** | Nenhum `dangerouslySetInnerHTML` aceito sem revisão dedicada. Bibliotecas que injetam `<style>` inline (legacy CSS-in-JS) ficam fora. |
| **COEP `require-corp` proíbe terceiros sem CORP** | Se um dia precisar embedar widget externo (mapa, gráfico), revisar CORP do recurso. |
| **`bun install --ignore-scripts` quebra algumas libs** | Lista de allowlist precisa ser mantida. ~5 libs comuns precisam de postinstall. |
| **`X-Requested-With` exige cliente sempre setar** | TanStack Query default não seta — wrapper de fetch precisa adicionar. Não é problema; é checkpoint. |
| **Pinned exact versions** | Renovate PRs frequentes para manter atualizado. Aceitável — mitiga ataques de range bumping. |
| **Idle timeout UX intrusivo** | Cuidador social pode estar em call atendendo família e ser deslogado. Mitigação: timeout só conta tempo sem keyboard/mouse, não tempo sem network request. |

### Quebras se as regras forem violadas

| Violação | Consequência | Detecção |
|---|---|---|
| `unsafe-inline` ou `unsafe-eval` em CSP | XSS via injeção fica possível | Lint CI + CSP report monitoring |
| Cookie sem `SameSite=Strict` ou sem `__Host-` | CSRF + cookie injection viável | Audit de auth handler em cada PR |
| `localStorage` para token | XSS exfiltra refresh + session permanente | Lint CI bloqueante |
| `shelf_static` com `serveFilesOutsidePath: true` | Path traversal arbitrário | Lint CI + test unitário |
| Bumping de dep sem audit | Supply chain comprometida | `bun audit` em CI |
| Source map em produção | Vazamento de código + comentários | Build pipeline test |
| PII em error log Sentry | LGPD Art. 46 violado | beforeSend scrubber test |

---

## Alternativas consideradas

### Alternativa 1 — CSP `unsafe-inline` para começar simples

**Rejeitada.** XSS é o vetor mais provável em SPA. Permitir `unsafe-inline` neutraliza CSP. Custo de implementar nonce + strict-dynamic é ~1 dia; benefício é permanente.

### Alternativa 2 — CSRF token em vez de Origin/Sec-Fetch

**Rejeitada.** Já argumentado em Dimensão 8.

### Alternativa 3 — Disable HSTS preload (manter `max-age` curto)

**Rejeitada.** App é interno e tem domínio próprio. HSTS preload elimina TLS-stripping em primeira visita. Single-use cost.

### Alternativa 4 — Token CSRF + Origin + SameSite (todos)

**Rejeitada por excesso.** Origin + SameSite cobre threat model atual. Adicionar token CSRF triplica complexidade sem mitigar vetor adicional.

### Alternativa 5 — Subresource Integrity (SRI)

**Não implementada na Fase 1.** SRI faz sentido para scripts de CDN externo. Aqui todos os assets são `'self'` (servidos pelo BFF). Vite não emite SRI automaticamente; integração custosa para benefício marginal.

Reavaliar se um dia carregarmos qualquer asset externo (CDN de fonte, widget).

### Alternativa 6 — Trusted Types API

**Adiada.** Custo de adoção alto (refactor de toda manipulação de DOM via `innerHTML`/`outerHTML`). CSP strict + lint contra `dangerouslySetInnerHTML` cobre o vetor principal. Reconsiderar se CSP reports mostrarem padrão de tentativa de XSS.

---

## Future enforcement

### CI checks BLOQUEANTES

```yaml
# .github/workflows/web-security.yml (FUTURE)
name: web-security
on:
  pull_request:
    paths: ['apps/conecta_web/**']
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - run: bun install --frozen-lockfile
        working-directory: apps/conecta_web
      - name: bun audit
        run: bun audit --audit-level high
        working-directory: apps/conecta_web
      - name: lint security rules
        run: bun run lint:security
        working-directory: apps/conecta_web
      - name: bundle inspection
        run: |
          # Falha se bundle contém 'localStorage', 'sessionStorage' (regex)
          # Falha se bundle contém token-like patterns que vazaram (alguns JWT prefixes)
          ! grep -r "localStorage\|sessionStorage" apps/conecta_web/dist
  headers-e2e:
    runs-on: ubuntu-latest
    steps:
      - name: Start container, curl headers, validate presence
        run: |
          docker run -d --name bff -p 8081:8081 acdg/social-care-bff:test
          sleep 5
          headers=$(curl -sI http://localhost:8081/)
          for header in \
            "Strict-Transport-Security" \
            "Content-Security-Policy" \
            "Cross-Origin-Opener-Policy" \
            "X-Content-Type-Options" \
            "Referrer-Policy" \
            "Permissions-Policy"; do
            echo "$headers" | grep -i "^$header:" || (echo "MISSING $header" && exit 1)
          done
```

### Scheduled scans

- **Weekly:** Mozilla Observatory + securityheaders.com via API; resultado em dashboard de segurança.
- **Monthly:** SSL Labs scan; alerta se cair abaixo de A+.
- **Quarterly:** pentest manual + DAST (OWASP ZAP authenticated scan).
- **Per release:** Trivy scan da imagem Docker.

### Threat modeling refresh

Re-rodar STRIDE em cada feature de domínio sensível (financeiro, dados de menor, integração com órgão público externo). Skill `threat-modeler` aplica.

---

## OWASP ASVS L2 mapping (Application Security Verification Standard 4.0)

| ASVS § | Controle | Dimensão deste ADR |
|---|---|---|
| 2.1 (Password Security) | Delegado ao Zitadel | ADR-012 |
| 2.2 (Authentication Mechanism) | OIDC PKCE | ADR-012 |
| 2.6 (Session Management) | Split-Token, __Host- cookie | ADR-011 + Dim. 6 |
| 3.2 (Session Binding) | SameSite=Strict + Origin validation | Dim. 6 + 8 |
| 3.3 (Session Termination) | Logout revoga + clear in-memory + broadcast | Dim. 6 |
| 3.5 (Token-based Session) | Bearer JWT + refresh rotation | ADR-011 + 023 |
| 4.1 (Access Control) | RBAC enforced no BFF | Dim. 7 |
| 5.1 (Input Validation) | Validação no BFF (R2 ADR-024) + schema OpenAPI | Dim. 7 + ADR-025 |
| 5.2 (Sanitization) | CSP + React escape default | Dim. 2 |
| 7.1 (Log Content) | Audit log com actorId; sem PII em logs | Dim. 10 + ADR-023 |
| 7.3 (Log Protection) | Sentry scrubber | Dim. 10 |
| 8.2 (Client-side Data Protection) | No-store em rotas sensíveis, mascaramento de PII | Dim. 4 + 10 |
| 9.1 (Communications Security) | TLS 1.3, HSTS preload | Dim. 1 |
| 9.2 (Server Communications) | mTLS BFF↔backend? deferido | Future ADR |
| 10.2 (Malicious Code) | CSP strict + SRI (futuro) + supply chain audit | Dim. 2 + 9 |
| 12.3 (File Path Validation) | shelf_static hardening + path traversal block | Dim. 4 |
| 13.1 (Generic Web Service) | OpenAPI contract + header validation | ADR-025 + Dim. 5 |
| 14.4 (HTTP Security Headers) | Pacote completo | Dim. 5 |
| 14.5 (HTTP Method Verification) | Methods explícitos no shelf_router; rejeita others | Dim. 8 |

**Cobertura estimada ASVS L2:** ~85%. Gaps documentados em Open Questions.

---

## LGPD mapping

| Artigo | Controle | Aderência via ADR-026 |
|---|---|---|
| Art. 6 (princípios — segurança) | Pacote completo de hardening | **Atendido**. |
| Art. 7 (bases legais) | Delegado a domínio (não cobre técnico aqui) | Out of scope. |
| Art. 11 (dados sensíveis) | Mascaramento + audit log + RBAC | **Parcial** — cobre Web; domínio cobre uso. |
| Art. 37 (registro de operações) | audit_access log para cada GET sensível | **Atendido** + cross-ref ADR-023. |
| Art. 46 (medidas técnicas) | TLS, CSP, supply chain, V8 hardening | **Atendido**. |
| Art. 47 (compartilhamento) | Mesma origem, sem terceiros | **Atendido**. |
| Art. 48 (notificação de incidente) | Sentry + CSP report alerta security team | **Parcial** — processo de IR fora de escopo deste ADR. |
| Art. 50 (boas práticas) | ADR público + future enforcement + ASVS mapping | **Atendido**. |

---

## Open questions

1. **mTLS BFF↔backend.** Atualmente Bearer (ADR-023). mTLS seria defense in depth adicional para BFF↔social-care. Decisão fora de escopo deste ADR; abrir ADR específico se Phase 7 mover para K8s service mesh.
2. **DAST automatizado em CI.** OWASP ZAP em modo authenticated scan no PR? Custo de manutenção real. Decidir após primeira release.
3. **Bug bounty / responsible disclosure.** Política pública? Programa privado? Não decidido — discussão para Conselho.
4. **Browser CSP report ingestor.** Endpoint `/csp-report` recebe + loga. Onde armazenar? Sentry tem suporte nativo; Grafana Loki é alternativa.
5. **Step-up auth para ações destrutivas.** "Apagar paciente" exige re-autenticação? Phase 7+.
6. **WebAuthn / passkeys** como fator adicional ou substituto de senha. Depende de roadmap Zitadel.
7. **Endpoint pinning de Zitadel.** Cert pinning ou DNS pinning para `auth.acdgbrasil.com.br`? Reduz risco de BGP/DNS hijack. Avaliar.

---

## Riscos não cobertos por este ADR

- **Endpoint device compromise** (notebook do cuidador infectado por malware). Mitigação: MDM + EDR corporativo, fora de escopo de código.
- **Insider threat** (cuidador com role legítima exfiltrando dados). Mitigação: audit log + monitoring de queries anômalas (taxa, volume). Out of scope desta ADR.
- **Zero-day em React 19 ou Vite 5.** Mitigação: subscribers em CVE feeds (npm, GitHub Security Advisory) + processo de patch rápido.
- **Zitadel compromise.** Out of scope — fora do domínio deste repo.
- **DNS hijack / BGP.** Mitigação: DNSSEC + CAA records, fora de escopo.
- **Browser zero-day.** Incoercível em runtime. Mitigação: navegadores corporativos atualizados (MDM).

---

## Referências

- **ADRs relacionados**: ADR-011, ADR-012, ADR-023, ADR-024, ADR-025
- **OWASP ASVS 4.0**: https://owasp.org/www-project-application-security-verification-standard/
- **OWASP Top 10 (2021)**: https://owasp.org/Top10/
- **MDN — Content Security Policy**: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- **MDN — Cross-Origin-Embedder-Policy**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy
- **MDN — Sec-Fetch-Site**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Sec-Fetch-Site
- **RFC 6749** (OAuth 2.0)
- **RFC 7519** (JWT)
- **RFC 8252** (OAuth for Native Apps — relevante para CLI/Desktop)
- **RFC 6797** (HSTS)
- **W3C — Trusted Types** (futuro): https://www.w3.org/TR/trusted-types/
- **Scott Helme — securityheaders.com**: https://securityheaders.com/
- **Mozilla Observatory**: https://observatory.mozilla.org/
- **OWASP Cheat Sheet — Web Service Security**: https://cheatsheetseries.owasp.org/cheatsheets/Web_Service_Security_Cheat_Sheet.html
- **OWASP Cheat Sheet — Cross-Site Request Forgery Prevention**: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
- **LGPD (Lei 13.709/2018)**: https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm
- **ANPD — Guia de boas práticas para segurança da informação**: https://www.gov.br/anpd/
