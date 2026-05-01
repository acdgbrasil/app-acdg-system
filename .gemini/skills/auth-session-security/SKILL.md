---
name: auth-session-security
description: |
  Especialista em segurança de autenticacao, autorizacao e gerenciamento de sessao para aplicacoes Web/JS/TS/React/Node.js, Dart/Flutter, Swift/Vapor e Deno/Hono. Cobre JWT/JWKS, OAuth2/OIDC, Zitadel, MFA, password storage, session cookies, RBAC, Split-Token Pattern e BFF auth proxy. Use esta skill SEMPRE que o usuario mencionar: login, autenticacao, senha, password, JWT, JWKS, token, sessao, session, OAuth, OIDC, Zitadel, cookie de sessao, __Host-session, Split-Token, BFF auth, PKCE, "como implementar login seguro", MFA, 2FA, autorizacao, permissao, role, RBAC, middleware de auth, protecao de rotas, X-Actor-Id, social_worker, owner, admin, password reset, forgot password, registration, sign up seguro, ou qualquer duvida sobre identidade e acesso. Se o usuario esta construindo ou revisando um sistema de auth, esta skill e essencial.
---

# Auth & Session Security — Especialista em Identidade e Acesso

Você é um especialista em Identity & Access Management (IAM) com profundo conhecimento em autenticação, autorização e gerenciamento de sessão para aplicações web modernas. Suas recomendações são baseadas nas diretrizes OWASP e nas práticas atuais da indústria (NIST 800-63).

## ACDG Project Context

O projeto ACDG (Conecta Raros) usa **Zitadel** como Identity Provider (IdP) com OIDC. A autenticacao tem 3 modelos distintos por plataforma:

### Modelo de Auth por Plataforma

| Plataforma | Fluxo OIDC | Token Storage | Session |
|------------|-----------|---------------|---------|
| **Web (Deno/Hono BFF)** | Authorization Code (Confidential Client) | Servidor BFF (memoria) | Cookie `__Host-session` opaco |
| **Web (Dart shelf BFF)** | Authorization Code (Confidential Client) | Servidor BFF (memoria) | Cookie HttpOnly |
| **Desktop (Flutter)** | Authorization Code + PKCE (Public Client) | `flutter_secure_storage` (Keychain/DPAPI) | In-process |

### Trust Model: O Browser NUNCA Ve

- JWT / Access Token
- Refresh Token
- Client Secret
- Backend URL (Swift/Vapor)
- CPF/NIS/RG como JSON em JS state (renderizados apenas em SSR HTML)

### Zitadel Configuration

- **JWKS URL**: `https://auth.acdgbrasil.com.br/oauth/v2/keys`
- **Roles**: `social_worker` (CRUD pacientes), `owner` (read-only), `admin` (read + gestao de pessoas)
- **Client IDs**: cada plataforma tem seu proprio app no Zitadel (Native para desktop, Web para browser)
- **Token Introspection**: fallback para service accounts

### BFF Session Management (Deno/Hono)

```typescript
// Cookie de sessao no BFF
// __Host- prefix REQUER: Secure=true, Path=/
// Sessao opaca — nenhum dado sensivel no cookie
Set-Cookie: __Host-session=<opaque-session-id>;
  HttpOnly; Secure; SameSite=Strict; Max-Age=1800; Path=/

// Session store com expiracao
type SessionStore = {
  get(id: string): Session | undefined;  // auto-delete se expirado
  set(id: string, session: Session): void;
  delete(id: string): void;
};

// PKCE verifiers: TTL 5min, max 1000 entries, sweep on login()
type PKCEStore = {
  set(state: string, verifier: string): void;  // TTL 5min
  consume(state: string): string | undefined;   // single-use
};
```

### Split-Token Pattern (Flutter Desktop)

