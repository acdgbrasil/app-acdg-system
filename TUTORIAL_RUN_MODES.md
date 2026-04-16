# Tutorial Completo: Como Rodar o Conecta Raros (Frontend ACDG)

> Este documento foi escrito para **outra IA ou desenvolvedor** que precisa entender e rodar todas as configuracoes possiveis deste projeto. Le de cima para baixo — cada secao depende da anterior.

---

## 0. Visao Geral da Arquitetura

```
Browser (Flutter Web WASM ou Desktop nativo)
   |
   | Cookie: __Host-session (HttpOnly, opaco)
   | X-Requested-With: XMLHttpRequest
   v
Caddy Reverse Proxy (:80)
   |
   +-- /api/*  --> BFF Dart Shelf (:8081)  --> Backend Swift/Vapor (upstream externo)
   +-- /*      --> Flutter WASM static files
```

**Componentes:**
- **Shell App** (`apps/acdg_system/`) — Flutter app (Web WASM + Desktop nativo)
- **BFF** (`bff/social_care_web/`) — Dart shelf server (auth OIDC, session cookies, API proxy)
- **BFF Shared** (`bff/shared/`) — DTOs e contracts compartilhados (usa `json_serializable`)
- **Packages** (`packages/`) — core, auth, network, persistence, social_care, people_admin, design_system, core_contracts
- **Static Site** (`site/`) — Landing pages HTML/CSS (gateway only)

**Regra de ouro:** O browser NUNCA ve tokens JWT, URLs de backend, ou secrets. Tudo passa pelo BFF.

---

## 1. Pre-requisitos

### 1.1 Ferramentas necessarias

| Ferramenta | Versao | Para que |
|-----------|--------|---------|
| Flutter | 3.41.6+ (stable) | Build do app |
| Dart | 3.7+ (vem com Flutter) | BFF server + code gen |
| Docker + Compose | v2.x (com `watch`) | Containers |
| Melos | qualquer (via `dart pub global activate melos`) | Monorepo management |
| FVM (opcional) | qualquer | Gerenciar versao do Flutter |

### 1.2 Clonar e instalar dependencias

```bash
# Clonar o repo
git clone <repo-url>
cd frontend

# Instalar dependencias de TODOS os packages do monorepo
melos bootstrap
```

`melos bootstrap` roda `dart pub get` em cada package respeitando as dependencias locais (path overrides). Sem isso, nada compila.

### 1.3 Code generation

Alguns packages usam `build_runner` (json_serializable, isar, etc.):

```bash
# BFF Shared (DTOs com fromJson/toJson)
cd bff/shared && dart run build_runner build --delete-conflicting-outputs

# Persistence (Isar schemas)
cd packages/persistence && dart run build_runner build --delete-conflicting-outputs

# Shell app (se necessario)
cd apps/acdg_system && dart run build_runner build --delete-conflicting-outputs
```

---

## 2. Configuracao de Ambiente (.env)

O projeto usa **dois** conjuntos de variaveis independentes:

### 2.1 BFF (.env)

**Arquivo:** `bff/social_care_web/.env` (copiar de `.env.example`)

```bash
cp bff/social_care_web/.env.example bff/social_care_web/.env
```

Preencher:

```env
# OBRIGATORIOS
API_BASE_URL=https://social-care-hml.acdgbrasil.com.br      # Backend Swift/Vapor
PEOPLE_CONTEXT_BASE_URL=https://social-care-hml.acdgbrasil.com.br  # People Context API
OIDC_ISSUER=https://auth.acdgbrasil.com.br                  # Zitadel IdP
OIDC_CLIENT_ID=<confidential-client-id>                      # App Confidential no Zitadel
OIDC_CLIENT_SECRET=<client-secret>                           # Secret do client
OIDC_REDIRECT_URI=http://localhost:8081/auth/callback         # Callback do BFF
SESSION_SECRET=<gerar-com-openssl-rand-hex-32>               # HMAC key para cookies

# OPCIONAIS
PORT=8081
HOST=0.0.0.0
SESSION_TTL_MINUTES=60
```

