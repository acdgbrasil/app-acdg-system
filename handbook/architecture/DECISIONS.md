# ADRs — Architecture Decision Records

> Registro formal de todas as decisoes arquiteturais do frontend.
> Cada decisao e imutavel apos aceita. Novas decisoes podem substituir anteriores referenciando o ADR original.

---

## ADR-001: Flutter/Dart como framework unico

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Precisamos de uma tecnologia que suporte Web (WASM), Desktop nativo (sem webview) e potencialmente Mobile, compartilhando a mesma codebase.

### Opcoes Consideradas
1. **Flutter/Dart** — Rendering engine propria (Impeller/Skia), WASM pra web, binario nativo pra desktop
2. **Tauri 2.0** — Web stack (TS/React) + Rust. Usa webview do sistema no desktop
3. **React Native + Electron** — Mobile nativo + desktop via Chromium embarcado

### Decisao
**Flutter/Dart**. Unica opcao que atende o requisito de desktop nativo sem webview. A engine propria garante consistencia visual entre plataformas.

### Consequencias
- Toda a equipe deve dominar Dart
- Ecossistema de packages menos maduro que npm/pub tem crescido
- Performance nativa em todas as plataformas

---

## ADR-002: BFF em Dart com EDD + DDD

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Precisamos de um BFF que (1) contenha toda a logica de negocio, (2) funcione embarcado no desktop e como servidor na web, (3) compartilhe types com o frontend.

### Opcoes Consideradas
1. **Dart** — Mesma linguagem do front, binario AOT otimizado, OOP forte
2. **Node.js/TypeScript** — Ecossistema maduro, nao compartilha types com Flutter
3. **Go** — Performance maxima, binario unico, sem sharing de types
4. **Rust (Axum)** — Seguranca maxima, overkill para BFF

### Decisao
**Dart**. Unifica a linguagem com o frontend, permite import direto do BFF como package no desktop (in-process), e `dart compile exe` gera binarios AOT leves para deploy no servidor.

### Consequencias
- Stack 100% Dart — onboarding simplificado
- Compartilhamento real de models entre BFF e frontend
- BFF desktop = import de package, sem overhead de HTTP
- BFF web = servidor Darto com HTTP

---

## ADR-003: MVVM com estado atomico (ChangeNotifier + ValueNotifier)

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Precisamos de gerenciamento de estado que seja previsivel, testavel e sem efeitos colaterais. O estado deve ser granular (atomico) para evitar rebuilds desnecessarios.

### Opcoes Consideradas
1. **ChangeNotifier + ValueNotifier** — Nativo do Flutter, atomico, simples
2. **BLoC/Cubit** — Streams, mais boilerplate, padrao do mercado
3. **Riverpod** — Moderno, compile-safe, mais complexo
4. **GetX** — Reativo, mas magico e pouco previsivel

### Decisao
**ChangeNotifier + ValueNotifier** com Provider para DI. Atomico por natureza — cada ValueNotifier contem um unico pedaco de estado. ChangeNotifier na ViewModel agrega os notifiers.

### Consequencias
- Zero dependencia externa para state management
- Testabilidade maxima — ValueNotifier e trivial de mockar
- Granularidade fina — rebuilds cirurgicos
- Provider como DI mantem simplicidade

---

## ADR-004: Micro-frontend via packages + deferred loading

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Cada dominio (social-care, people-context, etc.) precisa ser independente para desenvolvimento e deploy, mas o usuario deve perceber uma unica aplicacao.

### Opcoes Consideradas
1. **Packages no monorepo + lazy routes** — Um binario, modulos sob demanda
2. **Apps independentes** — Deploy separado, iframe/plugin na web
3. **Packages sem lazy loading** — Um binario, tudo carregado no boot

### Decisao
**Packages no monorepo com deferred loading via GoRouter**. Cada dominio e um package Dart que exporta suas rotas. O Shell importa todos mas so carrega quando o usuario navega.

### Consequencias
- Um unico binario final (simplifica deploy)
- Carregamento sob demanda (performance)
- Isolamento de codigo por dominio
- Compartilhamento do design system e core entre packages

---

## ADR-005: Offline First com Isar + Queue CRDT-like

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Usuarios em areas remotas precisam usar o app sem internet. Acoes offline devem ser sincronizadas automaticamente ao reconectar, com resolucao de conflitos.

### Opcoes Consideradas
1. **Isar + queue com timestamp** — NoSQL embarcado, CRDT-like merge
2. **Drift (SQLite) + queue** — Relacional, mais controle, mais complexo
3. **Hive + queue** — Key-value simples, limitado para queries

### Decisao
**Isar** para storage local + queue de acoes com timestamp. Resolucao de conflitos CRDT-like: merge automatico por campo, resolucao manual se mesmo campo editado.

### Consequencias
- Isar funciona em web (IndexedDB) e desktop (file-based) nativamente
- Queue ordenada por timestamp garante consistencia
- BFF faz reconciliacao — front so enfileira
- Conflitos de mesmo campo exigem UX de resolucao manual

