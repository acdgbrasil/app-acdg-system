import 'package:shared/shared.dart';

/// Mapper responsible for converting [Patient] and related domain objects
/// to and from JSON Map representations. Used for API communication and local persistence.
class PatientMapper {
  /// Converts a [Patient] aggregate to a JSON Map.
  static Map<String, dynamic> toJson(Patient p) {
    return {
      'patientId': p.id.value,
      'personId': p.personId.value,
      'version': p.version,
      'prRelationshipId': p.prRelationshipId.value,
      'personalData': p.personalData == null
          ? null
          : personalDataToJson(p.personalData!),
      'civilDocuments': p.civilDocuments == null
          ? null
          : civilDocumentsToJson(p.civilDocuments!),
      'address': p.address == null ? null : addressToJson(p.address!),
      'familyMembers': p.familyMembers
          .map((m) => familyMemberToJson(m))
          .toList(),
      'initialDiagnoses': p.diagnoses.map((d) => diagnosisToJson(d)).toList(),
      'socialIdentity': p.socialIdentity == null
          ? null
          : socialIdentityToJson(p.socialIdentity!),
      'housingCondition': p.housingCondition == null
          ? null
          : housingConditionToJson(p.housingCondition!),
      'socioeconomicSituation': p.socioeconomicSituation == null
          ? null
          : socioEconomicToJson(p.socioeconomicSituation!),
      'workAndIncome': p.workAndIncome == null
          ? null
          : workAndIncomeToJson(p.workAndIncome!),
      'educationalStatus': p.educationalStatus == null
          ? null
          : educationalStatusToJson(p.educationalStatus!),
      'healthStatus': p.healthStatus == null
          ? null
          : healthStatusToJson(p.healthStatus!),
      'communitySupportNetwork': p.communitySupportNetwork == null
          ? null
          : communitySupportToJson(p.communitySupportNetwork!),
      'socialHealthSummary': p.socialHealthSummary == null
          ? null
          : socialHealthSummaryToJson(p.socialHealthSummary!),
      'appointments': p.appointments.map((a) => appointmentToJson(a)).toList(),
      'intakeInfo': p.intakeInfo == null
          ? null
          : intakeInfoToJson(p.intakeInfo!),
      'placementHistory': p.placementHistory == null
          ? null
          : placementHistoryToJson(p.placementHistory!),
      'violationReports': p.violationReports
          .map((r) => violationReportToJson(r))
          .toList(),
      'referrals': p.referrals.map((r) => referralToJson(r)).toList(),
    };
  }

  // --- Sub-module Mappers (To JSON) ---

  static Map<String, dynamic> personalDataToJson(PersonalData d) {
    return {
      'firstName': d.firstName,
      'lastName': d.lastName,
      'motherName': d.motherName,
      'nationality': d.nationality,
      'sex': d.sex.name, // Keep original casing for Sex (masculino/feminino)
      'socialName': d.socialName,
      'birthDate': d.birthDate.toIso8601(),
      'phone': d.phone,
    };
  }

  static Map<String, dynamic> civilDocumentsToJson(CivilDocuments d) {
    return {
      'cpf': d.cpf?.value,
      'nis': d.nis?.value,
      'rgDocument': d.rgDocument == null
          ? null
          : {
              'number': d.rgDocument!.number,
              'issuingState': d.rgDocument!.issuingState,
              'issuingAgency': d.rgDocument!.issuingAgency,
              'issueDate': d.rgDocument!.issueDate.toIso8601(),
            },
    };
  }

  static Map<String, dynamic> addressToJson(Address a) {
    return {
      'cep': a.cep?.value,
      'state': a.state,
      'city': a.city,
      'street': a.street,
      'neighborhood': a.neighborhood,
      'number': a.number,
      'complement': a.complement,
      'residenceLocation': a.residenceLocation == ResidenceLocation.urbano
          ? 'URBANO'
          : 'RURAL',
      'isShelter': a.isShelter,
    };
  }

  static Map<String, dynamic> familyMemberToJson(FamilyMember m) {
    return {
      'personId': m.personId.value,
      'relationshipId': m.relationshipId.value,
      'residesWithPatient': m.residesWithPatient,
      'isPrimaryCaregiver': m.isPrimaryCaregiver,
      'hasDisability': m.hasDisability,
      'requiredDocuments': m.requiredDocuments.map((d) => d.value).toList(),
      'birthDate': m.birthDate.toIso8601(),
    };
  }

