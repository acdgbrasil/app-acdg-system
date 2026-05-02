# D03 — DesktopAssembler (Builder) + AutoDrainObserver (Observer)

## Onda: 1.5 (refactor débito) | Profile: refactor | Depende de: D01, D02 | Não bloqueia: C01

## Motivação

Após D01 (helpers extraídos) e D02 (use cases agrupados), `social_care_desktop.dart` ainda tem ~350L com 4 responsabilidades:
1. Composition root da factory `create()`
2. Connectivity observer com `late SocialCareDesktop desktop` self-reference
3. Constructor com 14 parâmetros
4. Entry point class (única responsabilidade legítima)

D03 é a **terceira e última onda** do refactor. Aplica **Builder pattern** (resolve construtor inflado + composition root) e **Observer pattern** (resolve self-reference circular). Após D03, `social_care_desktop.dart` fica em ~150L com **uma só responsabilidade**: ser o entry point.

## Padrões aplicados (GoF)

- **Builder** — `DesktopAssembler` com API fluente; tests pulam fases declarativamente
- **Observer** — `AutoDrainObserver` se inscreve em connectivity_plus; recebe `SyncEngine` direto (elimina self-reference)

## Escopo

### NEW: `apps/social_care_bff/desktop/lib/src/facade/composition/desktop_runtime.dart`

Data class privada que carrega tudo construído:

```dart
class DesktopRuntime {
  const DesktopRuntime({
    required this.cacheDb,
    required this.syncDb,
    required this.engine,
    required this.connectivityObserver,
    required this.drainController,
    required this.registry,
    required this.assessment,
    required this.care,
    required this.protection,
    required this.audit,
    required this.lookup,
    required this.health,
  });

  final CacheDatabase cacheDb;
  final SyncDatabase syncDb;
  final SyncEngine engine;
  final AutoDrainObserver connectivityObserver;
  final StreamController<DrainSummary> drainController;

  final RegistryFacade registry;
  final AssessmentFacade assessment;
  final CareFacade care;
  final ProtectionFacade protection;
  final AuditFacade audit;
  final LookupFacade lookup;
  final HealthFacade health;
}
```

### NEW: `apps/social_care_bff/desktop/lib/src/facade/composition/desktop_assembler.dart`

`DesktopAssembler` com Builder fluente:

```dart
class DesktopAssembler {
  DesktopAssembler({
    required this.baseUrl,
    required this.actorId,
    required this.tokenProvider,
  });

  final String baseUrl;
  final String actorId;
  final String? Function() tokenProvider;

  String? _cacheFilePath;
  String? _syncQueueFilePath;
  Dio? _dio;
  Clock? _clock;
  Duration _staleAfter = const Duration(minutes: 5);
  Connectivity? _connectivity;
  DriftExecutorFactory _executorFactory = DriftExecutorFactory.production;

  DesktopAssembler withLocalCache({String? path}) {
    _cacheFilePath = path;
    return this;
  }

  DesktopAssembler withSyncQueue({String? path}) {
    _syncQueueFilePath = path;
    return this;
  }

  DesktopAssembler withDio(Dio dio) {
    _dio = dio;
    return this;
  }

  DesktopAssembler withClock(Clock clock) {
    _clock = clock;
    return this;
  }

  DesktopAssembler withStaleAfter(Duration duration) {
    _staleAfter = duration;
    return this;
  }

  DesktopAssembler withConnectivity(Connectivity connectivity) {
    _connectivity = connectivity;
    return this;
  }

  DesktopAssembler withExecutorFactory(DriftExecutorFactory factory) {
    _executorFactory = factory;
    return this;
  }

  Future<DesktopRuntime> build() async {
    // 1. Resolve paths (defaults via path_provider)
    final cachePath = _cacheFilePath ?? await defaultDesktopFilePath('app_cache.sqlite');
    final syncPath = _syncQueueFilePath ?? await defaultDesktopFilePath('app_sync_queue.sqlite');

    // 2. Open databases via factory
    final cacheDb = CacheDatabase(_executorFactory.open(cachePath));
    final syncDb = SyncDatabase(_executorFactory.open(syncPath));

    // 3. Build infra (clock + dio)
    final clock = _clock ?? const SystemClock();
    final dio = _dio ?? RemoteBase.buildDio(baseUrl: baseUrl, actorId: actorId, tokenProvider: tokenProvider);

    // 4. Build remotes + caches + outbox
    final caches = _buildCaches(cacheDb, clock);
    final remotes = _buildRemotes(dio);
    final outbox = DriftOutboxRepository(syncDb);

    // 5. Build sync engine + drain controller (PumpingSyncEngine from D01)
    final drainController = StreamController<DrainSummary>.broadcast();
    final engine = PumpingSyncEngine(
      outbox: outbox,
      registry: remotes.registry,
      assessment: remotes.assessment,
      care: remotes.care,
      protection: remotes.protection,
      lookup: remotes.lookup,
      drainController: drainController,
    );

    // 6. Build use cases via 7 builders (from D02)
    final registryUseCases = RegistryUseCases.build(
      patientsCache: caches.patients,
      remote: remotes.registry,
      outbox: outbox,
      engine: engine,
      clock: clock,
      staleAfter: _staleAfter,
    );
    // ... 6 more builders

    // 7. Build sub-facades (now thin via D02 grouping)
    final registryFacade = RegistryFacade.internal(useCases: registryUseCases);
    // ... 6 more

    // 8. Build observer (from below)
    final observer = await AutoDrainObserver.watch(
      engine: engine,
      connectivity: _connectivity ?? Connectivity(),
    );

    return DesktopRuntime(
      cacheDb: cacheDb,
      syncDb: syncDb,
      engine: engine,
      connectivityObserver: observer,
      drainController: drainController,
      registry: registryFacade,
      assessment: assessmentFacade,
      // ... 5 more
    );
  }

  // Private helpers grouped by what they build
  ({PatientsCache patients, CareCache care, ProtectionCache protection,
    AuditCache audit, LookupCache lookup}) _buildCaches(CacheDatabase db, Clock clock) {
    return (
      patients: DriftPatientsCache(db, clock: clock),
      care: DriftCareCache(db, clock: clock),
      protection: DriftProtectionCache(db, clock: clock),
      audit: DriftAuditCache(db, clock: clock),
      lookup: DriftLookupCache(db, clock: clock),
    );
  }

  ({RegistryRemote registry, AssessmentRemote assessment, CareRemote care,
    ProtectionRemote protection, AuditRemote audit, LookupRemote lookup,
    HealthRemote health}) _buildRemotes(Dio dio) {
    return (
      registry: RegistryRemote(dio: dio),
      assessment: AssessmentRemote(dio: dio),
      // ...
    );
  }
}
```

