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
| **View** | Exibe dados, captura eventos. NAO decide nada. | Organizada em **Atomic Design** (Atoms, Molecules, Organisms). | `HomePage`, `UserMenuButton` |
| **ViewModel** | Gerencia estado da UI. | Recebe acoes da View e delega para **UseCases**. NAO fala com Repositories. | `AuthViewModel` |
| **UseCase** | Orquestrador da Camada de Lógica. | Regras de negócio cross-cutting e orquestração de dados. Retorna `Result<T>`. | `LoginUseCase` |
| **Repository** | Fonte de verdade para dados. | Abstrai Repositories reais e Fakes. Encapsula Services. | `AuthRepository` |
| **Config/Env** | Gestão de Infraestrutura e Ambiente. | Centraliza `--dart-define` e decisão de plataforma. | `Env`, `OidcConfigFactory` |

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
| Validacao estrutural nos models | **Fortemente recomendado** (ADR-014) | VOs e entidades validam formato/normalizacao no construtor. Logica de negocio permanece no BFF. Alinhado com `contracts/shared/validation-rules/TESTING_GUIDE.md` |
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

### 4.1 Papel do BFF

O backend (Swift/Vapor) **ja contem todo o DDD**: agregados, VOs com validacao, event sourcing, CQRS, analytics computados. O BFF **nao duplica** essa logica. O papel do BFF e:

1. **Proxy tipado** — traduz chamadas Flutter em requests HTTP para a API, retornando domain models Dart limpos
2. **Barreira de seguranca** — o Flutter web nunca fala diretamente com a API; o BFF gerencia tokens e headers
3. **Adaptacao de interface** — desktop usa import direto (in-process), web usa HTTP (Darto)
4. **Preparacao para offline** — ponto de integracao futuro com SyncQueue/cache (Fase 4)

### 4.2 Arquitetura Interna

```
BFF (Dart package)
+-- contract/                  # Interface abstrata (o que o Flutter consome)
|   +-- social_care_contract.dart   # Metodos tipados para cada operacao
|   +-- dto/                   # Request/Response DTOs compartilhados
|       +-- requests/          # Input DTOs (RegisterPatientRequest, etc.)
|       +-- responses/         # Re-exports dos domain models retornados pelo contract
|
+-- models/                    # Domain models Dart (imutaveis, puros)
|   +-- patient.dart           # Patient agregado
|   +-- family_member.dart     # FamilyMember entidade
|   +-- assessment/            # HousingCondition, HealthStatus, etc.
|   +-- care/                  # Appointment, IntakeInfo
|   +-- protection/            # Referral, ViolationReport, PlacementHistory
|   +-- lookup_item.dart       # Item de tabela de dominio
|   +-- audit_event.dart       # Evento de auditoria
|   +-- value_objects/         # CPF, NIS, CEP (validacao no construtor)
|
+-- api_client/                # Dio wrapper -> API backend
|   +-- social_care_api_client.dart  # HTTP calls com Bearer token
|   +-- api_models/            # JSON serialization (fromJson/toJson)
|
+-- impl/                     # Implementacoes concretas do contract
|   +-- in_process_bff.dart    # Desktop: chamadas Dart diretas via api_client
|   +-- darto_server.dart      # Web: servidor HTTP que expoe o contract
|
+-- testing/                   # Fakes para testes (dentro de lib/src/, exportado via lib/testing.dart)
    +-- fake_social_care_bff.dart
```

### 4.3 Comunicacao por Plataforma

**Desktop (in-process, sem HTTP):**
```
Flutter App -> import bff package -> InProcessBff -> ApiClient (Dio) -> API Backend
```

**Web (HTTP via Darto):**
```
Flutter App -> Dio HTTP -> Darto Server (BFF) -> ApiClient (Dio) -> API Backend
```

### 4.4 Separacao de responsabilidades

