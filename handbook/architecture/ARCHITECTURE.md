# Arquitetura Completa — Frontend ACDG (Conecta Raros)

> **Stack:** Flutter/Dart (Web WASM + Desktop Nativo) | BFF Dart AOT (EDD + DDD) | Isar (Offline)
> **Idioma:** Code EN / UI PT-BR

---

## 1. Visao Macro — Micro-Frontend

O usuario final enxerga uma unica aplicacao. Internamente, cada dominio e um package Flutter independente, carregado sob demanda (deferred loading). Um **Shell** centraliza autenticacao e roteamento por roles.

```
+--------------------------------------------------+
|                  Shell (Client)                   |
|         Login + Router por Roles (OIDC)           |
+-------------+-------------+----------------------+
| social-care  | people-ctx  |  ... (futuros)       |
| (package)    | (package)   |  (package)           |
+------+-------+------+------+----------+-----------+
       |              |                 |
+------v-------+------v--------+--------v-----------+
| BFF social   | BFF people    | BFF ...            |
| (Dart AOT)   | (Dart AOT)    | (Dart AOT)         |
| EDD + DDD    | EDD + DDD     | EDD + DDD          |
+------+-------+------+--------+--------+-----------+
       |              |                 |
+------v-------+------v--------+--------v-----------+
| API social   | API people    | API ...            |
| (Swift/Vapor)| (futuro)      | (futuro)           |
+--------------+---------------+--------------------+
```

### 1.1 Composicao dos Micro-Apps

- Cada dominio e um **Dart package** dentro de `packages/`
- O **Shell** importa todos os packages e registra suas rotas
- **Deferred loading**: modulos so carregam quando o usuario navega para a area
- Na perspectiva do usuario: navegacao fluida sem percepcao de multiplos apps

### 1.2 Deploy por Plataforma

| Plataforma | BFF | Storage | Seguranca |
|------------|-----|---------|-----------|
| **Web** | Servidor no Edge (K3s) via Darto | PostgreSQL no servidor | Cliente ZERO info sensivel |
| **Desktop** | Embarcado no app (in-process) | DB local (Isar) | Maximo — tudo local, sem rede |

---

## 2. Camadas Internas — MVVM + Logic Layer

Segue as diretrizes oficiais de arquitetura Flutter (MVVM), com adição de Logic Layer (UseCase) para preparar o app para crescimento.

### 2.1 Diagrama de Camadas

```
+------------------------------------------------------------------+
|                        Flutter Application                        |
|                                                                    |
|  +---------------------+    +----------------------------------+  |
|  |     UI Layer         |    |    Logic Layer (UseCase)         |  |
|  |                     |    |                                  |  |
|  |  View  --> ViewModel| -->|  UseCase                         |  |
|  |  (widgets)  (state) |    |  (orquestrador)                  |  |
|  +---------------------+    +----+-----------------------------+  |
|                                   |                                |
|  +--------------------------------v-------------------------------+|
|  |                      Data Layer                                ||
|  |                                                                ||
|  |  Repository A    Repository B    Repository C                  ||
|  |      |               |               |                        ||
|  |  Service 1       Service 2       Service 3                    ||
|  |      |               |               |                        ||
|  +------+---------------+---------------+------------------------+|
+---------|---------------|---------------|-------------------------+
          v               v               v
    Platform API     Platform API    BFF (Darto / in-process)
                                         |
                                         v
                                    API Backend
                                   (Swift/Vapor)
```

### 2.2 Responsabilidades por Camada

