import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'json_helpers.dart';

/// Mapper for the Assessment bounded context:
/// HousingCondition, SocioEconomicSituation, SocialBenefit, WorkAndIncome,
/// EducationalStatus, HealthStatus, CommunitySupportNetwork, SocialHealthSummary.
abstract final class AssessmentMapper {
  // ── To JSON ─────────────────────────────────────────────────

  static Map<String, dynamic> housingConditionToJson(HousingCondition c) => {
    'type': c.type.name.toSnakeCaseUpper(),
    'wallMaterial': c.wallMaterial.name.toSnakeCaseUpper(),
    'numberOfRooms': c.numberOfRooms,
    'numberOfBedrooms': c.numberOfBedrooms,
    'numberOfBathrooms': c.numberOfBathrooms,
    'waterSupply': c.waterSupply.name.toSnakeCaseUpper(),
    'hasPipedWater': c.hasPipedWater,
    'electricityAccess': c.electricityAccess.name.toSnakeCaseUpper(),
    'sewageDisposal': c.sewageDisposal.name.toSnakeCaseUpper(),
    'wasteCollection': c.wasteCollection.name.toSnakeCaseUpper(),
    'accessibilityLevel': c.accessibilityLevel.name.toSnakeCaseUpper(),
    'isInGeographicRiskArea': c.isInGeographicRiskArea,
    'hasDifficultAccess': c.hasDifficultAccess,
    'isInSocialConflictArea': c.isInSocialConflictArea,
    'hasDiagnosticObservations': c.hasDiagnosticObservations,
  };

  static Map<String, dynamic> socioEconomicToJson(SocioEconomicSituation s) => {
    'totalFamilyIncome': s.totalFamilyIncome,
    'incomePerCapita': s.incomePerCapita,
    'receivesSocialBenefit': s.receivesSocialBenefit,
    'hasUnemployed': s.hasUnemployed,
    'mainSourceOfIncome': s.mainSourceOfIncome,
    'socialBenefits': s.socialBenefits.items.map(socialBenefitToJson).toList(),
  };

  static Map<String, dynamic> socialBenefitToJson(SocialBenefit b) => {
    'benefitName': b.benefitName,
    'benefitTypeId': b.benefitTypeId.value,
    'amount': b.amount,
    'beneficiaryId': b.beneficiaryId.value,
    if (b.birthCertificateNumber != null)
      'birthCertificateNumber': b.birthCertificateNumber,
    if (b.deceasedCpf != null) 'deceasedCpf': b.deceasedCpf!.value,
  };

  static Map<String, dynamic> workAndIncomeToJson(WorkAndIncome w) => {
    'hasRetiredMembers': w.hasRetiredMembers,
    'individualIncomes': w.individualIncomes
        .map(
          (i) => {
            'memberId': i.memberId.value,
            'occupationId': i.occupationId.value,
            'hasWorkCard': i.hasWorkCard,
            'monthlyAmount': i.monthlyAmount,
          },
        )
        .toList(),
    'socialBenefits': w.socialBenefits.map(socialBenefitToJson).toList(),
  };

  static Map<String, dynamic> educationalStatusToJson(EducationalStatus e) => {
    'memberProfiles': e.memberProfiles
        .map(
          (p) => {
            'memberId': p.memberId.value,
            'canReadWrite': p.canReadWrite,
            'attendsSchool': p.attendsSchool,
            'educationLevelId': p.educationLevelId.value,
          },
        )
        .toList(),
    'programOccurrences': e.programOccurrences
        .map(
          (o) => {
            'memberId': o.memberId.value,
            'date': o.date.toIso8601(),
            'effectId': o.effectId.value,
            'isSuspensionRequested': o.isSuspensionRequested,
          },
        )
        .toList(),
  };

  static Map<String, dynamic> healthStatusToJson(HealthStatus h) => {
    'deficiencies': h.deficiencies
        .map(
          (d) => {
            'memberId': d.memberId.value,
            'deficiencyTypeId': d.deficiencyTypeId.value,
            'needsConstantCare': d.needsConstantCare,
            'responsibleCaregiverName': d.responsibleCaregiverName,
          },
        )
        .toList(),
    'gestatingMembers': h.gestatingMembers
        .map(
          (g) => {
            'memberId': g.memberId.value,
            'monthsGestation': g.monthsGestation,
            'startedPrenatalCare': g.startedPrenatalCare,
          },
        )
        .toList(),
    'constantCareNeeds': h.constantCareNeeds.map((id) => id.value).toList(),
    'foodInsecurity': h.foodInsecurity,
  };

