import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import 'cep.dart';

enum ResidenceLocation { urbano, rural }

/// Value Object para Endereço.
final class Address with Equatable {
  const Address._({
    this.cep,
    required this.state,
    required this.city,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
    required this.residenceLocation,
    required this.isShelter,
    required this.isHomeless,
  });

  final Cep? cep;
  final String state;
  final String city;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final ResidenceLocation residenceLocation;
  final bool isShelter;
  final bool isHomeless;

  @override
  List<Object?> get props => [
    cep,
    state,
    city,
    street,
    neighborhood,
    number,
    complement,
    residenceLocation,
    isShelter,
    isHomeless,
  ];

  static const _validStates = {
    "AC",
    "AL",
    "AP",
    "AM",
    "BA",
    "CE",
    "DF",
    "ES",
    "GO",
    "MA",
    "MT",
    "MS",
    "MG",
    "PA",
    "PB",
    "PR",
    "PE",
    "PI",
    "RJ",
    "RN",
    "RS",
    "RO",
    "RR",
    "SC",
    "SP",
    "SE",
    "TO",
  };

  static Result<Address> create({
    Cep? cep,
    required String? state,
    required String? city,
    String? street,
    String? neighborhood,
    String? number,
    String? complement,
    required ResidenceLocation residenceLocation,
    required bool isShelter,
    bool isHomeless = false,
  }) {
    final st = state?.normalizedTrim().toUpperCase();
    if (st == null || st.isEmpty) {
      return Failure(_buildError('ADR-002', 'UF é obrigatória.'));
    }
    if (!_validStates.contains(st)) {
      return Failure(_buildError('ADR-003', 'UF inválida.'));
    }

    final ct = city?.normalize();
    if (ct == null || ct.isEmpty) {
      return Failure(_buildError('ADR-004', 'Cidade é obrigatória.'));
    }

    return Success(
      Address._(
        cep: cep,
        state: st,
        city: ct,
        street: street?.nullIfEmptyNormalized(),
        neighborhood: neighborhood?.nullIfEmptyNormalized(),
        number: number?.nullIfEmptyNormalized(),
        complement: complement?.nullIfEmptyNormalized(),
        residenceLocation: residenceLocation,
        isShelter: isShelter,
        isHomeless: isHomeless,
      ),
    );
  }

  Address copyWith({
    Cep? Function()? cep,
    String? state,
    String? city,
    String? Function()? street,
    String? Function()? neighborhood,
    String? Function()? number,
    String? Function()? complement,
    ResidenceLocation? residenceLocation,
    bool? isShelter,
    bool? isHomeless,
  }) {
    return Address._(
      cep: cep != null ? cep() : this.cep,
      state: state ?? this.state,
      city: city ?? this.city,
      street: street != null ? street() : this.street,
      neighborhood: neighborhood != null ? neighborhood() : this.neighborhood,
      number: number != null ? number() : this.number,
      complement: complement != null ? complement() : this.complement,
      residenceLocation: residenceLocation ?? this.residenceLocation,
      isShelter: isShelter ?? this.isShelter,
      isHomeless: isHomeless ?? this.isHomeless,
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/address',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
