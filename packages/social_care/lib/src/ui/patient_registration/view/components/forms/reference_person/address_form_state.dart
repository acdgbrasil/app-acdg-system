import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

/// Housing situation options for the address step.
enum HousingSituation { shelter, regular, homeless }

class AddressFormState {
  // 1. Controladores — Seleções
  final housingSituation = ValueNotifier<HousingSituation?>(null);
  final residenceLocation = ValueNotifier<String?>(null);
  final state = ValueNotifier<String?>(null);

  // 2. Controladores — Texto
  final cep = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final complement = TextEditingController();
  final neighborhood = TextEditingController();
  final city = TextEditingController();

  // 3. Derived values for contract
  bool get isShelterValue => housingSituation.value == HousingSituation.shelter;
  bool get isHomelessValue => housingSituation.value == HousingSituation.homeless;

  /// Whether address fields (CEP, street, number, complement, neighborhood)
  /// should be disabled. State and city remain enabled for CRAS reference.
  bool get areAddressFieldsDisabled => isHomelessValue;

  // 4. Getters de Erro
  String? get housingSituationError {
    if (housingSituation.value == null) return ReferencePersonLn10.errorSelectHousingSituation;
    return null;
  }

  String? get residenceLocationError {
    if (residenceLocation.value == null) return ReferencePersonLn10.errorSelectLocation;
    return null;
  }

  String? get cepError {
    if (areAddressFieldsDisabled) return null;
    final digits = cep.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 8) return ReferencePersonLn10.cepError;
    return null;
  }

  String? get stateError {
    if (state.value == null) return ReferencePersonLn10.errorSelectState;
    return null;
  }

  String? get cityError {
    final text = city.text.trim();
    if (text.isEmpty) return ReferencePersonLn10.errorInformCity;
    if (text.length < 2) return ReferencePersonLn10.errorMinChars2;
    return null;
  }

  // 5. Validação do Step
  bool get isValidForNextStep {
    if (housingSituationError != null) return false;
    if (residenceLocationError != null) return false;
    if (cepError != null) return false;
    if (stateError != null) return false;
    if (cityError != null) return false;
    return true;
  }

  List<String> get validationErrors => [
    if (housingSituationError != null) housingSituationError!,
    if (residenceLocationError != null) residenceLocationError!,
    if (cepError != null) cepError!,
    if (stateError != null) stateError!,
    if (cityError != null) cityError!,
  ];

  // 6. Acesso a valores
  String get cepDigits => cep.text.replaceAll(RegExp(r'\D'), '');

  /// Clears address-specific fields when switching to homeless.
  void clearAddressFields() {
    cep.clear();
    street.clear();
    number.clear();
    complement.clear();
    neighborhood.clear();
  }

  // 7. Auto-preenchimento via CEP (stub para futura integração ViaCEP)
  void fillFromCep({
    String? street,
    String? neighborhood,
    String? state,
    String? city,
  }) {
    if (street != null) this.street.text = street;
    if (neighborhood != null) this.neighborhood.text = neighborhood;
    if (state != null) this.state.value = state;
    if (city != null) this.city.text = city;
  }

  // 8. Gerenciamento de Memória
  void dispose() {
    housingSituation.dispose();
    residenceLocation.dispose();
    state.dispose();
    cep.dispose();
    street.dispose();
    number.dispose();
    complement.dispose();
    neighborhood.dispose();
    city.dispose();
  }
}
