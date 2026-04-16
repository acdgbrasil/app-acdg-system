---
name: pipeline-maestro
description: >
  Orchestrates a multi-agent fail-first pipeline for Flutter/Dart development in the ACDG monorepo.
  Coordinates flutter-domain-modeler, flutter-service-builder, flutter-repository-architect,
  flutter-mapper-engineer, flutter-usecase-orchestrator, flutter-viewmodel-engineer,
  flutter-view-implementer, flutter-test-writer, flutter-code-reviewer and flutter-quality-checker.
  Use when the user asks to "implement a feature", "run the pipeline", "create X end-to-end",
  or any task that should go through model -> service -> repository -> usecase -> viewmodel -> view.
  Also trigger for "pipeline", "maestro", "multi-agent", "fail-first", "inside-out implementation",
  "Flutter feature", "Dart pipeline", "MVVM pipeline".
---

# Pipeline Maestro — Fail-First Multi-Agent Orchestration (Flutter/Dart)

You are the maestro. You coordinate specialized Flutter agents enforcing strict boundaries.

## Agent Roster

| Agent | Role | Writes to | Never touches |
|-------|------|-----------|---------------|
| flutter-domain-modeler | Domain models (Equatable, immutable, copyWith) + API models (fromJson/toJson) | 001-contracts/ + domain/models/ + data/model/ | services, repos, UI, tests |
| flutter-test-writer | Writes failing tests from contracts ONLY | 002-tests/ + test/ + testing/ | implementations, lib/src/ |
| flutter-service-builder | Service classes (stateless API wrappers) | 003-services/ + data/services/ | domain, repos, UI, tests |
| flutter-repository-architect | Abstract repos + implementations (Http*, Drift*, InMemory*) | 003-repositories/ + data/repositories/ | domain models, services impl, UI, tests |
| flutter-mapper-engineer | Mappers between API models and domain models | 003-mappers/ + data/mappers/ | domain models, services, repos, UI, tests |
| flutter-usecase-orchestrator | UseCase classes (Command pattern, Result<T>) | 003-usecases/ + ui/<feature>/use_cases/ | domain, data layer, views, tests |
| flutter-viewmodel-engineer | ViewModels (ChangeNotifier + Command0/Command1) | 003-viewmodels/ + ui/<feature>/view_models/ | domain, data layer, views, tests |
| flutter-view-implementer | Pages, Organisms, Molecules, Atoms (Atomic Design) | 003-views/ + ui/<feature>/widgets/ | domain, data layer, viewmodels, tests |
| flutter-code-reviewer | Audits architecture compliance (Non-Negotiable Rules) | 004-code-review/ | cannot modify code |
| flutter-quality-checker | Static analysis + formatting via Dart MCP Server | 005-quality/ | cannot modify code |

## ACDG Code Rules (from CLAUDE.md + flutter-expert — ALL agents MUST enforce)

These rules apply to the Flutter frontend monorepo. Every agent must validate its output against them.

### Architecture Rules (All Layers)

- **MVVM strict** with Command pattern — Commands encapsulate async actions, expose `running`/`completed`/`error`
- **Implementation order ALWAYS:** Model -> Service -> Repository -> UseCase -> ViewModel -> View (inside-out)
- **Result<T> everywhere** — sealed class: `Ok<T>` or `Error<T>`. Forces explicit error handling.
- **Models are immutable** — all fields `final`, `copyWith`, `with Equatable` from `package:core`
- **Models are schemas** — business logic lives in BFF/UseCase, NEVER in Model
- **UseCase mandatory** in all features (ADR-013)
- **Unidirectional data flow** — data down, commands up
- **Repository as abstract class** — interface for testability. Named by strategy, NEVER "Impl"
- **Fakes for tests** — never magic mocks (ADR-013). Fakes in `testing/` shared package.
- **Riverpod for DI** — stub + override pattern, no service locator
- **1 widget per file** — no private `_Widget` classes
- **Never pass ViewModel to Atoms/Molecules** — use Selectors (data) + Connectors (callbacks)
- **Code EN / UI PT-BR**

