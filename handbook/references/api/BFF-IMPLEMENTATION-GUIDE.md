# Guia de Implementacao — Feature via BFF

Guia pratico para desenvolvedores frontend implementarem novas features consumindo a API Social Care atraves do BFF.

**Fonte de verdade da API:** [API-REFERENCE.md](./API-REFERENCE.md)

---

## Visao Geral do Fluxo

```
View → ViewModel → UseCase → Repository → BFF (SocialCareContract) → API Swift
                                                    ↓
                                              PatientMapper
                                              (Domain ↔ JSON)
```

**Direcao dos dados:**
- **Downstream (leitura):** API → BFF → Repository → UseCase → ViewModel → View
- **Upstream (escrita):** View → Command → ViewModel → UseCase → Repository → BFF → API

**Regra fundamental:** cada camada so conhece a camada imediatamente adjacente. A View nunca sabe que existe um BFF. O UseCase nunca sabe que existe HTTP.

---

## Ordem de Implementacao

```
1. Domain Model (se novo)
2. Repository (interface abstrata)
3. Repository Impl (delega ao BFF)
4. UseCase
5. Intent/Command (se escrita)
6. Mapper Intent → Domain (se escrita)
7. ViewModel
8. View (Page)
9. Testes
```

**NUNCA comece pela View.** De dentro para fora, sempre.

---

## Passo a Passo Completo

Usaremos como exemplo a implementacao de "Atualizar Condicao Habitacional" (`PUT .../housing-condition`).

---

### Passo 1 — Verificar o que o BFF ja oferece

O contrato do BFF (`SocialCareContract`) ja expoe **21 metodos** prontos para uso. Antes de criar qualquer coisa, verifique se o metodo ja existe.

**Arquivo:** `bff/shared/lib/src/contract/social_care_contract.dart`

```dart
abstract interface class SocialCareContract {
  // Registry (8 metodos)
  Future<Result<PatientId>> registerPatient(Patient patient);
  Future<Result<Patient>> getPatient(PatientId id);
  Future<Result<Patient>> getPatientByPersonId(PersonId personId);
  Future<Result<void>> addFamilyMember(PatientId patientId, FamilyMember member, LookupId prRelationshipId);
  Future<Result<void>> removeFamilyMember(PatientId patientId, PersonId memberId);
  Future<Result<void>> assignPrimaryCaregiver(PatientId patientId, PersonId memberId);
  Future<Result<void>> updateSocialIdentity(PatientId patientId, SocialIdentity identity);
  Future<Result<List<AuditEvent>>> getAuditTrail(PatientId patientId, {String? eventType});

  // Assessment (7 metodos)
  Future<Result<void>> updateHousingCondition(PatientId patientId, HousingCondition condition);
  Future<Result<void>> updateSocioEconomicSituation(PatientId patientId, SocioEconomicSituation situation);
  Future<Result<void>> updateWorkAndIncome(PatientId patientId, WorkAndIncome data);
  Future<Result<void>> updateEducationalStatus(PatientId patientId, EducationalStatus status);
  Future<Result<void>> updateHealthStatus(PatientId patientId, HealthStatus status);
  Future<Result<void>> updateCommunitySupportNetwork(PatientId patientId, CommunitySupportNetwork network);
  Future<Result<void>> updateSocialHealthSummary(PatientId patientId, SocialHealthSummary summary);

  // Care (2 metodos)
  Future<Result<AppointmentId>> registerAppointment(PatientId patientId, SocialCareAppointment appointment);
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info);

  // Protection (3 metodos)
  Future<Result<void>> updatePlacementHistory(PatientId patientId, PlacementHistory history);
  Future<Result<ViolationReportId>> reportViolation(PatientId patientId, RightsViolationReport report);
  Future<Result<ReferralId>> createReferral(PatientId patientId, Referral referral);

  // Lookup (1 metodo)
  Future<Result<List<LookupItem>>> getLookupTable(String tableName);

  // Health (2 metodos)
  Future<Result<void>> checkHealth();
  Future<Result<void>> checkReady();
}
```

O metodo `updateHousingCondition` ja existe. Entao nao precisamos mexer no BFF — so construir as camadas do frontend.

---

### Passo 2 — Repository (interface abstrata)

Crie a interface do repositorio em `packages/social_care/lib/src/data/repositories/`.

