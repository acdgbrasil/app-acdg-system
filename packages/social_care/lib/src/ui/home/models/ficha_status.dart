import 'package:shared/shared.dart';

/// Represents a ficha (form/section) and whether it's been filled.
final class FichaStatus {
  final String name;
  final bool filled;

  const FichaStatus({required this.name, required this.filled});

  /// Derives all 10 fichas from a domain [Patient].
  static List<FichaStatus> fromPatient(Patient patient) {
    return [
      FichaStatus(
        name: 'Composição familiar',
        filled: patient.familyMembers.isNotEmpty,
      ),
      FichaStatus(
        name: 'Acesso a benefícios eventuais',
        filled: patient.socioeconomicSituation != null,
      ),
      FichaStatus(
        name: 'Condições de saúde da família',
        filled: patient.healthStatus != null,
      ),
      FichaStatus(
        name: 'Convivência familiar e comunitária',
        filled: patient.communitySupportNetwork != null,
      ),
      FichaStatus(
        name: 'Condições educacionais da família',
        filled: patient.educationalStatus != null,
      ),
      FichaStatus(
        name: 'Situações de violência e violação de direitos',
        filled: patient.violationReports.isNotEmpty,
      ),
      FichaStatus(
        name: 'Condições de trabalho e rendimento da família',
        filled: patient.workAndIncome != null,
      ),
      FichaStatus(
        name: 'Especificidades sociais, étnicas ou culturais',
        filled: patient.socialIdentity != null,
      ),
      FichaStatus(
        name: 'Forma de ingresso e motivo do primeiro atendimento',
        filled: patient.intakeInfo != null,
      ),
      FichaStatus(
        name: 'Serviços e programas de convivência comunitária',
        filled: patient.housingCondition != null,
      ),
    ];
  }
}
