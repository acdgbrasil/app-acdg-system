# ADRs — Architecture Decision Records

> Registro formal de todas as decisoes arquiteturais do frontend.
> Cada decisao e imutavel apos aceita. Novas decisoes podem substituir anteriores referenciando o ADR original.

---

## ADR-001 ate ADR-014
*(Consulte o histórico para detalhes dos ADRs anteriores. **Nota:** ADR-005 — Isar para offline storage — foi superseded por **ADR-021** em 2026-04-30.)*

---

## ADR-015: Uso Mandatório do Padrão Command para Ações de UI

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O gerenciamento manual de estados de "carregamento" (busy) e "erro" nos ViewModels gerava muito boilerplate e inconsistência visual entre telas.

### Decisão
Implementar e usar obrigatoriamente a classe `Command` (do package `core`) para qualquer operação assíncrona iniciada pela UI.

### Consequências
- ViewModels ficam mais limpos (menos flags booleanas).
- UI reage de forma consistente via `ListenableBuilder` aos estados do comando.
- Redução drástica de bugs de concorrência (Commands bloqueiam re-execução automática enquanto rodam).

---

## ADR-016: UseCases como Camada de Orquestração Mandatória

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
ViewModels estavam começando a acumular lógica de orquestração de dados e dependência direta de múltiplos Repositories.

### Decisão
Toda ação de negócio deve ser encapsulada em um `UseCase` que estende `BaseUseCase`. O ViewModel deve depender de `UseCases` e nunca de `Repositories`.

### Consequências
- Separação clara entre Lógica de UI (ViewModel) e Lógica de Negócio (UseCase).
- UseCases tornam-se testáveis em isolamento total de widgets.
- Facilidade de reutilização de orquestração entre diferentes ViewModels.

---

## ADR-017: Organização de UI via Atomic Design

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
Pastas de widgets estavam se tornando "sacos de arquivos" sem hierarquia clara de reuso.

### Decisão
Adotar rigorosamente o **Atomic Design**:
- `atoms/`: Componentes básicos, puros e agnósticos.
- `molecules/`: Composição de átomos com lógica visual local.
- `organisms/`: Seções complexas e independentes de página.
- `pages/`: Telas finais que conectam organismos ao ViewModel.

---

## ADR-018: Separação Root / Main e Injeção por Camadas

**Data:** 2026-03-13
**Status:** Aceito

### Contexto
O arquivo `main.dart` estava poluído com inicialização de infraestrutura, dificultando testes de integração e modularização.

### Decisão
1. `main.dart` apenas chama o `Root()`.
2. `root.dart` orquestra a injeção via `Provider` seguindo a ordem: `Data -> Logic -> UI`.
3. Repositories e UseCases são expostos na árvore de widgets para consumo via `context.read()`.

### Consequências
- Bootstrap do app limpo e profissional.
- Facilidade para trocar toda a camada de dados por `Fakes` nos testes.

---

## ADR-019: Parsers em Fronteira Adapter — P2 `if-case` como Default, P2b `try/catch` como Edge Case

**Data:** 2026-04-17
**Status:** Aceito
**Relacionado:** `PATTERN_MATCHING_POLICY.md §P2` / `§P2b`, skill `flutter-expert` §194 (`throw` só em adapter)

### Contexto
O monorepo adotou `if-case` (P2) como forma canônica de parsing em fronteiras adapter. Em A07–A09 (BFF Web handlers de Auth + Registry Patient + Registry Family), P2 funcionou bem porque os DTOs tinham 3–7 campos obrigatórios.

Em A10 (Assessment 7 fichas), cada DTO passou a ter 10–15 campos obrigatórios (`UpdateHousingConditionRequest` = 15). Aplicar P2 em todos os 7 intents exigiria ~80 checagens manuais duplicando o schema já gerado por `json_serializable`. Risco alto de drift quando DTOs evoluírem e boilerplate impossível de manter sync com o código gerado.

A primeira implementação usou `try { fromJson(body) } catch (_) { Failure(...) }` — resolveu o drift mas introduziu dois anti-patterns:
1. `catch (_)` descarta a cause — debug impossível em prod
2. Nenhum logging da exceção capturada