| Camada | Responsabilidade | Regras | Exemplos |
|--------|-----------------|--------|----------|
| **View** | Exibe dados, captura eventos do usuario. NAO decide nada. | Logica permitida: (1) if/else para mostrar/esconder widgets, (2) logica de animacao, (3) logica de layout baseada em tamanho de tela, (4) roteamento simples. Tudo mais vai no ViewModel. | Pages (Desktop/Web/Mobile), Components (Atomic Design) |
| **ViewModel** | Gerencia estado da UI. Recebe acoes do usuario e delega para UseCases/Repositories. | Contem logica de **UI** (formatacao, loading states, validacao de formulario). NAO contem logica de negocio (vive no BFF). Expoe estado via **ValueNotifier** (atomico) + **ChangeNotifier** (agregador). Uma instancia por feature, compartilhada entre plataformas. | `PatientRegistrationViewModel`, `AuthViewModel` |
| **UseCase** | Orquestra chamadas a multiplos Repositories. Camada de indireção entre ViewModel e Data Layer. | Sempre presente por padronizacao, mesmo em features simples (prepara para crescimento). Retorna `Result<T>`. Usa **Command pattern** para acoes do usuario. | `RegisterPatientUseCase`, `SyncOfflineQueueUseCase` |
| **Repository** | Fonte de verdade para dados. Cache, retry, error handling, mapeamento de modelos. | Classes abstratas (interfaces) para permitir fakes em testes e diferentes implementacoes (dev/staging/prod). Podem ser compartilhados entre features. | `PatientRepository`, `LookupRepository` |
| **Service** | Wrapper puro de chamadas externas (HTTP/Platform). Sem logica. | Uma responsabilidade: traduzir chamadas externas em objetos Dart. | `PatientService` (Dio -> BFF), `ConnectivityService` |

### 2.3 Fluxo de Dados (Unidirecional)

Dados fluem em uma unica direcao: da Data Layer para a UI Layer. Acoes do usuario fluem no sentido inverso via Commands.

```
Dados (downstream):
  Service -> Repository -> UseCase -> ViewModel -> View (ValueNotifier)

Acoes do usuario (upstream):
  View -> Command -> ViewModel -> UseCase -> Repository -> Service -> BFF -> API
```

**Command pattern:** cada acao do usuario e encapsulada em um metodo no ViewModel que:
1. Atualiza o estado de loading/busy
2. Delega para o UseCase
3. Trata o Result (Success/Failure)
4. Atualiza o estado final (dados ou erro)

### 2.4 Principios (alinhados com Flutter Architecture Guidelines)

| Principio | Nivel | Descricao |
|-----------|-------|-----------|
| Separacao UI/Data Layer | **Fortemente recomendado** | Camadas claramente definidas, sem vazamento |
| Repository pattern | **Fortemente recomendado** | Abstrai acesso a dados, classes abstratas para testabilidade |
| MVVM (ViewModel + View) | **Fortemente recomendado** | Views "burras", ViewModel contem logica de UI |
| ChangeNotifier + ValueNotifier | **Condicional** (adotado) | Nativo do Flutter, atomico, sem dependencia externa |
| Logic Layer (UseCase) | **Condicional** (adotado) | Presente em todas as features por padronizacao e preparacao para crescimento |
| Command pattern | **Recomendado** | Previne erros de renderizacao, padroniza interacao usuario -> dados |
| Models imutaveis | **Fortemente recomendado** | `final` em tudo, `copyWith()`, fluxo unidirecional |
| Modelos de API separados de dominio | **Condicional** (adotado) | API models na Data Layer, domain models na Domain Layer |
| Provider para DI | **Recomendado** | Integrado com widget tree, sem code generation |
| GoRouter | **Recomendado** | Roteamento declarativo com deferred loading |
| Fakes para testes | **Fortemente recomendado** | Fakes compartilhados em `testing/`, nunca mocks magicos |

---

## 3. Adaptive Design — Views por Plataforma

Cada feature possui **3 Pages** otimizadas para cada plataforma. A **ViewModel e unica** — compartilhada entre todas.

```
+----------------------------------------+
|          ViewModel (unica)             |
+------------+------------+--------------+
| Desktop    | Web Page   | Mobile Page  |
| Page       |            |              |
| (nativa,   | (responsiva| (responsiva  |
|  mouse/kb) |  breakpts) |  touch/gestos|
+------------+------------+--------------+
```

### 3.1 Regras

