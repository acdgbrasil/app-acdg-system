import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

import '../../../../models/family_member_snapshot.dart';

/// Form controllers and validation for a single family member entry.
///
/// Created and pre-populated by the FormState/ViewModel, then passed
/// to the modal as a ready-to-consume dependency.
class FamilyMemberEntry {
  final name = TextEditingController();
  final birthDate = TextEditingController();
  final sex = ValueNotifier<String?>(null);
  final relationship = ValueNotifier<String?>(null);
  final hasDisability = ValueNotifier<bool?>(null);
  final isResiding = ValueNotifier<bool?>(null);
  final isCaregiver = ValueNotifier<bool?>(null);
  final requiredDocuments = ValueNotifier<Set<String>>({});

  // ── Validation ──

  String? get nameError {
    final text = name.text.trim();
    if (text.isEmpty) return ReferencePersonLn10.errorRequired;
    if (text.length < 3) return ReferencePersonLn10.errorMinChars3;
    return null;
  }

  String? get birthDateError {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return ReferencePersonLn10.errorRequired;
    if (digits.length != 8) return ReferencePersonLn10.errorDateIncomplete;
    if (dateParsed == null) return ReferencePersonLn10.errorDateInvalid;
    return null;
  }

  String? get sexError =>
      sex.value == null ? ReferencePersonLn10.errorSelectGender : null;
  String? get relationshipError =>
      relationship.value == null
          ? ReferencePersonLn10.errorSelectRelationship
          : null;
  String? get hasDisabilityError =>
      hasDisability.value == null ? ReferencePersonLn10.errorRequired : null;

  bool get isValid =>
      nameError == null &&
      birthDateError == null &&
      sexError == null &&
      relationshipError == null &&
      hasDisabilityError == null;

  List<String> get validationErrors => [
        ?nameError,
        ?birthDateError,
        ?sexError,
        ?relationshipError,
        ?hasDisabilityError,
      ];

  DateTime? get dateParsed {
    final digits = birthDate.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  /// Creates a pre-populated entry from an existing snapshot (for editing).
  static FamilyMemberEntry fromSnapshot(FamilyMemberSnapshot snapshot) {
    final entry = FamilyMemberEntry();
    entry.name.text = snapshot.name;
    final d = snapshot.birthDate;
    entry.birthDate.text =
        '${d.day.toString().padLeft(2, '0')}${d.month.toString().padLeft(2, '0')}${d.year}';
    entry.sex.value = snapshot.sex;
    entry.relationship.value = snapshot.relationshipCode;
    entry.hasDisability.value = snapshot.hasDisability;
    entry.isResiding.value = snapshot.isResiding;
    entry.isCaregiver.value = snapshot.isCaregiver;
    entry.requiredDocuments.value = {...snapshot.requiredDocuments};
    return entry;
  }

  void dispose() {
    name.dispose();
    birthDate.dispose();
    sex.dispose();
    relationship.dispose();
    hasDisability.dispose();
    isResiding.dispose();
    isCaregiver.dispose();
    requiredDocuments.dispose();
  }
}