---

## ADR-006: Adaptive Design (3 Pages por feature)

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Desktop, Web e Mobile tem experiencias fundamentalmente diferentes (mouse vs touch, tamanho de tela, gestos). Responsividade sozinha nao resolve.

### Decisao
Cada feature tem **3 Pages** (Desktop, Web, Mobile) que compartilham a **mesma ViewModel**. Breakpoints adaptam DENTRO de cada Page. O Shell resolve a plataforma no boot.

### Consequencias
- UX otimizada por plataforma
- ViewModel nunca duplicada
- Components (Atomic Design) compartilhados entre Pages
- Mais arquivos por feature, mas cada Page e simples e focada

---

## ADR-007: BFF como barramento de seguranca

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
O frontend web nao pode conter informacao sensivel. Toda comunicacao com a API deve passar por um intermediario que valide, transforme e proteja os dados.

### Decisao
O **BFF** e o unico ponto de contato com a API backend. No web, roda como servidor separado. No desktop, roda embarcado mas com a mesma camada de dominio.

### Consequencias
- Cliente web nunca fala diretamente com a API
- Toda validacao/regra de negocio vive no BFF
- Frontend trata models como schemas puros
- Engenharia reversa via requests e significativamente mais dificil

---

## ADR-008: Darto como servidor HTTP do BFF + Dio como HTTP client

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Precisamos de um servidor HTTP Dart para o BFF (deploy web) e um client HTTP para comunicacao BFF -> API.

### Opcoes Consideradas (servidor)
1. **Darto** — Open source, contribuidor conhecido, facil de contribuir e corrigir
2. **Shelf** — Oficial do Google, mais maduro
3. **dart_frog** — Abstracoes de alto nivel, mais opinado

### Opcoes Consideradas (client)
1. **Dio** — Interceptors, retry, cancel tokens, maduro
2. **http** — Package oficial, basico
3. **chopper** — Gerado a partir de specs, mais boilerplate

### Decisao
**Darto** para servidor HTTP. **Dio** para client HTTP. Darto por proximidade com o contribuidor (facilita correcoees e contribuicoes). Dio por maturidade e features (interceptors, retry).

---

## ADR-009: Provider para Dependency Injection

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Precisamos de DI para injetar ViewModels, UseCases, Repositories e Services de forma testavel.

### Opcoes Consideradas
1. **Provider** — Oficial do Flutter, simples, integrado com widget tree
2. **GetIt** — Service Locator, nao integrado com widget tree
3. **Riverpod** — Moderno, compile-safe, mais complexo
4. **Injectable (GetIt + code gen)** — Geracao de codigo, mais boilerplate

### Decisao
**Provider**. Nativo do Flutter, integrado com a widget tree, sem code generation. Suficiente para MVVM com escopo por feature.

---

## ADR-010: Imutabilidade total nos Models

**Data:** 2026-03-07
**Status:** Aceito

### Contexto
Efeitos colaterais sao a maior fonte de bugs em apps reativos. Models mutaveis propagam estado inconsistente.

### Decisao
**Todos os models sao imutaveis** (`final` em todos os campos). Mudancas criam novas instancias via `copyWith()`. Dart trabalha bem com OOP imutavel.

### Consequencias
- Zero side effects
- Estado previsivel
- Facilita debugging e testes
- `copyWith()` em todos os models

---

## ADR-011: Split-Token Pattern para Web Token Storage

**Data:** 2026-03-10
**Status:** Aceito
**Substitui:** Parte do ADR implícito na ARCHITECTURE.md que dizia "Memoria apenas — NUNCA localStorage/cookie"

### Contexto
A estrategia original de armazenar tokens exclusivamente em memoria Dart (variaveis) e a mais segura contra XSS, porem tem uma falha grave: qualquer page refresh (F5) no browser destroi todo o estado Dart, forcando o usuario a fazer login novamente. Em uma SPA, isso e inaceitavel para UX.

### Opcoes Consideradas
1. **Memoria apenas** — Maximo seguro contra XSS, perde sessao no F5
2. **localStorage** — Sobrevive F5, totalmente exposto a XSS (OWASP proibe para tokens)
3. **sessionStorage** — Sobrevive F5, igualmente exposto a XSS
4. **flutter_secure_storage (web)** — Usa WebCrypto, mas XSS pode esperar decriptacao
5. **Split-Token Pattern** — Access Token em memoria + Refresh Token em cookie HttpOnly

### Decisao
**Split-Token Pattern**. Combina seguranca maxima com sobrevivencia ao F5:

- **Access Token**: armazenado SOMENTE em memoria Dart. Curto TTL (5-15 min). Enviado como `Authorization: Bearer` header.
- **Refresh Token**: armazenado em cookie `HttpOnly + Secure + SameSite=Strict`. Invisivel ao JavaScript. Enviado automaticamente pelo browser ao endpoint de refresh.