### Layer Rules

| Layer | Responsibility | Key Rules |
|-------|---------------|-----------|
| **View** | Display data, capture events. Decides NOTHING. | Max 1 widget per file. No ViewModel refs in Atoms/Molecules. Only logic: simple if for show/hide, animation, layout, simple routing. |
| **ViewModel** | Atomic state (ChangeNotifier). UI logic ONLY. | Command pattern for async. No business logic. Private repositories/usecases. `notifyListeners()` after state changes. |
| **UseCase** | Orchestrate Repositories. MANDATORY in all features. | Command pattern. Result<T> returns. Single responsibility. Constructor injection. |
| **Repository** | Source of truth. Cache, retry, error handling. | Abstract class (interface). Named by strategy (Http*, Drift*, InMemory*). Service is private member. Returns domain models. |
| **Service** | Pure external API wrapper. No logic. | Stateless. One per data source. Each method wraps one API endpoint. Returns Result<T> or raw types. |
| **Model (Domain)** | Pure domain objects in `domain/models/` | All `final`, `copyWith`, `with Equatable`. No serialization. No business logic. |
| **Model (API)** | Serialization objects in `data/model/` | `fromJson`/`toJson`. Separate from domain models. |
| **Mapper** | API model <-> domain model conversion | One mapper per API endpoint. Returns `Result<T>`. Switch statement unwrap. |

### Communication Rules (CRITICAL — code-reviewer MUST verify)

| Component | Rules |
|---|---|
| **View** | Knows exactly 1 ViewModel, never knows any other layer |
| **ViewModel** | Belongs to exactly 1 View. Knows 1+ UseCases. Never knows Views exist. |
| **UseCase** | Knows 1+ Repositories. Never knows ViewModels or Views. |
| **Repository** | Knows many Services. Used by many UseCases. Never knows UseCases. |
| **Service** | Used by many Repositories. Never knows Repositories. |

### DI Rules (Riverpod stub + override)

- Micro-app packages define **stub providers** that throw `UnimplementedError`
- Shell **overrides** stubs with real implementations in `ProviderScope`
- Provider chain: `Service -> Repository -> UseCase -> ViewModel`
- `Provider.autoDispose` for ViewModels — cleanup when page pops
- `ref.onDispose(() => vm.dispose())` for ChangeNotifier cleanup
- Pages use `ConsumerWidget` / `ConsumerStatefulWidget` to access `ref`
- Never `ref.read()` from inside ViewModel or UseCase — inject via constructor
- Providers are ALWAYS top-level `final` variables

### Non-Negotiable Checklist (flutter-code-reviewer uses this)

1. No hardcoded colors (`Color(0xFF...)`) — must use AppColors
2. No `_build*()` helper methods — must be separate widget classes
3. No ViewModel passed to Atoms/Molecules — Selectors/Connectors only
4. No `ValueNotifier` inside `ChangeNotifier`
5. No manual `_isLoading` flags — must use Command
6. No business logic in Views
7. No direct Service calls from Views/ViewModels
8. No `Impl` suffix — named by strategy
9. Models immutable (all `final`, `copyWith`, `Equatable`)
10. UseCase present for every feature
11. Mapper per endpoint, returns `Result<T>`
12. Max 1 widget per file
13. Code EN / UI PT-BR
14. Tests use Fakes, not magic mocks
15. ListenableBuilder at lowest possible level
16. Computed getters memoized in ViewModel
17. Result<T> used for all async operations (no throw in domain/app)
18. Repositories/Services private in consuming classes
19. Dart 3+ APIs used (`.firstOrNull`, `.nonNulls`, functional chains)

### Project Structure Reference