- **Page** = muda por plataforma (experiencia diferente)
- **Breakpoints** = adapta DENTRO da mesma Page (responsividade)
- **ViewModel** = sempre a mesma instancia, zero duplicacao de logica
- **Components** (atoms/cells/templates) = compartilhados entre as 3 Pages

### 3.2 Resolucao de Plataforma

O Shell resolve a plataforma no boot e injeta o builder correto. Cada feature expoe um `PlatformPageResolver` que retorna a Page adequada.

---

## 4. BFF — Backend for Frontend

### 4.1 Arquitetura Interna (EDD + DDD)

```
BFF (Dart)
+-- domain/           # DDD: agregados, entities, VOs
|   +-- models/        # Imutaveis, validacao no construtor
|   +-- events/        # Eventos de dominio (EDD)
|   +-- value_objects/  # VOs com validacao
|
+-- application/       # Use cases, commands, event handlers
|   +-- commands/       # Write operations
|   +-- queries/        # Read operations
|   +-- sync/           # Reconciliacao offline (CRDT-like)
|
+-- infrastructure/    # Adapters externos
|   +-- api_client/     # Dio -> API backend
|   +-- local_db/       # Isar (desktop) / memoria (web)
|   +-- cache/          # Cache layer
|
+-- interface/         # Contratos de entrada
    +-- in_process/     # Desktop: chamadas Dart diretas
    +-- http/           # Web: Darto server
```

### 4.2 Comunicacao por Plataforma

**Desktop:**
```
Flutter App -> import bff package -> chamada Dart direta -> BFF Domain -> Dio -> API
```

**Web:**
```
Flutter App -> Dio HTTP -> Darto Server (BFF) -> BFF Domain -> Dio -> API
```

### 4.3 Toda regra de negocio no BFF

O Flutter App trata models como **schemas** — sem logica de negocio. Validacao, transformacao, regras de dominio: tudo no BFF.

---

## 5. Offline First

### 5.1 Estrategia

```
+------------------+     +-----------------+     +------------------+
|  User Action     | --> |  SyncQueue      | --> |  BFF             |
|  (ViewModel)     |     |  (Isar)         |     |  (reconcilia)    |
+------------------+     |  timestamp +    |     |  CRDT-like merge |
                         |  payload +      |     +--------+---------+
                         |  status         |              |
                         +-----------------+              v
                                                    API Backend
```

### 5.2 Queue Ordenada (CRDT-like)

- Cada acao offline e um **evento com timestamp** (relogio monotonic + UUID)
- Ao reconectar, o BFF envia a queue para a API **na ordem dos timestamps**
- Conflitos: se dois usuarios editaram o **mesmo campo** do mesmo registro, o BFF detecta e pede resolucao manual
- Se editaram **campos diferentes**, faz merge automatico

### 5.3 Storage

| Plataforma | Engine | Dados |
|------------|--------|-------|
| Web | Isar (IndexedDB) | Cache + SyncQueue |
| Desktop | Isar (file-based) | DB completo + SyncQueue + BFF data |

---

## 6. Autenticacao

### 6.1 Zitadel OIDC (PKCE)

| Aspecto | Detalhe |
|---------|---------|
| Provider | Zitadel (self-hosted em `auth.acdgbrasil.com.br`) |
| Flow | Authorization Code + PKCE |
| Package | `package:oidc` (Bdaya-Dev) — OpenID Certified, todas as plataformas |
| Roles | `social_worker` (CRUD), `owner` (read-only), `admin` (read + gestao) |
| Scopes | `openid profile email offline_access urn:zitadel:iam:org:project:roles` |
| Token Storage (Web) | **Split-Token Pattern**: Access Token em memoria Dart, Refresh Token em cookie `HttpOnly + Secure + SameSite=Strict` |
| Token Storage (Desktop) | `flutter_secure_storage`: Keychain (macOS), DPAPI + AES-GCM (Windows), libsecret (Linux) |
| Redirect (Web) | Browser redirect padrao → callback URI registrada no Zitadel |
| Redirect (Desktop) | Loopback listener (`oidc_loopback_listener`) — servidor HTTP efemero em localhost |
| Refresh | Silent refresh via refresh token (sobrevive F5 na web gracas ao cookie HttpOnly) |
| Auth Guard | Layered Security: `GoRouter.redirect` global (auth check) + local (RBAC) + `GoRouter.refresh()` imperativo |

