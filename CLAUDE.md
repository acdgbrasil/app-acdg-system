# CLAUDE.md — Frontend ACDG (Conecta Raros)

> **REGRA #0: SEMPRE use o Dart MCP Server (`dart mcp-server`) para validar o codigo.**
> - Use `analyze_files` para rodar `dart analyze` nos arquivos modificados antes de considerar qualquer tarefa concluida.
> - Use `run_tests` para rodar testes dos packages afetados.
> - Use `dart_format` para formatar codigo modificado.
> - Use `dart_fix` para aplicar fixes automaticos quando disponivel.
> - **Setup:** `claude mcp add --transport stdio dart -- dart mcp-server`
>
> **REGRA #1: O handbook/ e a fonte de verdade arquitetural. SEMPRE consulte-o antes de tomar decisoes.**
> - `handbook/architecture/ARCHITECTURE.md` — arquitetura completa
> - `handbook/architecture/DECISIONS.md` — ADRs (decisoes imutaveis)
> - `handbook/architecture/DIAGRAMS.md` — diagramas visuais
> - `handbook/references/flutter_archteture/` — referencia oficial Flutter usada como base
> - `handbook/research/` — pesquisas que embasam as decisoes
>
> Em caso de conflito entre este CLAUDE.md e o handbook, **o handbook prevalece**.

## Repositorio

Monorepo Flutter/Dart do frontend da **ACDG Technology**. Contem o Shell (app principal), micro-apps por dominio, BFFs, design system e core compartilhado.

## Comandos

```bash
# Monorepo (Melos)
melos bootstrap                    # Instalar dependencias de todos os packages
melos run analyze                  # Lint em todos os packages
melos run test                     # Testes em todos os packages

# Shell (requer .env — copie .env.example e preencha)
cp apps/acdg_system/.env.example apps/acdg_system/.env  # Primeira vez: copiar e preencher
cd apps/acdg_system && flutter run -d macos --dart-define-from-file=.env
cd apps/acdg_system && flutter build web --wasm --release --dart-define-from-file=.env

# BFF
cd bff/social_care_bff && dart run bin/server.dart  # Rodar BFF server (Darto)
cd bff/social_care_bff && flutter test              # Testes do BFF (usa flutter test por dep transitiva)
cd bff/social_care_bff && dart compile exe bin/server.dart -o social-care-bff  # Build AOT

# Testes
flutter test                       # Testes do package atual
flutter test --coverage            # Testes com cobertura
```

## Arquitetura (resumo — detalhes no handbook/)

### Stack (ADR-001, ADR-002, ADR-008)
- **Flutter 3.x** (Web WASM + Desktop nativo sem webview)
- **Dart 3.x** (AOT para BFF, JIT para dev)
- **Provider** para DI (ADR-009)
- **GoRouter** para roteamento (deferred loading)
- **Dio** para HTTP client / **Darto** para HTTP server (BFF)
- **Isar** para offline storage (ADR-005)
- **package:oidc** (Bdaya-Dev) para auth OIDC (ADR-012)

### Padrao Arquitetural: MVVM + Logic Layer (ADR-003, ADR-013)

Alinhado com **Flutter Architecture Guidelines** oficiais. Detalhes em `handbook/architecture/ARCHITECTURE.md` secao 2.

```
Dados (downstream):
  Service -> Repository -> UseCase -> ViewModel -> View (ValueNotifier)

Acoes do usuario (upstream):
  View -> Command -> ViewModel -> UseCase -> Repository -> Service -> BFF -> API
```

| Camada | Responsabilidade |
|--------|-----------------|
| **View** | Exibe dados, captura eventos. NAO decide nada. |
| **ViewModel** | Estado atomico (ValueNotifier + ChangeNotifier). Logica de **UI** apenas. NAO contem logica de negocio. |
| **UseCase** | Orquestra Repositories. **Obrigatorio em todas as features** (ADR-013). Command pattern. |
| **Repository** | Fonte de verdade. Cache, retry, error handling. Classes abstratas para testabilidade. Compartilhados entre features. |
| **Service** | Wrapper puro de chamadas externas. Sem logica. |

### Estrutura de Pastas (ADR-013)

**UI por feature, Data por tipo, Domain compartilhado.** Segue recomendacao oficial Flutter.