**Gerar SESSION_SECRET:**
```bash
openssl rand -hex 32
```

**OIDC_REDIRECT_URI muda conforme o modo:**
- BFF standalone: `http://localhost:8081/auth/callback`
- Atras do Caddy (compose): `http://localhost/api/auth/callback`

### 2.2 Shell App Flutter (.env)

**Arquivo:** `apps/acdg_system/.env`

Para **Desktop nativo** (Flutter direto, sem BFF web):
```env
OIDC_ISSUER=https://auth.acdgbrasil.com.br
OIDC_CLIENT_ID=<public-client-id-desktop>
OIDC_SCOPES=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud
BFF_BASE_URL=http://localhost:8081
SENTRY_DSN=<opcional>
APP_ENV=dev
```

Para **Web** (via BFF): usar `apps/acdg_system/.env.web`
```env
OIDC_ISSUER=https://auth.acdgbrasil.com.br
OIDC_CLIENT_ID=367349956392059030
OIDC_SCOPES=openid profile email offline_access urn:zitadel:iam:org:project:id:363109883022671995:aud
BFF_BASE_URL=http://localhost:8081
SENTRY_DSN=<opcional>
APP_ENV=dev
```

**Diferenca critica Desktop vs Web:**
- Desktop: usa OIDC PKCE diretamente (public client), tokens em flutter_secure_storage
- Web: delega auth ao BFF (confidential client), tokens NUNCA saem do servidor

### 2.3 Docker Producao (.env.prod.local)

**Arquivo:** `.env.prod.local` (raiz do projeto)

Ja existe pre-configurado para simulacao local. Usado pelos `docker-compose.prod.yml` e `docker-compose.full.yml`.

---

## 3. Modos de Execucao

### MODO A — Desktop Nativo (Desenvolvimento Local)

**Quando usar:** Desenvolvimento do app Flutter com hot reload nativo. Sem BFF web (usa OIDC PKCE direto).

```bash
cd apps/acdg_system
flutter run -d macos --dart-define-from-file=.env
```

- Hot reload automatico (R no terminal)
- Sem Docker, sem BFF web
- Auth via OIDC PKCE direto (public client)
- Offline-first com Isar database local

**Variantes de plataforma:**
```bash
flutter run -d macos --dart-define-from-file=.env   # macOS
flutter run -d windows --dart-define-from-file=.env  # Windows
flutter run -d linux --dart-define-from-file=.env    # Linux
```

---

### MODO B — BFF Local + Flutter Web Hot Reload (RECOMENDADO PARA WEB DEV)

**Quando usar:** Desenvolvimento web com hot reload do Flutter E BFF rodando em Docker. Melhor DX para web.

**Topologia:**
```
Flutter dev server (host:8080) ─┐
                                ├── Caddy proxy (:80) ── Browser
BFF Docker (container:8081) ────┘
```

**Passo 1 — Subir BFF + Caddy proxy:**
```bash
# Na raiz do projeto
docker compose --profile hotreload up --build
```

Isso sobe dois containers:
- `bff` — Dart JIT, le `bff/social_care_web/.env`
- `proxy` — Caddy que roteia `/api/*` para o BFF e `/*` para o Flutter dev server local

**Passo 2 — Rodar Flutter Web com hot reload:**
```bash
# Em outro terminal
cd apps/acdg_system
flutter run -d web-server --web-port=8080 --dart-define-from-file=.env.web
```

**Acessar:** `http://localhost` (porta 80 do Caddy)

**Como funciona o proxy (Caddyfile.hotreload):**
- `http://localhost/api/*` → `bff:8081` (container Docker)
- `http://localhost/*` → `host.docker.internal:8080` (Flutter dev server local)
- WebSocket proxied para hot reload funcionar

**Se a porta do Flutter nao for 8080:**
```bash
FLUTTER_PORT=9090 docker compose --profile hotreload up --build
# E rodar Flutter com --web-port=9090
```

---

### MODO C — BFF Local (Dart JIT, sem Docker)

**Quando usar:** Debugar o BFF direto no host, sem Docker.

