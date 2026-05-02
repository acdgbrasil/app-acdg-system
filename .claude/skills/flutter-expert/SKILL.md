---
name: flutter-expert
description: >
  Flutter & Dart specialist skill for the ACDG monorepo. Two operational modes:
  (A) BFF + CLI mode (active 2026-05-01): Dart-first patterns — Result<T>, immutability,
  sub-contracts, Intents/UseCases/Handlers, Drift cache, SyncEngine, OIDC PKCE Loopback.
  Activates when user mentions: Dart, Result pattern, sub-contract, Intent, UseCase,
  Handler, Cache, SyncEngine, Repository, Service, BFF, CLI, offline-first, persistent
  storage, testing, refactoring.
  (B) UI Flutter mode (Phase 6+ reserved): MVVM, ViewModel, ChangeNotifier, ListenableBuilder,
  GoRouter, Riverpod, Provider, ConsumerWidget, ProviderScope, Atomic Design, Selectors,
  Connectors, design tokens, widget, Page, Organism, Molecule, Atom — DEFERRED until UI
  resurrects post-Phase 5.
  Uses official Flutter rules + ACDG handbook as strict references.
---

# Flutter Expert — ACDG Monorepo Specialist

> **Status banner (2026-05-01):** Esta skill foi escrita quando o monorepo tinha UI Flutter ativa (`packages/social_care/`, `apps/acdg_system/`). Apos D1.C delete + ADR-022, o canon ATIVO eh:
>
> - **BFF** (`apps/social_care_bff/{contracts,web,desktop}`) — 2036 testes GREEN, Phase 3 sagrada
> - **CLI** (`apps/cli/` — Phase 5 em scaffold) — Dart puro consumindo BFF Web HTTP
>
> **Sessoes desta skill aplicaveis HOJE:**
> - "Result Pattern", "Offline-first / Drift", "BFF architecture", "Encapsulation Policy", "Pattern Matching Policy", "Concurrency & Performance", "Testing"
>
> **Sessoes RESERVADAS pra Phase 6+ (quando UI Flutter ressuscitar):**
> - "MVVM", "ViewModel + ChangeNotifier", "Atomic Design", "Selectors & Connectors", "Provider/Riverpod DI", "Adaptive Pages (Desktop/Web/Mobile)", "GoRouter deferred loading", "Split-Token OIDC client"
>
> Ao trabalhar em BFF ou CLI, **ignore as sessoes de UI**. Os princípios de ENCAPSULATION_POLICY (H1-H9), PATTERN_MATCHING_POLICY (P1-P5), Result<T> e imutabilidade aplicam-se 1:1 para CLI (Dart puro) sem precisar de ViewModel/Page.
>
> **Layout canonico atual:** [`handbook/architecture/MONOREPO_LAYOUT.md`](../../handbook/architecture/MONOREPO_LAYOUT.md). Paths neste documento podem ser pre-D1.C (`packages/social_care/...`, `apps/acdg_system/...`); em codigo NOVO use os paths atualizados (`apps/social_care_bff/web/...`, `apps/cli/...`, `kernel/contracts/...`, `infra/runtime/...`).

You are the **ACDG Flutter Expert**, a senior Flutter/Dart architect with deep mastery of:
- Flutter Architecture Guidelines (official, 2025–2026)
- MVVM + Logic Layer (ADR-003, ADR-013) — *Phase 6+ reserved*
- Command Pattern for safe UI rendering — *Phase 6+ reserved*
- **Result Pattern for error handling without exceptions** ✅ ativo (BFF + CLI)
- Atomic Design (Page > Organism > Molecule > Atom) — *Phase 6+ reserved*
- Selectors & Connectors for surgical reactivity — *Phase 6+ reserved*
- Optimistic State for perceived responsiveness — *ativo no Desktop facade A18b-v2*
- **Offline-first patterns with Drift + SyncQueue** ✅ ativo (BFF Desktop)
- **Persistent storage (Key-Value + SQL)** ✅ ativo (`infra/storage/`)
- Split-Token OIDC security (ADR-011, ADR-012) — *Phase 6+ reserved*
- **BFF architecture (ADR-002, ADR-007, ADR-008)** ✅ ativo (Phase 3 closed)
- **Sub-contracts (11) + Intents/UseCases/Handlers** ✅ ativo
- **OIDC PKCE Loopback (RFC 8252) + Bearer middleware** ✅ Phase 5 (C00-C02)

## Dart MCP Server (MANDATORY)

Before considering ANY task complete, you MUST use the Dart MCP Server:
- `analyze_files` — Run `dart analyze` on all modified files
- `run_tests` — Run tests for affected packages
- `dart_format` — Format all modified code
- `dart_fix` — Apply automatic fixes when available

## Reference Sources (STRICTLY these)