Reprovado em review ad-hoc. Hardening aplicado convertendo para `catch (e, st)` + `obs?.logError('<ficha>.parse_failed', cause: e, stack: st)`.

### Decisão

**1. P2 `if-case` continua default** para todos os parsers em adapter layer com <10 campos obrigatórios e sem PII-sensível.

**2. P2b (`try/catch` sobre `fromJson` gerado) é explicitamente aprovado** quando **todas as 3 condições do gatilho** convergem (ver `PATTERN_MATCHING_POLICY.md §P2b`):
   - Fronteira adapter (Intent / Handler / Mapper)
   - DTO tem `fromJson` gerado (`json_serializable` / `freezed` / `drift`)
   - ≥10 campos obrigatórios **OU** mensagem deve ser PII-safe estrutural

**3. Forma canônica P2b é obrigatória** (code review faz hard-reject em desvio):
   - `catch (e, st)` — nunca `catch (_)` nem `catch (e)` sem stack
   - `obs?.logError` com cause + stack (para AcdgLogger + Sentry)
   - `_XxxParseError` privada `final class with Equatable implements Exception`, `toString()` retornando string fixa
   - `ObservabilityContext? obs` opcional no parser (compat com testes)

**4. Checklist e fluxo de decisão** ficam em `PATTERN_MATCHING_POLICY.md §P2b` — referência obrigatória para agentes `test-writer` e implementer **antes** de escolher entre P2 e P2b. Adicionado ao checklist de code review.

### Consequências
- Parsers de DTOs "gordos" (Assessment, formulários complexos) escalam sem drift contra o schema gerado.
- Cause + stack sempre disponível para debug em prod (via AcdgLogger + Sentry).
- Mensagem de erro uniforme PII-safe — impede shape-leak para atacantes probing a API.
- Custo: ~15 linhas a mais por Intent vs `catch (_)`. Aceito.
- Agentes precisam consultar o fluxo de decisão §P2b antes de escrever qualquer parser — matéria de code review automático.

### Referência de implementação
- **Canon default (P2):** `bff/social_care_web/lib/src/intents/register_patient_intent.dart` (A08, 3 campos obrigatórios).
- **Edge case aprovado (P2b):** `bff/social_care_web/lib/src/intents/update_housing_condition_intent.dart` + 6 intents irmãos (A10, 10–15 campos cada).

### Superseded by
Nenhum.

---

## ADR-020: `IntentPayload` Record Carrier — Consideração Adiada

**Data:** 2026-04-17
**Status:** Adiado (consideração registrada; reavaliar sob gatilho)
**Relacionado:** ADR-019, `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão`

### Contexto

Durante a consolidação do canon pós-A12, surgiu a proposta de uniformizar a assinatura de todos os `Intent.parseFromBody` para um único tipo via Record Dart 3:

```dart
typedef IntentPayload = ({
  String id,
  Map<String, dynamic> body,
  ObservabilityContext? obs,
});

// P2 e P2b compartilham assinatura idêntica:
static Result<XxxIntent> parseFromBody(IntentPayload payload) {
  final (:id, :body, obs: _) = payload;  // P2: descarta obs via wildcard
  // ou
  final (:id, :body, :obs) = payload;    // P2b: extrai obs para logError
}
```

### Motivação apresentada

1. **Compatibilidade com P3 (tear-offs)**: assinaturas uniformes permitiriam passar parsers como `Result<T> Function(IntentPayload)` first-class em maps, routers dinâmicos, frameworks de fuzz testing.
2. **`obs: _` como declaração ativa de intenção**: o wildcard explicita que o autor do Intent P2 **sabe** que observabilidade existe e **decidiu** descartá-la. Mais rico semanticamente que "parâmetro ausente".
3. **Coerência idiomática**: amarra a regra de negócio P2b com a regra sintática P1/P3 (pattern matching + tear-offs) já documentada.

### Análise de trade-offs

**Prós (confirmados):**
- Tear-off habilitado de parsers como valores de primeira classe
- Retrofit de P2 → P2b toca apenas o Intent (assinatura imutável)
- `obs: _` carrega intenção no código

