---
title: "Models must be immutable with final properties"
scope: "file"
path: ["**/model/**/*.dart", "**/models/**/*.dart"]
severity_min: "high"
languages: ["dart"]
buckets: ["architecture", "style-conventions"]
enabled: true
---

## Instructions

All models must be immutable (ADR-010). Models are schemas — no business logic.

Rules:
- All properties must be `final`
- No mutable state (`var`, late mutable)
- Must provide `copyWith` for creating modified copies
- Domain models (`domain/models/`) must NOT have `fromJson`/`toJson` — those belong in data models (`data/model/`)
- Data models may have `fromJson`/`toJson` but remain immutable

Flag:
- Non-final properties in model classes
- Business logic methods in models (validation, computation)
- Domain models with JSON serialization

## Examples

### Bad example
```dart
class Patient {
  String name; // Mutable!
  int age;
  
  void validate() { /* Business logic in model */ }
  
  Map<String, dynamic> toJson() => {}; // JSON in domain model
}
```

### Good example
```dart
class Patient {
  final String name;
  final int age;

  const Patient({required this.name, required this.age});

  Patient copyWith({String? name, int? age}) =>
    Patient(name: name ?? this.name, age: age ?? this.age);
}
```
