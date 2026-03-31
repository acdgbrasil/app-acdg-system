import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update work and income.
class UpdateWorkAndIncomeUseCase
    extends BaseUseCase<UpdateWorkAndIncomeIntent, void> {
  UpdateWorkAndIncomeUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateWorkAndIncomeIntent intent) {
    return _patientRepository.updateWorkAndIncome(
      intent.patientId,
      WorkAndIncome(
        familyId: intent.patientId,
        individualIncomes: intent.individualIncomes,
        socialBenefits: intent.socialBenefits,
        hasRetiredMembers: intent.hasRetiredMembers,
      ),
    );
  }
}