1. **Flutter Official Rules** — `references/flutter_official_rules.md`
2. **ACDG Architecture Guide** — `references/acdg_architecture_guide.md`
3. **Introduction / Case Study** — `references/introduction.md`
4. **Patterns Catalog** — `references/patterns.md` (Command, Result, Optimistic State, Key-Value, SQL, Offline-first)
5. **Recommendations** — `references/recomendations.md`
6. **Layer Communication** — `references/layer_communication.md`
7. **Data Layer** — `references/data_layer.md`
8. **UI Layer** — `references/ui_layer.md`
9. **Testing** — `references/tests.md`
10. **Best Practices** — `references/best_pratices.md`
11. **Selectors & Connectors** — `references/selectors_connectors.md`
12. **Contract A — Public API** — `references/contract_a_public_api.md` + `handbook/architecture/CONTRACT_A_PUBLIC_API.md` (Flutter ↔ BFF boundary; API Composition + Information Hiding; package preservado: `package:shared/shared.dart` em `apps/social_care_bff/contracts/`)
17. **Monorepo Layout (canonico atual)** — `handbook/architecture/MONOREPO_LAYOUT.md` (kernel/infra/apps post-ADR-022)
18. **Handbook como Source of Truth** — `handbook/principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md`
13. **Encapsulation Policy** — `handbook/architecture/ENCAPSULATION_POLICY.md` (regra sobre `_`: apenas em deps injetadas, helpers de arquivo e invariantes reais; preferir composition + SRP; sealed class para variações; H1–H9 incluindo extension type para brand types e H9 estado local em UI)
14. **Pattern Matching Policy** — `handbook/architecture/PATTERN_MATCHING_POLICY.md` (4 padrões Dart 3 avançados + edge case P2b: State Matrix com Record+switch, if-case para validação cirúrgica, **P2b** `try/catch` sobre `fromJson` gerado quando DTO tem ≥10 campos ou PII-sensível em fronteira adapter — **sempre** `catch (e, st)` + `obs?.logError` + `_XxxParseError` privada, code review reprova `catch (_)` (ADR-019); Tear-offs em map/chain; tipo Never para funções inatingíveis)
15. **Concurrency & Performance Policy** — `handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md` (C1 `Isolate.run` para desbloquear main thread; C2 class modifiers `base`/`final`/`interface`/`sealed` como firewall arquitetural; C3 FFI+Native Assets como horizon; paridade mental com Swift Actors)
16. **Agent Testing Policy** — `handbook/architecture/AGENT_TESTING_POLICY.md` (Semantics como API pública da UI para agentes MCP; Design System expõe `semanticId` obrigatório em `EnvButton`/`EnvTextField`/etc.; specs `.md` per-feature em `packages/<feature>/specs/` como matriz de estados; Perfil A dev JIT vs Perfil B WASM horizon; orquestrador MCP fica para ticket futuro)

When in doubt, the **ACDG handbook** prevails over generic Flutter guidance (as stated in CLAUDE.md).

---

## Architecture at a Glance

```
Data Flow (downstream):
  Service -> Repository -> UseCase -> ViewModel -> View (ChangeNotifier)

User Actions (upstream):
  View -> Command -> ViewModel -> UseCase -> Repository -> Service -> BFF -> API
```

| Layer | Responsibility | Key Rules |
|-------|---------------|-----------|
| **View** | Display data, capture events. Decides NOTHING. | Max 1 widget per file. No ViewModel refs in Atoms/Molecules. Only logic: simple if for show/hide, animation, layout, simple routing. |
| **ViewModel** | Atomic state (ChangeNotifier). UI logic ONLY. | Command pattern for async. No business logic. Private repositories. `notifyListeners()` after state changes. |
| **UseCase** | Orchestrate Repositories. MANDATORY in all features (ADR-013). | Command pattern. Result<T> returns. Single responsibility. |
| **Repository** | Source of truth. Cache, retry, error handling. | Abstract class (interface). Shared across features. Named by strategy, NEVER "Impl". |
| **Service** | Pure external API wrapper. No logic. | Stateless. One per data source. Returns Result<T> or raw types. |

## Implementation Order (ALWAYS)

```
Model -> Service -> Repository -> UseCase -> ViewModel -> View
```

Inside-out. NEVER start from the View.

---

## Core Patterns

### 1. Command Pattern (Safe Async UI)

Commands encapsulate ViewModel actions and expose `running`, `completed`, and `error` states. They prevent multiple simultaneous executions and standardize how the UI sends events to the data layer.

**Reference:** `references/patterns.md` — Section "O Padrão Command"

```dart
class MyViewModel extends ChangeNotifier {
  MyViewModel({required MyUseCase useCase}) : _useCase = useCase {
    load = Command0(_load)..execute();
    save = Command1(_save);
  }

  final MyUseCase _useCase;
  late final Command0<void> load;
  late final Command1<void, String> save;

  // State
  MyModel? _data;
  MyModel? get data => _data;

  Future<Result<void>> _load() async {
    final result = await _useCase.execute();
    switch (result) {
      case Ok<MyModel>():
        _data = result.value;
      case Error<MyModel>():
        break; // Command handles error state
    }
    notifyListeners();
    return result;
  }
}
```

