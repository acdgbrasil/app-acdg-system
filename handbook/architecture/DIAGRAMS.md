# Diagramas — Frontend ACDG

> Todos os diagramas de arquitetura do ecossistema frontend.

---

## 1. Visao Geral — UI Layer + Data Layer

```mermaid
flowchart LR
    subgraph UI["UI layer"]
        View <--> ViewModel
    end

    subgraph Data["Data layer"]
        subgraph Model["Model"]
            Repository <--> Service
        end
    end

    ViewModel <--> Repository
```

---

## 2. Arquitetura Completa — Flutter Application + External Data

```mermaid
flowchart LR
    subgraph App["Flutter Application"]
        subgraph UI["UI layer"]
            View["View\n- displays data\n- listens for events"]
            ViewModel["ViewModel\n- handles view logic"]
        end

        subgraph Data["Data layer"]
            RepoA["Repository A\n- caching and retry logic\n- error handling\n- handling raw data"]
            RepoB["Repository B\n- caching and retry logic\n- error handling\n- handling raw data"]
            RepoC["Repository C\n- caching and retry logic\n- error handling\n- handling raw data"]

            Svc1["Service 1\n- wraps API calls"]
            Svc2["Service 2\n- wraps API calls"]
            Svc3["Service 3\n- wraps API calls"]
        end
    end

    subgraph External["External data"]
        PlatAPI1["Platform API i"]
        PlatAPI2["Platform API ii"]
        Server["Client facing server"]
    end

    View -->|UI state| View
    View <-->|domain models| ViewModel
    View --> ViewModel
    View -->|User action triggers command| ViewModel
    ViewModel -->|method calls| RepoA
    ViewModel -->|method calls| RepoB
    ViewModel -->|method calls| RepoC

    RepoA -->|API models| Svc1
    RepoA -->|poll data| Svc1
    RepoB <--> Svc2
    RepoC <--> Svc3

    Svc1 <-->|method channels\nand native objects| PlatAPI1
    Svc2 <-->|method channels\nand native objects| PlatAPI2
    Svc3 <-->|HTTP| Server
```

---

## 3. Arquitetura com Logic Layer (UseCase)

```mermaid
flowchart LR
    subgraph UI["UI layer"]
        View
        ViewModel
    end

    subgraph Logic["Logic layer"]
        UseCase
    end

    subgraph Data["Data layer"]
        RepoA["Repository A"]
        RepoB["Repository B"]
        Svc1["Service 1"]
        Svc2["Service 2"]
    end

    View -->|UI state| ViewModel
    UseCase -->|domain models| ViewModel
    Svc1 -->|API models| RepoA

    View <--> ViewModel
    ViewModel <--> UseCase
    UseCase --> RepoA
    UseCase --> RepoB

    RepoA <--> Svc1
    RepoA <--> Svc2
    RepoB <--> Svc1
    RepoB <--> Svc2

    View -->|User action triggers command| ViewModel
    ViewModel -->|method calls| UseCase
    RepoA -->|polls data| ViewModel
    Svc1 -->|polls data| ViewModel
```

---

## 4. Adaptive Design — Resolucao de Plataforma

```mermaid
flowchart TB
    Shell["Shell (boot)"] --> Resolver["Platform Resolver"]
    Resolver -->|kIsWeb| WebPage["Web Page\n(breakpoints: lg, md, sm)"]
    Resolver -->|Platform.isMacOS\nPlatform.isWindows\nPlatform.isLinux| DesktopPage["Desktop Page\n(layout fixo, mouse/kb)"]
    Resolver -->|Platform.isAndroid\nPlatform.isIOS| MobilePage["Mobile Page\n(breakpoints: sm, xs + touch)"]

    WebPage --> VM["ViewModel (unica)"]
    DesktopPage --> VM
    MobilePage --> VM
```

---

## 5. Offline First — Queue de Sincronizacao

