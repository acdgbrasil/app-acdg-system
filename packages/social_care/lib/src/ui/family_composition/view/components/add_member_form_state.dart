import 'package:flutter/widgets.dart';
import '../../constants/family_composition_ln10.dart';
import '../../models/add_member_result.dart';

/// State holder for the add/edit member modal form.
///
/// Encapsulates all field values, validation logic, and date parsing
/// that was previously inline in [AddMemberModal].
class AddMemberFormState {
  final name = TextEditingController();
  final birthDate = TextEditingController();
  final sex = ValueNotifier<String?>(null);
  final relationship = ValueNotifier<String?>(null);
  final residing = ValueNotifier<bool?>(null);
  final pcd = ValueNotifier<bool?>(null);
  final caregiver = ValueNotifier<bool?>(false);
  final requiredDocuments = ValueNotifier<Set<String>>({});

  /// Populates the form from an existing [AddMemberResult] for editing.
  void populateFrom(AddMemberResult existing) {
    name.text = existing.name;
    final d = existing.birthDate;
    birthDate.text =
        '${d.day.toString().padLeft(2, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.year}';
    sex.value = existing.sex == FamilyCompositionLn10.sexMale
        ? 'masculino'
        : existing.sex == FamilyCompositionLn10.sexFemale
        ? 'feminino'
        : 'outro';
    relationship.value = existing.relationshipCode;
    residing.value = existing.residesWithPatient;
    pcd.value = existing.hasDisability;
    caregiver.value = existing.isPrimaryCaregiver;
    requiredDocuments.value = {...existing.requiredDocuments};
  }

  // ── Validation ──

  String? get nameError {
    if (name.text.trim().isEmpty) return FamilyCompositionLn10.errorRequired;
    if (name.text.trim().length < 3) {
      return FamilyCompositionLn10.errorMinChars3;
    }
    return null;
  }

  String? get birthDateError {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return FamilyCompositionLn10.errorBirthDate;
    if (digits.length != 8) return FamilyCompositionLn10.errorDateIncomplete;
    if (parsedDate == null) return FamilyCompositionLn10.errorDateInvalid;
    return null;
  }

  DateTime? get parsedDate {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String? get sexError =>
      sex.value == null ? FamilyCompositionLn10.errorSelectSex : null;

  String? get relationshipError => relationship.value == null
      ? FamilyCompositionLn10.errorSelectRelationship
      : null;

  String? get residingError =>
      residing.value == null ? FamilyCompositionLn10.errorSelectResiding : null;

  String? get pcdError =>
      pcd.value == null ? FamilyCompositionLn10.errorSelectPcd : null;

  bool get isValid =>
      nameError == null &&
      birthDateError == null &&
      sexError == null &&
      relationshipError == null &&
      residingError == null &&
      pcdError == null;

  /// Builds the result snapshot from the current form values.
  AddMemberResult toResult() {
    final sexLabel = switch (sex.value) {
      'masculino' => FamilyCompositionLn10.sexMale,
      'feminino' => FamilyCompositionLn10.sexFemale,
      _ => FamilyCompositionLn10.sexOther,
    };

    return AddMemberResult(
      name: name.text.trim(),
      birthDate: parsedDate!,
      sex: sexLabel,
      relationshipCode: relationship.value!,
      residesWithPatient: residing.value!,
      hasDisability: pcd.value!,
      isPrimaryCaregiver: caregiver.value ?? false,
      requiredDocuments: {...requiredDocuments.value},
    );
  }

  void toggleDocument(String doc) {
    final current = {...requiredDocuments.value};
    if (current.contains(doc)) {
      current.remove(doc);
    } else {
      current.add(doc);
    }
    requiredDocuments.value = current;
  }

  void dispose() {
    name.dispose();
    birthDate.dispose();
    sex.dispose();
    relationship.dispose();
    residing.dispose();
    pcd.dispose();
    caregiver.dispose();
    requiredDocuments.dispose();
  }
}
