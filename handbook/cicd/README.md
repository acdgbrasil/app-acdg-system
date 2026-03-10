# CI/CD — frontend (Conecta Raros)

Pipelines, ambientes, deploy e rollback.

---

## 1. Pipeline CI

Executado em todo PR:

```
1. melos bootstrap              # Resolve dependencias do monorepo
2. flutter analyze               # Lint em todos os packages
3. flutter test                  # Testes em todos os packages
4. dart test (bff/)              # Testes do BFF
5. flutter build web --wasm      # Build web (valida compilacao)
```

---

## 2. Pipeline Release (Web)

Executado no merge para `main`:

```
1. CI completo (acima)
2. flutter build web --wasm --release
3. docker build -t conecta-web:sha-<commit>
4. docker push ghcr.io/acdgbrasil/conecta-web:sha-<commit>
5. Tag: latest (apenas main)
6. Tag: vX.Y.Z (quando tag git)
```

### Deploy
- Imagem publicada no GHCR
- FluxCD (Kubernetes) detecta nova imagem e faz rollout no K3s
- Servido via Traefik ingress no Edge server

---

## 3. Pipeline Release (Desktop)

Executado quando tag `vX.Y.Z` e criada:

```
1. CI completo
2. flutter build macos --release
3. flutter build windows --release
4. flutter build linux --release
5. dart compile exe bff/social_care_bff/bin/server.dart  # (se necessario)
6. Publicar artifacts no GitHub Releases
```

### Distribuicao
- macOS: `.dmg` via GitHub Releases
- Windows: `.exe` installer via GitHub Releases
- Linux: `.AppImage` ou `.deb` via GitHub Releases

---

## 4. Pipeline BFF (Web Server)

Executado no merge para `main`:

```
1. dart test bff/social_care_bff/
2. dart compile exe bff/social_care_bff/bin/server.dart -o social-care-bff
3. docker build -t social-care-bff:sha-<commit>
4. docker push ghcr.io/acdgbrasil/social-care-bff:sha-<commit>
5. FluxCD deploy no K3s
```

---

## 5. Ambientes

| Ambiente | Web URL | BFF URL | API URL |
|----------|---------|---------|---------|
| **DEV** | localhost:3000 | localhost:8081 | localhost:8080 |
| **STG** | staging.conecta.acdgbrasil.com.br | staging-bff.acdgbrasil.com.br | staging-api.acdgbrasil.com.br |
| **PROD** | conecta.acdgbrasil.com.br | bff.acdgbrasil.com.br | api.acdgbrasil.com.br |

---

## 6. Rollback

- Web: FluxCD reverte para imagem anterior via digest `@sha256:...`
- Desktop: usuario baixa versao anterior do GitHub Releases
- BFF: FluxCD reverte para imagem anterior

---

## 7. Segredos

Seguindo padrao ACDG:
- NUNCA hardcoded
- Bitwarden Secret Manager para credenciais
- `${{ github.token }}` para GHCR
- Variaveis de ambiente para configuracao runtime