  static Map<String, dynamic> communitySupportToJson(
    CommunitySupportNetwork c,
  ) => {
    'hasRelativeSupport': c.hasRelativeSupport,
    'hasNeighborSupport': c.hasNeighborSupport,
    'familyConflicts': c.familyConflicts,
    'patientParticipatesInGroups': c.patientParticipatesInGroups,
    'familyParticipatesInGroups': c.familyParticipatesInGroups,
    'patientHasAccessToLeisure': c.patientHasAccessToLeisure,
    'facesDiscrimination': c.facesDiscrimination,
  };

  static Map<String, dynamic> socialHealthSummaryToJson(
    SocialHealthSummary s,
  ) => {
    'requiresConstantCare': s.requiresConstantCare,
    'hasMobilityImpairment': s.hasMobilityImpairment,
    'functionalDependencies': s.functionalDependencies,
    'hasRelevantDrugTherapy': s.hasRelevantDrugTherapy,
  };

  // ── From JSON ───────────────────────────────────────────────

  static Result<HousingCondition> housingConditionFromJson(
    Map<String, dynamic> j,
  ) {
    final ConditionType type;
    switch (enumFromJson(
      ConditionType.values,
      j['type'],
      'housingCondition.type',
    )) {
      case Success(:final value):
        type = value;
      case Failure(:final error):
        return Failure(error);
    }
    final WallMaterial wallMaterial;
    switch (enumFromJson(
      WallMaterial.values,
      j['wallMaterial'],
      'housingCondition.wallMaterial',
    )) {
      case Success(:final value):
        wallMaterial = value;
      case Failure(:final error):
        return Failure(error);
    }
    final WaterSupply waterSupply;
    switch (enumFromJson(
      WaterSupply.values,
      j['waterSupply'],
      'housingCondition.waterSupply',
    )) {
      case Success(:final value):
        waterSupply = value;
      case Failure(:final error):
        return Failure(error);
    }
    final ElectricityAccess electricityAccess;
    switch (enumFromJson(
      ElectricityAccess.values,
      j['electricityAccess'],
      'housingCondition.electricityAccess',
    )) {
      case Success(:final value):
        electricityAccess = value;
      case Failure(:final error):
        return Failure(error);
    }
    final SewageDisposal sewageDisposal;
    switch (enumFromJson(
      SewageDisposal.values,
      j['sewageDisposal'],
      'housingCondition.sewageDisposal',
    )) {
      case Success(:final value):
        sewageDisposal = value;
      case Failure(:final error):
        return Failure(error);
    }
    final WasteCollection wasteCollection;
    switch (enumFromJson(
      WasteCollection.values,
      j['wasteCollection'],
      'housingCondition.wasteCollection',
    )) {
      case Success(:final value):
        wasteCollection = value;
      case Failure(:final error):
        return Failure(error);
    }
    final AccessibilityLevel accessibilityLevel;
    switch (enumFromJson(
      AccessibilityLevel.values,
      j['accessibilityLevel'],
      'housingCondition.accessibilityLevel',
    )) {
      case Success(:final value):
        accessibilityLevel = value;
      case Failure(:final error):
        return Failure(error);
    }

    return HousingCondition.create(
      type: type,
      wallMaterial: wallMaterial,
      numberOfRooms: j['numberOfRooms'],
      numberOfBedrooms: j['numberOfBedrooms'],
      numberOfBathrooms: j['numberOfBathrooms'],
      waterSupply: waterSupply,
      hasPipedWater: j['hasPipedWater'],
      electricityAccess: electricityAccess,
      sewageDisposal: sewageDisposal,
      wasteCollection: wasteCollection,
      accessibilityLevel: accessibilityLevel,
      isInGeographicRiskArea: j['isInGeographicRiskArea'],
      hasDifficultAccess: j['hasDifficultAccess'],
      isInSocialConflictArea: j['isInSocialConflictArea'],
      hasDiagnosticObservations: j['hasDiagnosticObservations'],
    );
  }

  static Result<SocialBenefit> socialBenefitFromJson(Map<String, dynamic> j) {
    final LookupId benefitTypeId;
    switch (LookupId.create(j['benefitTypeId'] ?? defaultUuid)) {
      case Success(:final value):
        benefitTypeId = value;
      case Failure(:final error):
        return Failure('socialBenefit.benefitTypeId: $error');
    }

    final PersonId beneficiaryId;
    switch (PersonId.create(j['beneficiaryId'])) {
      case Success(:final value):
        beneficiaryId = value;
      case Failure(:final error):
        return Failure('socialBenefit.beneficiaryId: $error');
    }

    Cpf? deceasedCpf;
    if (j['deceasedCpf'] != null) {
      switch (Cpf.create(j['deceasedCpf'])) {
        case Success(:final value):
          deceasedCpf = value;
        case Failure(:final error):
          return Failure('socialBenefit.deceasedCpf: $error');
      }
    }

    return SocialBenefit.create(
      benefitName: j['benefitName'],
      benefitTypeId: benefitTypeId,
      amount: (j['amount'] as num).toDouble(),
      beneficiaryId: beneficiaryId,
      birthCertificateNumber: j['birthCertificateNumber'],
      deceasedCpf: deceasedCpf,
    );
  }

