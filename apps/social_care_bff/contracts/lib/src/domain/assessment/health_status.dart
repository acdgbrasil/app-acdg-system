import 'package:core_contracts/core_contracts.dart';
import '../kernel/ids.dart';

final class MemberDeficiency with Equatable {
  const MemberDeficiency({
    required this.memberId,
    required this.deficiencyTypeId,
    required this.needsConstantCare,
    this.responsibleCaregiverName,
  });

  final PersonId memberId;
  final LookupId deficiencyTypeId;
  final bool needsConstantCare;
  final String? responsibleCaregiverName;

  @override
  List<Object?> get props => [
    memberId,
    deficiencyTypeId,
    needsConstantCare,
    responsibleCaregiverName,
  ];
}

final class PregnantMember with Equatable {
  const PregnantMember({
    required this.memberId,
    required this.monthsGestation,
    required this.startedPrenatalCare,
  });

  final PersonId memberId;
  final int monthsGestation;
  final bool startedPrenatalCare;

  @override
  List<Object?> get props => [memberId, monthsGestation, startedPrenatalCare];
}

final class HealthStatus with Equatable {
  const HealthStatus({
    required this.familyId,
    required this.deficiencies,
    required this.gestatingMembers,
    required this.constantCareNeeds,
    required this.foodInsecurity,
  });

  final PatientId familyId;
  final List<MemberDeficiency> deficiencies;
  final List<PregnantMember> gestatingMembers;
  final List<PersonId> constantCareNeeds;
  final bool foodInsecurity;

  @override
  List<Object?> get props => [
    familyId,
    deficiencies,
    gestatingMembers,
    constantCareNeeds,
    foodInsecurity,
  ];
}