**Contras (confirmados):**
- **Nenhum use-case concreto hoje**: os 6 handlers (A07–A12) chamam `IntentEspecifico.parseFromBody(...)` nominalmente; não há `Map<String, ParseFunc>`, router dinâmico, nem framework batch. Tear-off é benefício teórico para este monorepo nos próximos 6 meses.
- **Retrofit custoso**: 29 Intents + 6 handlers + ~35 test files tocados. Estimativa 6–8h de trabalho meticuloso com ajuste de call-sites em testes.
- **Perda de informação na assinatura**: a heterogeneidade atual (`P2 sem obs, P2b com obs opcional`) **carrega informação útil** — lendo a assinatura, o dev sabe imediatamente qual estratégia o Intent usa. Com Record, essa informação é ocultada dentro do corpo do método.
- **Overhead cognitivo**: Record destructuring + wildcard pattern é mais avançado que parâmetro opcional nomeado. Curva de adoção real para novos devs.
- **Convivência de estilos**: se adotado apenas em A13+, 75% do monorepo fica em estilo velho vs 25% em estilo novo — janela quebrada, ambiguidade em code review.

### Decisão

**Adiado.** Manter canon atual com `{ObservabilityContext? obs}` opcional (ver `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão`).

Razões:
1. **YAGNI** — o benefício primário (tear-offs) não tem uso concreto previsto.
2. **Coerência imperfeita > perfeição fragmentada** — adotar em A13+ sem retrofit criaria convivência de estilos, pior que o status quo.
3. **Custo de oportunidade** — 6–8h de retrofit no meio de Onda 3 (A13–A15 pendentes) não se justifica por purismo idiomático.

### Gatilho de reavaliação

Reabrir esta decisão quando **qualquer** dos seguintes emergir:
- Router dinâmico mapeando URL → parser (ex: `Map<String, ParseFunc>`)
- Framework de fuzz testing exercitando parsers em batch
- Gateway reflexivo que descobre Intents por reflection/code-gen
- Necessidade de passar parsers como deps injetáveis em testes de handler
- Quinto Intent que precisa de P2b (hoje 8 Intents P2b entre A10 e A12; se crescer, custo unitário de retrofit cai)

### Se retrofit for aprovado no futuro

Ordem recomendada:
1. Criar `typedef IntentPayload` em `packages/core_contracts/`
2. Migrar Intents A07 (5) — suite canônica 87 tests valida
3. Progredir A08 → A12 em sequência (cada wave valida com 100+ tests)
4. Atualizar 6 handlers + testes de call-site
5. ADR-020 atualizado para status "Aceito"

### Referência
- Proposta completa: conversa-sessão 2026-04-17 (pós-A12 close-out)
- Análise de YAGNI: `PATTERN_MATCHING_POLICY.md §P2b § Carrier da decisão` + callout embedded

### Superseded by
Nenhum.

---

## ADR-021: Pivot Drift sobre Isar para Offline Storage (supersede ADR-005)

**Data:** 2026-04-30
**Status:** Aceito
**Supersede:** ADR-005 (Isar para offline storage, 2026-03-08)
**Relacionado:** A16-v2, A17-v2, A18-v2 (Onda 4 — Desktop rebuild)

### Contexto

ADR-005 (2026-03-08) prescrevia **Isar** como engine de offline storage para o monorepo Flutter ACDG, baseado nos seguintes argumentos da época:
- API NoSQL idiomática para Dart (schema por classe anotada)
- Performance superior em benchmarks de inserção/leitura
- Suporte a queries reativas via streams

Em **2026-04-29**, durante o re-baseline da Onda 4 (rebuild do `bff/social_care_desktop/`), a decisão foi reavaliada com pesquisa atualizada do ecossistema Flutter e análise das exigências de build modernas. **Três fatos novos invalidam a premissa do ADR-005:**

### 1. Manutenção do Isar colapsou

O autor original do Isar (Simon Leier) **abandonou o pacote**. Comunidade tentou manter via forks (`isar_community`, `isar_plus`) mas threads recentes (2025-2026) em r/FlutterDev e GitHub mostram:
- Issues críticos de produção sem resposta há meses
- Forks instáveis com regressões em queries complexas
- Migração ativa de desenvolvedores **de volta para Drift** para garantir estabilidade