  static Result<SocioEconomicSituation> socioEconomicFromJson(
    Map<String, dynamic> j,
  ) {
    final List<SocialBenefit> benefits;
    switch (listFromJson(
      j['socialBenefits'],
      socialBenefitFromJson,
      field: 'socioEconomic.socialBenefits',
    )) {
      case Success(:final value):
        benefits = value;
      case Failure(:final error):
        return Failure(error);
    }

    final SocialBenefitsCollection collection;
    switch (SocialBenefitsCollection.create(benefits)) {
      case Success(:final value):
        collection = value;
      case Failure(:final error):
        return Failure('socioEconomic.socialBenefits: $error');
    }

    return SocioEconomicSituation.create(
      totalFamilyIncome: j['totalFamilyIncome'],
      incomePerCapita: j['incomePerCapita'],
      receivesSocialBenefit: j['receivesSocialBenefit'],
      hasUnemployed: j['hasUnemployed'],
      mainSourceOfIncome: j['mainSourceOfIncome'],
      socialBenefits: collection,
    );
  }

  static Result<WorkAndIncome> workAndIncomeFromJson(Map<String, dynamic> j) {
    final PatientId familyId;
    switch (idFromJsonOrDefault(PatientId.create, j['familyId'], defaultUuid)) {
      case Success(:final value):
        familyId = value;
      case Failure(:final error):
        return Failure('workAndIncome.familyId: $error');
    }

    final incomes = <WorkIncomeVO>[];
    for (final (i, item) in ((j['individualIncomes'] as List?) ?? []).indexed) {
      final m = item as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure(
            'workAndIncome.individualIncomes[$i].memberId: $error',
          );
      }

      final LookupId occupationId;
      switch (LookupId.create(m['occupationId'])) {
        case Success(:final value):
          occupationId = value;
        case Failure(:final error):
          return Failure(
            'workAndIncome.individualIncomes[$i].occupationId: $error',
          );
      }

      switch (WorkIncomeVO.create(
        memberId: memberId,
        occupationId: occupationId,
        hasWorkCard: m['hasWorkCard'],
        monthlyAmount: m['monthlyAmount'],
      )) {
        case Success(:final value):
          incomes.add(value);
        case Failure(:final error):
          return Failure('workAndIncome.individualIncomes[$i]: $error');
      }
    }

    final List<SocialBenefit> benefits;
    switch (listFromJson(
      j['socialBenefits'],
      socialBenefitFromJson,
      field: 'workAndIncome.socialBenefits',
    )) {
      case Success(:final value):
        benefits = value;
      case Failure(:final error):
        return Failure(error);
    }