### 6.2 Split-Token Pattern (Web)

```
Page Load / F5
    |
    v
Dart memory vazio (access token perdido)
    |
    v
Silent refresh request (withCredentials: true)
    |
    v
Browser envia cookie HttpOnly automaticamente (refresh token)
    |
    v
Endpoint valida refresh token, retorna novo access token no body JSON
    |
    v
Access token armazenado em memoria Dart
    |
    v
App retoma sessao sem re-login
```

**Cookie flags obrigatorias:** `HttpOnly` (bloqueia JS/XSS), `Secure` (HTTPS only), `SameSite=Strict` (bloqueia CSRF).

**CORS:** Backend deve responder com origin exato (nao `*`) e `Access-Control-Allow-Credentials: true`.

**NUNCA usar:** localStorage, sessionStorage ou cookies acessiveis por JavaScript para tokens.

### 6.3 Role-Based Routing

O Shell resolve as roles do JWT e roteia para o micro-app correto:

```
social_worker -> social_care module
admin         -> social_care module (read) + admin module
owner         -> social_care module (read-only)
```

---

## 7. Estrutura de Pastas

Segue a recomendacao oficial do Flutter: **UI organizada por feature**, **Data organizada por tipo**. Isso facilita onboarding de novos devs familiarizados com o padrao Flutter.

### 7.1 Monorepo

```
frontend/
+-- shell/                          # App principal (login + router)
+-- packages/
|   +-- design_system/              # Atomic Design tokens + widgets
|   +-- core/                       # Shared: network, auth, platform, base
|   +-- social_care/                # Micro-app: Social Care
|   +-- people_context/             # Micro-app: People Context (futuro)
+-- bff/
|   +-- social_care_bff/            # BFF do social-care (EDD + DDD)
|   +-- people_context_bff/         # BFF (futuro)
+-- handbook/                       # Documentacao viva
+-- CLAUDE.md                       # Instrucoes para Claude Code
```

### 7.2 Shell

```
shell/
+-- lib/
|   +-- main.dart                   # Entry point
|   +-- router/                     # GoRouter + deferred loading
|   |   +-- app_router.dart
|   +-- auth/                       # Auth ViewModel (consome core/auth)
|   |   +-- auth_view_model.dart
|   +-- pages/                      # Shell pages (splash, login, home)
|       +-- splash_page.dart
|       +-- login_page.dart
|       +-- home_page.dart
+-- test/                           # Testes espelham lib/
|   +-- auth/
|   +-- router/
|   +-- pages/
+-- pubspec.yaml
```

### 7.3 Core

```
packages/core/
+-- lib/
|   +-- core.dart                   # Barrel export
|   +-- src/
|       +-- auth/                   # AuthService, AuthUser, AuthToken, AuthRole, AuthStatus
|       +-- base/                   # BaseViewModel, BaseUseCase, Result<T>
|       +-- network/                # DioClient, interceptors
|       +-- platform/               # PlatformResolver
|       +-- connectivity/           # ConnectivityService
|       +-- offline/                # Isar setup, SyncQueue, CRDT (futuro)
+-- test/
+-- pubspec.yaml
```

### 7.4 Design System

```
packages/design_system/
+-- lib/
|   +-- design_system.dart          # Barrel export
|   +-- src/
|       +-- tokens/                 # AcdgColors, AcdgTypography, AcdgSpacing, AcdgRadius, AcdgShadows, AcdgTheme
|       +-- atoms/                  # AcdgButton, AcdgText, AcdgTextField, AcdgIcon, AcdgCard, AcdgCheckbox, AcdgRadio, AcdgDropdown
|       +-- cells/                  # AcdgFormField, AcdgInfoCard
|       +-- templates/              # FormLayoutTemplate, PageScaffoldTemplate
+-- test/
+-- pubspec.yaml
```