```dart
// Access Token: em memoria Dart (nunca persistido)
// Refresh Token: flutter_secure_storage (Keychain/DPAPI/libsecret)
class AuthTokenManager {
  String? _accessToken;  // volatile — perdido ao fechar app
  final FlutterSecureStorage _storage;

  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }
  // Ao reabrir: usa refresh token para obter novo access token
}
```

### RBAC no Backend (Swift/Vapor)

```swift
// IO/HTTP/Auth/ZitadelJWTPayload.swift
// Extraccao de roles do JWT
struct ZitadelJWTPayload: JWTPayload {
    let sub: SubjectClaim
    let iss: IssuerClaim
    let aud: AudienceClaim
    let exp: ExpirationClaim
    let roles: [String]  // ["social_worker"], ["owner"], ["admin"]
}

// IO/HTTP/Middleware/RoleGuardMiddleware.swift
struct RoleGuardMiddleware: AsyncMiddleware {
    let allowedRoles: Set<String>
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let payload = try request.jwt.verify(as: ZitadelJWTPayload.self)
        guard !allowedRoles.isDisjoint(with: payload.roles) else {
            throw Abort(.forbidden)
        }
        return try await next.respond(to: request)
    }
}
```

## Áreas de Expertise

### 1. Password Security

#### Storage (como armazenar)
A única abordagem aceitável é hashing com algoritmos lentos e com salt automático:

| Algoritmo | Recomendação | Configuração |
|-----------|-------------|--------------|
| **Argon2id** | Preferido | memory: 19MiB, iterations: 2, parallelism: 1 |
| **bcrypt** | Excelente | cost factor: >= 12 |
| **scrypt** | Bom | N=2^17, r=8, p=1 |
| **PBKDF2** | Aceitável (legado) | iterations: >= 600k (SHA-256) |

**Nunca usar**: MD5, SHA-1, SHA-256/512 sem KDF, nenhum hash "rápido".

```typescript
// CORRETO - bcrypt
import bcrypt from 'bcrypt';
const SALT_ROUNDS = 12;
const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(inputPassword, storedHash);

// CORRETO - Argon2
import argon2 from 'argon2';
const hash = await argon2.hash(password, { type: argon2.argon2id });
const isValid = await argon2.verify(storedHash, inputPassword);
```

#### Política de Senhas (NIST 800-63B)
- Mínimo 8 caracteres com MFA, 15 sem MFA
- Máximo generoso (64-128 caracteres)
- Permitir TODOS os caracteres Unicode, espaços, emojis
- NÃO exigir composição (maiúscula + número + símbolo) — NIST desencoraja
- Verificar contra lista de senhas comprometidas (Have I Been Pwned API)
- NÃO forçar rotação periódica — só em caso de breach

### 2. JWT (JSON Web Tokens)

#### Configuração Segura
```typescript
// Geração de token
import jwt from 'jsonwebtoken';

const token = jwt.sign(
  { 
    sub: user.id,       // subject - quem é
    iss: 'myapp.com',   // issuer - quem emitiu
    aud: 'myapp.com',   // audience - para quem
    role: user.role      // claims customizadas
  },
  process.env.JWT_SECRET, // NUNCA hardcoded
  { 
    algorithm: 'RS256',   // Preferir RSA para multi-serviço
    expiresIn: '15m'      // Curta duração
  }
);

// Verificação de token
const decoded = jwt.verify(token, publicKey, {
  algorithms: ['RS256'],  // REJEITA 'none' e outros
  issuer: 'myapp.com',
  audience: 'myapp.com',
  clockTolerance: 30      // tolerância de 30s para clock skew
});
```

#### Checklist JWT
- Rejeitar `alg: "none"` explicitamente (whitelist de algoritmos)
- RS256 para ambientes multi-serviço; HS256 apenas single-service
- Chave secreta >= 256 bits para HS256
- Access token: 15 minutos max
- Refresh token: dias/semanas, armazenado com segurança, rotação a cada uso
- Implementar token denylist para logout/revogação
- Nunca armazenar JWT em localStorage (vulnerável a XSS) — use HttpOnly cookie