    return Success(
      WorkAndIncome(
        familyId: familyId,
        individualIncomes: incomes,
        socialBenefits: benefits,
        hasRetiredMembers: j['hasRetiredMembers'],
      ),
    );
  }

  static Result<EducationalStatus> educationalStatusFromJson(
    Map<String, dynamic> j,
  ) {
    final PatientId familyId;
    switch (idFromJsonOrDefault(PatientId.create, j['familyId'], defaultUuid)) {
      case Success(:final value):
        familyId = value;
      case Failure(:final error):
        return Failure('educationalStatus.familyId: $error');
    }

    final profiles = <MemberEducationalProfile>[];
    for (final (i, p) in ((j['memberProfiles'] as List?) ?? []).indexed) {
      final m = p as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure(
            'educationalStatus.memberProfiles[$i].memberId: $error',
          );
      }

      final LookupId educationLevelId;
      switch (LookupId.create(m['educationLevelId'])) {
        case Success(:final value):
          educationLevelId = value;
        case Failure(:final error):
          return Failure(
            'educationalStatus.memberProfiles[$i].educationLevelId: $error',
          );
      }

      profiles.add(
        MemberEducationalProfile(
          memberId: memberId,
          canReadWrite: m['canReadWrite'],
          attendsSchool: m['attendsSchool'],
          educationLevelId: educationLevelId,
        ),
      );
    }

    final occurrences = <ProgramOccurrence>[];
    for (final (i, o) in ((j['programOccurrences'] as List?) ?? []).indexed) {
      final m = o as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure(
            'educationalStatus.programOccurrences[$i].memberId: $error',
          );
      }

      final TimeStamp date;
      switch (TimeStamp.fromIso(m['date'])) {
        case Success(:final value):
          date = value;
        case Failure(:final error):
          return Failure(
            'educationalStatus.programOccurrences[$i].date: $error',
          );
      }

      final LookupId effectId;
      switch (LookupId.create(m['effectId'])) {
        case Success(:final value):
          effectId = value;
        case Failure(:final error):
          return Failure(
            'educationalStatus.programOccurrences[$i].effectId: $error',
          );
      }

      occurrences.add(
        ProgramOccurrence(
          memberId: memberId,
          date: date,
          effectId: effectId,
          isSuspensionRequested: m['isSuspensionRequested'],
        ),
      );
    }

    return Success(
      EducationalStatus(
        familyId: familyId,
        memberProfiles: profiles,
        programOccurrences: occurrences,
      ),
    );
  }

  static Result<HealthStatus> healthStatusFromJson(Map<String, dynamic> j) {
    final PatientId familyId;
    switch (idFromJsonOrDefault(PatientId.create, j['familyId'], defaultUuid)) {
      case Success(:final value):
        familyId = value;
      case Failure(:final error):
        return Failure('healthStatus.familyId: $error');
    }

    final deficiencies = <MemberDeficiency>[];
    for (final (i, d) in ((j['deficiencies'] as List?) ?? []).indexed) {
      final m = d as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure('healthStatus.deficiencies[$i].memberId: $error');
      }

      final LookupId deficiencyTypeId;
      switch (LookupId.create(m['deficiencyTypeId'])) {
        case Success(:final value):
          deficiencyTypeId = value;
        case Failure(:final error):
          return Failure(
            'healthStatus.deficiencies[$i].deficiencyTypeId: $error',
          );
      }

      deficiencies.add(
        MemberDeficiency(
          memberId: memberId,
          deficiencyTypeId: deficiencyTypeId,
          needsConstantCare: m['needsConstantCare'],
          responsibleCaregiverName: m['responsibleCaregiverName'],
        ),
      );
    }

    final gestating = <PregnantMember>[];
    for (final (i, g) in ((j['gestatingMembers'] as List?) ?? []).indexed) {
      final m = g as Map<String, dynamic>;

      final PersonId memberId;
      switch (PersonId.create(m['memberId'])) {
        case Success(:final value):
          memberId = value;
        case Failure(:final error):
          return Failure('healthStatus.gestatingMembers[$i].memberId: $error');
      }

      gestating.add(
        PregnantMember(
          memberId: memberId,
          monthsGestation: m['monthsGestation'],
          startedPrenatalCare: m['startedPrenatalCare'],
        ),
      );
    }

    final careNeeds = <PersonId>[];
    for (final (i, id) in ((j['constantCareNeeds'] as List?) ?? []).indexed) {
      switch (PersonId.create(id)) {
        case Success(:final value):
          careNeeds.add(value);
        case Failure(:final error):
          return Failure('healthStatus.constantCareNeeds[$i]: $error');
      }
    }

    return Success(
      HealthStatus(
        familyId: familyId,
        deficiencies: deficiencies,
        gestatingMembers: gestating,
        constantCareNeeds: careNeeds,
        foodInsecurity: j['foodInsecurity'],
      ),
    );
  }

  static Result<CommunitySupportNetwork> communitySupportFromJson(
    Map<String, dynamic> j,
  ) {
    return CommunitySupportNetwork.create(
      hasRelativeSupport: j['hasRelativeSupport'],
      hasNeighborSupport: j['hasNeighborSupport'],
      familyConflicts: j['familyConflicts'],
      patientParticipatesInGroups: j['patientParticipatesInGroups'],
      familyParticipatesInGroups: j['familyParticipatesInGroups'],
      patientHasAccessToLeisure: j['patientHasAccessToLeisure'],
      facesDiscrimination: j['facesDiscrimination'],
    );
  }

  static Result<SocialHealthSummary> socialHealthSummaryFromJson(
    Map<String, dynamic> j,
  ) {
    return SocialHealthSummary.create(
      requiresConstantCare: j['requiresConstantCare'],
      hasMobilityImpairment: j['hasMobilityImpairment'],
      functionalDependencies: List<String>.from(
        j['functionalDependencies'] ?? [],
      ),
      hasRelevantDrugTherapy: j['hasRelevantDrugTherapy'],
    );
  }
}
