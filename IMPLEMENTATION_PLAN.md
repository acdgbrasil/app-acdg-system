# Plano de Implementação — Frontend ACDG (Conecta Raros)

> **Stack:** Flutter/Dart (Web WASM + Desktop Nativo) | Isar (Offline)
> **Idioma:** Code EN / UI PT-BR
> **Padrão:** Camadas (Data, Logic, UI) | MVVM + UseCase | Command Pattern | Atomic Design

---

## Índice

1. [Diagnóstico: Ponto de Partida](#1-diagnóstico)
2. [Plano de Fases](#2-plano-de-fases)
3. [Fase 1 — Foundation](#fase-1)
4. [Fase 2 — Shell + Auth](#fase-2)
5. [Fase 3 — BFF Social Care](#fase-3)
6. [Fase 4 — Offline Engine](#fase-4)
7. [Fase 5 — Features Social Care](#fase-5)
8. [Fase 6 — Polish + Desktop Build](#fase-6)
9. [Checklist Final](#checklist-final)

---

## Decisões de Re-estruturação (2026-03-13)

> **HISTÓRICO DE MUDANÇAS CRÍTICAS:**
>
> ### Consolidação Core (2026-03-13)
> - **Internalização Técnica:** Engine `Equatable`, padrão `Command` e utilitário `Env` movidos para o package `core` para eliminar dependências externas.
> - **Arquitetura de 3 Camadas:** Estabelecida a divisão rigorosa: `Data Layer` (Repos/Config), `Logic Layer` (UseCases/Router) e `UI Layer` (ViewModels/Atomic Design).
> - **Injeção de Dependência:** Configuração movida para `root.dart` com injeção hierárquica por camada via Provider.
>
> ### Design System (2026-03-12)
> - O `packages/design_system/` original foi removido. A UI agora segue os princípios de **Atomic Design** integrados no app, usando Material 3 e tokens refinados.

---

## 1. Diagnóstico

### Backend Disponível (social-care API)
*Status: 100% Funcional (Registry, Assessment, Protection, Care, Lookup, Health, Auth).*

### Frontend (Estado Atual)

| Item | Status |
|------|--------|
| **Package Core** | PRONTO (Equatable, Command, Env, Result, Platform) |
| **Package Auth** | PRONTO (AuthRepository, AuthUser, Models) |
| **Package Network** | PRONTO (DioClient, Connectivity) |
| **App acdg_system** | REESTRUTURADO (Root/Main, UseCases, Atomic UI) |
| **BFF Social Care** | A REFAZER (Seguindo novos padrões core) |
| **Design System** | EM TRANSIÇÃO (Atomic Design implementado na UI Layer) |

---

## 2. Plano de Fases

```
FASE 1: Foundation (monorepo + core)                        ██████████  100%
FASE 2: Shell + Auth (Zitadel OIDC PKCE)                    ██████████  100%
FASE 3: BFF Social Care (re-estruturação)                    ░░░░░░░░░░  0%
FASE 4: Offline Engine (Isar + SyncQueue + CRDT)             ░░░░░░░░░░  0%
FASE 5: Features Social Care (12 features MVVM)              ░░░░░░░░░░  0%
FASE 6: Polish + Desktop Build + CI/CD                       ░░░░░░░░░░  0%
                                                             ──────────
                                                             Progresso: ~35%
```

---

## FASE 1 — Foundation

Consolidação da base tecnológica e infraestrutura.

### Entregáveis
- [x] **Core Engine Customizada**:
  - [x] `Equatable` (Dart 3 mixin class) sem dependências externas.
  - [x] Padrão `Command` (`Command0`, `Command1`) para reatividade uniforme.
  - [x] Utilitário `Env` para acesso seguro a variáveis de ambiente.
  - [x] `Result<T>` simplificado para tratamento de erros.
- [x] **Organização por Camadas**:
  - [x] `Data Layer`: Configurações e Repositórios.
  - [x] `Logic Layer`: UseCases e Router.
  - [x] `UI Layer`: ViewModels e Hierarquia Atômica.
- [x] **Bootstrap Limpo**:
  - [x] `main.dart` minimalista.
  - [x] `root.dart` orquestrando DI e Router.

---

## FASE 2 — Shell + Auth

Módulo de autenticação e proteção de rotas seguindo o novo padrão de camadas.

### Entregáveis
- [x] **Auth Layering**:
  - [x] `AuthRepository`: Única fonte de verdade para tokens e status.
  - [x] `AuthUseCases`: `Login`, `Logout`, `RestoreSession`.
  - [x] `AuthViewModel`: Reativo via `Command`s.
- [x] **OIDC PKCE Flow**:
  - [x] Implementação com `package:oidc`.
  - [x] Configuração via `OidcConfigFactory` consumindo `Env`.
- [x] **Atomic UI**:
  - [x] `atoms/`: `AppLogo`, `RoleBadge`.
  - [x] `molecules/`: `UserMenuButton`, `ModuleCard`.
  - [x] `organisms/`: `HomeContent`.
  - [x] `pages/`: `LoginPage`, `HomePage`, `SplashPage`.
- [x] **Router**:
  - [x] `AppRouter` na camada de lógica.
  - [x] Guards por Role e verificação de status.

---

## FASE 3 — BFF Social Care (A Refazer)

Reconstrução do BFF para alinhar com os modelos do `core` e o padrão `Result`.

### Entregáveis
- [ ] **BFF Shared**: Models usando `with Equatable` e imutabilidade total.
- [ ] **Contract Layer**: Retornando `Future<Result<T>>` em todos os 21 métodos.
- [ ] **UseCases no App**: Mapeamento 1:1 entre BFF e Logic Layer do app.
- [ ] **Configuração via Env**: Base URLs e timeouts centralizados.

---

## FASE 4 — Offline Engine
*(Inalterado - Aguardando início)*

---

## FASE 5 — Features Social Care
*(Inalterado - Agora exigindo UseCase e Atomic Design obrigatórios)*

---

## Checklist Final (v2)

### Foundation & Infra
- [x] Monorepo Melos 7.x funcionando.
- [x] Package `core` independente e testado.
- [x] Gestão de ambiente via classe `Env`.
- [x] Separação Root/Main e Injeção por Camadas.

### Shell + Auth
- [x] Auth via UseCases e Repository.
- [x] UI organizada em Atomic Design.
- [x] Todos os botões e loadings usando `Command Pattern`.

### BFF & Offline
- [ ] BFF Shared com `Equatable` e `Result`.
- [ ] SyncQueue integrada via UseCases.

### Qualidade
- [x] Testes unitários de ViewModel suportando UseCases.
- [ ] Cobertura global >= 85%.
- [ ] Acessibilidade WCAG AA.
