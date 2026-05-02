import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import 'time_stamp.dart';

/// Value Object para o Registro Geral (RG).
///
/// **História da validação:** o RG é um documento legado brasileiro sem
/// padronização nacional. Cada estado emite no formato que quiser — SP usa
/// 9 dígitos com check digit mod-11, MG usa 10+ dígitos sem padrão, RJ inclui
/// letras em alguns formatos, outros variam de 4 a 14 caracteres sem
/// algoritmo universal.
///
/// **Validação atual** (espelhando a decisão do backend Swift em `fix(domain)!`):
/// - Regex alfanumérica: `^[A-Z0-9]{4,15}$`
/// - Sem checksum (não existe algoritmo universal entre os 27 estados)
/// - Separadores (`.`, `-`, ` `) são removidos antes da validação
/// - Número é armazenado no formato compacto
final class RgDocument with Equatable {
  const RgDocument._({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  /// Número compacto, já sem separadores e em uppercase. Ex: `123456782`, `MG1234567`.
  final String number;

  /// UF de emissão validada (ex: `SP`).
  final String issuingState;

  /// Órgão emissor normalizado (ex: `SSP SP`).
  final String issuingAgency;

  /// Data de emissão (não pode ser no futuro).
  final TimeStamp issueDate;

  @override
  List<Object?> get props => [number, issuingState, issuingAgency, issueDate];

  static const _validStates = {
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  };

  /// Regex alfanumérica, 4–15 caracteres — aceita RGs de todos os 27 estados.
  static final _numberRegex = RegExp(r'^[A-Z0-9]{4,15}$');

  /// Separadores aceitos no input (pontos, hífens, espaços).
  static final _separatorRegex = RegExp(r'[\.\-\s]');

  static Result<RgDocument> create({
    required String? number,
    required String? issuingState,
    required String? issuingAgency,
    required TimeStamp? issueDate,
    TimeStamp? now,
  }) {
    if (number == null || number.normalizedTrim().isEmpty) {
      return Failure(
        _buildError(
          code: 'RGD-001',
          message: 'Número do RG não pode ser vazio.',
        ),
      );
    }

    final compact = number
        .normalizedTrim()
        .toUpperCase()
        .replaceAll(_separatorRegex, '');

    if (!_numberRegex.hasMatch(compact)) {
      return Failure(
        _buildError(
          code: 'RGD-005',
          message:
              'Número do RG inválido. Aceitos 4 a 15 caracteres '
              'alfanuméricos (A–Z, 0–9). Pontos, hifens e espaços '
              'são removidos antes da validação.',
          providedLength: compact.length,
          maskedNumber: _maskRg(compact),
        ),
      );
    }

    final state = issuingState?.normalizedTrim().toUpperCase();
    if (state == null || !_validStates.contains(state)) {
      return Failure(
        _buildError(
          code: 'RGD-002',
          message: 'UF emissora do RG é inválida.',
        ),
      );
    }

    final agency = issuingAgency?.normalize().toUpperCase();
    if (agency == null || agency.isEmpty) {
      return Failure(
        _buildError(
          code: 'RGD-003',
          message: 'Órgão emissor do RG não pode ser vazio.',
        ),
      );
    }

    if (issueDate == null) {
      return Failure(
        _buildError(
          code: 'RGD-004',
          message: 'Data de emissão não pode ser vazia.',
        ),
      );
    }

    final referenceNow = now ?? TimeStamp.now;
    if (issueDate.date.isAfter(referenceNow.date)) {
      return Failure(
        _buildError(
          code: 'RGD-004',
          message: 'Data de emissão do RG não pode ser no futuro.',
        ),
      );
    }

    return Success(
      RgDocument._(
        number: compact,
        issuingState: state,
        issuingAgency: agency,
        issueDate: issueDate,
      ),
    );
  }

  /// Mascara o RG para logs: primeiros 2 + últimos 2, resto trocado por `*`.
  /// Ex: `123456782` → `12*****82`.
  static String _maskRg(String compact) {
    if (compact.length <= 4) return '*' * compact.length;
    final head = compact.substring(0, 2);
    final tail = compact.substring(compact.length - 2);
    final stars = '*' * (compact.length - 4);
    return '$head$stars$tail';
  }

  static AppError _buildError({
    required String code,
    required String message,
    int? providedLength,
    String? maskedNumber,
  }) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/rg-document',
      kind: 'domainValidation',
      http: 422,
      // context sem PII — só metadados seguros.
      context: {
        if (providedLength != null) 'providedLength': providedLength,
      },
      // safeContext com valor mascarado para correlação em Sentry/logs.
      safeContext: {
        if (maskedNumber != null) 'maskedNumber': maskedNumber,
      },
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