Apos F5, o app faz silent refresh: browser envia o cookie HttpOnly automaticamente (`withCredentials: true`), servidor valida e retorna novo access token no body JSON.

### Consequencias
- Sessao sobrevive F5 e navegacao normal
- Access token nunca exposto a XSS (memoria apenas)
- Refresh token nunca acessivel via JavaScript (HttpOnly)
- CSRF bloqueado por SameSite=Strict
- Requer endpoint de proxy/refresh que sete o cookie HttpOnly (BFF ou middleware dedicado)
- CORS deve usar origin exato (nao `*`) com `Access-Control-Allow-Credentials: true`
- Apple ITP pode afetar cookies third-party (mitigado por same-site deployment)

---

## ADR-012: package:oidc (Bdaya-Dev) como biblioteca OIDC

**Data:** 2026-03-10
**Status:** Aceito

### Contexto
Precisamos de um package Flutter que implemente OIDC Authorization Code + PKCE em todas as plataformas (Web, macOS, Windows, Linux) com suporte a Zitadel.

### Opcoes Consideradas
1. **flutter_appauth** — Battle-tested, sem suporte Web, Windows/Linux limitado a Device Code Flow
2. **openid_client** — Pure Dart, bugs recorrentes com PKCE S256, sem session manager
3. **flutter_web_auth_2** — Apenas abre browser, nao e biblioteca OIDC (PKCE manual)
4. **package:oidc (Bdaya-Dev)** — OpenID Certified, plugin federado, todas as plataformas
5. **openidconnect** — Desktop parcial, Device Code Flow obrigatorio em Windows/Linux

### Decisao
**package:oidc** (Bdaya-Dev). Razoes:

- **OpenID Certified** (Basic RP) pela OpenID Foundation
- Plugin federado: `oidc_core` (protocolo), `oidc` (orquestrador), `oidc_default_store` (storage), `oidc_loopback_listener` (desktop)
- Desktop usa loopback listener (UX nativa, sem Device Code Flow)
- `OidcUserManager` gerencia refresh automatico via Dart Streams
- Zitadel usa este package no exemplo oficial (`zitadel_flutter`)
- PKCE built-in e automatico

### Consequencias
- Dependencia em package mantido por terceiro (Bdaya-Dev), porem com certificacao OpenID
- Desktop requer `oidc_loopback_listener` para capturar redirect
- Web usa browser redirect nativo
- Token storage delegado a `oidc_default_store` (flutter_secure_storage no desktop)

---

## ADR-013: Alinhamento com Flutter Architecture Guidelines

**Data:** 2026-03-10
**Status:** Aceito
**Substitui:** Estrutura de pastas da seção 7 do ARCHITECTURE.md original

### Contexto
A arquitetura original organizava tudo dentro de cada feature (view, view_model, use_case, model/repositories, model/services). A referencia oficial de arquitetura Flutter (caso de estudo Compass app) recomenda organizar UI por feature e Data por tipo, pois Repositories e Services podem ser compartilhados entre features.

### Decisoes

**1. Estrutura de pastas: UI por feature, Data por tipo**

Adotamos o padrao Flutter oficial:
- `ui/<feature>/` — ViewModel + Views + UseCase (acoplados a feature)
- `data/repositories/` + `data/services/` + `data/model/` — compartilhados entre features
- `domain/models/` — modelos de dominio imutaveis compartilhados
- `testing/` — subpacote para fakes e fixtures compartilhados

Motivacao: familiaridade para novos devs que conhecem o padrao Flutter, e compartilhamento real de repositories entre features.

**2. UseCase obrigatorio em todas as features**

Mesmo que a referencia Flutter trate UseCases como condicionais, decidimos mante-los obrigatorios por:
- Padronizacao (toda feature tem a mesma estrutura)
- Preparacao para crescimento (features simples hoje podem se tornar complexas)
- Indireçao util para testes (injetar fakes no UseCase em vez do Repository)

**3. Command pattern para acoes do usuario**

Alinhado com a recomendacao Flutter ("Recomendado"). Cada acao do usuario e um metodo no ViewModel que encapsula loading state, delegacao e tratamento de resultado.

**4. Modelos de API separados de modelos de dominio**

- `domain/models/` — modelos puros, imutaveis, sem logica de serializacao
- `data/model/` — API models com fromJson/toJson, mapeamento para domain models
- Repositories fazem a conversao entre os dois

**5. Fakes em `testing/` compartilhado**

Seguindo a recomendacao Flutter ("Fortemente recomendado"), fakes vivem em um diretorio `testing/` no mesmo nivel de `test/`, funcionando como um "subpacote" que pode ser importado por testes de outros packages.

### Consequencias
- Repositories ficam mais reutilizaveis (nao presos a uma feature)
- Mais arquivos na raiz do package (`data/`, `domain/`, `ui/`, `testing/`)
- Devs familiarizados com o padrao Flutter se orientam imediatamente
- UseCase presente mesmo em features simples (overhead minimo, consistencia maxima)