```dart
// assessment_repository.dart
import 'package:core/core.dart';
import 'package:shared/shared.dart';

abstract class AssessmentRepository {
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  );
}
```

**Regras:**
- Classe abstrata (nao interface), para permitir extensao futura
- Retorna `Result<T>` (nunca throws)
- Parametros sao objetos de dominio (nunca JSON, nunca DTOs)
- Um repositorio por bounded context (Assessment, Care, Protection, etc.)

---

### Passo 3 — Repository Impl (delega ao BFF)

Crie a implementacao concreta no mesmo diretorio.

```dart
// bff_assessment_repository.dart
import 'package:core/core.dart';
import 'package:shared/shared.dart';

class BffAssessmentRepository implements AssessmentRepository {
  BffAssessmentRepository({required SocialCareContract bff}) : _bff = bff;

  final SocialCareContract _bff;

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) {
    return _bff.updateHousingCondition(patientId, condition);
  }
}
```

**Regras:**
- Recebe `SocialCareContract` via construtor (DI)
- Apenas delega ao BFF — sem logica de negocio
- Pode adicionar cache, retry ou offline queue no futuro

---

### Passo 4 — Intent (comando do usuario)

Para operacoes de escrita, crie um Intent que captura os dados do formulario como snapshot imutavel.

```dart
// update_housing_intent.dart
import 'package:equatable/equatable.dart';

final class UpdateHousingIntent with EquatableMixin {
  const UpdateHousingIntent({
    required this.type,
    required this.wallMaterial,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.waterSupply,
    required this.hasPipedWater,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.accessibilityLevel,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
  });

  final String type;
  final String wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final String waterSupply;
  final bool hasPipedWater;
  final String electricityAccess;
  final String sewageDisposal;
  final String wasteCollection;
  final String accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  @override
  List<Object?> get props => [
        type, wallMaterial, numberOfRooms, numberOfBedrooms,
        numberOfBathrooms, waterSupply, hasPipedWater,
        electricityAccess, sewageDisposal, wasteCollection,
        accessibilityLevel, isInGeographicRiskArea,
        hasDifficultAccess, isInSocialConflictArea,
        hasDiagnosticObservations,
      ];
}
```

**Regras:**
- Todos os campos sao `final`
- Usa `EquatableMixin` para comparacao por valor
- Tipos primitivos (String, int, bool) — nunca objetos de dominio
- Nomes dos campos refletem o que o usuario ve no formulario

---

### Passo 5 — Mapper (Intent → Domain)

Converte o intent (dados crus do form) para o objeto de dominio validado.

```dart
// housing_condition_mapper.dart
import 'package:core/core.dart';
import 'package:shared/shared.dart';

abstract final class HousingConditionMapper {
  static Result<HousingCondition> toDomain(UpdateHousingIntent intent) {
    try {
      return Success(HousingCondition(
        type: HousingType.fromString(intent.type),
        wallMaterial: WallMaterial.fromString(intent.wallMaterial),
        numberOfRooms: intent.numberOfRooms,
        numberOfBedrooms: intent.numberOfBedrooms,
        numberOfBathrooms: intent.numberOfBathrooms,
        waterSupply: WaterSupply.fromString(intent.waterSupply),
        hasPipedWater: intent.hasPipedWater,
        electricityAccess: ElectricityAccess.fromString(intent.electricityAccess),
        sewageDisposal: SewageDisposal.fromString(intent.sewageDisposal),
        wasteCollection: WasteCollection.fromString(intent.wasteCollection),
        accessibilityLevel: AccessibilityLevel.fromString(intent.accessibilityLevel),
        isInGeographicRiskArea: intent.isInGeographicRiskArea,
        hasDifficultAccess: intent.hasDifficultAccess,
        isInSocialConflictArea: intent.isInSocialConflictArea,
        hasDiagnosticObservations: intent.hasDiagnosticObservations,
      ));
    } catch (e) {
      return Failure(e);
    }
  }
}
```

**Regras:**
- Classe abstrata final (nao instanciavel)
- Retorna `Result<T>` — validacao acontece aqui
- Converte strings para enums/VOs do dominio

---

### Passo 6 — UseCase

Orquestra a operacao: valida, transforma, persiste.