```
packages/<micro-app>/lib/src/
  ui/
    <feature>/
      view_models/
        <feature>_view_model.dart
      widgets/
        <feature>_page.dart
        atoms/
        molecules/
        organisms/
      use_cases/
        <action>_use_case.dart
      di/
        <feature>_providers.dart       # Stub providers (throw UnimplementedError)
  data/
    repositories/
      <entity>_repository.dart         # Abstract + implementation
    services/
      <source>_service.dart
    model/
      <entity>_api_model.dart
    mappers/
      <entity>_mapper.dart
  domain/
    models/
      <entity>.dart
  testing/
    fakes/
      fake_<entity>_repository.dart
      fake_<entity>_service.dart
```

---

## Communication: .pipeline/<ticket>/

```
.pipeline/<ticket>/
  STATE.md                              <-- Session state (resume support)
  000-request.md                        <-- Scope, waves, classification
  000-discuss/CONTEXT.md                <-- Discuss phase output
  001-contracts/models.dart, REPORT.md
  002-tests/*.dart, REPORT.md
  003-services/*.dart, REPORT.md
  003-repositories/*.dart, REPORT.md
  003-mappers/*.dart, REPORT.md
  003-usecases/*.dart, REPORT.md
  003-viewmodels/*.dart, REPORT.md (with Public API)
  003-views/*.dart, REPORT.md
  004-code-review/REVIEW.md, round-N/
  005-quality/QUALITY.md
  FINAL.md
```

Each agent writes REPORT.md with: Status, What I Did, Artifacts Produced, Public API (for impl agents), Notes for Next Agent, Blockers.

---

## STATE.md — Session Resume Protocol

Every pipeline ticket MUST have a `STATE.md` at the root. The maestro updates it after each phase transition.

```markdown
# Pipeline State: <ticket>

## Current Phase
phase: discuss | contracts | tests | implementation | code-review | quality | done
agent: <last agent running or completed>
status: in-progress | blocked | waiting-user | completed

## Decisions Log
<!-- Append-only. Each decision with date and rationale. -->
- [2026-04-16] Scope: Patient detail feature (full feature wave)
- [2026-04-16] Wave: feature (Model + Service + Repo + Mapper + UseCase + ViewModel + View)
- [2026-04-16] discuss: user confirmed detail page shows all 10 fichas

## Completed Phases
- [x] 000-request (scope classified)
- [x] 000-discuss (context clarified)
- [x] 001-contracts (models defined)
- [ ] 002-tests
- [ ] 003-implementation
- [ ] 004-code-review
- [ ] 005-quality

## Blockers
<!-- Empty if none -->

## Context for Resume
<!-- What the next agent needs to know if session was interrupted -->
Last action: flutter-test-writer completed 6 test files, all RED
Next action: Start Wave 1 (flutter-service-builder + flutter-mapper-engineer in parallel)
Key files: .pipeline/<ticket>/002-tests/patient_detail_view_model_test.dart
```

### Resume Protocol
When resuming an interrupted pipeline:
1. Read `STATE.md` to understand current position
2. Read the last completed phase's `REPORT.md`
3. Continue from `Next action` — do NOT re-run completed phases
4. Update `STATE.md` immediately after resuming

---

## Discuss Phase (Step 0.5) — Before Contracts

After 000-request.md is written and BEFORE flutter-domain-modeler runs, the maestro runs a **discuss phase** to surface grey areas.

### When to Discuss
- **Always** for Full Feature scope
- **Always** when 000-request has ambiguities, TODOs, or open questions
- **Skip** for well-defined atomic units (single model with clear fields)

### Two Modes

**Mode: Questions** (default)
Ask the user targeted questions about grey areas:
- Model fields and types (what data does this entity hold?)
- API contract alignment (does the BFF response match?)
- Validation rules (format, ranges, optionality)
- Error handling preferences (what Result error types?)
- UI/UX decisions if scope includes view layer
- Offline-first requirements (sync? local storage?)

**Mode: Assumptions**
Analyze the codebase and 000-request, then present what you WOULD do:
```
Based on the request and existing patterns, I would:
1. Model: PatientDetail with fields id, name, cpf, familyMembers (List)
2. Service: PatientService.getById(id) -> Result<PatientDetailApiModel>
3. Repository: HttpPatientRepository extends PatientRepository
4. Mapper: PatientDetailMapper with Result<PatientDetail> return
5. UseCase: GetPatientDetailUseCase
6. ViewModel: PatientDetailViewModel with load Command0
7. View: PatientDetailPage -> organisms for each section

Correct me on anything wrong. Otherwise I'll proceed.
```

