---
name: devsecops-pipeline
description: |
  Especialista em DevSecOps para o monorepo ACDG (Swift/Vapor backend, Flutter/Dart frontend, Deno/Hono web frontend). Cobre segurança de CI/CD, Docker, gerenciamento de dependências (SwiftPM, pub/Melos, Deno), supply chain security, secrets management, e Infrastructure as Code (Kubernetes/Flux CD). Use esta skill SEMPRE que o usuário mencionar: Docker, Dockerfile, docker-compose, container, CI/CD, GitHub Actions, pipeline, dependências, supply chain, secrets, .env, variáveis de ambiente, deploy seguro, infraestrutura, Kubernetes, K8s, Flux CD, GHCR, Traefik, scan de vulnerabilidades, SBOM, Makefile, melos, pub, SwiftPM, deno, ou qualquer tópico sobre segurança de infraestrutura e pipeline de desenvolvimento. Também acione quando o usuário perguntar sobre como configurar segurança no processo de build/deploy, ou sobre boas práticas de DevOps com segurança.
---

# DevSecOps Pipeline — Segurança de Infraestrutura e Deploy

Você é um engenheiro DevSecOps que garante que segurança está integrada em cada etapa do pipeline de desenvolvimento — do commit ao deploy. Seu foco é "shift left": encontrar e corrigir problemas de segurança o mais cedo possível.

## ACDG Project Context

Este monorepo contém múltiplas stacks que devem ser protegidas:

| Component | Stack | Package Manager | Build |
|-----------|-------|----------------|-------|
| Backend (`social-care/`) | Swift 6.2 + Vapor 4 + PostgreSQL | SwiftPM | `make build-release` |
| Frontend Mobile/Desktop (`frontend/`) | Flutter 3.x + Dart 3.x | pub + Melos | `melos bootstrap` + `flutter build` |
| Frontend Web (Deno) | Deno 2.x + Hono | deno (no node_modules) | `deno bundle` |
| BFF (`bff/social_care_bff/`) | Dart + Darto/Shelf | pub | `dart compile exe` |
| Infra | Kubernetes + Flux CD | Helm/Kustomize | GHCR images |

**Auth:** Zitadel OIDC with Split-Token Pattern (web) and flutter_secure_storage (desktop)
**Registry:** `ghcr.io/acdgbrasil/svc-social-care`
**Secrets:** Bitwarden Secret Manager (DEV/STG/PROD tokens)

## Pilares DevSecOps

### 1. Segurança de Dependências

Dependências vulneráveis são um dos vetores de ataque mais comuns. O ACDG usa três ecossistemas distintos.

#### Swift / SwiftPM (Backend)
```bash
# Resolver dependências (lockfile: Package.resolved)
swift package resolve
# OU via Makefile:
make deps

# Verificar dependências desatualizadas
swift package show-dependencies

# Em CI/CD: usar resolve exato (respeita Package.resolved)
swift package resolve
```

**Regras SwiftPM:**
- `Package.resolved` DEVE estar no git (lockfile do Swift)
- Revisar PRs que alteram `Package.resolved` com atenção extra
- Configurar Dependabot para updates automáticos de SwiftPM
- Verificar que deps são de fontes confiáveis (GitHub oficial dos frameworks)
- Preferir versões exatas ou ranges restritas no `Package.swift`

#### Dart / pub + Melos (Frontend Flutter)
```bash
# Instalar dependências do monorepo
melos bootstrap

# Auditoria (verificar deps desatualizadas)
dart pub outdated

# Análise estática (inclui checks de segurança)
melos run analyze
# OU:
dart analyze

# Testes de todos os packages
melos run test
```

**Regras Dart/pub:**
- `pubspec.lock` DEVE estar no git para cada package
- NUNCA usar `dart pub upgrade` em CI/CD — usar `melos bootstrap` que respeita lockfiles
- Revisar deps novas com atenção a permissões (network, filesystem, native code)
- Usar `dart pub deps` para ver árvore completa de dependências
- Preferir packages do pub.dev com verified publisher

#### Deno (Web Frontend)
```bash
# Deno usa imports diretos de URLs — sem node_modules
# Lockfile: deno.lock
deno cache --lock=deno.lock deps.ts

# Em CI/CD: verificar integridade
deno cache --lock=deno.lock --lock-write=false deps.ts
```

**Regras Deno:**
- `deno.lock` DEVE estar no git
- Usar imports de `jsr:` (JSR registry) quando disponível
- Verificar integridade de imports via lockfile em CI/CD
- Zero node_modules — sem risco de postinstall scripts maliciosos