```bash
cd bff/social_care_web
dart run bin/server.dart
```

- Porta: `8081` (default, configuravel via .env)
- Necessita `.env` preenchido
- Hot restart manual (Ctrl+C + rerun)
- Usa JIT — startup rapido, bom para debug

---

### MODO D — Docker Compose Dev (BFF + Flutter WASM)

**Quando usar:** Testar o build WASM completo com BFF, sem hot reload do Flutter (rebuild a cada mudanca).

```bash
# Subir tudo
docker compose up web --build

# Em outro terminal, ativar watch para auto-rebuild
docker compose watch
```

**Containers:**
- `bff` — Dart JIT (Dockerfile.bff.dev)
- `web` — Flutter WASM build + Caddy (Dockerfile.web + Caddyfile.dev)

**Watch behaviors:**
| Mudanca em | Acao | Tempo |
|-----------|------|-------|
| `bff/` | sync + restart (JIT) | ~2s |
| `packages/` | sync + restart BFF / rebuild Web | ~2s / ~3min |
| `apps/` | rebuild Web (WASM completo) | ~3min |
| `Caddyfile.dev` | sync + restart Caddy | ~1s |

**Acessar:** `http://localhost` (porta 80)
- `/api/*` → BFF (port-stripping via `handle_path`)
- `/*` → Flutter WASM SPA

**NOTA:** O build WASM demora ~3 minutos. Para desenvolvimento web iterativo, prefira o **MODO B** (hot reload).

---

### MODO E — Producao Minimal (2 containers)

**Quando usar:** Simular producao com topologia minima. BFF AOT compilado, Flutter WASM servido pelo Caddy.

```bash
docker compose -f docker-compose.prod.yml up --build
```

**Containers:**
- `bff` — Dart AOT (distroless, ~20MB) — `Dockerfile.bff`
- `web` — Caddy + Flutter WASM — `Dockerfile.web` + `Caddyfile.prod`

**Topologia:**
```
Browser --> Caddy (:80)
              |
              +-- /api/*  --> bff:8081 (rede interna, nao exposto ao host)
              +-- /*      --> arquivos WASM estaticos
```

**Seguranca (Caddyfile.prod):**
- HSTS, X-Content-Type-Options: nosniff, X-Frame-Options: DENY
- Cross-Origin-Embedder-Policy: credentialless (WASM multi-thread)
- Cross-Origin-Opener-Policy: same-origin
- Health check no BFF a cada 10s
- Cache agressivo para assets estaticos, no-store para codigo Flutter

**Acessar:** `http://localhost`

**Rede:** Bridge interna `internal` — BFF so acessivel pelo Caddy, nao pelo host.

---

### MODO F — Producao Completa (3 containers)

**Quando usar:** Simular a topologia de producao real com gateway, site estatico, app Flutter e BFF separados.

```bash
docker compose -f docker-compose.full.yml up --build
```

**Containers:**
| Container | Dockerfile | Porta exposta | Funcao |
|-----------|-----------|--------------|--------|
| `site` | Dockerfile.site | :80 (unico exposto) | Gateway Caddy + landing pages |
| `app` | Dockerfile.web (BASE_HREF=/app/) | Interna | Flutter WASM |
| `bff` | Dockerfile.bff | Interna | Dart AOT server |

**Topologia:**
```
Browser --> site (Caddy Gateway :80)
              |
              +-- /api/*   --> bff:8081  (auth, session, proxy)
              +-- /app/*   --> app:80    (Flutter WASM)
              +-- /*       --> /srv/site (landing pages HTML)
```

**Rotas do gateway (Caddyfile.gateway):**
- `/api/*` → BFF com health check + X-Real-IP
- `/app/*` → Flutter WASM (Caddy interno)
- `/cache-invalidate` → Endpoint de cache busting
- `/healthz` → Health check do gateway
- `/*` → Site estatico (landing pages)

**Acessar:**
- `http://localhost` — Landing page
- `http://localhost/app/` — Flutter app
- `http://localhost/api/health/live` — BFF health

