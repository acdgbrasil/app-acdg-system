import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

/// State for a single family member entry in the modal.
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

  String? get sexError => sex.value == null ? ReferencePersonLn10.errorSelectGender : null;
  String? get relationshipError =>
      relationship.value == null ? ReferencePersonLn10.errorSelectRelationship : null;
  String? get hasDisabilityError =>
      hasDisability.value == null ? ReferencePersonLn10.errorRequired : null;

  bool get isValid =>
      nameError == null &&
      birthDateError == null &&
      sexError == null &&
      relationshipError == null &&
      hasDisabilityError == null;

  List<String> get validationErrors => [
        if (nameError != null) nameError!,
        if (birthDateError != null) birthDateError!,
        if (sexError != null) sexError!,
        if (relationshipError != null) relationshipError!,
        if (hasDisabilityError != null) hasDisabilityError!,
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

/// Snapshot of a saved family member (immutable, for display in table).
class FamilyMemberSnapshot {
  const FamilyMemberSnapshot({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.relationshipCode,
    required this.hasDisability,
    required this.isResiding,
    required this.isCaregiver,
    required this.requiredDocuments,
  });

  final String name;
  final DateTime birthDate;
  final String sex;
  final String relationshipCode;
  final bool hasDisability;
  final bool isResiding;
  final bool isCaregiver;
  final Set<String> requiredDocuments;

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

/// Form state for Step 4 — Family Composition.
class FamilyCompositionFormState {
  final members = ValueNotifier<List<FamilyMemberSnapshot>>([]);

  void addMember(FamilyMemberSnapshot member) {
    members.value = [...members.value, member];
  }

  void updateMember(int index, FamilyMemberSnapshot member) {
    if (index < 0 || index >= members.value.length) return;
    members.value = [
      for (var i = 0; i < members.value.length; i++)
        if (i == index) member else members.value[i],
    ];
  }

  void removeMember(int index) {
    if (index < 0 || index >= members.value.length) return;
    members.value = [
      for (var i = 0; i < members.value.length; i++)
        if (i != index) members.value[i],
    ];
  }

  /// Whether any existing member is already marked as primary caregiver.
  bool get hasPrimaryCaregiver =>
      members.value.any((m) => m.isCaregiver);

  // Family members are optional — reference person is always included by the ViewModel.
  bool get isValidForNextStep => true;

  List<String> get validationErrors => const [];

  void dispose() {
    members.dispose();
  }
}
