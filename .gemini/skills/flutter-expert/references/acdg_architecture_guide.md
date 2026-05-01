# ACDG Architecture Guide — Flutter Frontend

> Compiled from: `handbook/references/flutter_archteture/`
> This is the CANONICAL reference for all Flutter architecture decisions in the ACDG monorepo.

---

## 1. MVVM + Logic Layer (ADR-003, ADR-013)

### Data Flow
```
Data (downstream):
  Service -> Repository -> UseCase -> ViewModel -> View (ChangeNotifier)

User actions (upstream):
  View -> Command -> ViewModel -> UseCase -> Repository -> Service -> BFF -> API
```

### Layer Responsibilities

| Layer | Responsibility | Rules |
|-------|---------------|-------|
| **View** | Display data, capture events. Decides NOTHING. | Only logic: simple if for show/hide, animation, layout, simple routing |
| **ViewModel** | Atomic state (ChangeNotifier). UI logic ONLY. | Uses Command pattern. No business logic. |
| **UseCase** | Orchestrate Repositories. MANDATORY (ADR-013). | Command pattern. Result<T>. |
| **Repository** | Source of truth. Cache, retry, sync. | Abstract class. Shared between features. |
| **Service** | Pure external wrapper. No logic. | Stateless. |

---

## 2. Package Structure (ADR-013)

**UI by feature, Data by type, Domain shared.**

```
packages/<micro-app>/lib/src/
  ui/<feature>/          — ViewModel + Views + UseCase (coupled to feature)
  data/repositories/     — shared between features
  data/services/         — shared between features
  data/model/            — API models (fromJson/toJson)
  domain/models/         — pure immutable domain models
  testing/               — fakes and fixtures
```

### Folder Layout
```
lib/
  ui/
    core/ui/<shared_widgets>, themes/
    <feature>/
      view_models/<view_model>.dart
      widgets/<feature>_screen.dart, <other_widgets>
  domain/models/<model>.dart
  data/
    repositories/<repository>.dart
    services/<service>.dart
    model/<api_model>.dart
  config/
  utils/
  routing/

test/        — unit + widget tests (mirrors lib/)
testing/     — fakes, fixtures (shared subpackage)
```

---

## 3. ViewModel Design

### Declaration
```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required BookingRepository bookingRepository,
  }) : _bookingRepository = bookingRepository {
    load = Command0(_load)..execute();
    deleteBooking = Command1(_deleteBooking);
  }

  final BookingRepository _bookingRepository;

  late final Command0<void> load;
  late final Command1<void, int> deleteBooking;

  // State — private with public getters
  User? _user;
  User? get user => _user;

  List<BookingSummary> _bookings = [];
  UnmodifiableListView<BookingSummary> get bookings =>
    UnmodifiableListView(_bookings);
}
```

### Key Rules
- Repositories are PRIVATE members (never exposed to View)
- State is immutable snapshots
- `notifyListeners()` after state updates
- Commands for async operations (running, completed, error states)
- No business logic — delegate to UseCase/Repository

### State Update Flow
1. New state from Repository
2. ViewModel updates UI state
3. `notifyListeners()` called
4. View re-renders

---

## 4. View Design

### View Responsibilities
1. Display ViewModel data properties
2. Listen for ViewModel updates and re-render
3. Attach ViewModel callbacks to event handlers

### View Structure
```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: viewModel.load,
        builder: (context, child) {
          if (viewModel.load.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.load.error) {
            return ErrorIndicator(
              title: 'Error loading',
              onPressed: viewModel.load.execute,
            );
          }
          return child!;
        },
        child: _HomeContent(viewModel: viewModel),
      ),
    );
  }
}
```

### Only inputs to a View: `key` + `viewModel`

---

## 5. Command Pattern

```dart
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  bool get error => _result is Error;
  bool get completed => _result is Ok;

  Future<void> _execute(action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
```

Commands are created in the ViewModel constructor. Safe to render even before data exists.

---

## 6. Data Layer

### Service — Stateless API wrapper
```dart
class ApiClient {
  Future<Result<List<BookingApiModel>>> getBookings() async { ... }
  Future<Result<void>> deleteBooking(int id) async { ... }
}
```

### Repository — Source of truth
```dart
class BookingRepositoryRemote implements BookingRepository {
  BookingRepositoryRemote({required ApiClient apiClient})
    : _apiClient = apiClient;
  final ApiClient _apiClient;

  Future<Result<Booking>> getBooking(int id) async {
    // Fetch raw data from service
    // Transform to domain model
    // Return Result
  }
}
```

### Domain Models vs API Models
- **API models** (`data/model/`): contain raw API data, fromJson/toJson
- **Domain models** (`domain/models/`): refined, only what the app needs, immutable
- Repository transforms API -> Domain