| Camada | Responsabilidade | O que NAO faz |
|--------|-----------------|---------------|
| **Flutter App** | UI, estado de tela, navegacao, validacao estrutural (formato, normalizacao, campos obrigatorios — ADR-014) | Logica de negocio (invariantes de agregado, state machines, regras cross-entidade) |
| **BFF** | Proxy tipado, auth headers, adaptacao de plataforma | Duplicar regras que ja existem na API |
| **API Backend** | DDD completo, validacao, event sourcing, CQRS, analytics | Apresentacao, estado de UI |

### 4.5 API Backend Disponivel (social-care)

O BFF consome a API social-care (Swift/Vapor) que oferece **29 endpoints** em 7 areas:

| Area | Endpoints | Operacoes |
|------|-----------|-----------|
| **Health** | 2 | Liveness, readiness |
| **Registry** | 6 | CRUD paciente, membros familiares, cuidador, identidade social |
| **Assessment** | 7 | Habitacao, socioeconomico, trabalho/renda, educacao, saude, rede comunitaria, resumo |
| **Care** | 2 | Atendimentos, informacao de ingresso |
| **Protection** | 3 | Acolhimento, violacoes, encaminhamentos |
| **Lookup** | 1 (13 tabelas) | Tabelas de dominio (parentesco, escolaridade, deficiencia, etc.) |
| **Audit** | 1 | Historico de eventos por paciente |

**Auth:** Bearer JWT (Zitadel). **Header obrigatorio:** `X-Actor-Id` para mutacoes.
**RBAC:** `social_worker` (CRUD), `owner` (read), `admin` (read).

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
|   +-- social_care_bff.dart        # Barrel export
|   +-- contract/                   # Interface abstrata (o que o Flutter consome)
|   |   +-- social_care_contract.dart
|   |   +-- dto/
|   |       +-- requests/           # RegisterPatientRequest, AddFamilyMemberRequest, etc.
|   |       +-- responses/          # PatientResponse, LookupItem, AuditEvent, etc.
|   +-- models/                     # Domain models Dart (imutaveis, puros)
|   |   +-- patient.dart
|   |   +-- family_member.dart
|   |   +-- assessment/             # HousingCondition, HealthStatus, etc.
|   |   +-- care/                   # Appointment, IntakeInfo
|   |   +-- protection/             # Referral, ViolationReport, PlacementHistory
|   |   +-- lookup_item.dart
|   |   +-- audit_event.dart
|   |   +-- value_objects/          # CPF, NIS, CEP (validacao no construtor)
|   +-- api_client/                 # Dio wrapper -> API backend
|   |   +-- social_care_api_client.dart
|   |   +-- api_models/             # JSON serialization (fromJson/toJson)
|   +-- impl/                      # Implementacoes concretas do contract
|       +-- in_process_bff.dart     # Desktop: chamadas Dart diretas
|       +-- darto_server.dart       # Web: servidor HTTP (Darto)
+-- bin/
|   +-- server.dart                 # Entry point web (Darto)
|   +-- testing/                   # Fakes compartilhados (dentro de lib/ para ser importavel)
|       +-- fake_social_care_bff.dart
+-- lib/testing.dart               # Barrel export para test utilities
+-- test/
+-- pubspec.yaml
```

**Por que esta organizacao:**
- `contract/` e a unica coisa que o Flutter importa — interface limpa, sem detalhes de implementacao
- `contract/dto/responses/` re-exporta domain models como tipos de retorno do contract (proxy tipado, sem DTOs duplicados)
- `models/` sao domain models Dart puros (imutaveis, sem fromJson) — usados tanto pelo contract quanto pelo Flutter
- `models/value_objects/` contem VOs com validacao e formatacao (CPF, NIS, CEP) — integrados nos domain models
- `api_client/` e `api_models/` contem a serializacao — separados dos models puros (ADR-013)
- `impl/` contem as implementacoes concretas — desktop (in-process) e web (Darto)
- `testing/` fica dentro de `lib/src/` (padrao Dart idiomatico) para ser importavel via `package:social_care_bff/testing.dart`
- O Flutter **nunca importa** `api_client/` ou `impl/` diretamente — so o `contract/` e `models/`
