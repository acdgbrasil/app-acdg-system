import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../kernel/ids.dart';
import 'assessment_vos.dart'; // To get SocialBenefit

final class WorkIncomeVO with Equatable {
  const WorkIncomeVO._({required this.memberId, required this.occupationId, required this.hasWorkCard, required this.monthlyAmount});
  
  final PersonId memberId;
  final LookupId occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  @override
  List<Object?> get props => [memberId, occupationId, hasWorkCard, monthlyAmount];

  static Result<WorkIncomeVO> create({
    required PersonId memberId,
    required LookupId occupationId,
    required bool hasWorkCard,
    required double monthlyAmount,
  }) {
    if (monthlyAmount < 0) {
      return Failure(
        AppError(code: 'WI-001', message: 'Renda mensal não pode ser negativa', module: 'social-care/work-income', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning))
      );
    }
    return Success(WorkIncomeVO._(memberId: memberId, occupationId: occupationId, hasWorkCard: hasWorkCard, monthlyAmount: monthlyAmount));
  }
}

final class WorkAndIncome with Equatable {
  const WorkAndIncome({
    required this.familyId,
    required this.individualIncomes,
    required this.socialBenefits,
    required this.hasRetiredMembers,
  });

  final PatientId familyId;
  final List<WorkIncomeVO> individualIncomes;
  final List<SocialBenefit> socialBenefits;
  final bool hasRetiredMembers;

  @override
  List<Object?> get props => [familyId, individualIncomes, socialBenefits, hasRetiredMembers];
}