```dart
// update_housing_condition_use_case.dart
import 'package:core/core.dart';
import 'package:shared/shared.dart';

class UpdateHousingConditionUseCase
    extends BaseUseCase<(PatientId, UpdateHousingIntent), void> {
  UpdateHousingConditionUseCase({
    required AssessmentRepository assessmentRepository,
  }) : _repo = assessmentRepository;

  final AssessmentRepository _repo;

  @override
  Future<Result<void>> execute((PatientId, UpdateHousingIntent) input) async {
    final (patientId, intent) = input;

    // 1. Mapear intent para dominio (com validacao)
    final conditionResult = HousingConditionMapper.toDomain(intent);

    if (conditionResult case Failure(:final error)) {
      return Failure(error);
    }

    final condition = (conditionResult as Success<HousingCondition>).value;

    // 2. Persistir via repositorio
    return _repo.updateHousingCondition(patientId, condition);
  }
}
```

**Regras:**
- Estende `BaseUseCase<Input, Output>`
- Input pode ser um Record `(A, B)` quando precisa de multiplos parametros
- Recebe repositorio via construtor (DI)
- Toda logica de orquestracao fica aqui (nunca no ViewModel)
- Retorna `Result<T>` — nunca throws

---

### Passo 7 — ViewModel

Gerencia estado da UI e conecta View aos UseCases.

```dart
// housing_condition_view_model.dart
import 'package:core/core.dart';
import 'package:shared/shared.dart';

class HousingConditionViewModel extends BaseViewModel {
  HousingConditionViewModel({
    required PatientId patientId,
    required UpdateHousingConditionUseCase updateUseCase,
  })  : _patientId = patientId,
        _updateUseCase = updateUseCase {
    save = Command0(_onSave);
  }

  final PatientId _patientId;
  final UpdateHousingConditionUseCase _updateUseCase;

  // --- Commands ---
  late final Command0<void> save;

  // --- State ---
  String _type = '';
  String get type => _type;

  String _wallMaterial = '';
  String get wallMaterial => _wallMaterial;

  int _numberOfRooms = 0;
  int get numberOfRooms => _numberOfRooms;

  int _numberOfBedrooms = 0;
  int get numberOfBedrooms => _numberOfBedrooms;

  int _numberOfBathrooms = 0;
  int get numberOfBathrooms => _numberOfBathrooms;

  String _waterSupply = '';
  String get waterSupply => _waterSupply;

  bool _hasPipedWater = false;
  bool get hasPipedWater => _hasPipedWater;

  // ... demais campos seguem o mesmo padrao

  // --- Mutators ---
  void setType(String value) {
    _type = value;
    notifyListeners();
  }

  void setWallMaterial(String value) {
    _wallMaterial = value;
    notifyListeners();
  }

  void setNumberOfRooms(int value) {
    _numberOfRooms = value;
    notifyListeners();
  }

  // ... demais setters seguem o mesmo padrao

  // --- Handlers ---
  Future<Result<void>> _onSave() {
    final intent = UpdateHousingIntent(
      type: _type,
      wallMaterial: _wallMaterial,
      numberOfRooms: _numberOfRooms,
      numberOfBedrooms: _numberOfBedrooms,
      numberOfBathrooms: _numberOfBathrooms,
      waterSupply: _waterSupply,
      hasPipedWater: _hasPipedWater,
      electricityAccess: _electricityAccess,
      sewageDisposal: _sewageDisposal,
      wasteCollection: _wasteCollection,
      accessibilityLevel: _accessibilityLevel,
      isInGeographicRiskArea: _isInGeographicRiskArea,
      hasDifficultAccess: _hasDifficultAccess,
      isInSocialConflictArea: _isInSocialConflictArea,
      hasDiagnosticObservations: _hasDiagnosticObservations,
    );

    return _updateUseCase.execute((_patientId, intent));
  }

  /// Preenche o form com dados existentes do paciente (modo edicao).
  void hydrate(HousingCondition existing) {
    _type = existing.type.value;
    _wallMaterial = existing.wallMaterial.value;
    _numberOfRooms = existing.numberOfRooms;
    _numberOfBedrooms = existing.numberOfBedrooms;
    _numberOfBathrooms = existing.numberOfBathrooms;
    _waterSupply = existing.waterSupply.value;
    _hasPipedWater = existing.hasPipedWater;
    // ... demais campos
    notifyListeners();
  }
}
```