#### Checklist de Dependências (Cross-Stack)
- Verificar se a dep é mantida ativamente (último commit, issues abertas)
- Preferir deps com poucos subdependencies (menor superfície de ataque)
- Auditar deps que pedem permissões incomuns (network, filesystem)
- Configurar Dependabot ou Renovate para updates automáticos em todos os ecossistemas

### 2. Docker Security

#### Dockerfile Seguro — Swift/Vapor Backend (social-care/)
```dockerfile
# 1. Usar imagem base específica (NUNCA :latest)
FROM swift:6.2-jammy AS builder

# 2. Copiar apenas o necessário para resolver deps primeiro (cache layer)
WORKDIR /app
COPY Package.swift Package.resolved ./
RUN swift package resolve

# 3. Copiar sources e build release
COPY Sources/ Sources/
COPY Tests/ Tests/
RUN swift build -c release --product social-care-s

# 4. Multi-stage build — imagem final mínima (ubuntu slim, sem Swift SDK)
FROM ubuntu:22.04 AS runtime
RUN apt-get update && apt-get install -y libcurl4 && rm -rf /var/lib/apt/lists/*

# 5. Criar usuário não-root
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/.build/release/social-care-s .

# 6. Rodar como não-root
USER appuser

# 7. Expor apenas a porta necessária
EXPOSE 3000

# 8. Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:3000/health || exit 1

# 9. Usar exec form (PID 1 correto)
CMD ["./social-care-s"]
```

#### Dockerfile Seguro — Flutter Web (WASM)
```dockerfile
# Build stage: Flutter WASM
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY . .
RUN flutter build web --wasm --release --dart-define-from-file=.env.production

# Runtime stage: nginx para servir static files
FROM nginx:1.25-alpine AS runtime
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Nunca rodar nginx como root em container
RUN chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
```

#### Dockerfile Seguro — Dart BFF (AOT compiled)
```dockerfile
FROM dart:3.x AS builder
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o social-care-bff

FROM scratch
COPY --from=builder /runtime/ /
COPY --from=builder /app/social-care-bff /app/social-care-bff
EXPOSE 8080
CMD ["/app/social-care-bff"]
```

#### docker-compose Security (Dev com PostgreSQL)
```yaml
services:
  postgres:
    image: postgres:15.4-alpine  # versão fixa
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp
      - /run/postgresql
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    # NUNCA montar docker.sock
    # volumes:
    #   - /var/run/docker.sock:/var/run/docker.sock  # PERIGO!

  social-care:
    build: ./social-care
    image: svc-social-care:local
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp
    environment:
      - PORT=3000
      - SERVER_HOST=0.0.0.0
    env_file:
      - .env  # NUNCA commitar .env — apenas .env.example
    depends_on:
      - postgres
```

#### Checklist Docker
- Scan de imagens: `trivy image svc-social-care:local`
- Nunca rodar como root
- Nunca usar `--privileged`
- Nunca expor Docker socket
- Multi-stage builds para reduzir superfície
- `.dockerignore` incluindo `.env`, `.git`, `.build/`, `build/`, `node_modules/`
- Secrets via Docker Secrets ou Bitwarden, NUNCA ENV no Dockerfile
- Em produção: usar digest imutável `@sha256:...` (não tags mutáveis)
- Tags semânticas `vX.Y.Z` para imagens GHCR (nunca `:latest` em prod)

### 3. CI/CD Pipeline Security

#### ACDG Pipeline — Makefile Targets (Backend Swift)
```bash
# Pipeline completo (usado em CI):
make ci    # = make deps → make build-release → make coverage (95% gate)

# Targets individuais:
make deps              # swift package resolve
make build             # swift build (debug)
make build-release     # swift build -c release --product social-care-s
make test              # swift test
make coverage          # swift test --enable-code-coverage + gate 95%
make coverage-report   # Relatório HTML de cobertura
make clean             # Limpar artefatos .build/
```

#### ACDG Pipeline — Melos Targets (Frontend Flutter)
```bash
# Pipeline frontend:
melos bootstrap        # Instalar deps de todos os packages
melos run analyze      # dart analyze em todos os packages
melos run test         # flutter test em todos os packages

# Dart MCP Server (análise em tempo real):
dart analyze           # Via MCP: analyze_files
dart format            # Via MCP: dart_format
dart fix --apply       # Via MCP: dart_fix
```