**NOTA:** O Flutter app usa `BASE_HREF=/app/` neste modo — GoRouter e assets funcionam com esse prefixo.

---

## 4. Tabela Resumo

| Modo | Comando | Hot Reload? | Docker? | Containers | Porta |
|------|---------|:-----------:|:-------:|:----------:|:-----:|
| A — Desktop | `flutter run -d macos` | Sim | Nao | 0 | N/A |
| B — Web Hot Reload | `docker compose --profile hotreload up` + `flutter run -d web-server` | Sim | Parcial | 2 | :80 |
| C — BFF Local | `dart run bin/server.dart` | Nao (manual) | Nao | 0 | :8081 |
| D — Docker Dev | `docker compose up web` + `docker compose watch` | Nao (rebuild) | Sim | 2 | :80 |
| E — Prod Minimal | `docker compose -f docker-compose.prod.yml up` | Nao | Sim | 2 | :80 |
| F — Prod Completa | `docker compose -f docker-compose.full.yml up` | Nao | Sim | 3 | :80 |

---

## 5. Combinacoes Comuns

### "Quero desenvolver a UI web com hot reload"
→ **MODO B**: BFF no Docker + Flutter web-server local

### "Quero desenvolver o app desktop"
→ **MODO A**: `flutter run -d macos`

### "Quero debugar o BFF"
→ **MODO C**: `dart run bin/server.dart` (com breakpoints no IDE)

### "Quero testar se o build WASM funciona"
→ **MODO D** ou **MODO E**

### "Quero simular producao antes de deploy"
→ **MODO F**: 3 containers, topologia real

### "Quero rodar so os testes"
→ Nenhum modo acima. Usar:
```bash
melos run test        # Todos os packages
melos run analyze     # Lint
flutter test          # Package especifico (dentro do diretorio)
dart test             # BFF (dentro de bff/social_care_web/)
```

---

## 6. Dockerfiles — O Que Cada Um Faz

### Dockerfile.bff (Producao)
- **Stage 1:** Flutter image → resolve deps → code gen (build_runner) → `dart compile exe` (AOT)
- **Stage 2:** `distroless/base-debian12:nonroot` → copia binario (~20MB final)
- Sem shell, sem ferramentas — so o binario

### Dockerfile.bff.dev (Desenvolvimento)
- Imagem unica Flutter → resolve deps → code gen → `dart run` (JIT)
- Mais rapido para iniciar, permite restart sem recompilar

### Dockerfile.web (Flutter WASM)
- **Stage 1:** Flutter image → resolve deps → code gen → `flutter build web --wasm` → cache busting (query params)
- **Stage 2:** `caddy:2-alpine` → copia `build/web/` → Caddyfile embutido
- `BASE_HREF` arg: `/` (standalone) ou `/app/` (atras do gateway)

### Dockerfile.site (Gateway)
- `caddy:2-alpine` → copia `site/` → entrypoint script que injeta config runtime
- Leve, so serve HTML/CSS/JS estatico

---

## 7. Caddyfiles — Roteamento por Modo

| Arquivo | Usado por | `/api/*` | `/*` |
|---------|----------|---------|------|
| Caddyfile.dev | docker-compose.yml (web) | → bff:8081 | Flutter WASM (local) |
| Caddyfile.hotreload | docker-compose.yml (proxy) | → bff:8081 | → host.docker.internal:8080 |
| Caddyfile.prod | docker-compose.prod.yml | → bff:8081 + health check | Flutter WASM + security headers |
| Caddyfile.gateway | docker-compose.full.yml | → bff:8081 + health check | `/app/*` → app:80, `/*` → static site |

---

## 8. Troubleshooting

### "Port 80 already in use"
Outro processo (Apache, nginx, outro container) usando porta 80.
```bash
lsof -i :80  # Descobrir quem esta usando
```

### "OIDC callback falha"
Verificar `OIDC_REDIRECT_URI`:
- BFF direto: `http://localhost:8081/auth/callback`
- Atras do Caddy: `http://localhost/api/auth/callback`
- Deve bater EXATAMENTE com o configurado no Zitadel

