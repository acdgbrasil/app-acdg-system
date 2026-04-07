---
title: "Enforce MVVM layer boundaries"
scope: "file"
path: ["**/*.dart"]
severity_min: "high"
languages: ["dart"]
buckets: ["architecture"]
enabled: true
---

## Instructions

This project follows strict MVVM + Logic Layer architecture (ADR-003, ADR-013). Enforce these boundaries:

**Views** (`**/view/**`, `**/views/**`, `**/pages/**`):
- Must be DUMB — display data and capture events only
- Must NOT import repositories, services, or use cases directly
- Must NOT contain business logic or data transformation
- Must receive state from ViewModel only

**ViewModels** (`**/*_view_model.dart`, `**/*_vm.dart`):
- Own UI state via ValueNotifier/ChangeNotifier
- Must delegate business logic to UseCases
- Must NOT call repositories or services directly
- Must NOT import data layer (repositories, services)

**UseCases** (`**/*_use_case.dart`):
- Orchestrate repositories — mandatory for all features (ADR-013)
- Must NOT import Views or ViewModels
- Must NOT import Flutter widgets

**Repositories** (`**/repositories/**`):
- Must be defined as abstract classes (interfaces) for testability
- Implementations must NOT import UI layer

**Services** (`**/services/**`):
- Pure wrappers for external calls — no business logic

Data flow is unidirectional: Service → Repository → UseCase → ViewModel → View

## Examples

### Bad example
```dart
// View importing repository directly — layer violation
class PatientListPage extends StatelessWidget {
  final PatientRepository repository;
  
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.fetchAll(), // View calling repository
      builder: (ctx, snap) => ListView(...),
    );
  }
}
```

### Good example
```dart
class PatientListPage extends StatelessWidget {
  final PatientListViewModel viewModel;

  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: viewModel.patients,
      builder: (ctx, patients, _) => ListView(...),
    );
  }
}
```
