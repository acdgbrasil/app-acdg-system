// Wave 0 (RED) — tests for value-equality across all Response DTOs.
//
// These tests currently FAIL because the DTOs do not mix in Equatable yet
// (LookupItemResponse is the only response that already does — tested in
// A03 round-trip suite; kept here as a sanity check).
//
// Wave 1 implementer will add `with Equatable` + `props` to each class,
// turning this entire file GREEN.

import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Response DTOs — value equality (Wave 0 RED)', () {
    // ------------------------------------------------------------------ //
    // analytics/                                                          //
    // ------------------------------------------------------------------ //
    test('AxisMetadataResponse equals by value', () {
      AxisMetadataResponse build() =>
          AxisMetadataResponse(name: 'housing');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ComputedAnalyticsResponse equals by value', () {
      ComputedAnalyticsResponse build() => ComputedAnalyticsResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('HousingAnalyticsResponse equals by value', () {
      HousingAnalyticsResponse build() => HousingAnalyticsResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('FinancialIndicatorsResponse equals by value', () {
      FinancialIndicatorsResponse build() =>
          FinancialIndicatorsResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('AgeProfileResponse equals by value', () {
      AgeProfileResponse build() => AgeProfileResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('EducationalVulnerabilityResponse equals by value', () {
      EducationalVulnerabilityResponse build() =>
          EducationalVulnerabilityResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IndicatorResponse equals by value', () {
      IndicatorResponse build() =>
          IndicatorResponse(axis: 'age', rows: []);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IndicatorRowResponse equals by value', () {
      IndicatorRowResponse build() =>
          IndicatorRowResponse(dimensions: {'k': 'v'}, count: 42);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IndicatorMetaResponse equals by value', () {
      IndicatorMetaResponse build() => IndicatorMetaResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // assessment/                                                         //
    // ------------------------------------------------------------------ //
    test('CommunitySupportNetworkResponse equals by value', () {
      CommunitySupportNetworkResponse build() =>
          CommunitySupportNetworkResponse(
            hasRelativeSupport: true,
            hasNeighborSupport: false,
            familyConflicts: 'none',
            patientParticipatesInGroups: false,
            familyParticipatesInGroups: true,
            patientHasAccessToLeisure: true,
            facesDiscrimination: false,
          );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('EducationalStatusResponse equals by value', () {
      EducationalStatusResponse build() => EducationalStatusResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('EducationalProfileResponse equals by value', () {
      EducationalProfileResponse build() => EducationalProfileResponse(
        memberId: 'm1',
        canReadWrite: true,
        attendsSchool: true,
        educationLevelId: 'lvl-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ProgramOccurrenceResponse equals by value', () {
      ProgramOccurrenceResponse build() => ProgramOccurrenceResponse(
        memberId: 'm1',
        date: '2026-01-01',
        effectId: 'eff-1',
        isSuspensionRequested: false,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('HealthStatusResponse equals by value', () {
      HealthStatusResponse build() =>
          HealthStatusResponse(foodInsecurity: true);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('MemberDeficiencyResponse equals by value', () {
      MemberDeficiencyResponse build() => MemberDeficiencyResponse(
        memberId: 'm1',
        deficiencyTypeId: 'def-1',
        needsConstantCare: false,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PregnantMemberResponse equals by value', () {
      PregnantMemberResponse build() => PregnantMemberResponse(
        memberId: 'm1',
        monthsGestation: 3,
        startedPrenatalCare: true,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('HousingConditionResponse equals by value', () {
      HousingConditionResponse build() => HousingConditionResponse(
        type: 'owned',
        wallMaterial: 'brick',
        numberOfRooms: 4,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: 'public',
        hasPipedWater: true,
        electricityAccess: 'public',
        sewageDisposal: 'public',
        wasteCollection: 'public',
        accessibilityLevel: 'full',
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocialBenefitResponse equals by value', () {
      SocialBenefitResponse build() => SocialBenefitResponse(
        benefitName: 'BPC',
        amount: 1412.0,
        beneficiaryId: 'mem-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocialHealthSummaryResponse equals by value', () {
      SocialHealthSummaryResponse build() =>
          SocialHealthSummaryResponse(
            requiresConstantCare: true,
            hasMobilityImpairment: false,
            hasRelevantDrugTherapy: false,
          );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocioEconomicResponse equals by value', () {
      SocioEconomicResponse build() => SocioEconomicResponse(
        totalFamilyIncome: 1000.0,
        incomePerCapita: 250.0,
        receivesSocialBenefit: true,
        hasUnemployed: false,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('WorkAndIncomeResponse equals by value', () {
      WorkAndIncomeResponse build() =>
          WorkAndIncomeResponse(hasRetiredMembers: false);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('WorkIncomeResponse equals by value', () {
      WorkIncomeResponse build() => WorkIncomeResponse(
        memberId: 'm1',
        occupationId: 'occ-1',
        hasWorkCard: true,
        monthlyAmount: 2000.0,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // audit/                                                              //
    // ------------------------------------------------------------------ //
    test('AuditTrailEntryResponse equals by value', () {
      AuditTrailEntryResponse build() => AuditTrailEntryResponse(
        id: 'ev-1',
        aggregateId: 'agg-1',
        eventType: 'PatientRegistered',
        occurredAt: '2026-04-17T10:00:00Z',
        recordedAt: '2026-04-17T10:00:01Z',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // auth/                                                               //
    // ------------------------------------------------------------------ //
    test('MeResponse equals by value', () {
      MeResponse build() => MeResponse(
        userId: 'u-1',
        email: 'user@example.com',
        fullName: 'Full Name',
        roles: ['social_worker'],
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // care/                                                               //
    // ------------------------------------------------------------------ //
    test('AppointmentResponse equals by value', () {
      AppointmentResponse build() => AppointmentResponse(
        id: 'ap-1',
        date: '2026-01-01',
        professionalId: 'prof-1',
        type: 'consultation',
        summary: 'summary',
        actionPlan: 'action-plan',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IngressInfoResponse equals by value', () {
      IngressInfoResponse build() => IngressInfoResponse(
        ingressTypeId: 'it-1',
        serviceReason: 'reason',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ProgramLinkResponse equals by value', () {
      ProgramLinkResponse build() =>
          ProgramLinkResponse(programId: 'prog-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // governance/                                                         //
    // ------------------------------------------------------------------ //
    test('LookupItemResponse equals by value (already Equatable via A03)', () {
      LookupItemResponse build() => LookupItemResponse(
        id: 'li-1',
        codigo: 'CODE',
        descricao: 'Descricao',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('LookupRequestResponse equals by value', () {
      LookupRequestResponse build() => LookupRequestResponse(
        id: 'lr-1',
        tableName: 'pr_relationships',
        codigo: 'CODE',
        descricao: 'Descricao',
        justificativa: 'why',
        status: 'pending',
        createdAt: '2026-01-01T00:00:00Z',
        requestedBy: 'user-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('LookupsBatchResponse equals by value', () {
      LookupsBatchResponse build() => LookupsBatchResponse(tables: {});
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // people/                                                             //
    // ------------------------------------------------------------------ //
    test('PersonResponse equals by value', () {
      PersonResponse build() =>
          PersonResponse(id: 'p-1', fullName: 'Joao');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PersonRoleResponse equals by value', () {
      PersonRoleResponse build() => PersonRoleResponse(
        id: 'pr-1',
        personId: 'p-1',
        system: 'social_care',
        role: 'owner',
        active: true,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // protection/                                                         //
    // ------------------------------------------------------------------ //
    test('PlacementHistoryResponse equals by value', () {
      PlacementHistoryResponse build() => PlacementHistoryResponse();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PlacementRegistryResponse equals by value', () {
      PlacementRegistryResponse build() => PlacementRegistryResponse(
        id: 'pr-1',
        memberId: 'm-1',
        startDate: '2026-01-01',
        reason: 'reason',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ReferralResponse equals by value', () {
      ReferralResponse build() => ReferralResponse(
        id: 'r-1',
        date: '2026-01-01',
        referredPersonId: 'p-1',
        destinationService: 'CRAS',
        reason: 'reason',
        status: 'open',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ViolationReportResponse equals by value', () {
      ViolationReportResponse build() => ViolationReportResponse(
        id: 'vr-1',
        reportDate: '2026-01-01',
        victimId: 'v-1',
        violationType: 'abuse',
        descriptionOfFact: 'fact',
        actionsTaken: 'taken',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // registry/                                                           //
    // ------------------------------------------------------------------ //
    test('AddressResponse equals by value', () {
      AddressResponse build() => AddressResponse(
        isShelter: false,
        residenceLocation: 'urbana',
        state: 'SP',
        city: 'Sao Paulo',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('CivilDocumentsResponse equals by value', () {
      CivilDocumentsResponse build() =>
          CivilDocumentsResponse(cpf: '12345678901');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RgDocumentResponse equals by value', () {
      RgDocumentResponse build() => RgDocumentResponse(
        number: '12.345.678-9',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: '2022-05-10',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('CnsResponse equals by value', () {
      CnsResponse build() => CnsResponse(
        number: '898001234567890',
        cpf: '12345678901',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('DiagnosisResponse equals by value', () {
      DiagnosisResponse build() => DiagnosisResponse(
        icdCode: 'Q90.0',
        description: 'Down',
        date: '2024-01-15',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('DischargeInfoResponse equals by value', () {
      DischargeInfoResponse build() => DischargeInfoResponse(
        reason: 'end-of-care',
        dischargedAt: '2026-01-01T00:00:00Z',
        dischargedBy: 'user-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('FamilyMemberResponse equals by value', () {
      FamilyMemberResponse build() => FamilyMemberResponse(
        personId: 'p-1',
        relationshipId: 'rel-1',
        birthDate: '2020-01-01',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PatientResponse equals by value', () {
      PatientResponse build() =>
          PatientResponse(patientId: 'pat-1', personId: 'p-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PatientSummaryResponse equals by value', () {
      PatientSummaryResponse build() =>
          PatientSummaryResponse(patientId: 'pat-1', personId: 'p-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PersonalDataResponse equals by value', () {
      PersonalDataResponse build() => PersonalDataResponse(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana Silva',
        nationality: 'Brasileira',
        sex: 'feminino',
        birthDate: '2020-01-01',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocialIdentityResponse equals by value', () {
      SocialIdentityResponse build() =>
          SocialIdentityResponse(typeId: 'type-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('WithdrawInfoResponse equals by value', () {
      WithdrawInfoResponse build() => WithdrawInfoResponse(
        reason: 'duplicate',
        withdrawnAt: '2026-01-01T00:00:00Z',
        withdrawnBy: 'user-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // team/                                                               //
    // ------------------------------------------------------------------ //
    test('TeamMemberResponse equals by value', () {
      TeamMemberResponse build() => TeamMemberResponse(
        id: 'tm-1',
        personId: 'p-1',
        fullName: 'Full Name',
        email: 'user@example.com',
        phone: '11999990000',
        active: true,
        primaryRole: 'social_worker',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('TeamMemberDetailResponse equals by value', () {
      TeamMemberDetailResponse build() => TeamMemberDetailResponse(
        id: 'tm-1',
        personId: 'p-1',
        fullName: 'Full Name',
        email: 'user@example.com',
        phone: '11999990000',
        active: true,
        roles: [],
        createdAt: '2026-01-01T00:00:00Z',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });
  });
}