  static Map<String, dynamic> diagnosisToJson(Diagnosis d) {
    return {
      'icdCode': d.id.value,
      'date': d.date.toIso8601(),
      'description': d.description,
    };
  }

  static Map<String, dynamic> socialIdentityToJson(SocialIdentity i) {
    return {'typeId': i.typeId.value, 'description': i.otherDescription};
  }

  static Map<String, dynamic> housingConditionToJson(HousingCondition c) {
    return {
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
  }

  static Map<String, dynamic> socioEconomicToJson(SocioEconomicSituation s) {
    return {
      'totalFamilyIncome': s.totalFamilyIncome,
      'incomePerCapita': s.incomePerCapita,
      'receivesSocialBenefit': s.receivesSocialBenefit,
      'hasUnemployed': s.hasUnemployed,
      'mainSourceOfIncome': s.mainSourceOfIncome,
      'socialBenefits': s.socialBenefits.items
          .map((b) => socialBenefitToJson(b))
          .toList(),
    };
  }

  static Map<String, dynamic> socialBenefitToJson(SocialBenefit b) {
    return {
      'benefitName': b.benefitName,
      'amount': b.amount,
      'beneficiaryId': b.beneficiaryId.value,
    };
  }

  static Map<String, dynamic> workAndIncomeToJson(WorkAndIncome w) {
    return {
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
      'socialBenefits': w.socialBenefits
          .map((b) => socialBenefitToJson(b))
          .toList(),
    };
  }

  static Map<String, dynamic> educationalStatusToJson(EducationalStatus e) {
    return {
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
  }

  static Map<String, dynamic> healthStatusToJson(HealthStatus h) {
    return {
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
  }

  static Map<String, dynamic> communitySupportToJson(
    CommunitySupportNetwork c,
  ) {
    return {
      'hasRelativeSupport': c.hasRelativeSupport,
      'hasNeighborSupport': c.hasNeighborSupport,
      'familyConflicts': c.familyConflicts,
      'patientParticipatesInGroups': c.patientParticipatesInGroups,
      'familyParticipatesInGroups': c.familyParticipatesInGroups,
      'patientHasAccessToLeisure': c.patientHasAccessToLeisure,
      'facesDiscrimination': c.facesDiscrimination,
    };
  }

  static Map<String, dynamic> socialHealthSummaryToJson(SocialHealthSummary s) {
    return {
      'requiresConstantCare': s.requiresConstantCare,
      'hasMobilityImpairment': s.hasMobilityImpairment,
      'functionalDependencies': s.functionalDependencies,
      'hasRelevantDrugTherapy': s.hasRelevantDrugTherapy,
    };
  }

  static Map<String, dynamic> appointmentToJson(SocialCareAppointment a) {
    return {
      'professionalId': a.professionalInChargeId.value,
      'summary': a.summary,
      'actionPlan': a.actionPlan,
      'date': a.date.toIso8601(),
      'type': a.type.name.toSnakeCaseUpper(),
    };
  }

  static Map<String, dynamic> intakeInfoToJson(IngressInfo i) {
    return {
      'ingressTypeId': i.ingressTypeId.value,
      'originName': i.originName,
      'originContact': i.originContact,
      'serviceReason': i.serviceReason,
      'linkedSocialPrograms': i.linkedSocialPrograms
          .map(
            (p) => {
              'programId': p.programId.value,
              'observation': p.observation,
            },
          )
          .toList(),
    };
  }

  static Map<String, dynamic> placementHistoryToJson(PlacementHistory p) {
    return {
      'registries': p.individualPlacements
          .map(
            (r) => {
              'memberId': r.memberId.value,
              'startDate': r.startDate.toIso8601(),
              'endDate': r.endDate?.toIso8601(),
              'reason': r.reason,
            },
          )
          .toList(),
      'collectiveSituations': {
        'homeLossReport': p.collectiveSituations.homeLossReport,
        'thirdPartyGuardReport': p.collectiveSituations.thirdPartyGuardReport,
      },
      'separationChecklist': {
        'adultInPrison': p.separationChecklist.adultInPrison,
        'adolescentInInternment': p.separationChecklist.adolescentInInternment,
      },
    };
  }

  static Map<String, dynamic> violationReportToJson(RightsViolationReport r) {
    return {
      'victimId': r.victimId.value,
      'violationType': r.violationType.name.toSnakeCaseUpper(),
      'descriptionOfFact': r.descriptionOfFact,
      'reportDate': r.reportDate.toIso8601(),
      'incidentDate': r.incidentDate?.toIso8601(),
      'actionsTaken': r.actionsTaken,
    };
  }

  static Map<String, dynamic> referralToJson(Referral r) {
    return {
      'referredPersonId': r.referredPersonId.value,
      'destinationService': r.destinationService.name.toSnakeCaseUpper(),
      'reason': r.reason,
      'date': r.date.toIso8601(),
      'professionalId': r.requestingProfessionalId.value,
    };
  }

  // --- From JSON Mappers (Hidration) ---

  /// Default prRelationshipId used when the server response omits it.
  static const _defaultPrRelationshipId =
      '00000000-0000-0000-0000-000000000000';

  static Patient fromJson(Map<String, dynamic> json) {
    return Patient.reconstitute(
      id: PatientId.create(json['patientId'] as String).valueOrNull!,
      version: json['version'] as int? ?? 1,
      personId: PersonId.create(json['personId'] as String).valueOrNull!,
      prRelationshipId: LookupId.create(
        json['prRelationshipId'] as String? ?? _defaultPrRelationshipId,
      ).valueOrNull!,
      personalData: json['personalData'] == null
          ? null
          : personalDataFromJson(json['personalData']),
      civilDocuments: json['civilDocuments'] == null
          ? null
          : civilDocumentsFromJson(json['civilDocuments']),
      address: json['address'] == null
          ? null
          : addressFromJson(json['address']),
      familyMembers: (json['familyMembers'] as List? ?? [])
          .map((m) => familyMemberFromJson(m))
          .toList(),
      diagnoses: (json['initialDiagnoses'] as List? ??
              json['diagnoses'] as List? ??
              [])
          .map((d) => diagnosisFromJson(d))
          .toList(),
      socialIdentity: json['socialIdentity'] == null
          ? null
          : socialIdentityFromJson(json['socialIdentity']),
      housingCondition: json['housingCondition'] == null
          ? null
          : housingConditionFromJson(json['housingCondition']),
      socioeconomicSituation: json['socioeconomicSituation'] == null
          ? null
          : socioEconomicFromJson(json['socioeconomicSituation']),
      workAndIncome: json['workAndIncome'] == null
          ? null
          : workAndIncomeFromJson(json['workAndIncome']),
      educationalStatus: json['educationalStatus'] == null
          ? null
          : educationalStatusFromJson(json['educationalStatus']),
      healthStatus: json['healthStatus'] == null
          ? null
          : healthStatusFromJson(json['healthStatus']),
      communitySupportNetwork: json['communitySupportNetwork'] == null
          ? null
          : communitySupportFromJson(json['communitySupportNetwork']),
      socialHealthSummary: json['socialHealthSummary'] == null
          ? null
          : socialHealthSummaryFromJson(json['socialHealthSummary']),
      appointments: (json['appointments'] as List? ?? [])
          .map((a) => appointmentFromJson(a))
          .toList(),
      intakeInfo: json['intakeInfo'] == null
          ? null
          : intakeInfoFromJson(json['intakeInfo']),
      placementHistory: json['placementHistory'] == null
          ? null
          : placementHistoryFromJson(json['placementHistory']),
      violationReports: (json['violationReports'] as List? ?? [])
          .map((r) => violationReportFromJson(r))
          .toList(),
      referrals: (json['referrals'] as List? ?? [])
          .map((r) => referralFromJson(r))
          .toList(),
    );
  }

  static PersonalData personalDataFromJson(Map<String, dynamic> j) {
    return PersonalData.create(
      firstName: j['firstName'],
      lastName: j['lastName'],
      motherName: j['motherName'],
      nationality: j['nationality'],
      sex: Sex.values.firstWhere((v) => v.name == j['sex']),
      socialName: j['socialName'],
      birthDate: TimeStamp.fromIso(j['birthDate']).valueOrNull!,
      phone: j['phone'],
    ).valueOrNull!;
  }

  static CivilDocuments civilDocumentsFromJson(Map<String, dynamic> j) {
    return CivilDocuments.create(
      cpf: j['cpf'] != null ? Cpf.create(j['cpf']).valueOrNull : null,
      nis: j['nis'] != null ? Nis.create(j['nis']).valueOrNull : null,
      rgDocument: j['rgDocument'] == null
          ? null
          : RgDocument.create(
              number: j['rgDocument']['number'],
              issuingState: j['rgDocument']['issuingState'],
              issuingAgency: j['rgDocument']['issuingAgency'],
              issueDate: TimeStamp.fromIso(
                j['rgDocument']['issueDate'],
              ).valueOrNull!,
            ).valueOrNull,
    ).valueOrNull!;
  }

  static Address addressFromJson(Map<String, dynamic> j) {
    return Address.create(
      cep: j['cep'] != null ? Cep.create(j['cep']).valueOrNull : null,
      state: j['state'],
      city: j['city'],
      street: j['street'],
      neighborhood: j['neighborhood'],
      number: j['number'],
      complement: j['complement'],
      residenceLocation: j['residenceLocation'] == 'URBANO'
          ? ResidenceLocation.urbano
          : ResidenceLocation.rural,
      isShelter: j['isShelter'],
    ).valueOrNull!;
  }

  static FamilyMember familyMemberFromJson(Map<String, dynamic> j) {
    return FamilyMember.reconstitute(
      personId: PersonId.create(j['personId']).valueOrNull!,
      relationshipId: LookupId.create(j['relationshipId']).valueOrNull!,
      residesWithPatient: j['residesWithPatient'],
      isPrimaryCaregiver: j['isPrimaryCaregiver'],
      hasDisability: j['hasDisability'] ?? false,
      requiredDocuments: (j['requiredDocuments'] as List? ?? [])
          .map((d) => RequiredDocument.values.firstWhere((v) => v.value == d))
          .toList(),
      birthDate: TimeStamp.fromIso(j['birthDate']).valueOrNull!,
    );
  }

  static Diagnosis diagnosisFromJson(Map<String, dynamic> j) {
    return Diagnosis.create(
      id: IcdCode.create(j['icdCode']).valueOrNull!,
      date: TimeStamp.fromIso(j['date']).valueOrNull!,
      description: j['description'],
    ).valueOrNull!;
  }

  static SocialIdentity socialIdentityFromJson(Map<String, dynamic> j) {
    return SocialIdentity.create(
      typeId: LookupId.create(j['typeId']).valueOrNull!,
      otherDescription: j['description'],
    ).valueOrNull!;
  }

  static HousingCondition housingConditionFromJson(Map<String, dynamic> j) {
    return HousingCondition.create(
      type: ConditionType.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['type'],
      ),
      wallMaterial: WallMaterial.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['wallMaterial'],
      ),
      numberOfRooms: j['numberOfRooms'],
      numberOfBedrooms: j['numberOfBedrooms'],
      numberOfBathrooms: j['numberOfBathrooms'],
      waterSupply: WaterSupply.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['waterSupply'],
      ),
      hasPipedWater: j['hasPipedWater'],
      electricityAccess: ElectricityAccess.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['electricityAccess'],
      ),
      sewageDisposal: SewageDisposal.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['sewageDisposal'],
      ),
      wasteCollection: WasteCollection.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['wasteCollection'],
      ),
      accessibilityLevel: AccessibilityLevel.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['accessibilityLevel'],
      ),
      isInGeographicRiskArea: j['isInGeographicRiskArea'],
      hasDifficultAccess: j['hasDifficultAccess'],
      isInSocialConflictArea: j['isInSocialConflictArea'],
      hasDiagnosticObservations: j['hasDiagnosticObservations'],
    ).valueOrNull!;
  }

  static SocioEconomicSituation socioEconomicFromJson(Map<String, dynamic> j) {
    final benefits = (j['socialBenefits'] as List? ?? [])
        .map((b) => socialBenefitFromJson(b))
        .toList();
    return SocioEconomicSituation.create(
      totalFamilyIncome: j['totalFamilyIncome'],
      incomePerCapita: j['incomePerCapita'],
      receivesSocialBenefit: j['receivesSocialBenefit'],
      hasUnemployed: j['hasUnemployed'],
      mainSourceOfIncome: j['mainSourceOfIncome'],
      socialBenefits: SocialBenefitsCollection.create(benefits).valueOrNull!,
    ).valueOrNull!;
  }

  static SocialBenefit socialBenefitFromJson(Map<String, dynamic> j) {
    return SocialBenefit.create(
      benefitName: j['benefitName'],
      amount: j['amount'],
      beneficiaryId: PersonId.create(j['beneficiaryId']).valueOrNull!,
    ).valueOrNull!;
  }

  static WorkAndIncome workAndIncomeFromJson(Map<String, dynamic> j) {
    return WorkAndIncome(
      familyId:
          PatientId.create(j['familyId'] ?? '').valueOrNull ??
          PatientId.create('00000000-0000-0000-0000-000000000000').valueOrNull!,
      individualIncomes: (j['individualIncomes'] as List? ?? [])
          .map(
            (i) => WorkIncomeVO.create(
              memberId: PersonId.create(i['memberId']).valueOrNull!,
              occupationId: LookupId.create(i['occupationId']).valueOrNull!,
              hasWorkCard: i['hasWorkCard'],
              monthlyAmount: i['monthlyAmount'],
            ).valueOrNull!,
          )
          .toList(),
      socialBenefits: (j['socialBenefits'] as List? ?? [])
          .map((b) => socialBenefitFromJson(b))
          .toList(),
      hasRetiredMembers: j['hasRetiredMembers'],
    );
  }

  static EducationalStatus educationalStatusFromJson(Map<String, dynamic> j) {
    return EducationalStatus(
      familyId:
          PatientId.create(j['familyId'] ?? '').valueOrNull ??
          PatientId.create('00000000-0000-0000-0000-000000000000').valueOrNull!,
      memberProfiles: (j['memberProfiles'] as List? ?? [])
          .map(
            (p) => MemberEducationalProfile(
              memberId: PersonId.create(p['memberId']).valueOrNull!,
              canReadWrite: p['canReadWrite'],
              attendsSchool: p['attendsSchool'],
              educationLevelId: LookupId.create(
                p['educationLevelId'],
              ).valueOrNull!,
            ),
          )
          .toList(),
      programOccurrences: (j['programOccurrences'] as List? ?? [])
          .map(
            (o) => ProgramOccurrence(
              memberId: PersonId.create(o['memberId']).valueOrNull!,
              date: TimeStamp.fromIso(o['date']).valueOrNull!,
              effectId: LookupId.create(o['effectId']).valueOrNull!,
              isSuspensionRequested: o['isSuspensionRequested'],
            ),
          )
          .toList(),
    );
  }

  static HealthStatus healthStatusFromJson(Map<String, dynamic> j) {
    return HealthStatus(
      familyId:
          PatientId.create(j['familyId'] ?? '').valueOrNull ??
          PatientId.create('00000000-0000-0000-0000-000000000000').valueOrNull!,
      deficiencies: (j['deficiencies'] as List? ?? [])
          .map(
            (d) => MemberDeficiency(
              memberId: PersonId.create(d['memberId']).valueOrNull!,
              deficiencyTypeId: LookupId.create(
                d['deficiencyTypeId'],
              ).valueOrNull!,
              needsConstantCare: d['needsConstantCare'],
              responsibleCaregiverName: d['responsibleCaregiverName'],
            ),
          )
          .toList(),
      gestatingMembers: (j['gestatingMembers'] as List? ?? [])
          .map(
            (g) => PregnantMember(
              memberId: PersonId.create(g['memberId']).valueOrNull!,
              monthsGestation: g['monthsGestation'],
              startedPrenatalCare: g['startedPrenatalCare'],
            ),
          )
          .toList(),
      constantCareNeeds: (j['constantCareNeeds'] as List? ?? [])
          .map((id) => PersonId.create(id).valueOrNull!)
          .toList(),
      foodInsecurity: j['foodInsecurity'],
    );
  }

  static CommunitySupportNetwork communitySupportFromJson(
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
    ).valueOrNull!;
  }

  static SocialHealthSummary socialHealthSummaryFromJson(
    Map<String, dynamic> j,
  ) {
    return SocialHealthSummary.create(
      requiresConstantCare: j['requiresConstantCare'],
      hasMobilityImpairment: j['hasMobilityImpairment'],
      functionalDependencies: List<String>.from(
        j['functionalDependencies'] ?? [],
      ),
      hasRelevantDrugTherapy: j['hasRelevantDrugTherapy'],
    ).valueOrNull!;
  }

  static SocialCareAppointment appointmentFromJson(Map<String, dynamic> j) {
    return SocialCareAppointment.create(
      id:
          AppointmentId.create(j['id'] ?? '').valueOrNull ??
          AppointmentId.create(
            '00000000-0000-0000-0000-000000000000',
          ).valueOrNull!,
      date: TimeStamp.fromIso(j['date']).valueOrNull!,
      professionalInChargeId: ProfessionalId.create(
        j['professionalId'],
      ).valueOrNull!,
      type: AppointmentType.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['type'],
      ),
      summary: j['summary'],
      actionPlan: j['actionPlan'],
    ).valueOrNull!;
  }

  static IngressInfo intakeInfoFromJson(Map<String, dynamic> j) {
    return IngressInfo.create(
      ingressTypeId: LookupId.create(j['ingressTypeId']).valueOrNull!,
      originName: j['originName'],
      originContact: j['originContact'],
      serviceReason: j['serviceReason'],
      linkedSocialPrograms: (j['linkedSocialPrograms'] as List? ?? [])
          .map(
            (p) => ProgramLink(
              programId: LookupId.create(p['programId']).valueOrNull!,
              observation: p['observation'],
            ),
          )
          .toList(),
    ).valueOrNull!;
  }

  static PlacementHistory placementHistoryFromJson(Map<String, dynamic> j) {
    return PlacementHistory(
      familyId:
          PatientId.create(j['familyId'] ?? '').valueOrNull ??
          PatientId.create('00000000-0000-0000-0000-000000000000').valueOrNull!,
      individualPlacements: (j['registries'] as List? ?? [])
          .map(
            (r) => PlacementRegistry.create(
              memberId: PersonId.create(r['memberId']).valueOrNull!,
              startDate: TimeStamp.fromIso(r['startDate']).valueOrNull!,
              endDate: r['endDate'] != null
                  ? TimeStamp.fromIso(r['endDate']).valueOrNull
                  : null,
              reason: r['reason'],
            ).valueOrNull!,
          )
          .toList(),
      collectiveSituations: CollectiveSituations(
        homeLossReport: j['collectiveSituations']['homeLossReport'],
        thirdPartyGuardReport:
            j['collectiveSituations']['thirdPartyGuardReport'],
      ),
      separationChecklist: SeparationChecklist(
        adultInPrison: j['separationChecklist']['adultInPrison'],
        adolescentInInternment:
            j['separationChecklist']['adolescentInInternment'],
      ),
    );
  }

  static RightsViolationReport violationReportFromJson(Map<String, dynamic> j) {
    return RightsViolationReport.create(
      id:
          ViolationReportId.create(j['id'] ?? '').valueOrNull ??
          ViolationReportId.create(
            '00000000-0000-0000-0000-000000000000',
          ).valueOrNull!,
      reportDate: TimeStamp.fromIso(j['reportDate']).valueOrNull!,
      victimId: PersonId.create(j['victimId']).valueOrNull!,
      violationType: ViolationType.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['violationType'],
      ),
      descriptionOfFact: j['descriptionOfFact'],
      incidentDate: j['incidentDate'] != null
          ? TimeStamp.fromIso(j['incidentDate']).valueOrNull
          : null,
      actionsTaken: j['actionsTaken'],
    ).valueOrNull!;
  }

  static Referral referralFromJson(Map<String, dynamic> j) {
    return Referral.create(
      id:
          ReferralId.create(j['id'] ?? '').valueOrNull ??
          ReferralId.create(
            '00000000-0000-0000-0000-000000000000',
          ).valueOrNull!,
      date: TimeStamp.fromIso(j['date']).valueOrNull!,
      requestingProfessionalId: ProfessionalId.create(
        j['professionalId'],
      ).valueOrNull!,
      referredPersonId: PersonId.create(j['referredPersonId']).valueOrNull!,
      destinationService: DestinationService.values.firstWhere(
        (v) => v.name.toSnakeCaseUpper() == j['destinationService'],
      ),
      reason: j['reason'],
    ).valueOrNull!;
  }
}