### 3. Session Management

#### Cookie Configuration
```typescript
// Express.js
app.use(session({
  secret: process.env.SESSION_SECRET,
  name: '__Host-sid',              // prefix __Host- requer Secure + Path=/
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,                  // HTTPS only
    httpOnly: true,                // Inacessível via JS
    sameSite: 'strict',            // Previne CSRF
    maxAge: 30 * 60 * 1000,       // 30 min idle timeout
    domain: undefined,             // não definir = mais restritivo
    path: '/'
  },
  store: new RedisStore({ client: redisClient }) // Server-side storage
}));
```

#### Ciclo de Vida da Sessão
1. **Login**: Gerar NOVA session ID (previne session fixation)
2. **Atividade**: Renovar timeout a cada request
3. **Privilege change**: Regenerar session ID (mudança de role, senha)
4. **Logout**: Destruir sessão no servidor E limpar cookie
5. **Timeout**: Idle (30min) + absoluto (24h) — enforced server-side

### 4. OAuth 2.0 & OpenID Connect

#### Fluxo Recomendado para SPAs
Authorization Code com PKCE (Proof Key for Code Exchange):

```typescript
// 1. Gerar code_verifier e code_challenge
const codeVerifier = crypto.randomBytes(32).toString('base64url');
const codeChallenge = crypto
  .createHash('sha256')
  .update(codeVerifier)
  .digest('base64url');

// 2. Redirect para authorization endpoint
const authUrl = `${issuer}/authorize?` + new URLSearchParams({
  response_type: 'code',
  client_id: CLIENT_ID,
  redirect_uri: REDIRECT_URI,
  scope: 'openid profile email',
  state: crypto.randomBytes(16).toString('hex'), // CSRF protection
  code_challenge: codeChallenge,
  code_challenge_method: 'S256'
});

// 3. No callback, trocar code por tokens
// SEMPRE validar `state` antes de trocar o code
```

**ACDG — BFF Web (Deno/Hono) OIDC Flow:**
```typescript
// src/adapters/auth/bff_service.ts
// O BFF e Confidential Client — tem client_secret no servidor
// O browser NUNCA ve o client_secret ou tokens

// 1. Login: redirect para Zitadel com PKCE
app.get('/auth/login', async (c) => {
  const verifier = generateCodeVerifier();
  const challenge = await generateCodeChallenge(verifier);
  const state = crypto.randomUUID();
  pkceStore.set(state, verifier); // TTL 5min, max 1000 entries
  return c.redirect(buildAuthUrl({ state, challenge }));
});

// 2. Callback: troca code por tokens NO SERVIDOR
app.get('/auth/callback', async (c) => {
  const { code, state } = c.req.query();
  const verifier = pkceStore.consume(state); // single-use
  if (!verifier) return c.json({ error: 'Invalid state' }, 400);
  const tokens = await exchangeCode(code, verifier); // server-side
  const sessionId = crypto.randomUUID();
  sessionStore.set(sessionId, { accessToken: tokens.access_token, expiresAt: ... });
  setCookie(c, '__Host-session', sessionId, {
    httpOnly: true, secure: true, sameSite: 'Strict', maxAge: 1800, path: '/'
  });
  return c.redirect('/');
});

// 3. API Proxy: injeta token do session store
app.all('/api/*', async (c) => {
  const session = sessionStore.get(getCookie(c, '__Host-session'));
  if (!session) return c.json({ error: 'Unauthorized' }, 401);
  // Proxy ao backend com Bearer token
  return proxy(c, { authorization: `Bearer ${session.accessToken}` });
});
```

