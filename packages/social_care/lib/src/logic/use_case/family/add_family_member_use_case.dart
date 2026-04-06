import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/family_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/family_mapper.dart';

/// Orchestrates adding a family member to a patient record.
class AddFamilyMemberUseCase extends BaseUseCase<AddFamilyMemberIntent, void> {
  AddFamilyMemberUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(AddFamilyMemberIntent intent) async {
    // 1. Domain Assembly via specialized Mapper
    final memberRes = FamilyMapper.toFamilyMember(intent);
    if (memberRes case Failure(:final error)) return Failure(error);

    final prRelIdRes = LookupId.create(intent.prRelationshipId);
    if (prRelIdRes case Failure(:final error)) return Failure(error);

    final fullName = '${intent.firstName} ${intent.lastName}'.trim();

    return _patientRepository.addFamilyMember(
      intent.patientId,
      (memberRes as Success<FamilyMember>).value,
      (prRelIdRes as Success<LookupId>).value,
      fullName: fullName.isNotEmpty ? fullName : null,
    );
  }
}