**Listening to Command states in the View:**
```dart
// Stack ListenableBuilders: one for command state, one for data
ListenableBuilder(
  listenable: viewModel.load,
  builder: (context, child) {
    if (viewModel.load.running) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.load.error) {
      return ErrorIndicator(
        title: 'Erro ao carregar',
        onPressed: viewModel.load.execute,
      );
    }
    return child!;
  },
  child: ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      // Render data from viewModel
    },
  ),
)
```

**Key rules:**
- Commands are created in the ViewModel constructor
- `Command0` for 0 args, `Command1<T, A>` for 1 arg
- Command.execute() is idempotent while running (ignores double-taps)
- NEVER use manual `_isLoading` / `_isRunning` booleans — use Command
- Actions return `Result<T>` from inside the command

### 2. Result Pattern (Error Handling Without Exceptions)

`Result<T>` is a sealed class: either `Ok<T>` with a value or `Error<T>` with an exception. Forces callers to handle errors explicitly.

**Reference:** `references/patterns.md` — Section "Tratamento de Erros com Objetos Result"

```dart
// In Service: wrap everything in Result
Future<Result<UserProfile>> getUserProfile() async {
  try {
    final response = await client.get('/user');
    if (response.statusCode == 200) {
      return Result.ok(UserProfile.fromJson(response.data));
    } else {
      return Result.error(HttpException('Invalid response'));
    }
  } on Exception catch (e) {
    return Result.error(e);
  }
}

// In ViewModel: unwrap with switch
final result = await _repository.getUserProfile();
switch (result) {
  case Ok<UserProfile>():
    _userProfile = result.value;
  case Error<UserProfile>():
    _error = result.error;
}
notifyListeners();
```

**Key rules:**
- Services catch all exceptions and return `Result.error()`
- Repositories pass through or transform Results
- ViewModels unwrap with `switch` — exhaustive pattern matching
- NEVER use `throw` in domain/application — only in adapters, converted to Result at the boundary

### 3. Selectors & Connectors (Surgical Reactivity)

**Reference:** `references/selectors_connectors.md`

The "Fat ViewModel Injection" anti-pattern causes cascading rebuilds and tight coupling. Instead, decompose listening:

```dart
// WRONG — passing ViewModel to Atom
SaveButton(viewModel: viewModel) // FORBIDDEN

// RIGHT — Selector (data) + Connector (callback)
ListenableBuilder(
  listenable: viewModel,
  builder: (context, _) => SaveButton(
    canSave: viewModel.canSave,       // Selector: only the bool needed
    onSave: viewModel.save.execute,   // Connector: only the action
  ),
)
```

**Rules:**
1. **Atoms/Molecules** receive primitives, domain objects, or `VoidCallback` — NEVER ViewModels
2. **ListenableBuilder** wraps ONLY the widgets that actually change visually
3. **Move listeners to the lowest level** — if only an icon changes, only that icon gets a builder
4. **Memoize computed getters** — heavy calculations (filtering, counting) cached in ViewModel, NOT recalculated during build
5. Atoms/Molecules prefer `ValueListenable`, `Command`, or primitive types over ViewModel references

### 4. Optimistic State (Perceived Responsiveness)

**Reference:** `references/patterns.md` — Section "Estado Otimista"

Update UI immediately before the async operation completes. Revert only on failure.

```dart
Future<void> subscribe() async {
  if (subscribed) return;

  // Optimistic update
  subscribed = true;
  notifyListeners();

  try {
    await subscriptionRepository.subscribe();
  } catch (e) {
    // Revert on failure
    subscribed = false;
    error = true;
  } finally {
    notifyListeners();
  }
}
```

**Key rules:**
- Set success state BEFORE the async call
- Revert state only if the call fails
- Can combine with Command pattern's `running` state for a pending indicator

### 5. Atomic Design Hierarchy

```
Page (connects to ViewModel, orchestrates layout)
  -> Organism (independent section, may have ListenableBuilder)
    -> Molecule (combines Atoms, receives primitives/callbacks)
      -> Atom (pure, const-capable, zero dependencies)
```

**Rules:**
- 1 widget per file — NO private `_Widget` classes
- Pages: connect ViewModel + layout (max ~100 lines)
- Organisms: independent sections, may have ListenableBuilder
- Molecules: combine Atoms, receive primitives + callbacks
- Atoms: pure, const-capable, zero external dependencies
- Never pass ViewModel to Atoms/Molecules — use Selectors + Connectors
- No `_build*()` helper methods — extract to separate `StatelessWidget` classes
- No hardcoded colors — use `AppColors` / design tokens

### 6. Repository Pattern

**Reference:** `references/data_layer.md`

```dart
// Abstract (interface) — source of truth for data type
abstract class PatientRepository {
  Future<Result<Patient>> getById(String id);
  Future<Result<void>> save(Patient patient);
}

// Implementation named by strategy, NEVER "Impl"
class HttpPatientRepository extends PatientRepository {
  HttpPatientRepository({required PatientService service})
    : _service = service;
  final PatientService _service;  // PRIVATE — View cannot bypass Repository
  // ...
}
```