### "WASM nao carrega (SharedArrayBuffer error)"
Flutter WASM multi-thread precisa de headers COEP/COOP. Todos os Caddyfiles ja incluem:
```
Cross-Origin-Embedder-Policy: credentialless
Cross-Origin-Opener-Policy: same-origin
```
Se servir de outro lugar, adicionar esses headers.

### "melos bootstrap falha"
```bash
dart pub global activate melos  # Instalar/atualizar melos
melos bootstrap                  # Tentar novamente
```

### "build_runner falha"
```bash
# Limpar cache de build_runner
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### "Docker compose watch nao detecta mudancas"
Docker Compose v2.22+ necessario para `watch`. Verificar versao:
```bash
docker compose version
```

---

## 9. Variaveis de Ambiente — Referencia Completa

### BFF (runtime, via .env ou env vars)

| Variavel | Obrigatoria | Default | Descricao |
|---------|:-----------:|---------|-----------|
| `API_BASE_URL` | Sim | — | URL do backend Swift/Vapor |
| `PEOPLE_CONTEXT_BASE_URL` | Sim | — | URL do People Context service |
| `OIDC_ISSUER` | Sim | — | URL do Zitadel (ex: https://auth.acdgbrasil.com.br) |
| `OIDC_CLIENT_ID` | Sim | — | ID do Confidential Client no Zitadel |
| `OIDC_CLIENT_SECRET` | Sim | — | Secret do Confidential Client |
| `OIDC_REDIRECT_URI` | Sim | — | Callback URL do BFF |
| `SESSION_SECRET` | Sim | — | HMAC key para assinar cookies (min 32 hex chars) |
| `PORT` | Nao | 8081 | Porta HTTP do BFF |
| `HOST` | Nao | 0.0.0.0 | Bind address |
| `SESSION_TTL_MINUTES` | Nao | 60 | Duracao da sessao em minutos |
| `POST_LOGIN_REDIRECT_URL` | Nao | — | URL pos-login (usado em prod) |

### Shell App Flutter (compile-time, via --dart-define-from-file)

| Variavel | Obrigatoria | Default | Descricao |
|---------|:-----------:|---------|-----------|
| `OIDC_ISSUER` | Sim | — | URL do Zitadel |
| `OIDC_CLIENT_ID` | Sim | — | ID do client (public para desktop, web para browser) |
| `OIDC_SCOPES` | Nao | openid profile email | Scopes OIDC |
| `BFF_BASE_URL` | Sim | — | URL do BFF (desktop: http://localhost:8081, web: /api) |
| `SENTRY_DSN` | Nao | — | DSN do Sentry para error tracking |
| `APP_ENV` | Nao | dev | Ambiente (dev, production) |

### Docker Build Args (Dockerfile.web, compile-time)

| Arg | Default | Descricao |
|-----|---------|-----------|
| `BASE_HREF` | `/` | Base path do Flutter (usar `/app/` atras de gateway) |
| `OIDC_WEB_REDIRECT_URI` | — | Redirect URI para web (ex: http://localhost/auth/callback) |
| `OIDC_WEB_POST_LOGOUT_URI` | — | URL pos-logout web |
| `SENTRY_RELEASE` | — | Release tag para Sentry |
| `SENTRY_DIST` | — | Distribution tag para Sentry |

---

## 10. Fluxo de Auth por Modo

### Desktop (MODO A)
```
Flutter → OIDC PKCE (public client) → Zitadel → Token em flutter_secure_storage
Flutter → API call com Bearer token direto ao backend
```

### Web (MODOS B-F)
```
Browser → GET /api/auth/login → BFF inicia OIDC (confidential client) → Zitadel
Zitadel → callback → BFF recebe tokens → armazena em SessionStore (memoria)
BFF → Set-Cookie: __Host-session=<opaque-id> (HttpOnly, Secure, SameSite=Strict)
Browser → GET /api/patients (cookie vai automatico) → BFF injeta Bearer token → Backend
```

O browser **NUNCA** ve o JWT. O BFF e o "Iron Frontier".
