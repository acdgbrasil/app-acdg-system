# D02 — UseCases Builders por Bounded Context

## Onda: 1.5 (refactor débito) | Profile: refactor | Depende de: D01 | Não bloqueia: C01

## Motivação

O `SocialCareDesktop.create()` lista 42 use cases manualmente em ~250 linhas (linhas 330-577 do `social_care_desktop.dart`). Cada use case tem 4-5 deps via `required:` — adicionar 1 use case novo (ex: `cancelAppointment`) toca o entry point em 3 lugares.

D02 quebra essa massa em **7 builders por bounded context** — espelha as 7 sub-facades existentes. Cada builder é uma classe `_RegistryUseCases`/etc. que sabe construir SEUS use cases. O entry point passa a chamar 7 builders em vez de listar 42 instâncias.

## Padrões aplicados (GoF)

- Nenhum padrão GoF formal — é **organização** (princípio Composition + SRP). Cada builder é uma "factory de classe" interna ao package.

## Escopo

### NEW: `apps/social_care_bff/desktop/lib/src/facade/composition/builders/registry_use_cases.dart`

Data class agrupando os 13 use cases de Registry + factory `build()`:

```dart
class RegistryUseCases {
  RegistryUseCases({
    required this.fetchPatient,
    required this.fetchPatientByPersonId,
    required this.listPatients,
    required this.searchPatients,
    required this.registerPatient,
    required this.addFamilyMember,
    required this.removeFamilyMember,
    required this.assignPrimaryCaregiver,
    required this.updateSocialIdentity,
    required this.dischargePatient,
    required this.readmitPatient,
    required this.admitPatient,
    required this.withdrawPatient,
  });

  final FetchPatientUseCase fetchPatient;
  final FetchPatientByPersonIdUseCase fetchPatientByPersonId;
  final ListPatientsUseCase listPatients;
  final SearchPatientsUseCase searchPatients;
  final RegisterPatientUseCase registerPatient;
  final AddFamilyMemberUseCase addFamilyMember;
  final RemoveFamilyMemberUseCase removeFamilyMember;
  final AssignPrimaryCaregiverUseCase assignPrimaryCaregiver;
  final UpdateSocialIdentityUseCase updateSocialIdentity;
  final DischargePatientUseCase dischargePatient;
  final ReadmitPatientUseCase readmitPatient;
  final AdmitPatientUseCase admitPatient;
  final WithdrawPatientUseCase withdrawPatient;

  /// Builds all 13 Registry use cases from shared dependencies.
  static RegistryUseCases build({
    required PatientsCache patientsCache,
    required RegistryRemote remote,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    required Duration staleAfter,
  }) {
    final readDeps = (cache: patientsCache, remote: remote, clock: clock, staleAfter: staleAfter);
    final writeDeps = (cache: patientsCache, outbox: outbox, engine: engine, clock: clock);

    return RegistryUseCases(
      // Reads
      fetchPatient: FetchPatientUseCase(cache: readDeps.cache, remote: readDeps.remote, clock: readDeps.clock, staleAfter: readDeps.staleAfter),
      fetchPatientByPersonId: FetchPatientByPersonIdUseCase(cache: readDeps.cache, remote: readDeps.remote, clock: readDeps.clock, staleAfter: readDeps.staleAfter),
      listPatients: ListPatientsUseCase(cache: readDeps.cache, remote: readDeps.remote, clock: readDeps.clock, staleAfter: readDeps.staleAfter),
      searchPatients: SearchPatientsUseCase(cache: readDeps.cache, remote: readDeps.remote, clock: readDeps.clock, staleAfter: readDeps.staleAfter),
      // Writes
      registerPatient: RegisterPatientUseCase(cache: writeDeps.cache, outbox: writeDeps.outbox, engine: writeDeps.engine, clock: writeDeps.clock),
      // ... rest
    );
  }
}
```

### NEW: análogos pros 6 outros bounded contexts