### NEW: `apps/social_care_bff/desktop/lib/src/sync/connectivity/auto_drain_observer.dart`

Observer pattern aplicado à connectivity. **Recebe `SyncEngine` direto — sem `late SocialCareDesktop`**:

```dart
class AutoDrainObserver {
  AutoDrainObserver._({
    required SyncEngine engine,
    required StreamSubscription<List<ConnectivityResult>> subscription,
    required bool initialOnline,
  }) : _engine = engine,
       _subscription = subscription,
       _wasOnline = initialOnline;

  final SyncEngine _engine;
  final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _wasOnline;

  /// Subscribes to [connectivity] and triggers `engine.triggerDrain()` on
  /// every offline → online edge. The subscription is bound at this call;
  /// remember to dispose via [dispose] when shutting down.
  static Future<AutoDrainObserver> watch({
    required SyncEngine engine,
    required Connectivity connectivity,
  }) async {
    final initialResults = await connectivity.checkConnectivity();
    final initialOnline = resultsAreOnline(initialResults);

    late AutoDrainObserver observer;
    final subscription = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = resultsAreOnline(results);
      if (isOnline && !observer._wasOnline) {
        unawaited(engine.triggerDrain());
      }
      observer._wasOnline = isOnline;
    });

    observer = AutoDrainObserver._(
      engine: engine,
      subscription: subscription,
      initialOnline: initialOnline,
    );
    return observer;
  }

  /// Cancels the connectivity subscription. Idempotent.
  Future<void> dispose() => _subscription.cancel();
}
```

**Observação:** o `late observer` aqui é local ao método estático e fecha sobre o callback ANTES de retornar — não atravessa a fronteira de uma classe externa. A self-reference circular do code-smell anterior some porque o callback agora se refere a outra instância (`engine`), não à classe consumidora.

### MOD: `social_care_desktop.dart` (rewrite parcial — fica ~150L)