**Regras:**
- Estende `BaseViewModel` (protege contra notify apos dispose)
- Commands sao `late final` (inicializados no construtor)
- Estado e privado com getters publicos
- Setters chamam `notifyListeners()`
- `hydrate()` para preencher com dados existentes (edicao)
- ZERO logica de negocio — apenas monta o Intent e delega ao UseCase

---

### Passo 8 — View (Page)

A View e a camada mais fina. So exibe dados e captura eventos.

```dart
// housing_condition_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HousingConditionPage extends StatelessWidget {
  const HousingConditionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HousingConditionViewModel(
        patientId: context.read<PatientId>(),
        updateUseCase: context.read<UpdateHousingConditionUseCase>(),
      ),
      child: const _HousingConditionBody(),
    );
  }
}

class _HousingConditionBody extends StatelessWidget {
  const _HousingConditionBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HousingConditionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Condicao Habitacional')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Campo: Tipo de moradia
          DropdownButtonFormField<String>(
            value: vm.type.isEmpty ? null : vm.type,
            items: const [
              DropdownMenuItem(value: 'proprio', child: Text('Proprio')),
              DropdownMenuItem(value: 'alugado', child: Text('Alugado')),
              DropdownMenuItem(value: 'cedido', child: Text('Cedido')),
            ],
            onChanged: (v) => vm.setType(v ?? ''),
            decoration: const InputDecoration(labelText: 'Tipo de moradia'),
          ),
          const SizedBox(height: 16),

          // Campo: Numero de comodos
          TextFormField(
            initialValue: vm.numberOfRooms.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Numero de comodos'),
            onChanged: (v) => vm.setNumberOfRooms(int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),

          // Campo: Agua encanada (switch)
          SwitchListTile(
            title: const Text('Possui agua encanada?'),
            value: vm.hasPipedWater,
            onChanged: (v) => vm.setHasPipedWater(v),
          ),

          // ... demais campos seguem o mesmo padrao

          const SizedBox(height: 32),

          // Botao de salvar
          ListenableBuilder(
            listenable: vm.save,
            builder: (context, _) {
              if (vm.save.running) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vm.save.completed) {
                // Sucesso — pode navegar ou mostrar snackbar
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvo com sucesso!')),
                  );
                });
              }

              if (vm.save.error) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: ${vm.save.result}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              }

              return FilledButton(
                onPressed: () => vm.save.execute(),
                child: const Text('Salvar'),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

**Regras:**
- `StatelessWidget` (estado no ViewModel, nao no widget)
- `context.watch` para dados reativos, `context.read` para acoes
- `ListenableBuilder` para escutar Commands individuais
- Nenhuma logica de negocio na View
- Feedback de sucesso/erro via `command.completed` / `command.error`

---

### Passo 9 — Registro no DI (DependencyManager)

Registre as novas dependencias no container de DI.

```dart
// Em dependency_manager.dart, dentro do initialize():

// Repository
final assessmentRepo = BffAssessmentRepository(bff: socialCareBff);

// UseCase
final updateHousingUseCase = UpdateHousingConditionUseCase(
  assessmentRepository: assessmentRepo,
);
```

E exponha via Provider em `app_providers.dart`:

```dart
Provider<AssessmentRepository>.value(value: assessmentRepo),
Provider<UpdateHousingConditionUseCase>.value(value: updateHousingUseCase),
```

---

### Passo 10 — Testes

#### Teste do UseCase (unitario)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/testing.dart'; // FakeSocialCareBff

void main() {
  late FakeSocialCareBff fakeBff;
  late BffAssessmentRepository repo;
  late UpdateHousingConditionUseCase useCase;

  setUp(() {
    fakeBff = FakeSocialCareBff();
    repo = BffAssessmentRepository(bff: fakeBff);
    useCase = UpdateHousingConditionUseCase(assessmentRepository: repo);
  });

  test('deve atualizar condicao habitacional com sucesso', () async {
    // Arrange: registrar paciente primeiro
    final patientId = await _registerTestPatient(fakeBff);

    final intent = UpdateHousingIntent(
      type: 'proprio',
      wallMaterial: 'alvenaria',
      numberOfRooms: 5,
      numberOfBedrooms: 2,
      numberOfBathrooms: 1,
      waterSupply: 'rede_publica',
      hasPipedWater: true,
      electricityAccess: 'regular',
      sewageDisposal: 'rede_publica',
      wasteCollection: 'direta',
      accessibilityLevel: 'parcial',
      isInGeographicRiskArea: false,
      hasDifficultAccess: false,
      isInSocialConflictArea: false,
      hasDiagnosticObservations: false,
    );

    // Act
    final result = await useCase.execute((patientId, intent));

    // Assert
    expect(result.isSuccess, isTrue);
  });

  test('deve retornar Failure com dados invalidos', () async {
    final patientId = await _registerTestPatient(fakeBff);

    final intent = UpdateHousingIntent(
      type: '', // invalido
      // ...
    );

    final result = await useCase.execute((patientId, intent));

    expect(result.isFailure, isTrue);
  });
}
```