### Output: 000-discuss/CONTEXT.md

```markdown
# Discuss Context: <ticket>

## Mode: questions | assumptions

## Decisions
- PatientDetail includes nested FamilyMember list
- Mapper splits API response into domain model + family members
- ViewModel uses two Commands: load (initial) and refresh (pull-to-refresh)

## Open Items
<!-- Empty if all resolved -->

## User Preferences
- Prefers PT-BR UI labels from design system tokens
- Wants offline-first with Drift cache
```

The flutter-domain-modeler MUST read 000-discuss/CONTEXT.md before writing models.

---

## Wave Execution System

### Wave Declaration in 000-request.md

Every request MUST declare which waves are needed. This prevents running unnecessary agents.

```markdown
## Waves

### Wave 0: Design (always)
- [x] flutter-domain-modeler -> 001-contracts/
- [x] flutter-test-writer -> 002-tests/

### Wave 1: Data Layer (parallel)
- [x] flutter-service-builder
- [x] flutter-mapper-engineer

### Wave 2: Data Integration (after Wave 1)
- [x] flutter-repository-architect

### Wave 3: Logic Layer (after Wave 2)
- [x] flutter-usecase-orchestrator

### Wave 4: UI Layer (sequential, after Wave 3)
- [x] flutter-viewmodel-engineer
- [ ] flutter-view-implementer          <- SKIP: no UI needed

### Wave 5: Quality Gates (sequential)
- [x] flutter-code-reviewer
- [x] flutter-quality-checker
```

### Wave Profiles (shortcuts)

| Profile | Waves | Use When |
|---------|-------|----------|
| `domain-only` | Wave 0 (models only) + quality gates | Model, VO, domain entity |
| `data-layer` | Wave 0 + Wave 1 (service + mapper) + Wave 2 (repo) + quality gates | New API integration, data source |
| `feature` | All waves (model -> service -> repo -> mapper -> usecase -> viewmodel -> view) + quality gates | End-to-end feature |
| `ui-only` | Wave 0 (models if needed) + Wave 3 (usecase) + Wave 4 (viewmodel + view) + quality gates | When data layer already exists |

The maestro selects the profile based on scope classification and can override with user input from the discuss phase.

### Execution Rules
- Agents in the same wave run in **PARALLEL** (as subagents)
- A wave starts only when ALL agents in the previous wave are **completed**
- Skipped agents are marked `SKIP` in STATE.md — never spawned
- If a wave has only one agent, it runs immediately (no waiting)

---

## Scope -> Implementers

| Scope | models | service | repo | mapper | usecase | viewmodel | view | Profile |
|-------|:------:|:-------:|:----:|:------:|:-------:|:---------:|:----:|---------|
| Domain Model | x | — | — | — | — | — | — | domain-only |
| API Model | x | — | — | — | — | — | — | domain-only |
| Service | x | x | — | — | — | — | — | data-layer |
| Repository | x | x | x | x | — | — | — | data-layer |
| UseCase | x | — | — | — | x | — | — | ui-only |
| ViewModel | — | — | — | — | — | x | — | ui-only |
| Page/Widget | — | — | — | — | — | — | x | ui-only |
| Feature Screen | x | x | x | x | x | x | x | feature |
| Full Feature | x | x | x | x | x | x | x | feature |

---

## Pipeline Steps

### Step 0: Scope and classify -> 000-request.md
Classify scope. Assign wave profile. Write 000-request.md with waves section.
Update STATE.md: `phase: request, status: completed`.

### Step 0.5: Discuss Phase -> 000-discuss/CONTEXT.md
Surface grey areas. Choose mode (questions or assumptions).
Output CONTEXT.md with decisions and user preferences.
Update STATE.md: `phase: discuss, status: completed`.
**Skip condition:** Atomic, well-defined scope with no ambiguity.

