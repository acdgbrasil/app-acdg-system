import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

enum PostalRegion {
  region0,
  region1,
  region2,
  region3,
  region4,
  region5,
  region6,
  region7,
  region8,
  region9;

  static PostalRegion fromDigit(int digit) => PostalRegion.values[digit];
}

enum DistributionKind {
  streetRange('STREET_RANGE'),
  specialCodes('SPECIAL_CODES'),
  promotional('PROMOTIONAL'),
  postOfficeUnits('POST_OFFICE_UNITS'),
  other('OTHER');

  const DistributionKind(this.value);
  final String value;
}

/// Value Object para o Código de Endereçamento Postal (CEP).
final class Cep with Equatable {
  const Cep._(this.value);

  /// 8 dígitos numéricos.
  final String value;

  String get prefix => value.substring(0, 5);
  String get suffix => value.substring(5, 8);
  int get regionDigit => int.parse(value[0]);
  PostalRegion get region => PostalRegion.fromDigit(regionDigit);

  DistributionKind get distributionKind {
    final s = int.parse(suffix);
    if (s >= 0 && s <= 899) return DistributionKind.streetRange;
    if (s >= 900 && s <= 959) return DistributionKind.specialCodes;
    if (s >= 960 && s <= 969) return DistributionKind.promotional;
    if ((s >= 970 && s <= 989) || s == 999) {
      return DistributionKind.postOfficeUnits;
    }
    return DistributionKind.other;
  }

  String get formatted => '$prefix-$suffix';

  @override
  List<Object?> get props => [value];

  static Result<Cep> create(String? rawValue) {
    if (rawValue == null || rawValue.normalizedTrim().isEmpty) {
      return Failure(_buildError('CEP-001', 'O CEP não pode ser vazio.'));
    }

    final trimmed = rawValue.normalizedTrim();
    if (!RegExp(r'^[\d\-\s]+$').hasMatch(trimmed)) {
      return Failure(
        _buildError('CEP-002', 'O CEP contém caracteres inválidos.'),
      );
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 8) {
      return Failure(
        _buildError('CEP-003', 'O CEP deve conter exatamente 8 dígitos.'),
      );
    }

    if (!_isValidStateRange(int.parse(digits))) {
      return Failure(
        _buildError(
          'CEP-004',
          'O CEP não pertence a nenhuma faixa de UF válida.',
        ),
      );
    }

    return Success(Cep._(digits));
  }

  static bool _isValidStateRange(int cep) {
    final ranges = [
      [1000000, 19999999], // SP
      [20000000, 28999999], // RJ
      [29000000, 29999999], // ES
      [30000000, 39999999], // MG
      [40000000, 48999999], // BA
      [49000000, 49999999], // SE
      [50000000, 56999999], // PE
      [57000000, 57999999], // AL
      [58000000, 58999999], // PB
      [59000000, 59999999], // RN
      [60000000, 63999999], // CE
      [64000000, 64999999], // PI
      [65000000, 65999999], // MA
      [66000000, 68899999], // PA
      [68900000, 68999999], // AP
      [69000000, 69299999], [69400000, 69899999], // AM
      [69300000, 69389999], // RR
      [69900000, 69999999], // AC
      [70000000, 73699999], // DF
      [72800000, 76799999], // GO
      [77000000, 77995999], // TO
      [78000000, 78899999], // MT
      [78900000, 78999999], // RO
      [79000000, 79999999], // MS
      [80000000, 87999999], // PR
      [88000000, 89999999], // SC
      [90000000, 99999999], // RS
    ];

    for (final range in ranges) {
      if (cep >= range[0] && cep <= range[1]) return true;
    }
    return false;
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/cep',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