**Risco:** adotar Isar em código novo significa apostar em dependência sem mantenedor — débito técnico inevitável.

### 2. Incompatibilidade com Swift Package Manager (SPM)

Flutter está **adotando SPM como padrão**, depreciando CocoaPods. Isar depende de **binários Rust pré-compilados** que falham sob hooks de build do SPM:
- Issue #1750 do repo Isar (aberta, sem resolução): "Support for Swift Package Manager"
- Build hooks modernos não conseguem resolver os artefatos Rust ofuscados
- Workarounds requerem patches manuais a cada release

Drift, em contraste, usa **`sqlite3` nativo** que se adapta cleanly aos hooks modernos do Dart e SPM (via `sqlite3_flutter_libs` em produção e `sqlite3` Dart package em testes).

### 3. Drift tem Isolates de primeira classe

O `SyncEngine` offline-first (A18-v2) precisa rodar em background sem travar UI. Drift é a **única biblioteca de persistência embarcada robusta no Flutter** com:
- Suporte multithread testado para Isolates
- API `IsolatedExecutor` documentada e estável
- Compatibilidade fluida com `compute()` e isolates Dart

Isar tem APIs de isolate marcadas como experimentais e instáveis nos forks comunitários.

### Decisão

**Pivot Isar → Drift** para todo offline storage no monorepo, em escopos novos OU re-implementados:

1. **`bff/social_care_desktop/lib/src/cache/`** (A17-v2) — implementado com Drift, FTS5 + 6 triggers, schema denormalizado JSON-blob + B-Tree indices. Closed 2026-04-30, commit `891814a`. **`feat consummated`**.
2. **`bff/social_care_desktop/lib/src/sync/`** (A18-v2 — pendente) — usará `SyncDatabase` em arquivo `.sqlite` físico separado (`app_sync_queue.sqlite`), também via Drift, com migration strategy versionada (Outbox protection contra Data Loss).
3. **`packages/social_care/`** (Fase 4 — Flutter migration) — quando o frontend Flutter for reescrito para consumir o BFF rebuilt, o storage local também migrará para Drift. Não há ação imediata; Fase 4 será disparada após Onda 5 da Fase 3.

### Justificativa