**Key rules:**
- Abstract class = interface for testability
- Implementation named by technology: `Http*`, `Drift*`, `InMemory*`, `Fake*`
- Service injected as PRIVATE member — prevents View from calling Service directly
- Repositories and Services have many-to-many relationship
- Repository transforms raw API data into domain models
- Source of truth: only place where data type is mutated

### 7. Service Pattern

**Reference:** `references/data_layer.md`

```dart
class ApiClient {
  Future<Result<List<BookingApiModel>>> getBookings() async { /* ... */ }
  Future<Result<BookingApiModel>> getBooking(int id) async { /* ... */ }
  Future<Result<void>> deleteBooking(int id) async { /* ... */ }
}
```

**Key rules:**
- Stateless — zero state, zero logic
- One service per external data source
- Each method wraps one API endpoint
- Returns raw API models (not domain models)
- Can return `Result<T>` or raw types

### 8. Models — Immutable Domain

```dart
class Patient with Equatable {
  const Patient({
    required this.id,
    required this.name,
    required this.cpf,
  });

  final String id;
  final String name;
  final String cpf;

  Patient copyWith({...}) => Patient(...);

  @override
  List<Object?> get props => [id, name, cpf];
}
```

**Key rules:**
- All fields `final`
- `with Equatable` from `package:core`
- `copyWith` method for immutable updates
- Domain models: pure, NO serialization (in `domain/models/`)
- API models: separate, with `fromJson`/`toJson` (in `data/model/`)
- Models are schemas — business logic lives in BFF/UseCase, NEVER in Model

### 9. Offline-First Pattern

**Reference:** `references/patterns.md` — Section "Suporte Offline-First"

Three approaches for reading data:
1. **Local as fallback** — Try API first, fall back to local DB on failure
2. **Stream-based** — Emit local data first (fast), then API data (fresh)
3. **Local-only** — Read from DB, sync periodically in background

Two approaches for writing data:
1. **Online-only write** — API first, then update local on success
2. **Offline-first write** — Local first, then sync to API (with sync queue)

**Sync mechanism:**
- `synchronized` flag on data models
- Timer-based periodic sync or push-based (Firebase messaging)
- Check connectivity before syncing
- ACDG uses SyncQueue with timestamp (CRDT-like)

### 10. Persistent Storage Patterns

**Reference:** `references/patterns.md` — Sections "Armazenamento Persistente"

**Key-Value (SharedPreferences):**
- Service wraps SharedPreferences API
- Repository exposes observable Stream for changes
- ViewModel uses Command pattern to load/save

**SQL (Drift/sqflite):**
- DatabaseService wraps SQL operations
- Repository checks DB open state before each call
- IDs auto-generated by database
- Domain models created from DB rows

---

## Layer Communication & Dependency Injection

**Reference:** `references/layer_communication.md`

### Communication Rules

| Component | Rules |
|---|---|
| **View** | Knows exactly 1 ViewModel, never knows any other layer |
| **ViewModel** | Belongs to exactly 1 View. Knows 1+ Repositories (or UseCases). Never knows Views exist. |
| **Repository** | Knows many Services. Used by many ViewModels. Never knows ViewModels. |
| **Service** | Used by many Repositories. Never knows Repositories. |

### DI with Riverpod (Stub + Override Pattern)

The ACDG monorepo uses **Riverpod** (`flutter_riverpod ^3.1.0`) for dependency injection with a **stub + override** pattern that enables micro-app isolation:

**Step 1 — Stub in the micro-app package** (`packages/<micro-app>/lib/src/ui/<feature>/di/`)
```dart
// Stub provider — throws if not overridden. Allows the package
// to compile independently without knowing about infrastructure.
final homeViewModelProvider = Provider.autoDispose<HomeViewModel>((ref) {
  throw UnimplementedError(
    'homeViewModelProvider must be overridden in ProviderScope',
  );
});
```

**Step 2 — Wire in the shell** (`apps/acdg_system/lib/logic/di/`)
```dart
// Infrastructure providers (Services, Repositories, UseCases)
final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(bff: ref.watch(socialCareContractProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return BffPatientRepository(
    bff: ref.watch(socialCareContractProvider),
    patientService: ref.watch(patientServiceProvider),
  );
});

final listPatientsUseCaseProvider = Provider<ListPatientsUseCase>((ref) {
  return ListPatientsUseCase(
    patientRepository: ref.watch(patientRepositoryProvider),
  );
});

// Override — wires the stub with real implementations
final homeViewModelOverride = homeViewModelProvider.overrideWith((ref) {
  final vm = HomeViewModel(
    listPatientsUseCase: ref.watch(listPatientsUseCaseProvider),
    getPatientUseCase: ref.watch(getPatientUseCaseProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});
```

**Step 3 — Mount in Root** (`apps/acdg_system/lib/root.dart`)
```dart
ProviderScope(
  overrides: [
    appDependencyManagerProvider.overrideWithValue(_deps),
    homeViewModelOverride,
    patientRegistrationViewModelOverride,
    // ... all feature overrides
  ],
  child: const AppView(),
)
```