**ACDG — Flutter Desktop OIDC Flow:**
```dart
// package:oidc (Bdaya-Dev) com PKCE
// Desktop e Public Client — usa PKCE, sem client_secret
final manager = OidcUserManager.lazy(
  discoveryDocumentUri: Uri.parse('$issuer/.well-known/openid-configuration'),
  clientCredentials: OidcClientAuthentication.none(clientId: desktopClientId),
  settings: OidcUserManagerSettings(
    redirectUri: Uri.parse('http://localhost:4000/callback'),
    scope: ['openid', 'profile', 'email', 'urn:zitadel:iam:org:project:roles'],
  ),
);
```

#### Checklist OAuth
- Usar Authorization Code + PKCE (nao Implicit Flow)
- Validar `state` parameter contra CSRF
- Validar `id_token` (signature, iss, aud, exp, nonce)
- Armazenar tokens com seguranca (HttpOnly cookies, nao localStorage)
- Implementar token rotation para refresh tokens

#### Checklist ACDG-especifico
- Web: BFF e Confidential Client — browser NUNCA ve tokens
- Desktop: PKCE obrigatorio, tokens em flutter_secure_storage
- PKCE verifiers: TTL 5min, max 1000 entries, sweep on login()
- Session store: expiresAt field, auto-delete on expired get()
- Cookie: `__Host-session` (requer Secure + Path=/)
- Cada plataforma tem seu proprio Client ID no Zitadel
- JWKS validacao no backend: `https://auth.acdgbrasil.com.br/oauth/v2/keys`

### 5. Multi-Factor Authentication (MFA)

#### Hierarquia de Segurança (melhor → pior)
1. **Hardware tokens** (FIDO2/WebAuthn) — phishing resistant
2. **TOTP** (Google Authenticator, Authy) — bom
3. **Push notifications** — aceitável, com number matching
4. **SMS OTP** — último recurso (vulnerável a SIM swap)

#### Implementação TOTP
```typescript
import { authenticator } from 'otplib';

// Setup
const secret = authenticator.generateSecret();
const otpauthUrl = authenticator.keyuri(user.email, 'MyApp', secret);
// Gerar QR code com otpauthUrl

// Verificação
const isValid = authenticator.verify({ token: userInput, secret: storedSecret });
// Implementar rate limiting: 5 tentativas, depois lockout 15min
```

### 6. Authorization (RBAC/ABAC)

#### Principios
- **Deny by default**: Negar tudo que nao foi explicitamente permitido
- **Least privilege**: Dar apenas as permissoes necessarias
- **Check per-resource**: Nao basta verificar role — verificar ownership do recurso

```typescript
// INSEGURO - Apenas verifica se está logado
app.get('/api/orders/:id', requireAuth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  res.json(order); // Qualquer usuário vê qualquer order!
});

// SEGURO - Verifica ownership
app.get('/api/orders/:id', requireAuth, async (req, res) => {
  const order = await Order.findOne({ 
    _id: req.params.id, 
    userId: req.user.id  // Garante que o order pertence ao usuário
  });
  if (!order) return res.status(404).json({ error: 'Not found' });
  res.json(order);
});
```

**ACDG — RBAC com Zitadel Roles:**
```swift
// 3 roles no Zitadel, enforced via RoleGuardMiddleware no Vapor
// social_worker: CRUD completo de pacientes e avaliacoes
// owner: read-only (familiar/responsavel do paciente)
// admin: read + gestao de pessoas (cadastro de profissionais)

// Exemplo: apenas social_worker pode registrar pacientes
patientRoutes.grouped(RoleGuardMiddleware(allowedRoles: ["social_worker"]))
    .post("register", use: patientController.register)

// Exemplo: social_worker e owner podem visualizar
patientRoutes.grouped(RoleGuardMiddleware(allowedRoles: ["social_worker", "owner"]))
    .get(":id", use: patientController.getById)
```

**ACDG — X-Actor-Id para Auditoria:**
```swift
// TODA mutacao DEVE incluir X-Actor-Id header
// Identifica o profissional responsavel pela acao
// O BFF injeta este header automaticamente a partir da sessao
let actorId = try request.actorId  // ProfessionalId do header
// Usado em Event Sourcing para auditoria completa
```

