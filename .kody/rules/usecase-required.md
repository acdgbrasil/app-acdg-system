---
title: "UseCase is mandatory for all features"
scope: "file"
path: ["**/viewmodel/**/*.dart", "**/*_view_model.dart", "**/*_vm.dart"]
severity_min: "high"
languages: ["dart"]
buckets: ["architecture"]
enabled: true
---

## Instructions

Per ADR-013, every feature MUST have a UseCase. ViewModels must delegate business logic to UseCases and must NOT call Repositories or Services directly.

Flag:
- ViewModels importing Repository or Service classes
- ViewModels calling repository/service methods directly
- Features missing a corresponding UseCase

The Command pattern is used: ViewModel → Command → UseCase → Repository → Service

## Examples

### Bad example
```dart
class PatientListViewModel extends ChangeNotifier {
  final PatientRepository _repository; // Direct dependency on repository

  Future<void> loadPatients() async {
    final patients = await _repository.fetchAll(); // Bypasses UseCase
    notifyListeners();
  }
}
```

### Good example
```dart
class PatientListViewModel extends ChangeNotifier {
  final ListPatientsUseCase _listPatients;

  Future<void> loadPatients() async {
    final result = await _listPatients.execute();
    // update state from result
    notifyListeners();
  }
}
```