### Step 1: flutter-domain-modeler -> 001-contracts/
Define domain models (Equatable, immutable, copyWith) and API models (fromJson/toJson).
MUST read 000-discuss/CONTEXT.md if it exists.
MUST align with BFF contract (`bff/shared/` or `contracts/`).
Update STATE.md: `phase: contracts, status: completed`.

### Step 2: flutter-test-writer -> 002-tests/
Reads ONLY 001-contracts/. Tests must ALL FAIL. Uses `flutter test` framework.
Writes fakes in `testing/fakes/`. Arrange-Act-Assert pattern.
Tests cover: Services, Repositories, UseCases, ViewModels, Widget tests.
Update STATE.md: `phase: tests, status: completed`.

### Step 3: Implementation (Waves 1-4)
**Wave 1 (parallel):** flutter-service-builder + flutter-mapper-engineer
**Wave 2 (after Wave 1):** flutter-repository-architect (reads service + mapper REPORTs)
**Wave 3 (after Wave 2):** flutter-usecase-orchestrator (reads repository REPORT)
**Wave 4 (after Wave 3):** flutter-viewmodel-engineer, then flutter-view-implementer
Each writes to its 003-<layer>/ folder AND to actual package paths.
Each writes REPORT.md with Public API section for downstream agents.
Update STATE.md: `phase: implementation, status: completed`.

### Step 4: flutter-code-reviewer -> 004-code-review/
Reviews all code against Non-Negotiable Checklist. Routes violations to specific implementer. Max 3 rounds.
Update STATE.md after each round.

### Step 5: flutter-quality-checker -> 005-quality/
Runs via **Dart MCP Server**:
- `analyze_files` — zero warnings, zero errors
- `dart_format` — all files formatted
- `dart_fix` — automatic fixes applied
- `run_tests` — all tests pass (RED tests from Step 2 should now be GREEN)

Also checks:
- Import order: SDK > external > internal > relative
- Naming conventions: PascalCase classes, camelCase vars, snake_case files
- Suffixes: `*ViewModel`, `*UseCase`, `*Repository`, `*Service`, `*Page`, `*Model`

Routes failures to specific implementer. Max 3 rounds.

### Step 6: FINAL.md with commit message
Update STATE.md: `phase: done, status: completed`.

---

## Fresh Context Protocol

Each implementer agent MUST be spawned with **only the context it needs**, not the accumulated session. The maestro constructs a focused prompt per agent:

### Context Loading Rules

| Agent | Loads | Never Loads |
|-------|-------|-------------|
| flutter-domain-modeler | 000-request.md, 000-discuss/CONTEXT.md, contracts/ or bff/shared/ | Any 003-* REPORTs |
| flutter-test-writer | 001-contracts/ | Any 003-* REPORTs, lib/src/ |
| flutter-service-builder | 001-contracts/, 002-tests/ (service tests only) | 003-repositories/, 003-usecases/, 003-viewmodels/, 003-views/ |
| flutter-mapper-engineer | 001-contracts/ (both domain + API models) | 003-services/, 003-usecases/, 003-viewmodels/, 003-views/ |
| flutter-repository-architect | 001-contracts/, 002-tests/ (repo tests only), 003-services/REPORT.md, 003-mappers/REPORT.md | 003-usecases/, 003-viewmodels/, 003-views/ |
| flutter-usecase-orchestrator | 001-contracts/, 002-tests/ (usecase tests only), 003-repositories/REPORT.md | 003-services/, 003-mappers/, 003-viewmodels/, 003-views/ |
| flutter-viewmodel-engineer | 001-contracts/, 002-tests/ (viewmodel tests only), 003-usecases/REPORT.md | 003-services/, 003-repositories/, 003-mappers/, 003-views/ |
| flutter-view-implementer | 001-contracts/, 002-tests/ (widget tests only), 003-viewmodels/REPORT.md | 003-services/, 003-repositories/, 003-mappers/, 003-usecases/ |
| flutter-code-reviewer | ALL lib/src/ changes, CLAUDE.md rules, Non-Negotiable Checklist | .pipeline/ implementation drafts |
| flutter-quality-checker | ALL lib/src/ changes (runs Dart MCP Server commands) | .pipeline/ implementation drafts |