```mermaid
flowchart LR
    subgraph Online["Modo Online"]
        Action1["User Action"] --> VM1["ViewModel"]
        VM1 --> UC1["UseCase"]
        UC1 --> Repo1["Repository"]
        Repo1 --> Svc1["Service"]
        Svc1 -->|Dio HTTP| BFF1["BFF"]
        BFF1 -->|Dio HTTP| API1["API Backend"]
    end

    subgraph Offline["Modo Offline"]
        Action2["User Action"] --> VM2["ViewModel"]
        VM2 --> UC2["UseCase"]
        UC2 --> Queue["SyncQueue\n(Isar)\ntimestamp + payload"]
    end

    subgraph Sync["Reconexao"]
        Queue -->|connectivity listener| SyncEngine["Sync Engine"]
        SyncEngine -->|ordenado por timestamp| BFF2["BFF"]
        BFF2 -->|CRDT-like merge| API2["API Backend"]
        BFF2 -->|conflito mesmo campo| Manual["Resolucao Manual"]
    end
```

---

## 6. Autenticacao — Zitadel OIDC PKCE

```mermaid
sequenceDiagram
    participant User
    participant Shell
    participant Zitadel as Zitadel (auth.acdgbrasil.com.br)
    participant BFF
    participant API

    User->>Shell: Acessa o app
    Shell->>Zitadel: Authorization Code + PKCE
    Zitadel->>User: Login page
    User->>Zitadel: Credenciais
    Zitadel->>Shell: Authorization Code
    Shell->>Zitadel: Troca code por tokens (+ code_verifier)
    Zitadel->>Shell: access_token + refresh_token + id_token

    Note over Shell: Extrai roles do JWT claim<br/>urn:zitadel:iam:org:project:roles

    Shell->>Shell: Roteia por role (social_worker -> social_care)

    User->>Shell: Acao autenticada
    Shell->>BFF: Request + Bearer token
    BFF->>API: Request + Bearer token
    API->>BFF: Response
    BFF->>Shell: Response processado
```

---

## 7. Micro-Frontend — Composicao de Packages

```mermaid
graph TB
    subgraph Shell["Shell App"]
        Main["main.dart"]
        Router["GoRouter"]
        Auth["Auth (Zitadel)"]
        DI["Provider (DI)"]
    end

    subgraph Packages["packages/"]
        DS["design_system\n(atoms, cells, templates, tokens)"]
        Core["core\n(network, offline, auth, base)"]
        SC["social_care\n(features por dominio)"]
        PC["people_context\n(futuro)"]
    end

    subgraph BFFs["bff/"]
        SCBFF["social_care_bff\n(EDD + DDD)"]
        PCBFF["people_context_bff\n(futuro)"]
    end

    Main --> Router
    Main --> Auth
    Main --> DI
    Router -->|deferred import| SC
    Router -->|deferred import| PC
    SC --> Core
    SC --> DS
    PC --> Core
    PC --> DS
    SC -->|in-process / HTTP| SCBFF
    PC -->|in-process / HTTP| PCBFF
```

---

## 8. Feature Interna — Estrutura MVVM

```mermaid
graph TB
    subgraph Feature["Feature: patient_registration"]
        subgraph ViewLayer["view/"]
            subgraph Pages["pages/"]
                Desktop["desktop_page.dart"]
                Web["web_page.dart"]
                Mobile["mobile_page.dart"]
            end
            subgraph Components["components/"]
                Atoms["atoms/"]
                Cells["cells/"]
            end
        end

        subgraph VMLayer["view_model/"]
            VM["patient_registration_vm.dart\n(ChangeNotifier + ValueNotifier)"]
        end

        subgraph UCLayer["use_case/"]
            UC["register_patient_use_case.dart"]
        end

        subgraph ModelLayer["model/"]
            Repo["repositories/\npatient_repository.dart"]
            Svc["services/\npatient_service.dart"]
        end
    end

    Desktop --> VM
    Web --> VM
    Mobile --> VM
    Desktop --> Atoms
    Desktop --> Cells
    Web --> Atoms
    Web --> Cells
    Mobile --> Atoms
    Mobile --> Cells
    VM --> UC
    UC --> Repo
    Repo --> Svc
```