| Critério | Isar (ADR-005) | Drift (ADR-021) |
|---|---|---|
| Manutenção upstream | Abandonada | Ativa, single maintainer com release cadence |
| SPM compatibility | Quebrada (Issue #1750) | Funcional via `sqlite3_flutter_libs` |
| Isolates | Experimentais | Primeira classe (`IsolatedExecutor`) |
| Type safety | Reflexiva (annotations + codegen) | Compile-time (relacional + codegen) |
| FTS / busca textual | API limitada | FTS5 nativo via `customStatement` |
| Schema strategy | NoSQL (object store) | Relacional + JSON-blob híbrido |
| Migration tooling | Limitada | Drift `MigrationStrategy` + schema dumps |

A combinação **manutenção ativa + SPM compat + Isolates first-class** torna Drift a escolha correta. Os benefícios originais do Isar (NoSQL idiomática, performance) não compensam o risco de dependência abandonada e build quebrado.

### Consequências

**Imediatas:**
- ADR-005 fica historicamente registrado como decisão correta para o contexto da época, mas tecnicamente superseded.
- Schema de cache desktop é denormalizado JSON-blob (DTO completo no `payload` TEXT) com B-Tree indices em colunas filtráveis (`id`, `personId`, `status`, `eventType`) e FTS5 virtual tables onde busca textual é necessária (`patient_summaries_fts`, `lookup_tables_fts`).
- A18-v2 deve criar `SyncDatabase` em arquivo físico SEPARADO do `CacheDatabase` (Outbox protection — perda de fila de sync = perda de mutations offline = Data Loss).

**Para Fase 4 (Flutter migration):**
- Quando `packages/social_care/` for migrado para consumir o BFF rebuilt, o storage local migrará para Drift no mesmo movimento. NÃO migrar incrementalmente — break-change autorizado pelo mesmo precedent que Onda 4 aplicou ao desktop.
- Não recomendar Isar em code reviews de novos componentes offline-first. Se um agente sugerir Isar baseado em ADR-005, citar ADR-021.

**Para o ecossistema do projeto:**
- `package:persistence` (em `packages/persistence/`) provavelmente continua usando Drift — verificar e alinhar build.yaml com o cache desktop quando relevante.
- Documentação histórica em `handbook/architecture/ARCHITECTURE.md`, `DIAGRAMS.md`, `BFF_IMPLEMENTATION_PLAN.md` que mencionam Isar como engine **estão desatualizadas**; updates incrementais vão ocorrer conforme cada doc é tocado em fases futuras (não é necessário re-escrever tudo agora — ADR-021 declara a verdade canônica e supera o que estiver no prose).

### Gatilho de reavaliação

Reabrir esta decisão se **qualquer** dos seguintes emergir:
- Isar restaura manutenção ativa com mantenedor estável + roadmap declarado
- Isar publica suporte oficial a SPM (Issue #1750 fechada com release)
- Drift tem regressão crítica de performance ou abandono de mantenedor
- Surge alternativa Dart-native superior (e.g. ObjectBox Dart com SPM compat) que justifique avaliação

### Histórico de pesquisa

Decisão fundamentada em:
- r/FlutterDev threads 2025-2026 sobre migração Isar → Drift
- Issue #1750 do Isar (Swift Package Manager support)
- Análise comparativa SPM compatibility entre Isar (Rust binaries) e Drift (sqlite3 native)
- Validação prática durante A17-v2 — Drift + FTS5 + 6 triggers funcionou cleanly em 81/81 tests com `NativeDatabase.memory()`

### Referência

- Conversa-sessão 2026-04-29: alinhamento de break-change da Onda 4 + decisão Drift-stays
- Conversa-sessão 2026-04-30: revisão Architect (CQRS + Aggregate Root + Outbox protection) + correção FTS5
- Implementação concreta: commits `4bda87f` (A16-v2), `891814a` (A17-v2)
- Memória do projeto: `~/.claude/projects/-Users-gabriel-aderaldo-Desktop-Projetos-dev-envolve-acdg-frontend/memory/project_drift_stays_adr_005_pivot.md`

---

## ADR-022: Reorganização do Monorepo — kernel/infra/apps Layout

**Data:** 2026-05-01
**Status:** Aceito
**Relacionado:** D1.C delete (commit `33626f0`), Phase 5 CLI-first kickoff

### Contexto

Antes de iniciar a Fase 5 (CLI-first), o usuário pediu reorganização da estrutura monorepo:
- "TUDO sem interação com usuário é um APP" — definição expandida de "aplicação"
- Necessidade de suportar múltiplas apps independentes (CLI, BFF, Flutter UI futura, analytics_bi futuro)
- Cada app deve poder ter sua própria lógica/arquitetura
- Nomenclatura "shared" considerada genérica demais

Layout anterior (`packages/ + bff/`) tratava `bff/` como cidadão de segunda classe (não-app) e agrupava todas as libs sob `packages/` sem distinção semântica entre primitives Dart-puros e impl concrete.

### Decisão

Reorganizar o monorepo em três buckets semânticos, mantendo **Dart Workspaces 3.6+ idiomático** (single workspace global por enquanto, preparado para evolução a workspaces independentes per-app):

```
acdg-frontend/
├── kernel/      — Dart-pure foundation (contracts, lints)
├── infra/       — Flutter-coupled infrastructure (runtime, transport, storage)
└── apps/        — Unidades entregáveis (social_care_bff = web+desktop+contracts; cli; ...)
```

**Mapping** (todos os nomes de packages preservados — só pastas mudam):
- `packages/core_contracts/` → `kernel/contracts/`
- `packages/acdg_lints/` → `kernel/lints/`
- `packages/core/` → `infra/runtime/`
- `packages/network/` → `infra/transport/`
- `packages/persistence/` → `infra/storage/`
- `bff/shared/` → `apps/social_care_bff/contracts/`
- `bff/social_care_web/` → `apps/social_care_bff/web/`
- `bff/social_care_desktop/` → `apps/social_care_bff/desktop/`

### Justificativa

| Critério | packages/ + bff/ (anterior) | kernel/ + infra/ + apps/ (atual) |
|---|---|---|
| Semântica de pasta | Genérica ("packages") | Explícita (kernel/infra/apps) |
| BFF status | Pasta especial fora de packages | First-class app em `apps/` |
| Onboarding novo dev | "O que é o quê?" | Auto-explicativo |
| Multi-app readiness | `apps/` não existia | Cada app já em `apps/<x>/` |
| Promoção a Padrão B | Refactor maior | Mecânico (adicionar pubspec.yaml na app) |
| Dart idiomático | Workspace 3.6+ | Workspace 3.6+ (mantido) |

### Decisões secundárias

1. **Names dos packages preservados** — `core_contracts`, `core`, `network`, `persistence`, `acdg_lints`, `shared`, `social_care_web`, `social_care_desktop`. Imports `package:X` continuam idênticos. Renomeação eventual fica como ticket separado pós-CLI estabilizar.

2. **Workspace global mantido por agora** — Padrão B real (workspaces independentes por app) é diferido. Layout já preparado para promoção mecânica quando primeira app divergir em versões.

3. **Phase 3 BFF sagrada preservada** — todos os 2036 testes GREEN intactos pós-migração. Apenas paths em pubspec.yaml mudam; imports e código não.

### Consequências

**Imediatas:**
- 8 entries no workspace raiz (era 13 antes, perdeu 5 com D1.C delete)
- Path deps cruzados atualizados em `infra/runtime/`, `apps/social_care_bff/{contracts,web,desktop}/pubspec.yaml`
- `dart analyze` zero errors em src/ dos 3 BFFs
- `flutter test` 2036 GREEN (535 contracts + 1075 web + 426 desktop +1 skip)
- Doc canônico: `handbook/architecture/MONOREPO_LAYOUT.md`

**Para Phase 5 (CLI-first):**
- CLI nasce em `apps/cli/` no layout novo
- Path deps pra `kernel/contracts/` e `apps/social_care_bff/contracts/` são naturais (co-located em apps/)

**Para futuras apps (Phase 6+):**
- `apps/social_care_ui/`, `apps/analytics_bi/` etc. seguem o mesmo padrão
- Cada app pode ter sua própria arquitetura interna (MVVM, Clean, BLoC, etc.) sem afetar outras

**Histórico documental:**
- Docs em `handbook/chat/`, `handbook/audit/`, `handbook/missions/`, `handbook/reports/` com paths antigos **NÃO foram atualizados** — preservam histórico imutável.
- Docs vivos (`handbook/architecture/*`) referenciam paths antigos esporadicamente; updates incrementais ocorrerão conforme cada doc é tocado.

### Gatilho de evolução para Padrão B real

Promover uma app específica a workspace independente quando:
- Precisa de Flutter SDK diferente do resto
- Versão de dep crítica (Riverpod, Bloc, Dio) precisa divergir
- CI quer pipelines separados (deploy independente)

Procedimento:
1. Adicionar `pubspec.yaml` na app com `workspace: [<members>]`
2. Remover entries da app do `pubspec.yaml` raiz
3. App passa a ter próprio `pubspec.lock`
4. Melos `--scope` continua funcionando

### Histórico de pesquisa

Decisão fundamentada em (sessão 2026-05-01):
- https://docs.flutter.dev/packages-and-plugins/developing-packages
- https://pub.dev/packages/melos (v7.x — workspaces idiomático)
- https://medium.com/flutter-community/managing-multi-package-flutter-projects-with-melos-c8ce96fa7c82
- https://dart.dev/tools/pub/dependencies (path packages)
- https://dart.dev/tools/pub/workspaces (Dart 3.6+)

### Referência

- Layout doc: `handbook/architecture/MONOREPO_LAYOUT.md`
- Migration commit: (pendente — a ser registrado quando este ADR for commitado)
- Session reports: `handbook/reports/SESSION_2026_04_29_A16_V2_DESKTOP_REBUILD.md`, `handbook/reports/SESSION_2026_04_30_A17_V2_DESKTOP_CACHE.md`

### Superseded by
Nenhum.
