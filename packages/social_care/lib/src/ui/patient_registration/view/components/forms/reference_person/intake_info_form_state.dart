import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

/// Form state for Step 6 — Intake Info (Forma de Ingresso).
///
/// Maps to `RegisterIntakeInfoRequest` in the contract:
/// - `ingressTypeId` (lookup `dominio_tipo_ingresso`)
/// - `originName`, `originContact` (encaminhamento details)
/// - `serviceReason` (required)
/// - `linkedSocialPrograms[]` (lookup `dominio_programa_social`)
class IntakeInfoFormState {
  /// Selected ingress type key (mapped to lookup UUID at submission).
  final ingressType = ValueNotifier<String?>(null);

  /// Referral source name (when ingress is an encaminhamento).
  final originName = TextEditingController();

  /// Referral source contact.
  final originContact = TextEditingController();

  /// Reason for the first appointment — required by the contract.
  final serviceReason = TextEditingController();

  /// Selected social programs (keys mapped to lookup UUIDs).
  final selectedPrograms = ValueNotifier<Set<String>>({});

  /// General observations (maps to program observation in the contract).
  final programObservation = TextEditingController();

  // ── Program selection helpers ──

  void toggleProgram(String key) {
    final current = {...selectedPrograms.value};
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    selectedPrograms.value = current;
  }

  // ── Validation ──

  String? get ingressTypeError =>
      ingressType.value == null ? ReferencePersonLn10.errorSelectIngressType : null;

  String? get serviceReasonError {
    final text = serviceReason.text.trim();
    if (text.isEmpty) return ReferencePersonLn10.errorRequired;
    return null;
  }

  bool get isValidForNextStep =>
      ingressTypeError == null && serviceReasonError == null;

  List<String> get validationErrors => [
        if (ingressTypeError != null) ingressTypeError!,
        if (serviceReasonError != null) serviceReasonError!,
      ];

  void dispose() {
    ingressType.dispose();
    originName.dispose();
    originContact.dispose();
    serviceReason.dispose();
    selectedPrograms.dispose();
    programObservation.dispose();
  }
}