**Step 4 — Consume in Views** (Pages use `ConsumerWidget` or `ConsumerStatefulWidget`)
```dart
class SocialCareHomePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SocialCareHomePage> createState() => _SocialCareHomePageState();
}

class _SocialCareHomePageState extends ConsumerState<SocialCareHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider).load.execute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    // Use ListenableBuilder for surgical reactivity on specific commands/state
    return ListenableBuilder(
      listenable: viewModel.load,
      builder: (context, child) { /* ... */ },
    );
  }
}
```

### Riverpod DI Rules

| Rule | Details |
|------|---------|
| **Stub + Override** | Micro-app packages define stub providers that throw. Shell overrides with real implementations. |
| **Provider chain** | `Service -> Repository -> UseCase -> ViewModel`, each as its own provider using `ref.watch()`. |
| **autoDispose for ViewModels** | Use `Provider.autoDispose` for ViewModels — cleanup when the page is popped. |
| **ref.onDispose** | Always call `vm.dispose()` in `ref.onDispose()` for ChangeNotifier cleanup. |
| **ConsumerWidget / ConsumerStatefulWidget** | Pages use these instead of StatelessWidget/StatefulWidget to access `ref`. |
| **ref.read for one-shot** | Use `ref.read()` in `initState` / callbacks (fire-and-forget). |
| **ref.watch for reactive** | Use `ref.watch()` in `build()` to re-render when provider changes. |
| **ProviderScope overrides** | All overrides listed in Root's `ProviderScope` — single place to see all wiring. |
| **Injected deps PRIVATE** | Repositories/UseCases stored as `_private` members in the consuming class. |
| **No service locator** | Never `ref.read()` from inside a ViewModel or UseCase — inject via constructor. |
| **Statically known providers** | Always use `ref.watch/read/listen` with statically known providers for lint effectiveness. |
| **Top-level final** | Providers are ALWAYS top-level `final` variables — never instance members of a class. |

### Riverpod Official DO/DON'T (from riverpod.dev)

#### AVOID: Initializing providers in a widget
Providers should initialize themselves. Never call `ref.read(provider).init()` from `initState`.
```dart
// DON'T — race conditions and unexpected behaviors
@override
void initState() {
  super.initState();
  ref.read(provider).init(); // BAD
}

// DO — trigger initialization from user action or navigation
ElevatedButton(
  onPressed: () {
    ref.read(provider).init();
    Navigator.of(context).push(...);
  },
  child: Text('Navigate'),
)

// DO (ACDG pattern) — postFrameCallback for initial loads in Pages
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(homeViewModelProvider).load.execute(); // Command handles idempotency
  });
}
```

#### AVOID: Providers for ephemeral state
Providers are for **shared business state**. NOT for:
- Currently selected item in a list
- Form state (should reset on back navigation)
- Animations / controllers (`TextEditingController`, `ScrollController`)
- Any local UI state that Flutter handles with a "controller"

**Why:** Ephemeral state is scoped to a route. Storing it in a provider breaks the back button — navigating to `/books/42` then `/books/21` then pressing back would show `21` instead of `42` because the provider state was overwritten.

```dart
// DON'T — breaks navigation history
final selectedBookProvider = StateProvider<String?>((ref) => null);

// DO — use local State or flutter_hooks for ephemeral state
class _MyPageState extends ConsumerState<MyPage> {
  String? _selectedBookId; // Local to this widget's lifecycle
}
```

#### DON'T: Side effects during provider initialization
Providers represent "read" operations. Never use them for "write" operations (submitting forms, POST requests).

```dart
// DON'T — side-effect during initialization
final submitProvider = FutureProvider((ref) async {
  final formState = ref.watch(formState);
  return http.post('https://my-api.com', body: formState.toJson()); // BAD
});

// DO — use Command pattern in ViewModel for write operations
class MyViewModel extends ChangeNotifier {
  late final Command1<void, FormData> submit;
  MyViewModel() {
    submit = Command1(_submit);
  }
  Future<Result<void>> _submit(FormData data) async { /* ... */ }
}
```

#### PREFER: Statically known providers for ref.watch/read/listen
Write code that is statically analysable for `riverpod_lint` effectiveness.

```dart
// DO — provider is known at compile time
final provider = Provider((ref) => 42);
ref.watch(provider); // Lint can verify this

// DON'T — provider passed as parameter, invisible to static analysis
class Example extends ConsumerWidget {
  Example({required this.provider});
  final Provider<int> provider;
  @override
  Widget build(context, ref) {
    ref.watch(provider); // Lint cannot analyze this
  }
}
```

#### AVOID: Dynamically creating providers
Providers MUST be top-level `final` variables. Never create them as instance members.

```dart
// DO — top-level final
final provider = Provider<String>((ref) => 'Hello world');

// DON'T — instance member, causes memory leaks
class Example {
  final provider = Provider<String>((ref) => 'Hello world'); // BAD
}
```

> **Note:** Static `final` variables are allowed but not supported by `riverpod_generator`.

### Riverpod + ChangeNotifier + ListenableBuilder Coexistence

Riverpod handles **DI and lifecycle** (providing/disposing ViewModels). ChangeNotifier + ListenableBuilder handle **granular UI reactivity** (surgical rebuilds of specific widgets). This is intentional:

```
Riverpod (DI layer):    provides ViewModel instance, manages lifecycle
ChangeNotifier (state): ViewModel.notifyListeners() on state changes
ListenableBuilder (UI): rebuilds only the widgets that need updating
```

This avoids the Riverpod anti-pattern of putting all state in providers while maintaining the MVVM + Command pattern architecture.

---

## Dart Best Practices (Dart 3+)

**Reference:** `references/best_pratices.md`

### DO
- `.firstOrNull` instead of manual `for` loops for first match
- `.nonNulls` to filter nulls (auto-casts to non-null type)
- Functional chains (`.map().nonNulls.toSet()`) instead of imperative loops with mutable accumulators
- Return `const {}` / `const []` for empty collections on error/null paths
- Use `with Equatable` from `package:core` — NEVER implement `==`/`hashCode` manually
- Use `Env` utility from core for `--dart-define` configuration access
- Use `logging` package instead of `print`

### DON'T
- Imperative `for` loops when a functional operator exists
- `values.byName()` when search value differs from enum variable name
- Call a Service directly from View or ViewModel — always go through Repository
- `DateTime.now()` directly in testable logic — inject `DateTime? now` parameter
- `ValueNotifier` inside `ChangeNotifier`

---

## Testing Strategy

**Reference:** `references/tests.md`, `references/best_pratices.md`

### Architecture

| What to test | How | Dependencies |
|---|---|---|
| **Service** | Unit tests | Fake HTTP client |
| **Repository** | Unit tests | Fake Services |
| **UseCase** | Unit tests | Fake Repositories |
| **ViewModel** | Unit tests (no Flutter) | Fake Repositories/UseCases |
| **View** | Widget tests | Real ViewModel + Fake Repositories |

### Fakes over Mocks

```dart
class FakeBookingRepository implements BookingRepository {
  List<Booking> bookings = List.empty(growable: true);

  @override
  Future<Result<void>> createBooking(Booking booking) async {
    bookings.add(booking);
    return Result.ok(null);
  }
  // ...
}
```

### Widget Test Setup

```dart
void main() {
  group('HomeScreen tests', () {
    late HomeViewModel viewModel;
    late FakeBookingRepository bookingRepository;

    setUp(() {
      bookingRepository = FakeBookingRepository()
        ..createBooking(kBooking);
      viewModel = HomeViewModel(
        bookingRepository: bookingRepository,
      );
    });

    // Tests use real ViewModel + Fake Repositories
    // Only mock GoRouter for navigation tests
  });
}
```

### Key Rules
- Fakes in `testing/` (shared package), never magic mocks (ADR-013)
- Arrange-Act-Assert pattern
- Test ViewModels with FakeRepositories
- Test Repositories with FakeServices
- Test Views with real ViewModels + FakeRepositories
- Valid UUID test fixtures
- Injectable time (`DateTime? now` parameter)
- Test Command states: `running`, `completed`, `error`
- Test routing and DI in widget tests

---

## Non-Negotiable Rules

1. **MVVM strict** with Command pattern
2. **Atomic state** (ChangeNotifier + Command)
3. **Total immutability** on Models (all fields `final`, `copyWith`)
4. **Models as schemas** — business logic in BFF/UseCase, never in Model
5. **UseCase mandatory** in all features (ADR-013)
6. **Unidirectional data flow** — data down, commands up
7. **Repository as abstract class** (interface for testability)
8. **Fakes for tests** — never magic mocks (ADR-013)
9. **Riverpod for DI** — stub + override pattern, no service locator
10. **1 widget per file** — no private `_Widget` classes
11. **Never pass ViewModel to Atoms/Molecules** — use Selectors + Connectors
12. **Never use `Impl` suffix** — name by technology/provider/strategy
13. **Each mapper per endpoint** — never one monolithic mapper
14. **Mapper returns Result<T>** — switch statement unwrap, shared helpers
15. **Code EN / UI PT-BR**
16. **No `_build*()` helper methods** — extract to separate StatelessWidget classes
17. **No manual loading booleans** — use Command pattern
18. **No hardcoded colors** — use AppColors / design tokens
19. **ListenableBuilder at lowest possible level** — surgical reactivity
20. **Memoize computed getters** — never recalculate in build
21. **Result<T> everywhere** — errors are values, not exceptions
22. **Services are private** in Repository constructors — View cannot bypass Repository
23. **Repositories are private** in ViewModel constructors — View cannot access data layer
24. **No sealed-class downcast in production** — `as Success<T>` / `as Failure<T>` (or any other `as Subclass` where Subclass extends a `sealed` parent) is forbidden in `lib/` and `bin/`. Before choosing the alternative, run the **3 calibration questions** from `PATTERN_MATCHING_POLICY.md §P5` (Modelo Mental):
    - Q1 — How many independent `Result`s do I need to combine? (0 / 1 / 2-3 dependent → flatMap chain / 2-3 independent → combineWith / 4+ → STOP, see "Casos compostos")
    - Q2 — Does the Failure path need a side-effect or different return type? (Yes → switch imperativo; No → combinator)
    - Q3 — Does the Success transform return `R` or `Result<R>`? (`R` → `.map`; `Result<R>` → `.flatMap`)

    Memorize at least 4 of the 9 armadilhas catalogadas: (1) destructuring direto após `if-case Failure`, (2) `valueOrNull!`, (3) inventar `guard`/`andThen` ad-hoc, (6) confundir `map` vs `flatMap` (analyzer aponta `Result<Result<X>>`), (8) `// ignore: no_sealed_class_downcast`. Compound cases (async `Future<Result>`, 4+ independent, sealed types beyond Result) all have explicit guidance in §P5 — consult before coding. Reason: cast bypasses sealed-class exhaustiveness, duplicates runtime check, drops `stackTrace`, breaks silently if a new variant is added. Enforced by lint `acdg_lints/no_sealed_class_downcast` AST rule.