**Regras de teste:**
- Use `FakeSocialCareBff` (nunca mocks magicos)
- Teste o UseCase, nao o ViewModel
- Teste sucesso E falha
- Fakes estao em `shared/testing.dart`

---

## Lookup Tables — Como Usar

Muitos formularios dependem de tabelas de dominio para dropdowns. O BFF ja oferece `getLookupTable(tableName)`.

### Tabelas disponiveis e onde sao usadas

| tableName | Usado em | Campo |
|-----------|----------|-------|
| `dominio_parentesco` | Registro de paciente, membros | `prRelationshipId`, `relationship` |
| `dominio_tipo_identidade` | Identidade social | `typeId` |
| `dominio_condicao_ocupacao` | Trabalho e renda | `occupationId` |
| `dominio_escolaridade` | Status educacional | `educationLevelId` |
| `dominio_efeito_condicionalidade` | Status educacional | `effectId` |
| `dominio_tipo_deficiencia` | Status de saude | `deficiencyTypeId` |
| `dominio_programa_social` | Info de ingresso | `programId` |
| `dominio_tipo_ingresso` | Info de ingresso | `ingressTypeId` |
| `dominio_tipo_beneficio` | Situacao socioeconomica | `benefitTypeId` |
| `dominio_tipo_violacao` | Violacao de direitos | `violationTypeId` |

### Padrao de uso no ViewModel

```dart
class MyViewModel extends BaseViewModel {
  MyViewModel({required SocialCareContract bff}) : _bff = bff {
    loadLookups = Command0(_onLoadLookups);
    loadLookups.execute(); // carrega ao inicializar
  }

  final SocialCareContract _bff;
  late final Command0<void> loadLookups;

  List<LookupItem> _relationships = const [];
  List<LookupItem> get relationships => _relationships;

  Future<Result<void>> _onLoadLookups() async {
    final result = await _bff.getLookupTable('dominio_parentesco');
    if (result case Success(:final value)) {
      _relationships = value;
      notifyListeners();
    }
    return result.map((_) {});
  }
}
```

### Na View (dropdown)

```dart
DropdownButtonFormField<String>(
  value: vm.selectedRelationshipId,
  items: vm.relationships
      .map((item) => DropdownMenuItem(
            value: item.id,
            child: Text(item.descricao),
          ))
      .toList(),
  onChanged: (v) => vm.setRelationshipId(v ?? ''),
  decoration: const InputDecoration(labelText: 'Parentesco'),
)
```

---

## Mapeamento Completo: Endpoint → BFF → Frontend