```
composition/builders/
├── registry_use_cases.dart       # 13 use cases
├── assessment_use_cases.dart     # 7 use cases
├── care_use_cases.dart           # 3 use cases
├── protection_use_cases.dart     # 6 use cases
├── audit_use_cases.dart          # 1 use case
├── lookup_use_cases.dart         # 10 use cases
└── health_use_cases.dart         # 2 use cases
```

Cada um segue o mesmo padrão: data class com fields + `build()` static factory.

### MOD: `social_care_desktop.dart`

`create()` reduz de ~250L de listagem manual pra ~30L de delegação:

```dart
// ── Build use cases per bounded context ──────────────────────────
final registryUseCases = RegistryUseCases.build(
  patientsCache: patientsCache,
  remote: registryRemote,
  outbox: outbox,
  engine: engine,
  clock: effectiveClock,
  staleAfter: staleAfter,
);

final assessmentUseCases = AssessmentUseCases.build(
  patientsCache: patientsCache,
  outbox: outbox,
  engine: engine,
  clock: effectiveClock,
);

// ... 5 more
```

E os sub-facades passam a receber o data class agrupado em vez de 13 parâmetros individuais:

```dart
// Antes:
final registryFacade = RegistryFacade.internal(
  fetchPatient: fetchPatient,
  fetchPatientByPersonId: fetchPatientByPersonId,
  // ... 11 more
);

// Depois:
final registryFacade = RegistryFacade.internal(useCases: registryUseCases);
```

### MOD: `sub_facades/registry_facade.dart` (e os outros 6)

Ajusta o construtor `.internal` pra receber o data class:

```dart
class RegistryFacade {
  RegistryFacade.internal({required RegistryUseCases useCases})
      : _useCases = useCases;

  final RegistryUseCases _useCases;

  // Reads
  Future<Result<PatientResponse>> fetchPatient(String id) =>
      _useCases.fetchPatient(id);

  // ... rest delegates to _useCases.X
}
```

Sub-facade reduz de 121L pra ~70L (Registry — outros proporcionalmente).

## Pipeline de refactor (3 waves — sem TDD RED)

| Wave | Agent | Output |
|------|-------|--------|
| W0 — Baseline | Bash direto | Confirma 426 GREEN |
| W1 — Refactor | flutter-bff-implementer | 7 builders + 7 sub-facades ajustadas |
| W2 — Review | flutter-code-reviewer | SRP per builder, surface pública intocada |
| W3 — Quality | flutter-quality-checker | analyze 0, format clean, 426 GREEN |

## Critérios de aceitação

- [ ] 7 builders criados em `composition/builders/`
- [ ] 7 sub-facades atualizadas pra receber `XxxUseCases` agrupado
- [ ] `social_care_desktop.dart` reduz de **~600L (pós-D01) → ~350L** (delta esperado ~250L)
- [ ] Sub-facades reduzem ~50% cada (apenas pass-through fica)
- [ ] `dart analyze apps/social_care_bff/desktop/lib/` zero issues
- [ ] **426 GREEN preservados** (zero teste tocado, zero comportamento alterado)
- [ ] Surface pública intocada
- [ ] BFF Web não regride — 1137 GREEN preservados
- [ ] Total BFF preservado — 2098 GREEN +1 skip

## Adicionar 1 use case novo pós-D02 (smoke test mental)

Adicionar `CancelAppointmentUseCase`:

1. Cria `use_cases/care/cancel_appointment_use_case.dart`
2. Adiciona field + parâmetro em `CareUseCases` (em `composition/builders/care_use_cases.dart`)
3. Adiciona método `cancel` em `CareFacade`
4. **Não toca** em `social_care_desktop.dart`

Hoje (pré-D02): toca 4 lugares no entry point + 1 no sub-facade.

## NÃO fazer

- Não criar `DesktopAssembler` — D03
- Não criar `AutoDrainObserver` — D03
- Não tocar em remotes/caches/sync layer — só use cases + sub-facades
- Não mudar signatures de use cases existentes
- Não introduzir interface `UseCase<I, O>` comum (premature; espera Decorator demand em D6)

## Status
ready — depende de D01 ter fechado