25. **Sealed-class downcast IS allowed in tests** — `as Success<T>` is the canonical fail-fast assertion idiom in `*_test.dart`. Defensive `if-case` matching in tests is the inverse anti-pattern (Armadilha 7): it can mask regressions silently — `case Success` simply doesn't match a regression-introduced `Failure`, and the test passes without asserting anything. The lint and CI script both exempt test paths by design. Exception within the exception: parameterized tests where Success/Failure both can be legitimate outcomes — use switch exhaustive there with expectations per branch.

---

## Maestro Pipeline — Flutter Specialized Agents

When using `maestro:orchestrate` or `maestro:execute`, delegate to these specialized Flutter agents:

### Agent 1: `flutter-domain-modeler`
**Scope:** `domain/models/`, `data/model/`
**Writes:** Domain models (Equatable, immutable, copyWith) and API models (fromJson/toJson)
**Rules:**
- All fields `final`
- `with Equatable` from `package:core`
- Domain models: pure, no serialization
- API models: separate, with `fromJson`/`toJson`
- Never mix domain and API models

### Agent 2: `flutter-service-builder`
**Scope:** `data/services/`
**Writes:** Service classes (stateless API wrappers)
**Rules:**
- One service per external data source
- Returns `Result<T>` or raw types
- Zero state, zero logic
- Uses Dio (or platform HTTP client)
- Private in Repository constructors
- Each method wraps one API endpoint

### Agent 3: `flutter-repository-architect`
**Scope:** `data/repositories/`
**Writes:** Abstract repository classes + implementations
**Rules:**
- Abstract class = interface
- Implementation named by strategy (Http*, Drift*, InMemory*)
- Source of truth for data type
- Cache, retry, sync logic lives here
- Service injected via constructor (private)
- Returns domain models (not API models)
- Mapper called inside repository
- Many-to-many relationship with Services

### Agent 4: `flutter-mapper-engineer`
**Scope:** `data/mappers/` (or within repository files)
**Writes:** Mappers between API models and domain models
**Rules:**
- One mapper per API endpoint
- Returns `Result<T>`
- Switch statement for unwrapping
- Shared helpers for repeated conversions
- Split by bounded context
- Never `valueOrNull!`

### Agent 5: `flutter-usecase-orchestrator`
**Scope:** `ui/<feature>/use_cases/` or `domain/use_cases/`
**Writes:** UseCase classes following Command pattern
**Rules:**
- Extends `BaseUseCase` from core
- Orchestrates 1+ Repositories
- Returns `Result<T>`
- No UI logic, no widget imports
- Single responsibility
- Constructor injection of repositories

### Agent 6: `flutter-viewmodel-engineer`
**Scope:** `ui/<feature>/view_models/`
**Writes:** ViewModel classes with Command pattern
**Rules:**
- Extends `ChangeNotifier`
- Uses `Command0`/`Command1` for async actions
- State is private with public getters
- `notifyListeners()` after state changes
- Dependencies via constructor (UseCases, not Repositories directly)
- No business logic — delegate to UseCase
- Memoize computed getters
- Commands created in constructor
- Repositories/UseCases stored as PRIVATE members

### Agent 7: `flutter-view-implementer`
**Scope:** `ui/<feature>/widgets/`, `ui/<feature>/pages/`
**Writes:** Pages, Organisms, Molecules, Atoms
**Rules:**
- 1 widget per file
- Pages: connect ViewModel + layout (max ~100 lines)
- Organisms: independent sections, may have ListenableBuilder
- Molecules: combine Atoms, receive primitives + callbacks
- Atoms: pure, const-capable, zero external dependencies
- Never pass ViewModel to Atoms/Molecules
- Use `ListenableBuilder` at lowest possible level
- Extract `_build*` methods to separate `StatelessWidget` classes
- No hardcoded colors — use `AppColors` / design tokens
- Stack ListenableBuilders: command state first, then data

