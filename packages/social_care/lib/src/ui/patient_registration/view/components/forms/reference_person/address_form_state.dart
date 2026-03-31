import 'package:flutter/widgets.dart';

class AddressFormState {
  // 1. Controladores — Seleções
  final isShelter = ValueNotifier<bool?>(null);
  final residenceLocation = ValueNotifier<String?>(null);
  final state = ValueNotifier<String?>(null);

  // 2. Controladores — Texto
  final cep = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final complement = TextEditingController();
  final neighborhood = TextEditingController();
  final city = TextEditingController();

  // 3. Getters de Erro
  String? get isShelterError {
    if (isShelter.value == null) return 'Informe se é um abrigo';
    return null;
  }

  String? get residenceLocationError {
    if (residenceLocation.value == null) return 'Selecione a localização';
    return null;
  }

  String? get cepError {
    final digits = cep.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 8) return 'CEP inválido';
    return null;
  }

  String? get stateError {
    if (state.value == null) return 'Selecione o estado';
    return null;
  }

  String? get cityError {
    final text = city.text.trim();
    if (text.isEmpty) return 'Informe a cidade';
    if (text.length < 2) return 'Mínimo de 2 caracteres';
    return null;
  }

  // 4. Validação do Step
  bool get isValidForNextStep {
    if (isShelterError != null) return false;
    if (residenceLocationError != null) return false;
    if (cepError != null) return false;
    if (stateError != null) return false;
    if (cityError != null) return false;
    return true;
  }

  List<String> get validationErrors => [
    if (isShelterError != null) isShelterError!,
    if (residenceLocationError != null) residenceLocationError!,
    if (cepError != null) cepError!,
    if (stateError != null) stateError!,
    if (cityError != null) cityError!,
  ];

  // 5. Acesso a valores
  String get cepDigits => cep.text.replaceAll(RegExp(r'\D'), '');

  // 6. Auto-preenchimento via CEP (stub para futura integração ViaCEP)
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

  // 7. Gerenciamento de Memória
  void dispose() {
    isShelter.dispose();
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