```dart
class SocialCareDesktop {
  SocialCareDesktop._(this._runtime);

  final DesktopRuntime _runtime;
  bool _closed = false;

  // ── Public sub-facades (delegates to runtime) ──────────────────────
  RegistryFacade get registry => _runtime.registry;
  AssessmentFacade get assessment => _runtime.assessment;
  CareFacade get care => _runtime.care;
  ProtectionFacade get protection => _runtime.protection;
  AuditFacade get audit => _runtime.audit;
  LookupFacade get lookup => _runtime.lookup;
  HealthFacade get health => _runtime.health;

  // ── Public sync state ──────────────────────────────────────────────
  Stream<DrainSummary> get drainStream => _runtime.drainController.stream;

  Future<Result<DrainSummary>> triggerDrain() {
    if (_closed) {
      return Future.value(Failure(SyncFailure('SocialCareDesktop closed')));
    }
    return _runtime.engine.triggerDrain();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────
  Future<void> startSync() => _runtime.engine.start();
  Future<void> stopSync() => _runtime.engine.stop();

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _runtime.connectivityObserver.dispose();
    await _runtime.engine.close();
    try { await _runtime.cacheDb.close(); } catch (_) {}
    try { await _runtime.syncDb.close(); } catch (_) {}
    if (!_runtime.drainController.isClosed) {
      await _runtime.drainController.close();
    }
  }

  // ── Factory (delegates to assembler) ───────────────────────────────
  static Future<SocialCareDesktop> create({
    required String baseUrl,
    required String actorId,
    required String? Function() tokenProvider,
    String? cacheFilePath,
    String? syncQueueFilePath,
    Dio? dio,
    Clock? clock,
    Duration staleAfter = const Duration(minutes: 5),
    Connectivity? connectivity,
  }) async {
    final assembler = DesktopAssembler(
      baseUrl: baseUrl,
      actorId: actorId,
      tokenProvider: tokenProvider,
    ).withStaleAfter(staleAfter);

    if (cacheFilePath != null) assembler.withLocalCache(path: cacheFilePath);
    if (syncQueueFilePath != null) assembler.withSyncQueue(path: syncQueueFilePath);
    if (dio != null) assembler.withDio(dio);
    if (clock != null) assembler.withClock(clock);
    if (connectivity != null) assembler.withConnectivity(connectivity);

    final runtime = await assembler.build();
    return SocialCareDesktop._(runtime);
  }
}
```

Total: ~150L. Surface pública 100% preservada.

## Pipeline de refactor (3 waves — sem TDD RED)

| Wave | Agent | Output |
|------|-------|--------|
| W0 — Baseline | Bash direto | Confirma 426 GREEN |
| W1 — Refactor | flutter-bff-implementer | DesktopAssembler + AutoDrainObserver + DesktopRuntime; SocialCareDesktop reduzido |
| W2 — Review | flutter-code-reviewer | Builder API consistente, Observer não tem self-reference, surface pública intocada |
| W3 — Quality | flutter-quality-checker | analyze 0, format clean, 426 GREEN |

## Critérios de aceitação

- [ ] 3 arquivos novos: `desktop_assembler.dart`, `desktop_runtime.dart`, `auto_drain_observer.dart`
- [ ] `social_care_desktop.dart` reduz de **~350L (pós-D02) → ~150L** (delta esperado ~200L)
- [ ] Constructor `SocialCareDesktop._` aceita 1 parâmetro (DesktopRuntime), não mais 14
- [ ] `late SocialCareDesktop desktop` self-reference **eliminado** do código
- [ ] AutoDrainObserver recebe `SyncEngine` direto, não `SocialCareDesktop`
- [ ] Surface pública 100% intocada
- [ ] **426 GREEN preservados**
- [ ] `dart analyze apps/social_care_bff/desktop/lib/` zero issues
- [ ] BFF Web não regride — 1137 GREEN
- [ ] Total BFF — 2098 GREEN +1 skip

## Resultado final pós-D01+D02+D03

```
apps/social_care_bff/desktop/lib/src/facade/
├── social_care_desktop.dart                  # ~150L (era 718L) — entry + lifecycle
│
├── sub_facades/                              # ~200L total (era 440L) — pass-through puro
│   ├── registry_facade.dart
│   ├── assessment_facade.dart
│   ├── care_facade.dart
│   ├── protection_facade.dart
│   ├── audit_facade.dart
│   ├── lookup_facade.dart
│   └── health_facade.dart
│
└── composition/                              # bastidores
    ├── desktop_assembler.dart                # ~200L — Builder
    ├── desktop_runtime.dart                  # ~50L — data class
    ├── db_executor.dart                      # ~80L — Factory Method (D01)
    ├── connectivity_helpers.dart             # ~10L (D01)
    └── builders/                             # 7 use cases builders (D02)
        ├── registry_use_cases.dart
        ├── assessment_use_cases.dart
        ├── care_use_cases.dart
        ├── protection_use_cases.dart
        ├── audit_use_cases.dart
        ├── lookup_use_cases.dart
        └── health_use_cases.dart

apps/social_care_bff/desktop/lib/src/sync/
├── engine/
│   ├── sync_engine.dart                      # já existia
│   └── pumping_sync_engine.dart              # extraído em D01
└── connectivity/
    └── auto_drain_observer.dart              # NOVO em D03
```

Antes: 1 arquivo de 718L com 6 responsabilidades.
Depois: 14 arquivos pequenos, cada um com 1 responsabilidade, padrões GoF formalizados.

## NÃO fazer

- Não introduzir Decorator nos use cases — D6 reservado
- Não introduzir Strategy no SyncEngine — D7 reservado
- Não criar interface `UseCase<I, O>` comum
- Não mudar surface pública de SocialCareDesktop

## Status
ready — depende de D01 + D02 fechados