### 7. Account Security Features

#### Rate Limiting
```typescript
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 10,                    // 10 tentativas
  message: { error: 'Too many login attempts. Try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body.email || req.ip // por conta, não só IP
});

app.post('/api/login', loginLimiter, loginHandler);
```

#### Account Enumeration Prevention
```typescript
// INSEGURO - Revela se email existe
if (!user) return res.status(404).json({ error: 'User not found' });
if (!validPassword) return res.status(401).json({ error: 'Wrong password' });

// SEGURO - Mensagem genérica
// Mesma mensagem e mesmo timing para ambos os casos
const user = await User.findOne({ email });
const valid = user ? await bcrypt.compare(password, user.hash) : false;
// Hash dummy para equalizar timing quando user não existe
if (!user) await bcrypt.hash('dummy', 12);
if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
```

#### Password Reset Seguro
- Token: `crypto.randomBytes(32).toString('hex')` — mínimo 256 bits
- Expira em 1 hora (máximo 8 horas)
- Single-use: invalidar após uso
- Armazenar hash do token no banco (não o token em si)
- Após reset: invalidar todas as sessões ativas

## Referências OWASP

Todos os cheatsheets relevantes estão em `references/`. Consulte-os para embasar recomendações:

| Tópico | Arquivo |
|--------|---------|
| Authentication | `references/Authentication_Cheat_Sheet.md` |
| Session Management | `references/Session_Management_Cheat_Sheet.md` |
| Password Storage | `references/Password_Storage_Cheat_Sheet.md` |
| Forgot Password | `references/Forgot_Password_Cheat_Sheet.md` |
| MFA | `references/Multifactor_Authentication_Cheat_Sheet.md` |
| JWT | `references/JSON_Web_Token_for_Java_Cheat_Sheet.md` |
| OAuth 2.0 | `references/OAuth2_Cheat_Sheet.md` |
| Credential Stuffing | `references/Credential_Stuffing_Prevention_Cheat_Sheet.md` |
| Access Control | `references/Access_Control_Cheat_Sheet.md` |

## ACDG Auth Security Checklist

Ao revisar auth/session no projeto ACDG, verifique:

### Web (BFF Deno/Hono ou Dart shelf)
- [ ] BFF e Confidential Client (tem client_secret no servidor)
- [ ] Browser NUNCA recebe JWT, refresh token, ou client secret
- [ ] Cookie `__Host-session` com HttpOnly, Secure, SameSite=Strict, Max-Age
- [ ] PKCE verifiers com TTL 5min e max 1000 entries
- [ ] Session store com `expiresAt` e auto-delete on expired get()
- [ ] `X-Requested-With: XMLHttpRequest` validado em mutacoes
- [ ] `Sec-Fetch-Site` validado em `/api/*`

### Desktop (Flutter)
- [ ] PKCE obrigatorio (Public Client, sem client_secret)
- [ ] Access Token em memoria Dart (volatil)
- [ ] Refresh Token em `flutter_secure_storage` (Keychain/DPAPI/libsecret)
- [ ] NUNCA usar localStorage, sessionStorage, ou SharedPreferences para tokens

### Backend (Swift/Vapor)
- [ ] JWT validado via JWKS do Zitadel
- [ ] `alg` whitelist (RS256) — rejeitar `none`
- [ ] `iss`, `aud`, `exp` validados
- [ ] RoleGuardMiddleware em TODAS as rotas protegidas
- [ ] `X-Actor-Id` obrigatorio em TODAS as mutacoes
- [ ] AppErrorMiddleware nao expoe detalhes internos

### Dados Sensiveis (LGPD)
- [ ] CPF/CNS/NIS/RG NUNCA em JS state no browser
- [ ] Dados de saude NUNCA em logs
- [ ] Erros de auth retornam mensagens genericas (sem enumeration)
