import 'package:flutter/foundation.dart';

import '../../shared/models/benefit_row.dart';
import '../../shared/models/member_option.dart';

/// Mutable form state for the Socio-Economic assessment.
///
/// Owns all editable fields, dirty tracking, and validation.
/// The ViewModel holds a reference and delegates UI mutations here.
class SocioEconomicFormState {
  double totalFamilyIncome = 0;
  bool receivesSocialBenefit = false;
  String mainSourceOfIncome = '';
  bool hasUnemployed = false;
  List<BenefitRow> socialBenefits = [];
  List<MemberOption> familyMembers = [];
  String patientName = '';

  // ── Computed ──────────────────────────────────────────────────

  double get incomePerCapita {
    final count = familyMembers.isNotEmpty ? familyMembers.length : 1;
    return totalFamilyIncome / count;
  }

  bool get canSave =>
      totalFamilyIncome >= 0 &&
      mainSourceOfIncome.trim().isNotEmpty &&
      (!receivesSocialBenefit || socialBenefits.isNotEmpty) &&
      (receivesSocialBenefit || socialBenefits.isEmpty) &&
      isDirty;

  bool get isDirty =>
      totalFamilyIncome != _origTotalIncome ||
      receivesSocialBenefit != _origReceivesBenefit ||
      mainSourceOfIncome != _origMainSource ||
      hasUnemployed != _origHasUnemployed ||
      socialBenefits.length != _origBenefitsCount;

  // ── Benefit mutations ────────────────────────────────────────

  void addBenefit() => socialBenefits = [...socialBenefits, BenefitRow()];

  void removeBenefit(int i) =>
      socialBenefits = List.of(socialBenefits)..removeAt(i);

  void updateBenefitName(int i, String v) => socialBenefits[i].benefitName = v;

  void updateBenefitAmount(int i, double v) => socialBenefits[i].amount = v;

  void updateBenefitBeneficiary(int i, String v) =>
      socialBenefits[i].beneficiaryId = v;

  void updateBenefitTypeId(int i, String v) =>
      socialBenefits[i].benefitTypeId = v;

  // ── Snapshot for dirty tracking ──────────────────────────────

  double _origTotalIncome = 0;
  bool _origReceivesBenefit = false;
  String _origMainSource = '';
  bool _origHasUnemployed = false;
  int _origBenefitsCount = 0;

  void saveOriginals() {
    _origTotalIncome = totalFamilyIncome;
    _origReceivesBenefit = receivesSocialBenefit;
    _origMainSource = mainSourceOfIncome;
    _origHasUnemployed = hasUnemployed;
    _origBenefitsCount = socialBenefits.length;
  }
}