---

## 7. Selectors & Connectors Pattern

### Problem: Fat ViewModel Injection
Passing entire ViewModel to child widgets causes:
1. Cascading rebuilds (any field change rebuilds everything)
2. Strong coupling (Atoms depend on giant ViewModels)
3. Impossible `const` (mutable objects prevent optimization)

### Solution: Decomposed Listening

**Selectors** = data (primitives, immutable objects)
**Connectors** = actions (Commands, callbacks)

```dart
// WRONG
SaveButton(viewModel: viewModel) // Atom coupled to entire ViewModel

// RIGHT
ListenableBuilder(
  listenable: viewModel,
  builder: (context, _) => SaveButton(
    canSave: viewModel.canSave,       // Selector
    onSave: viewModel.save.execute,   // Connector
  ),
)
```

### Surgical Listening
ListenableBuilder at the LOWEST possible level:
```dart
// Only the checkbox rebuilds, not the entire list
class SpecificityTile extends StatelessWidget {
  final String id;
  final bool isSelected;
  final VoidCallback onToggle;
  // ...
}
```

### Rules
1. No `_buildHeader()` methods — use StatelessWidget classes
2. ListenableBuilder wraps ONLY widgets that actually change
3. Atoms/Molecules receive `ValueListenable`, `Command`, or primitives — never ViewModels
4. Memoize expensive computations in ViewModel

---

## 8. Dependency Injection

### Provider at Root Level
```dart
runApp(
  MultiProvider(
    providers: [
      Provider(create: (_) => ApiClient()),
      Provider(create: (ctx) =>
        BookingRepositoryRemote(apiClient: ctx.read()) as BookingRepository),
      // ...
    ],
    child: const MainApp(),
  ),
);
```

### ViewModel Creation in GoRouter
```dart
GoRoute(
  path: Routes.home,
  builder: (context, state) {
    final viewModel = HomeViewModel(
      bookingRepository: context.read(),
    );
    return HomeScreen(viewModel: viewModel);
  },
),
```

### Injected components must be PRIVATE
```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required BookingRepository bookingRepository})
    : _bookingRepository = bookingRepository; // PRIVATE
  final BookingRepository _bookingRepository;
}
```

---

## 9. Testing

### ViewModel Unit Tests
```dart
test('Load bookings', () {
  final viewModel = HomeViewModel(
    bookingRepository: FakeBookingRepository()..createBooking(kBooking),
  );
  expect(viewModel.bookings.isNotEmpty, true);
});
```

### Widget Tests
```dart
setUp(() {
  viewModel = HomeViewModel(
    bookingRepository: FakeBookingRepository()..createBooking(kBooking),
  );
});

// Only need to mock Repositories — ViewModel is real
```

### Rules
- Fakes over mocks (FakeBookingRepository implements BookingRepository)
- Fakes live in `testing/` shared subpackage
- Arrange-Act-Assert pattern
- Test Command states (running, completed, error)
- Injectable time for time-dependent logic

---

## 10. Dart 3+ Modern Patterns

### DO
- `.firstOrNull` instead of manual `for` loops
- `.nonNulls` to filter nulls (auto-casts to non-null type)
- Functional chains (`.map().nonNulls.toSet()`) over imperative loops
- `const {}` / `const []` for empty collections in error paths
- Exhaustive `switch` expressions
- Pattern matching for Result unwrapping

### DON'T
- Imperative `for` loops when functional equivalent exists
- `values.byName()` when value differs from enum variable name
- Manual `==`/`hashCode` — use `with Equatable`
- `DateTime.now()` directly — inject time parameter

---

## 11. Optimistic State Pattern

For perceived responsiveness:
1. Update UI immediately (optimistic)
2. Execute async action in background
3. If failure: revert UI and show error
4. If success: no-op (UI already correct)

```dart
Future<void> subscribe() async {
  if (subscribed) return;

  subscribed = true;       // Optimistic update
  notifyListeners();

  try {
    await repository.subscribe();
  } catch (e) {
    subscribed = false;    // Revert on failure
    error = true;
  } finally {
    notifyListeners();
  }
}
```

---

## 12. Persistent Storage Pattern

### Key-Value (SharedPreferences)
```
ThemeSwitch (View) -> ThemeSwitchViewModel -> ThemeRepository -> SharedPreferencesService
```

- Repository wraps service, returns `Result<T>`
- Repository can expose `Stream` for reactive updates
- Service hides third-party dependency

### Relational (Drift/SQLite)
- Same pattern but with Drift DAOs as Services
- SyncQueue with timestamps for offline-first
- Auto-sync on reconnect
- Conflict resolution: same field = manual, different fields = auto-merge
