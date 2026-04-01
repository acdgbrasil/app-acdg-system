import 'package:flutter/widgets.dart';

/// Form state for Step 5 — Social Specificities.
///
/// Maps to `socialIdentity` in the contract: a single `typeId` (lookup
/// `dominio_tipo_identidade`) with an optional `description`.
/// Only one identity can be selected at a time (radio, not checkboxes).
class SpecificitiesFormState {
  /// The selected identity option key (e.g. 'cigana', 'quilombola', etc.).
  /// This will be mapped to a lookup UUID at submission time.
  final selectedIdentity = ValueNotifier<String?>(null);

  /// Text field for identities that require elaboration
  /// (e.g. indigenous tribe name, "outras" description).
  final identityDescription = TextEditingController();

  /// Keys that require description text when selected.
  static const keysRequiringDescription = {
    'indigena_aldeia',
    'indigena_fora',
    'outras',
  };

  /// Whether the description field should be enabled.
  bool get isDescriptionEnabled =>
      selectedIdentity.value != null &&
      keysRequiringDescription.contains(selectedIdentity.value);

  /// Selects an identity and clears description if the new option
  /// does not require one.
  void selectIdentity(String? key) {
    selectedIdentity.value = key;
    if (!keysRequiringDescription.contains(key)) {
      identityDescription.clear();
    }
  }

  // Section is entirely optional — user can skip without selecting anything.
  bool get isValidForNextStep => true;

  List<String> get validationErrors => const [];

  void dispose() {
    selectedIdentity.dispose();
    identityDescription.dispose();
  }
}
