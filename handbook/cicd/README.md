# CI/CD — frontend (Conecta Raros)

> Pipelines, ambientes, deploy e rollback.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Pipelines de Flutter Web (`conecta_web_image.yml`) e Windows MSIX (`windows_build_msix.yml`) **deletados** junto com `apps/acdg_system/`. Pipeline atual cobre BFF (`apps/social_care_bff/web`) + CI lint/test. Pipeline CLI release (Phase 5 C11) sera adicionado.

---

## 1. Pipeline CI (PRs)

Executado em todo PR via `.github/workflows/ci.yml`:

```
1. melos bootstrap                          # Resolve workspace deps
2. melos run analyze                        # dart analyze --fatal-infos em todos
3. melos run test (Flutter packages)        # flutter test
4. melos run test:dart (Dart-only packages) # dart test
5. dart compile exe (smoke)                 # apps/social_care_bff/web/bin/server.dart
```

Bucket scopes (Melos) podem ser usados para PRs targeted:
- `melos run analyze:kernel` (so kernel/*)
- `melos run analyze:infra` (so infra/*)
- `melos run analyze:bff` (so apps/social_care_bff/*)
- `melos run test:bff` (so testes BFF — ~2036 GREEN baseline)

---

## 2. Pipeline Release BFF Web Server (`apps/social_care_bff/web`)

Executado no merge para `main` via `.github/workflows/social_care_bff_image.yml`:

```
1. CI completo
2. dart compile exe apps/social_care_bff/web/bin/server.dart -o social-care-bff
3. docker build -t social-care-bff:sha-<commit>
4. docker push ghcr.io/acdgbrasil/social-care-bff:sha-<commit>
5. Tag: latest (apenas main)
6. Tag: vX.Y.Z (quando tag git criada)
```

### Deploy
- Imagem publicada no GHCR
- FluxCD (Kubernetes) detecta nova imagem e faz rollout no K3s
- Servido via Traefik ingress no Edge server

---

## 3. Pipeline Release CLI (`apps/cli` — Phase 5 C11)

**Projetado** — ainda nao implementado. Quando C11 fechar:

```
1. CI completo
2. Matrix build (cada OS):
   - macos arm64: dart compile exe -o acdg-macos-arm64
   - macos x64:   dart compile exe -o acdg-macos-x64
   - linux x64:   dart compile exe -o acdg-linux-x64
   - windows x64: dart compile exe -o acdg-windows-x64.exe
3. Anexar binarios a release tag SemVer (v0.1.0 etc)
4. Generate man page + autocomplete bash/zsh
```

### Distribuicao
- GitHub Releases — `https://github.com/acdgbrasil/acdg/releases`
- Homebrew tap (futuro): `brew install acdgbrasil/tap/acdg`
- Apt/yum (futuro): repositorio Debian/RPM

---

## 4. Pipelines descontinuados (D1.C)

Removidos em commit `33626f0` quando `apps/acdg_system/` foi deletado:
- `conecta_web_image.yml` — Flutter Web image build (WASM)
- `windows_build_msix.yml` — Windows MSIX installer

Quando UI Flutter ressuscitar (Phase 6+), pipelines equivalentes vao ser recriados em `.github/workflows/` para o novo app em `apps/social_care_ui/` (ou nome a definir).

---

## 5. Ambientes

| Ambiente | BFF Web URL | API URL (backend Swift) | OIDC Issuer |
|----------|-------------|-------------------------|-------------|
| **DEV (local)** | localhost:3000 | localhost:8080 | https://auth.acdgbrasil.com.br (sempre prod) |
| **STG** | staging-bff.acdgbrasil.com.br | staging-api.acdgbrasil.com.br | https://auth.acdgbrasil.com.br |
| **PROD** | bff.acdgbrasil.com.br | api.acdgbrasil.com.br | https://auth.acdgbrasil.com.br |

Cada ambiente tem **Native app proprio no Zitadel** com client_id distinto (variavel de ambiente `ZITADEL_CLIENT_ID`).

---

## 6. Rollback

- **BFF Web:** FluxCD reverte para imagem anterior via digest `@sha256:...` (config em `edge-cloud-infra/`)
- **CLI:** usuario reinstala versao anterior via `brew install acdgbrasil/tap/acdg@x.y.z` ou download direto do GitHub Releases
- **Future UI Flutter (Phase 6+):** reservado

---

## 7. Segredos

Padrao ACDG:
- **NUNCA hardcoded** em codigo ou pubspec
- **Bitwarden Secret Manager** para credenciais DEV/STG/PROD
- **`${{ github.token }}`** para GHCR (nao `secrets.GITHUB_TOKEN`)
- **Variaveis de ambiente** runtime (BFF web le `OIDC_ISSUER`, `BACKEND_URL`, `JWT_AUDIENCE` em startup)
- **`--dart-define-from-file=.env`** quando UI Flutter ressuscitar (Phase 6+)
- **CLI credentials:** `~/.config/acdg/credentials` chmod 600 (nunca em repo)

---

## 8. Workflows ativos hoje

```
.github/workflows/
├── ci.yml                          # PR lint + test
└── social_care_bff_image.yml       # BFF Web Docker image
```

---

## 9. Referencia cruzada

- [../tooling/README.md](../tooling/README.md) — Dev tools e Melos scripts
- [../process/README.md](../process/README.md) — pipeline TDD 4-agent + DoD
- [../architecture/MONOREPO_LAYOUT.md](../architecture/MONOREPO_LAYOUT.md) — paths atuais
- `edge-cloud-infra/` (repo separado) — manifests Kubernetes/Flux CD
