import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import 'time_stamp.dart';

/// Value Object para o Registro Geral (RG).
///
/// Alinhado ao contrato OpenAPI `RegisterPatientRequest.rgDocument`:
/// `number`, `issuingState` e `issuingAgency` são `string` livre (sem regex
/// ou enum), `issueDate` é `IsoDate`. Os 4 campos são obrigatórios quando
/// `rgDocument` é informado.
final class RgDocument with Equatable {
  const RgDocument._({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  /// Número do RG, normalizado (trim + uppercase + remoção de `.`/`-`/espaços).
  /// Pode conter qualquer combinação alfanumérica — sem regex/check digit.
  final String number;

  /// UF de emissão (ex: SP). Normalizada (trim + uppercase). Sem whitelist.
  final String issuingState;

  /// Órgão emissor (ex: SSP). Normalizado (trim + collapse + uppercase).
  final String issuingAgency;

  /// Data de emissão.
  final TimeStamp issueDate;

  /// Retorna o número como guardado, sem formatação (RG não tem máscara fixa).
  String get formattedNumber => number;

  @override
  List<Object?> get props => [number, issuingState, issuingAgency, issueDate];

  static Result<RgDocument> create({
    required String? number,
    required String? issuingState,
    required String? issuingAgency,
    required TimeStamp? issueDate,
  }) {
    if (number == null || number.normalizedTrim().isEmpty) {
      return Failure(
        _buildError('RGD-001', 'Número do RG não pode ser vazio.'),
      );
    }

    final rawNumber = number.normalizedTrim().toUpperCase().replaceAll(
      RegExp(r'[\.\-\s]'),
      '',
    );

    final state = issuingState?.normalizedTrim().toUpperCase();
    if (state == null || state.isEmpty) {
      return Failure(
        _buildError('RGD-002', 'UF emissora do RG não pode ser vazia.'),
      );
    }

    final agency = issuingAgency?.normalize().toUpperCase();
    if (agency == null || agency.isEmpty) {
      return Failure(
        _buildError('RGD-003', 'Órgão emissor do RG não pode ser vazio.'),
      );
    }

    if (issueDate == null) {
      return Failure(
        _buildError('RGD-004', 'Data de emissão não pode ser vazia.'),
      );
    }

    return Success(
      RgDocument._(
        number: rawNumber,
        issuingState: state,
        issuingAgency: agency,
        issueDate: issueDate,
      ),
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/rg-document',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