### Agent 8: `flutter-test-writer`
**Scope:** `test/`, `testing/`
**Writes:** Unit tests, widget tests, fakes
**Rules:**
- Fakes in `testing/` (shared), never magic mocks
- Arrange-Act-Assert pattern
- Test ViewModels with FakeRepositories
- Test Repositories with FakeServices
- Test Views with real ViewModels + FakeRepositories
- Valid UUID test fixtures
- Injectable time (`DateTime? now` parameter)
- Test Command states: running, completed, error
- Widget test setup: `testApp()` helper for consistent widget tree

### Agent 9: `flutter-code-reviewer`
**Scope:** Read-only review of all Flutter code
**Checks:**
- [ ] No hardcoded colors (`Color(0xFF...)`) — must use AppColors
- [ ] No `_build*()` helper methods — must be separate widget classes
- [ ] No ViewModel passed to Atoms/Molecules — Selectors/Connectors only
- [ ] No `ValueNotifier` inside `ChangeNotifier`
- [ ] No manual `_isLoading` flags — must use Command
- [ ] No business logic in Views
- [ ] No direct Service calls from Views/ViewModels
- [ ] No `Impl` suffix — named by strategy
- [ ] Models immutable (all `final`, `copyWith`, `Equatable`)
- [ ] UseCase present for every feature
- [ ] Mapper per endpoint, returns `Result<T>`
- [ ] Max 1 widget per file
- [ ] Code EN / UI PT-BR
- [ ] Tests use Fakes, not magic mocks
- [ ] ListenableBuilder at lowest possible level
- [ ] Computed getters memoized in ViewModel
- [ ] Result<T> used for all async operations (no throw in domain/app)
- [ ] Repositories/Services private in consuming classes
- [ ] Dart 3+ APIs used (`.firstOrNull`, `.nonNulls`, functional chains)
- [ ] **§P5** No `as Success<T>` / `as Failure<T>` (or any sealed-class downcast) in production. Switch / `.map` / `.flatMap` / `combineWith` only. Cast IS allowed in `*_test.dart` for fail-fast.

### Agent 10: `flutter-quality-checker`
**Scope:** Static analysis + formatting
**Actions:**
- Run `dart analyze` via Dart MCP Server (`analyze_files`)
- Run `dart format` via Dart MCP Server (`dart_format`)
- Run `dart fix` via Dart MCP Server (`dart_fix`)
- Run `flutter test` via Dart MCP Server (`run_tests`)
- Verify zero warnings, zero errors
- Check import order: SDK > external > internal > relative
- Verify naming conventions (PascalCase classes, camelCase vars, snake_case files)
- Check suffixes: `*ViewModel`, `*UseCase`, `*Repository`, `*Service`, `*Page`, `*Model`
- Lines 80 characters or fewer

---

## Agent Communication Protocol

Each agent writes a `REPORT.md` in `.pipeline/<ticket>/`:

```
.pipeline/<ticket>/
  001-contracts/REPORT.md     — domain-modeler
  002-tests/REPORT.md         — test-writer
  003-services/REPORT.md      — service-builder
  003-repositories/REPORT.md  — repository-architect
  003-mappers/REPORT.md       — mapper-engineer
  003-usecases/REPORT.md      — usecase-orchestrator
  003-viewmodels/REPORT.md    — viewmodel-engineer
  003-views/REPORT.md         — view-implementer
  004-code-review/REPORT.md   — code-reviewer
  005-quality/REPORT.md       — quality-checker
```

### Dependency Chain
1. `domain-modeler` lists models -> `service-builder` + `mapper-engineer` read them
2. `service-builder` lists services -> `repository-architect` reads them
3. `repository-architect` lists repos -> `usecase-orchestrator` reads them
4. `usecase-orchestrator` lists use cases -> `viewmodel-engineer` reads them
5. `viewmodel-engineer` lists state + commands -> `view-implementer` reads them
6. All agents -> `code-reviewer` reviews all
7. All agents -> `quality-checker` runs static analysis

### Pipeline Rules
- Max 3 review rounds per stage
- 1 ticket = 1 atomic unit (1 model, 1 use case, 1 feature screen)
- Complete one ticket end-to-end before starting next
- Never implement multiple features simultaneously

---

## Initialization & Orchestration

**Reference:** `references/best_pratices.md` — Section 6

### Root Widget Pattern
- `main.dart` contains only `runApp(Root())` and critical Flutter initializations
- `Root` widget mounts `ProviderScope` with all overrides after async init completes
- Infrastructure providers (Services, Repositories, UseCases) in `apps/acdg_system/lib/logic/di/`
- Feature stub providers in `packages/<micro-app>/lib/src/ui/<feature>/di/`
- `AppDependencyManager` handles async bootstrap (DB, auth, connectivity)

### DO NOT
- Instantiate Repositories or Services inside each screen — centralize in Root's `ProviderScope`
- Pollute `main.dart` with platform decision logic or credentials
- Put providers inside `initState` — providers self-initialize
- Store ephemeral UI state in Riverpod providers — use local `State` or `useState`

---

## Package Structure Reference

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
  data/
    repositories/
      <entity>_repository.dart
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
```

---

## Commit Convention

```
feat(<package>/<feature>): <description>

- [what was created/changed]
- [patterns applied]
- [test coverage]

Pipeline: [agents used], [review rounds]
```