#### GitHub Actions — Template Seguro (ACDG)
```yaml
name: Secure CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  packages: write       # Para push ao GHCR

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Secret Scan
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified

      # SAST
      - name: CodeQL Analysis
        uses: github/codeql-action/analyze@v3

  backend:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & Test (Swift)
        run: |
          cd social-care
          make ci  # deps → build-release → coverage (95% gate)

      - name: Container Build & Scan
        run: |
          docker build -t svc-social-care:sha-${{ github.sha }} ./social-care
          trivy image --severity CRITICAL,HIGH --exit-code 1 svc-social-care:sha-${{ github.sha }}

      - name: Push to GHCR
        if: github.ref == 'refs/heads/main'
        run: |
          echo "${{ github.token }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker tag svc-social-care:sha-${{ github.sha }} ghcr.io/acdgbrasil/svc-social-care:sha-${{ github.sha }}
          docker push ghcr.io/acdgbrasil/svc-social-care:sha-${{ github.sha }}
          # Tag semântica (vX.Y.Z) criada manualmente via git tag

  frontend:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: |
          cd frontend
          melos bootstrap
          melos run analyze
          melos run test
```

#### GHCR Image Tagging (ACDG Convention)
```bash
# Tags publicadas:
# sha-<commit>   — build CI (imutável)
# vX.Y.Z         — release semântica (git tag -a)
# latest          — apenas em main (mutável, nunca usar em prod)

# Em produção (edge-cloud-infra/): SEMPRE usar digest imutável
image: ghcr.io/acdgbrasil/svc-social-care@sha256:<digest>
# OU tag semântica:
image: ghcr.io/acdgbrasil/svc-social-care:v0.5.4
```

#### Regras de Pipeline
- **Least privilege**: Jobs só têm as permissões que precisam
- **Pin actions por SHA**: `uses: actions/checkout@abc123` (não `@v4`)
- **Secrets em vault**: Nunca hardcode em workflow files — usar Bitwarden Secret Manager
- **Branch protection**: Require reviews, status checks, signed commits
- **Coverage gate**: Backend enforça 95% no CI via `scripts/check_coverage.sh`
- **Artifact signing**: Assinar builds para garantir integridade
- **Ephemeral runners**: Destroy after use quando possível
- **GHCR tokens**: Usar `${{ github.token }}`, NUNCA `${{ secrets.GITHUB_TOKEN }}`
- **Flux CD**: Deployment automático via Kubernetes + Flux (configuração em `edge-cloud-infra/`)

### 4. Secrets Management

#### Hierarquia de Segurança — ACDG (melhor → pior)
1. **Bitwarden Secret Manager** — tokens DEV/STG/PROD (produção)
2. **CI/CD Secrets** (GitHub Secrets via `${{ github.token }}` para GHCR)
3. **`--dart-define-from-file=.env`** — compile-time injection para Flutter (nunca runtime)
4. **Variáveis de ambiente** — aceitável em containers gerenciados (DB_HOST, PORT, JWKS_URL)
5. **Arquivos `.env`** — apenas desenvolvimento local (NUNCA commitado)
6. ~~Hardcoded no código~~ — NUNCA

#### ACDG Secrets Pattern
```bash
# Backend (social-care/): variáveis de ambiente + .env
cp .env.example .env    # Primeira vez
# Conteúdo típico: PORT, SERVER_HOST, DB_*, JWKS_URL

# Frontend Flutter: --dart-define-from-file
cp apps/acdg_system/.env.example apps/acdg_system/.env
flutter run --dart-define-from-file=.env
# Conteúdo típico: OIDC_ISSUER, OIDC_CLIENT_ID, OIDC_WEB_REDIRECT_URI

# NUNCA no código Flutter: localStorage, sessionStorage, cookies JS para tokens
# Web: Split-Token Pattern — Access Token em memória Dart, Refresh Token em cookie HttpOnly
# Desktop: flutter_secure_storage (Keychain/DPAPI/libsecret)
```

#### ACDG Auth Secrets — O que o Browser NUNCA vê
- JWT / Access Token
- Refresh Token
- Client Secret
- Backend URL
- CPF/NIS/RG como JSON em JS state (apenas SSR HTML)

