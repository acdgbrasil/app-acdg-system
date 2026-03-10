# Plano de Implementacao — Frontend ACDG (Conecta Raros)

> **Stack:** Flutter/Dart (Web WASM + Desktop Nativo) | BFF Dart AOT (EDD + DDD) | Isar (Offline)
> **Idioma:** Code EN / UI PT-BR
> **Design:** Figma ACDG (Atomic Design)
> **Padrao:** MVVM + Logic Layer (UseCase) | Estado Atomico (ValueNotifier) | GoF Patterns

---

## Indice

1. [Diagnostico: Ponto de Partida](#1-diagnostico)
2. [Plano de Fases](#2-plano-de-fases)
3. [Fase 1 — Foundation](#fase-1)
4. [Fase 2 — Shell + Auth](#fase-2)
5. [Fase 3 — BFF Social Care](#fase-3)
6. [Fase 4 — Offline Engine](#fase-4)
7. [Fase 5 — Features Social Care](#fase-5)
8. [Fase 6 — Polish + Desktop Build](#fase-6)
9. [Checklist Final](#checklist-final)

---

## 1. Diagnostico

### Backend Disponivel (social-care API)

| Recurso | Endpoints | Status |
|---------|-----------|--------|
| Patient Registry | 8 rotas (CRUD + audit trail) | PRONTO |
| Assessment | 7 rotas (PUT housing, socioeco, work, education, health, community, summary) | PRONTO |
| Protection | 3 rotas (placement, violations, referrals) | PRONTO |
| Care | 2 rotas (appointments, intake) | PRONTO |
| Lookup | 1 rota (13 tabelas de dominio) | PRONTO |
| Health | 2 rotas (/health, /ready) | PRONTO |
| Auth | JWT via Zitadel OIDC + RBAC (social_worker, owner, admin) | PRONTO |

### Frontend

| Item | Status |
|------|--------|
| Codigo Flutter | EM ANDAMENTO (shell + core + auth OIDC) |
| BFF Dart | NAO INICIADO |
| Design System (Figma) | EXISTENTE |
| Design System (codigo) | EM ANDAMENTO (tokens + 8 atoms) |
| Offline Engine | NAO INICIADO |
| CI/CD Frontend | NAO INICIADO |

---

## 2. Plano de Fases

```
FASE 1: Foundation (monorepo + core + design system)      ██████████  100%
FASE 2: Shell + Auth (Zitadel OIDC PKCE)                  ██████████  100%
FASE 3: BFF Social Care (EDD + DDD + Darto)               ░░░░░░░░░░
FASE 4: Offline Engine (Isar + SyncQueue + CRDT)           ░░░░░░░░░░
FASE 5: Features Social Care (12 features MVVM)            ░░░░░░░░░░
FASE 6: Polish + Desktop Build + CI/CD                     ░░░░░░░░░░
                                                           ──────────
                                                           Progresso: ~28%
```

---

## FASE 1 — Foundation

Setup do monorepo Flutter com packages compartilhados.

### Entregaveis

- [x] Monorepo com Melos (config em `pubspec.yaml`, Melos 7.x)
- [x] `shell/` — app Flutter com `main.dart`, GoRouter, Provider
- [x] `packages/core/` — network (Dio), platform resolver, base classes
  - [x] `Result<T>` (Success/Failure) para error handling — 13 testes
  - [x] `BaseViewModel` com dispose automatico — 4 testes
  - [x] `BaseUseCase<Input, Output>`
  - [x] `DioClient` com interceptors (auth token, retry, logging)
  - [x] `PlatformResolver` (isDesktop, isWeb, isMobile)
  - [x] `ConnectivityService` (online/offline listener)
- [x] `packages/design_system/` — tokens do Figma + atoms base
  - [x] Tokens: cores (Figma), tipografia (Inter/Space Grotesk/Erode), spacing, radius, shadows
  - [x] Atoms: AcdgButton, AcdgTextField, AcdgText, AcdgIcon, AcdgCard, AcdgCheckbox, AcdgRadioGroup, AcdgDropdown — 51 testes
  - [x] Cells: AcdgFormField (label + input + error), AcdgInfoCard — 16 testes
  - [x] Templates: FormLayoutTemplate, PageScaffoldTemplate — 10 testes
- [x] `analysis_options.yaml` compartilhado (lint rules)
- [x] `.gitignore` para Flutter

---

## FASE 2 — Shell + Auth

App principal com login e roteamento por roles.

### Entregaveis

- [x] Domain models (core/src/auth/) — 62 testes
  - [x] `AuthRole` — enum com 3 roles, `fromString()`, `fromJwtClaim()`
  - [x] `AuthUser` — modelo imutavel (id, name, email, roles, canWrite, canRead, copyWith)
  - [x] `AuthToken` — modelo imutavel (accessToken, refreshToken, idToken, expiresAt, isExpired)
  - [x] `AuthStatus` — sealed class (Authenticated, Unauthenticated, AuthLoading, AuthError)
  - [x] `AuthService` — interface abstrata (statusStream, login, logout, tryRestoreSession, refreshToken)
- [x] `OidcAuthConfig` — configuracao imutavel do OIDC (issuer, clientId, redirectUri, scopes) — 7 testes
  - [x] Discovery document URI derivado do issuer
  - [x] Default scopes para Zitadel (openid, profile, email, offline_access, roles)
- [x] `OidcAuthService` — implementacao concreta com `package:oidc` (Bdaya-Dev) — 3 testes
  - [x] OIDC Authorization Code + PKCE via `OidcUserManager`
  - [x] Mapeamento de claims JWT para AuthUser/AuthRole
  - [x] Token refresh automatico via `OidcUserManager`
  - [x] Session restore via `OidcUserManager.init()`
  - [x] Login/logout delegados ao OidcUserManager
- [x] `AuthViewModel` (shell/auth/) — 12 testes
  - [x] Estado atomico: `status` (ValueNotifier<AuthStatus>), `user` (ValueNotifier<AuthUser?>), `busy` (ValueNotifier<bool>)
  - [x] Command pattern: `init()`, `login()`, `logout()`, `tryRestoreSession()`
  - [x] ChangeNotifier para GoRouter refreshListenable
- [x] GoRouter configurado — 10 testes
  - [x] Global redirect (auth check por AuthStatus)
  - [x] `requireRole()` guard (RBAC local redirect)
  - [x] `refreshListenable: authViewModel` (reativo a mudancas de auth)
  - [x] Rotas: `/` (splash), `/login`, `/home`
- [x] Role-based routing:
  - [x] `social_worker` -> Social Care (full CRUD)
  - [x] `owner` -> Social Care (read-only)
  - [x] `admin` -> Social Care (read) + Admin area
- [x] Role extraction do JWT (`urn:zitadel:iam:org:project:roles`)
- [x] Telas — 13 testes
  - [x] Splash (logo + loading, GoRouter redireciona)
  - [x] Login (logo, descricao, botao OIDC, banner de erro, loading state)
  - [x] Home (avatar com iniciais, menu popup com email/roles, module cards com permissoes)
- [x] Provider DI setup (main.dart)
  - [x] MultiProvider com ChangeNotifierProvider<AuthViewModel>
  - [x] OidcAuthService configurado com platform-specific redirect URIs
  - [x] AuthService injetavel para testes
- [x] Token storage (via package:oidc + oidc_default_store)
  - [x] Web: Split-Token Pattern (ADR-011) — access token em memoria, refresh em cookie HttpOnly
  - [x] Desktop: flutter_secure_storage (Keychain/DPAPI/libsecret)
- [x] Token refresh silencioso (OidcUserManager auto-refresh)
- [x] Logout com limpeza de tokens
- [x] Splash screen / loading state
- [x] Documentacao atualizada
  - [x] ADR-011: Split-Token Pattern
  - [x] ADR-012: package:oidc
  - [x] ADR-013: Flutter Architecture Guidelines alignment
  - [x] ARCHITECTURE.md secoes 2, 6, 7 reescritas
  - [x] CLAUDE.md atualizado com todas as decisoes

- [x] Configuracao de plataforma
  - [x] macOS entitlements: `network.client` + `network.server`
  - [x] macOS Info.plist: custom URL scheme `com.acdg.conectararos`
  - [x] Zitadel: app type "Native" (PKCE public client)
  - [x] Redirect URIs: `com.acdg.conectararos://callback` (macOS), `http://localhost:0` (Win/Linux)
  - [x] OIDC config via `--dart-define` (nunca hardcoded)
  - [x] Error handling no init (app nao trava se Zitadel indisponivel)
- [x] .gitignore atualizado (macOS Pods, ephemeral, secrets)

**Total Fase 2: 116 testes (81 core + 35 shell)**

**Como buildar:**
```bash
# macOS (debug)
flutter build macos --debug \
  --dart-define=OIDC_ISSUER=https://auth.acdgbrasil.com.br \
  --dart-define=OIDC_CLIENT_ID=363110312318140539

# macOS (run)
flutter run -d macos \
  --dart-define=OIDC_ISSUER=https://auth.acdgbrasil.com.br \
  --dart-define=OIDC_CLIENT_ID=363110312318140539
```

**Nota:** Web precisara de app separado no Zitadel (tipo "Web") com seu proprio Client ID.

---

## FASE 3 — BFF Social Care

Backend for Frontend com EDD + DDD em Dart.

### Entregaveis

- [ ] `bff/social_care_bff/` — package Dart
- [ ] Domain Layer (DDD)
  - [ ] Models imutaveis espelhando a API (Patient, FamilyMember, etc.)
  - [ ] Value Objects (CPF, NIS, CEP — validacao no construtor)
  - [ ] Domain Events (EDD)
- [ ] Application Layer
  - [ ] Commands: RegisterPatient, AddFamilyMember, UpdateHousing, etc.
  - [ ] Queries: GetPatient, GetLookups, GetAuditTrail
  - [ ] SyncManager: reconciliacao de queue offline
- [ ] Infrastructure Layer
  - [ ] `ApiClient` (Dio -> API social-care com Bearer token)
  - [ ] `LocalCache` (Isar para cache de lookups e dados recentes)
- [ ] Interface Layer
  - [ ] `SocialCareBffContract` (interface abstrata)
  - [ ] `InProcessBff` (implementacao para desktop — chamadas Dart diretas)
  - [ ] `DartoServer` (implementacao para web — servidor HTTP)
- [ ] Testes unitarios do domain e application

---

## FASE 4 — Offline Engine

Sistema completo de offline first.

### Entregaveis

- [ ] Isar schemas para:
  - [ ] `SyncAction` (id, timestamp, type, payload, status, retries)
  - [ ] `CachedPatient` (cache local do agregado)
  - [ ] `CachedLookup` (cache de tabelas de dominio)
- [ ] `SyncQueue` — fila ordenada por timestamp
  - [ ] Enqueue: salva acao no Isar com timestamp monotonic + UUID
  - [ ] Dequeue: processa acoes pendentes na ordem
  - [ ] Retry: backoff exponencial em caso de falha
- [ ] `SyncEngine` — orquestrador de sincronizacao
  - [ ] Escuta `ConnectivityService`
  - [ ] Ao reconectar: processa queue via BFF
  - [ ] Reporta progresso (syncing, synced, conflict)
- [ ] Conflict resolution
  - [ ] Merge automatico por campo (campos diferentes = merge)
  - [ ] Conflito de mesmo campo = flag para resolucao manual
  - [ ] UI de resolucao de conflitos
- [ ] Indicador visual de status (online/offline/syncing)
- [ ] Testes unitarios da SyncQueue e SyncEngine

---

## FASE 5 — Features Social Care

12 features seguindo MVVM + Logic Layer. Cada feature com 3 Pages (Desktop/Web/Mobile).

### 5.1 Features por Prioridade

**Prioridade 1 — Fluxo Principal:**

- [ ] `patient_registration` — Cadastro da PR (3 partes: dados pessoais, endereco, composicao familiar)
- [ ] `family_composition` — Composicao familiar + perfil etario
- [ ] `housing_assessment` — Condicoes habitacionais + densidade
- [ ] `lookup` — Servico de tabelas de dominio (compartilhado)

**Prioridade 2 — Avaliacao Social:**

- [ ] `health_status` — Saude, deficiencias, gestantes
- [ ] `work_income` — Trabalho e renda (4 calculos automaticos)
- [ ] `education` — Educacao + vulnerabilidades
- [ ] `socioeconomic` — Situacao socioeconomica + beneficios
- [ ] `community_support` — Rede de apoio comunitario
- [ ] `social_health_summary` — Resumo de saude social

**Prioridade 3 — Protecao e Atendimento:**

- [ ] `protection` — Acolhimento + violencia + encaminhamentos
- [ ] `care` — Atendimentos + ingresso
- [ ] `audit_trail` — Historico de eventos (read-only)

### 5.2 Checklist por Feature

Para cada feature acima:
- [ ] Models (schemas imutaveis)
- [ ] Service (Dio wrapper)
- [ ] Repository (interface + impl)
- [ ] UseCase
- [ ] ViewModel (ChangeNotifier + ValueNotifier)
- [ ] Desktop Page
- [ ] Web Page
- [ ] Mobile Page
- [ ] Components (atoms/cells reutilizaveis)
- [ ] Testes (ViewModel + UseCase)
- [ ] Funciona offline

---

## FASE 6 — Polish + Desktop Build

Finalizacao, builds nativos e CI/CD.

### Entregaveis

- [ ] Desktop builds:
  - [ ] macOS (.dmg)
  - [ ] Windows (.exe installer)
  - [ ] Linux (.AppImage)
- [ ] BFF embarcado no desktop (in-process + Isar local)
- [ ] CI pipeline:
  - [ ] `flutter analyze` em todo PR
  - [ ] `flutter test` em todo PR
  - [ ] `dart test` (BFF) em todo PR
  - [ ] Build web WASM no merge para main
  - [ ] Build desktop artifacts na tag
- [ ] Docker:
  - [ ] Dockerfile para web (Flutter WASM)
  - [ ] Dockerfile para BFF (Dart AOT)
  - [ ] FluxCD HelmRelease no K3s
- [ ] Performance:
  - [ ] Deferred loading verificado
  - [ ] Bundle size otimizado
  - [ ] Memory profiling
- [ ] Acessibilidade:
  - [ ] Semantics em widgets interativos
  - [ ] Navegacao por teclado (desktop)
  - [ ] Contraste WCAG AA
- [ ] Testes E2E:
  - [ ] Login flow
  - [ ] Cadastro de paciente completo
  - [ ] Sync offline -> online
- [ ] README.md atualizado
- [ ] CHANGELOG.md criado

---

## Checklist Final

Quando TODOS os itens abaixo estiverem marcados, o frontend esta pronto para deploy:

### Foundation
- [x] Monorepo com Melos funcionando
- [x] core package (network, platform, base) — 20 testes passando
- [x] design_system package (tokens + 8 atoms) — 51 testes passando
- [x] design_system cells (AcdgFormField, AcdgInfoCard) — 16 testes passando
- [x] design_system templates (FormLayoutTemplate, PageScaffoldTemplate) — 10 testes passando

### Shell + Auth
- [x] Login com Zitadel OIDC PKCE (OidcAuthService + package:oidc)
- [x] Token storage seguro (Split-Token web, keychain desktop via oidc_default_store)
- [x] Role-based routing (GoRouter global + local redirect)

### BFF
- [ ] Domain layer (DDD) com models e VOs
- [ ] Application layer (commands, queries, sync)
- [ ] Interface dupla (in-process + Darto HTTP)
- [ ] Testes >= 95%

### Offline
- [ ] Isar schemas
- [ ] SyncQueue CRDT-like
- [ ] SyncEngine com auto-sync
- [ ] Conflict resolution (merge + manual)
- [ ] Indicador visual

### Features
- [ ] 12 features Social Care implementadas
- [ ] 3 Pages por feature (Desktop/Web/Mobile)
- [ ] ViewModel testada por feature
- [ ] Funciona offline por feature

### Desktop
- [ ] Build macOS funcionando
- [ ] Build Windows funcionando
- [ ] Build Linux funcionando
- [ ] BFF embarcado + Isar local

### CI/CD
- [ ] Pipeline CI (analyze + test + build)
- [ ] Pipeline release web (WASM + Docker + GHCR)
- [ ] Pipeline release desktop (artifacts no GitHub Releases)
- [ ] Pipeline BFF (Dart AOT + Docker + GHCR)

### Qualidade
- [ ] Cobertura >= 85% global
- [ ] ViewModels/UseCases >= 95%
- [ ] BFF Domain >= 95%
- [ ] Acessibilidade WCAG AA
- [ ] Performance targets atingidos