### 7.5 Micro-App (ex: social_care)

Segue a recomendacao Flutter: **UI por feature, Data por tipo, Domain compartilhado**.

```
packages/social_care/
+-- lib/
|   +-- social_care.dart            # Barrel export + module registration
|   +-- ui/                         # UI Layer — organizada POR FEATURE
|   |   +-- core/                   # Widgets e temas compartilhados entre features
|   |   |   +-- widgets/
|   |   +-- patient_registration/   # Feature: cadastro de paciente
|   |   |   +-- view_model/
|   |   |   |   +-- patient_registration_vm.dart
|   |   |   +-- widgets/
|   |   |   |   +-- patient_registration_desktop_page.dart
|   |   |   |   +-- patient_registration_web_page.dart
|   |   |   |   +-- patient_registration_mobile_page.dart
|   |   |   |   +-- <other_widgets>.dart
|   |   |   +-- use_case/
|   |   |       +-- register_patient_use_case.dart
|   |   +-- family_composition/     # Feature: composicao familiar
|   |   |   +-- view_model/
|   |   |   +-- widgets/
|   |   |   +-- use_case/
|   |   +-- housing_assessment/
|   |   +-- health_status/
|   |   +-- work_income/
|   |   +-- education/
|   |   +-- socioeconomic/
|   |   +-- community_support/
|   |   +-- social_health_summary/
|   |   +-- protection/
|   |   +-- care/
|   |   +-- audit_trail/
|   |
|   +-- domain/                     # Domain Layer — modelos compartilhados
|   |   +-- models/                 # Modelos imutaveis do dominio
|   |   |   +-- patient.dart
|   |   |   +-- family_member.dart
|   |   |   +-- housing_condition.dart
|   |   |   +-- ...
|   |
|   +-- data/                       # Data Layer — organizada POR TIPO
|       +-- repositories/           # Fontes de verdade, cache, retry
|       |   +-- patient_repository.dart       # Classe abstrata
|       |   +-- patient_repository_impl.dart  # Implementacao concreta
|       |   +-- lookup_repository.dart
|       |   +-- ...
|       +-- services/               # Wrappers puros de API calls
|       |   +-- patient_service.dart
|       |   +-- lookup_service.dart
|       |   +-- ...
|       +-- model/                  # API models (serializacao/deserializacao)
|           +-- patient_api_model.dart
|           +-- ...
|
+-- test/                           # Espelha lib/
|   +-- ui/
|   +-- domain/
|   +-- data/
|
+-- testing/                        # Fakes compartilhados para testes
|   +-- fakes/
|   |   +-- fake_patient_repository.dart
|   |   +-- fake_patient_service.dart
|   +-- fixtures/
|       +-- patient_fixtures.dart
|
+-- pubspec.yaml
```

**Por que esta organizacao:**

- `ui/` por feature porque cada feature tem exatamente um ViewModel e um conjunto de Views — sao acoplados
- `data/` por tipo porque Repositories e Services podem ser compartilhados entre features (ex: `LookupRepository` usado por varias features)
- `domain/models/` compartilhado porque modelos de dominio sao usados por ambas as camadas
- `data/model/` separado de `domain/models/` — API models contem logica de serializacao (fromJson/toJson), domain models sao puros
- `testing/` como subpacote dedicado para fakes — evita duplicacao de mocks entre testes

### 7.6 BFF

```
bff/social_care_bff/
+-- lib/
|   +-- domain/                     # DDD: agregados, entities, VOs
|   |   +-- models/
|   |   +-- events/
|   |   +-- value_objects/
|   +-- application/                # Use cases, commands, event handlers
|   |   +-- commands/
|   |   +-- queries/
|   |   +-- sync/
|   +-- infrastructure/             # Adapters externos
|   |   +-- api_client/
|   |   +-- local_db/
|   |   +-- cache/
|   +-- interface/                  # Contratos de entrada
|       +-- in_process/
|       +-- http/
+-- bin/
|   +-- server.dart                 # Entry point web (Darto)
+-- test/
+-- pubspec.yaml
```