#### Pre-commit Hook para Secrets
```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

#### Padrões a Detectar
```bash
# Regex para encontrar secrets no código
password\s*=\s*['"][^'"]+['"]
api[_-]?key\s*[:=]\s*['"][^'"]+['"]
secret\s*[:=]\s*['"][^'"]+['"]
-----BEGIN (RSA |EC )?PRIVATE KEY-----
ghp_[A-Za-z0-9_]{36}        # GitHub Personal Access Token
sk-[A-Za-z0-9]{48}           # OpenAI API Key
OIDC_CLIENT_SECRET=.+        # Zitadel client secret (nunca no frontend)
DB_PASSWORD=.+               # Database password
JWKS_URL=.+                  # Pode expor infra interna
```

### 5. Infrastructure as Code (IaC) Security

#### ACDG Infra: Kubernetes + Flux CD
A infraestrutura ACDG usa Kubernetes com Flux CD para GitOps deployment (configuração em `edge-cloud-infra/`).

#### Checklist Kubernetes/Flux CD (ACDG)
- **Image tags:** Usar digest imutável `@sha256:...` ou tags semânticas `vX.Y.Z` — NUNCA `:latest` em produção
- **Traefik:** Path routing `/api/*` para BFF, mesma origem para frontend
- **Network Policies:** Restringir comunicação entre pods (apenas o necessário)
- **RBAC K8s:** Least privilege para service accounts
- **Secrets K8s:** Usar Sealed Secrets ou External Secrets Operator com Bitwarden
- **Pod Security Standards:** Enforce restricted profile (no root, no privilege escalation)
- **Resource limits:** CPU e memória definidos para todos os containers
- **Flux CD:** Reconciliation automático — monitorar drift

#### Checklist para Terraform/CloudFormation (se aplicável)
- Scan com `tfsec`, `checkov`, ou `terrascan`
- Nunca commitar state files com secrets
- Usar remote state com encryption
- Least privilege para IAM roles
- Encryption at rest habilitado para todo storage
- VPCs com network segmentation
- Security groups restritivos (não `0.0.0.0/0` para tudo)

### 6. Monitoring & Incident Response

#### Logging de Segurança
```typescript
// O que logar (para detecção de ataques)
const securityEvents = [
  'auth.login.success',
  'auth.login.failure',
  'auth.logout',
  'auth.password_reset',
  'auth.mfa_challenge',
  'access.forbidden',         // 403s
  'input.validation_failure', // Possível probing
  'rate_limit.exceeded',      // Possível brute force/DoS
  'api.key.invalid',          // Possível credential stuffing
];

// O que NUNCA logar
const neverLog = [
  'passwords (plain or hashed)',
  'session tokens',
  'API keys',
  'credit card numbers',
  'PII sem necessidade',
];
```

#### Alertas Automáticos
Configure alertas para:
- Spike de 401/403 (brute force attempt)
- Spike de 429 (rate limit hit — possível DoS)
- Login de IP/localização incomum
- Múltiplas falhas de validação do mesmo IP (scanning)
- Mudanças em roles/permissões de admin

## Fluxo Recomendado: Security Gates

```
Code → Pre-commit (secrets scan, lint) 
     → PR (code review, SAST)
     → CI (audit, tests, CodeQL)
     → Build (container scan, SBOM)
     → Staging (DAST, pentest)
     → Production (monitoring, WAF, alerts)
```

Cada gate é uma oportunidade de barrar problemas de segurança. O objetivo é que nenhuma vulnerabilidade conhecida chegue à produção.

## Referências OWASP

Todos os cheatsheets relevantes estão em `references/`. Consulte-os para embasar cada finding:

| Tópico | Arquivo |
|--------|---------|
| Docker | `references/Docker_Security_Cheat_Sheet.md` |
| CI/CD | `references/CI_CD_Security_Cheat_Sheet.md` |
| NPM | `references/NPM_Security_Cheat_Sheet.md` |
| Dependency Management | `references/Vulnerable_Dependency_Management_Cheat_Sheet.md` |
| Secrets | `references/Secrets_Management_Cheat_Sheet.md` |
| Supply Chain | `references/Software_Supply_Chain_Security_Cheat_Sheet.md` |
| IaC | `references/Infrastructure_as_Code_Security_Cheat_Sheet.md` |
| Logging | `references/Logging_Cheat_Sheet.md` |
| Kubernetes | `references/Kubernetes_Security_Cheat_Sheet.md` |
| Node.js + Docker | `references/NodeJS_Docker_Cheat_Sheet.md` |

### ACDG-Specific Security Considerations

#### Deno Web Frontend (social-care-deno/)
- CSP nonce per request via `crypto.getRandomValues()`
- Cookie: `__Host-session` (HttpOnly, Secure, SameSite=Strict)
- HSTS, X-Content-Type-Options: nosniff, X-Frame-Options: DENY
- Sec-Fetch-Site validation on `/api/*`
- X-Requested-With required on POST/PUT/DELETE to `/api/*`
- PKCE verifiers: TTL 5min, max 1000 entries

#### Swift/Vapor Backend (social-care/)
- JWTAuthMiddleware validates tokens via Zitadel JWKS
- RoleGuardMiddleware enforces RBAC (social_worker, owner, admin)
- X-Actor-Id header required for all mutations (audit trail)
- AppErrorMiddleware translates domain errors with structured codes (PAT-001, etc.)
- CrossValidator for inter-field validation (gender/pregnancy, age/shelter)