| Endpoint API | Metodo BFF | Tipo |
|---|---|---|
| `POST /api/v1/patients` | `registerPatient(Patient)` | Escrita → `Result<PatientId>` |
| `GET /api/v1/patients/{id}` | `getPatient(PatientId)` | Leitura → `Result<Patient>` |
| `GET /api/v1/patients/by-person/{id}` | `getPatientByPersonId(PersonId)` | Leitura → `Result<Patient>` |
| `POST .../family-members` | `addFamilyMember(patientId, member, prRelId)` | Escrita → `Result<void>` |
| `DELETE .../family-members/{id}` | `removeFamilyMember(patientId, memberId)` | Escrita → `Result<void>` |
| `PUT .../primary-caregiver` | `assignPrimaryCaregiver(patientId, memberId)` | Escrita → `Result<void>` |
| `PUT .../social-identity` | `updateSocialIdentity(patientId, identity)` | Escrita → `Result<void>` |
| `GET .../audit-trail` | `getAuditTrail(patientId, eventType?)` | Leitura → `Result<List<AuditEvent>>` |
| `PUT .../housing-condition` | `updateHousingCondition(patientId, condition)` | Escrita → `Result<void>` |
| `PUT .../socioeconomic-situation` | `updateSocioEconomicSituation(patientId, situation)` | Escrita → `Result<void>` |
| `PUT .../work-and-income` | `updateWorkAndIncome(patientId, data)` | Escrita → `Result<void>` |
| `PUT .../educational-status` | `updateEducationalStatus(patientId, status)` | Escrita → `Result<void>` |
| `PUT .../health-status` | `updateHealthStatus(patientId, status)` | Escrita → `Result<void>` |
| `PUT .../community-support-network` | `updateCommunitySupportNetwork(patientId, network)` | Escrita → `Result<void>` |
| `PUT .../social-health-summary` | `updateSocialHealthSummary(patientId, summary)` | Escrita → `Result<void>` |
| `POST .../appointments` | `registerAppointment(patientId, appointment)` | Escrita → `Result<AppointmentId>` |
| `PUT .../intake-info` | `updateIntakeInfo(patientId, info)` | Escrita → `Result<void>` |
| `PUT .../placement-history` | `updatePlacementHistory(patientId, history)` | Escrita → `Result<void>` |
| `POST .../violation-reports` | `reportViolation(patientId, report)` | Escrita → `Result<ViolationReportId>` |
| `POST .../referrals` | `createReferral(patientId, referral)` | Escrita → `Result<ReferralId>` |
| `GET /api/v1/dominios/{table}` | `getLookupTable(tableName)` | Leitura → `Result<List<LookupItem>>` |

---

## Tratamento de Erros

### Na camada UseCase

Transforme erros do BFF em erros de dominio legiveis:

```dart
return result.mapFailure((error) => switch (error) {
  AppError(code: 'PAT-409') => const DuplicatePatientError(),
  AppError(code: 'HTTP-422') => ValidationError(error.toString()),
  AppError(code: 'HTTP-401') => const UnauthorizedError(),
  _ => GenericError(error.toString()),
});
```

### Na View

```dart
ListenableBuilder(
  listenable: vm.save,
  builder: (context, _) {
    if (vm.save.error) {
      final error = (vm.save.result as Failure).error;
      return Text(
        switch (error) {
          DuplicatePatientError() => 'Paciente ja cadastrado.',
          ValidationError(:final message) => 'Dados invalidos: $message',
          UnauthorizedError() => 'Sessao expirada. Faca login novamente.',
          _ => 'Erro inesperado. Tente novamente.',
        },
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## Checklist para Nova Feature

- [ ] Verificar se o metodo existe no `SocialCareContract`
- [ ] Consultar [API-REFERENCE.md](./API-REFERENCE.md) para campos, tipos e validacoes
- [ ] Criar Repository (interface + impl BFF)
- [ ] Criar Intent (se escrita)
- [ ] Criar Mapper Intent → Domain (se escrita)
- [ ] Criar UseCase
- [ ] Criar ViewModel com Commands
- [ ] Criar Page (StatelessWidget + Provider)
- [ ] Registrar no DependencyManager + AppProviders
- [ ] Escrever testes (UseCase com FakeSocialCareBff)
- [ ] Carregar lookup tables necessarias no ViewModel

---

## Arquivos de Referencia

| O que | Onde |
|-------|------|
| Contrato BFF | `bff/shared/lib/src/contract/social_care_contract.dart` |
| Impl Desktop (HTTP) | `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` |
| Fake (testes) | `bff/shared/lib/src/testing/fake_social_care_bff.dart` |
| Modelos de dominio | `bff/shared/lib/src/domain/` |
| Mapper JSON | `bff/shared/lib/src/infrastructure/patient_mapper.dart` |
| BaseViewModel | `packages/core/lib/src/base/base_view_model.dart` |
| BaseUseCase | `packages/core/lib/src/base/base_use_case.dart` |
| Result | `packages/core/lib/src/base/result.dart` |
| Command | `packages/core/lib/src/base/command.dart` |
| Exemplo completo (registro) | `packages/social_care/lib/src/ui/patient_registration/` |
| DI Container | `apps/acdg_system/lib/logic/di/dependency_manager.dart` |
| API Reference | `handbook/references/api/API-REFERENCE.md` |
