import 'patient_detail.dart';

/// Represents a ficha (form/section) and whether it's been filled.
final class FichaStatus {
  final String name;
  final bool filled;
  final bool disabled;

  const FichaStatus({
    required this.name,
    required this.filled,
    this.disabled = false,
  });

  /// Derives all 10 fichas from a UI [PatientDetail].
  static List<FichaStatus> fromDetail(PatientDetail detail) {
    return [
      FichaStatus(
        name: 'Composição familiar',
        filled: detail.familyMembers.isNotEmpty,
      ),
      FichaStatus(
        name: 'Acesso a benefícios eventuais',
        filled: detail.socioeconomicSituation != null,
        disabled: true,
      ),
      FichaStatus(
        name: 'Condições de saúde da família',
        filled: detail.healthStatus != null,
      ),
      FichaStatus(
        name: 'Convivência familiar e comunitária',
        filled: detail.communitySupportNetwork != null,
      ),
      FichaStatus(
        name: 'Condições educacionais da família',
        filled: detail.educationalStatus != null,
        disabled: true,
      ),
      FichaStatus(
        name: 'Situações de violência e violação de direitos',
        filled: detail.violationReports.isNotEmpty,
        disabled: true,
      ),
      FichaStatus(
        name: 'Condições de trabalho e rendimento da família',
        filled: detail.workAndIncome != null,
        disabled: true,
      ),
      FichaStatus(
        name: 'Especificidades sociais, étnicas ou culturais',
        filled: detail.socialIdentity != null,
      ),
      FichaStatus(
        name: 'Forma de ingresso e motivo do primeiro atendimento',
        filled: detail.intakeInfo != null,
      ),
      FichaStatus(
        name: 'Condições habitacionais da família',
        filled: detail.housingCondition != null,
      ),
    ];
  }
}