```
monorepo/
+-- shell/                          # App principal (login + router)
+-- packages/
|   +-- design_system/              # Tokens + Atomic Design widgets
|   +-- core/                       # Shared: auth, network, platform, base
|   +-- social_care/                # Micro-app (ui/ por feature, data/ por tipo, domain/ compartilhado)
+-- bff/
|   +-- social_care_bff/            # BFF (EDD + DDD)
+-- handbook/                       # Documentacao viva (FONTE DE VERDADE)
```

Dentro de cada micro-app:
- `ui/<feature>/` — ViewModel + Views + UseCase (acoplados a feature)
- `data/repositories/` + `data/services/` + `data/model/` — compartilhados entre features
- `domain/models/` — modelos de dominio imutaveis
- `testing/` — fakes e fixtures compartilhados para testes

### Autenticacao (ADR-011, ADR-012)

- **Zitadel OIDC PKCE** com `package:oidc` (Bdaya-Dev)
- **Split-Token Pattern (Web):** Access Token em memoria Dart + Refresh Token em cookie HttpOnly
- **Desktop:** `flutter_secure_storage` (Keychain/DPAPI/libsecret)
- **3 Roles:** `social_worker` (CRUD), `owner` (read-only), `admin` (read + gestao)
- **NUNCA:** localStorage, sessionStorage ou cookies acessiveis por JS para tokens

### Micro-Frontend (ADR-004)
- Cada dominio e um package Dart em `packages/`
- Shell importa e registra rotas via deferred loading
- Um unico binario final

### Adaptive Design (ADR-006)
- 3 Pages por feature: Desktop, Web, Mobile
- ViewModel UNICA compartilhada entre plataformas
- Components (Atomic Design) compartilhados entre Pages

### BFF (ADR-002, ADR-007, ADR-008)
- **Web:** servidor Darto (HTTP) no Edge
- **Desktop:** in-process (package Dart importado diretamente)
- **Toda regra de negocio no BFF**, nunca no Flutter
- Frontend trata models como schemas puros

### Offline First (ADR-005)
- Isar para storage local
- SyncQueue com timestamp (CRDT-like)
- Auto-sync ao reconectar
- Conflito mesmo campo: resolucao manual / campos diferentes: merge automatico

## Convencoes

### Codigo
- **Idioma:** Code EN / UI PT-BR
- **Nomenclatura:** PascalCase para classes, camelCase para variaveis, snake_case para arquivos
- **Sufixos:** `*ViewModel`, `*UseCase`, `*Repository`, `*Service`, `*Page`, `*Model`
- **Imports:** SDK -> external -> internal -> relative
- **Models:** IMUTAVEIS (final em tudo, copyWith). Sem logica de negocio. (ADR-010)
- **Modelos de API separados de dominio:** `data/model/` (fromJson/toJson) vs `domain/models/` (puros) (ADR-013)
- **Testes:** Fakes em `testing/` compartilhado, nunca mocks magicos (ADR-013)

### Git
- **Branches:** `feat/<issue-id>-<slug>`, `fix/...`, `chore/...`, `docs/...`
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`)

### Ordem de Implementacao por Feature

```
Model -> Service -> Repository -> UseCase -> ViewModel -> View
```

De dentro para fora. NUNCA comece pela View.

### Principios Inegociaveis
- MVVM estrito com Command pattern
- Estado atomico (ValueNotifier + ChangeNotifier)
- Imutabilidade total nos Models
- Models como schemas (logica no BFF)
- UseCase obrigatorio em todas as features
- Fluxo de dados unidirecional
- Repository como classe abstrata (interface)
- Fakes para testes (nunca mocks magicos)
- Provider para DI (sem service locator)
- Atomic Design (Page > Template > Cell > Atom)
- GoRouter com deferred loading
- Offline First
- GoF Design Patterns quando aplicavel

## Segredos e Variaveis de Ambiente

- NUNCA hardcoded — usar `--dart-define-from-file=.env` para injetar em compile-time
- Bitwarden Secret Manager para valores de producao
- `${{ github.token }}` para GHCR
- **OIDC config:** `OIDC_ISSUER`, `OIDC_CLIENT_ID` (obrigatorios), `OIDC_WEB_REDIRECT_URI`, `OIDC_WEB_POST_LOGOUT_URI` (web only)
- **Web:** Split-Token Pattern — Access Token em memoria, Refresh Token em cookie HttpOnly (ADR-011)
- **Desktop:** Keychain/Credential Manager nativo via flutter_secure_storage
- **Client IDs:** cada plataforma tem seu proprio app no Zitadel (Native para desktop, Web para browser)