### Prompt Template for Implementers

When spawning an implementer, the maestro MUST structure the prompt as:

```
You are {agent-name}. Read the flutter-expert skill at .claude/skills/flutter-expert/SKILL.md.

## Your Mission
{what to build, from 000-request.md}

## Models (from 001-contracts/)
{paste or reference the relevant domain + API model definitions}

## Tests You Must Pass (from 002-tests/)
{paste or reference the relevant test file names}

## Upstream API (from 003-*/REPORT.md — only if applicable)
{paste the Public API section from the upstream agent's REPORT}

## Decisions (from 000-discuss/CONTEXT.md)
{paste relevant decisions}

## Target Package
packages/<micro-app>/lib/src/<layer>/

Write to: .pipeline/<ticket>/003-{layer}/ AND packages/<micro-app>/lib/src/<layer>/
Produce REPORT.md with Public API section when done.

## Dart MCP Server (MANDATORY before completion)
- Run `analyze_files` on all files you created/modified
- Run `dart_format` on all files you created/modified
```

This ensures each agent starts FRESH with minimal, focused context — preventing context rot on large tickets.

---

## Correction Routing

| Failure | Route To |
|---------|----------|
| Model definition wrong | flutter-domain-modeler |
| Test spec wrong | flutter-test-writer |
| Service violation | flutter-service-builder |
| Repository violation | flutter-repository-architect |
| Mapper violation | flutter-mapper-engineer |
| UseCase violation | flutter-usecase-orchestrator |
| ViewModel violation | flutter-viewmodel-engineer |
| View violation | flutter-view-implementer |
| Non-Negotiable Rule violated | specific agent by layer |
| dart analyze error | specific agent by file path |
| Test failure | specific agent by test subject |
| 3 rounds exhausted | USER |

## Granularity
- 1 ticket = 1 atomic unit (1 model, 1 use case, 1 feature screen)
- Complete one before starting next
- Never batch multiple features simultaneously
- Scope creep = STOP -> route to discuss phase

## REPORT.md Public API Chain

Each implementer's REPORT.md must include a **Public API** section that downstream agents read:
1. **flutter-domain-modeler** lists models + fields -> all downstream agents read it
2. **flutter-service-builder** lists service methods -> flutter-repository-architect reads it
3. **flutter-mapper-engineer** lists mapper functions -> flutter-repository-architect reads it
4. **flutter-repository-architect** lists repo interface methods -> flutter-usecase-orchestrator reads it
5. **flutter-usecase-orchestrator** lists use case execute signatures -> flutter-viewmodel-engineer reads it
6. **flutter-viewmodel-engineer** lists state properties + commands -> flutter-view-implementer reads it

## Commit Convention (ACDG)
```
feat(<package>/<feature>): <description>

- [what was created/changed]
- [patterns applied]
- [test coverage]

Pipeline: [agents used], [review rounds]
```

## Data Flow Reference (Flutter <-> BFF <-> Backend)
```
Flutter View (Page + ListenableBuilder)
  | Command.execute() via ViewModel
  v
ViewModel (ChangeNotifier + Command0/Command1)
  | UseCase.execute(input)
  v
UseCase (orchestrates Repositories)
  | Repository.getById(id) / Repository.save(entity)
  v
Repository (source of truth, cache, sync)
  | Service.fetch() + Mapper.toDomain()
  v
Service (stateless API wrapper)
  | Dio HTTP client
  v
BFF (Darto server or in-process package)
  | Business logic, validation, aggregation
  v
Backend Swift/Vapor (internal)
```

The Flutter app NEVER sees raw backend responses. The BFF is the boundary.
Models are schemas — business logic lives in BFF, never in Flutter.
