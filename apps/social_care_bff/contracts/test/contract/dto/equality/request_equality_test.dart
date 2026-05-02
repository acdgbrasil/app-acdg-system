// Wave 0 (RED) — tests for value-equality across all Request DTOs.
//
// These tests currently FAIL because the DTOs do not mix in Equatable yet.
// Wave 1 implementer will add `with Equatable` + `props` to each class,
// turning this entire file GREEN.
//
// IMPORTANT: each `build()` factory below intentionally AVOIDS `const`. If we
// used `const` constructors with identical field values, Dart would
// canonicalize both literals to the SAME instance and `a == b` would pass
// trivially via identity — masking the absence of Equatable. Forcing fresh
// instances via non-constructors is the only way to genuinely prove
// structural (value) equality.

import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Request DTOs — value equality (Wave 0 RED)', () {
    // ------------------------------------------------------------------ //
    // assessment/                                                         //
    // ------------------------------------------------------------------ //
    test('UpdateCommunitySupportNetworkRequest equals by value', () {
      UpdateCommunitySupportNetworkRequest build() =>
          UpdateCommunitySupportNetworkRequest(
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

    test('UpdateEducationalStatusRequest equals by value', () {
      UpdateEducationalStatusRequest build() =>
          UpdateEducationalStatusRequest();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ProfileDraftDto equals by value', () {
      ProfileDraftDto build() => ProfileDraftDto(
        memberId: 'm1',
        canReadWrite: true,
        attendsSchool: true,
        educationLevelId: 'lvl-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('OccurrenceDraftDto equals by value', () {
      OccurrenceDraftDto build() => OccurrenceDraftDto(
        memberId: 'm1',
        date: '2026-01-01',
        effectId: 'eff-1',
        isSuspensionRequested: false,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateHealthStatusRequest equals by value', () {
      UpdateHealthStatusRequest build() =>
          UpdateHealthStatusRequest(foodInsecurity: true);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('DeficiencyDraftDto equals by value', () {
      DeficiencyDraftDto build() => DeficiencyDraftDto(
        memberId: 'm1',
        deficiencyTypeId: 'def-1',
        needsConstantCare: true,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PregnantDraftDto equals by value', () {
      PregnantDraftDto build() => PregnantDraftDto(
        memberId: 'm1',
        monthsGestation: 5,
        startedPrenatalCare: true,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateHousingConditionRequest equals by value', () {
      UpdateHousingConditionRequest build() =>
          UpdateHousingConditionRequest(
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

    test('UpdateSocialHealthSummaryRequest equals by value', () {
      UpdateSocialHealthSummaryRequest build() =>
          UpdateSocialHealthSummaryRequest(
            requiresConstantCare: true,
            hasMobilityImpairment: false,
            hasRelevantDrugTherapy: false,
          );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateSocioEconomicSituationRequest equals by value', () {
      UpdateSocioEconomicSituationRequest build() =>
          UpdateSocioEconomicSituationRequest(
            totalFamilyIncome: 1000.0,
            incomePerCapita: 250.0,
            receivesSocialBenefit: true,
            mainSourceOfIncome: 'salary',
            hasUnemployed: false,
          );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocialBenefitDraftDto equals by value', () {
      SocialBenefitDraftDto build() => SocialBenefitDraftDto(
        benefitName: 'BPC',
        amount: 1412.0,
        beneficiaryId: 'mem-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateWorkAndIncomeRequest equals by value', () {
      UpdateWorkAndIncomeRequest build() =>
          UpdateWorkAndIncomeRequest(hasRetiredMembers: false);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('IncomeDraftDto equals by value', () {
      IncomeDraftDto build() => IncomeDraftDto(
        memberId: 'm1',
        occupationId: 'occ-1',
        hasWorkCard: true,
        monthlyAmount: 2000.0,
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // care/                                                               //
    // ------------------------------------------------------------------ //
    test('RegisterAppointmentRequest equals by value', () {
      RegisterAppointmentRequest build() =>
          RegisterAppointmentRequest(professionalId: 'prof-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RegisterIntakeInfoRequest equals by value', () {
      RegisterIntakeInfoRequest build() => RegisterIntakeInfoRequest(
        ingressTypeId: 'it-1',
        serviceReason: 'reason',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ProgramLinkDraftDto equals by value', () {
      ProgramLinkDraftDto build() =>
          ProgramLinkDraftDto(programId: 'prog-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // governance/                                                         //
    // ------------------------------------------------------------------ //
    test('CreateLookupItemRequest equals by value', () {
      CreateLookupItemRequest build() => CreateLookupItemRequest(
        codigo: 'CODE',
        descricao: 'Descricao',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('CreateLookupRequestRequest equals by value', () {
      CreateLookupRequestRequest build() => CreateLookupRequestRequest(
        tableName: 'pr_relationships',
        codigo: 'CODE',
        descricao: 'Descricao',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ToggleLookupItemRequest equals by value', () {
      ToggleLookupItemRequest build() =>
          ToggleLookupItemRequest(active: true);
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateLookupItemRequest equals by value', () {
      UpdateLookupItemRequest build() =>
          UpdateLookupItemRequest(codigo: 'NEW', descricao: 'novo');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // people/                                                             //
    // ------------------------------------------------------------------ //
    test('AssignRoleRequest equals by value', () {
      AssignRoleRequest build() =>
          AssignRoleRequest(system: 'social_care', role: 'owner');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RegisterPersonRequest equals by value', () {
      RegisterPersonRequest build() => RegisterPersonRequest(
        fullName: 'Joao Silva',
        birthDate: '1990-01-01',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RegisterPersonWithLoginRequest equals by value', () {
      RegisterPersonWithLoginRequest build() =>
          RegisterPersonWithLoginRequest(
            fullName: 'Joao Silva',
            birthDate: '1990-01-01',
            email: 'joao@example.com',
          );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // protection/                                                         //
    // ------------------------------------------------------------------ //
    test('CreateReferralRequest equals by value', () {
      CreateReferralRequest build() => CreateReferralRequest(
        referredPersonId: 'p-1',
        destinationService: 'CRAS',
        reason: 'reason',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ReportRightsViolationRequest equals by value', () {
      ReportRightsViolationRequest build() => ReportRightsViolationRequest(
        victimId: 'v-1',
        violationType: 'abuse',
        descriptionOfFact: 'fact',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdatePlacementHistoryRequest equals by value', () {
      UpdatePlacementHistoryRequest build() =>
          UpdatePlacementHistoryRequest();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RegistryDraftDto equals by value', () {
      RegistryDraftDto build() => RegistryDraftDto(
        memberId: 'm-1',
        startDate: '2026-01-01',
        reason: 'reason',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('CollectiveDraftDto equals by value', () {
      CollectiveDraftDto build() => CollectiveDraftDto();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SeparationDraftDto equals by value', () {
      SeparationDraftDto build() => SeparationDraftDto();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    // ------------------------------------------------------------------ //
    // registry/                                                           //
    // ------------------------------------------------------------------ //
    test('AddFamilyMemberRequest equals by value', () {
      AddFamilyMemberRequest build() => AddFamilyMemberRequest(
        memberPersonId: 'p-1',
        relationship: 'child',
        isResiding: true,
        isCaregiver: false,
        hasDisability: false,
        birthDate: '2020-01-01',
        prRelationshipId: 'rel-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('AdmitPatientRequest equals by value', () {
      AdmitPatientRequest build() => AdmitPatientRequest(
        reason: 'readmission',
        admittedAt: '2026-04-17T10:00:00Z',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('AssignPrimaryCaregiverRequest equals by value', () {
      AssignPrimaryCaregiverRequest build() =>
          AssignPrimaryCaregiverRequest(memberPersonId: 'p-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('DischargePatientRequest equals by value', () {
      DischargePatientRequest build() =>
          DischargePatientRequest(reason: 'end-of-care');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('ReadmitPatientRequest equals by value', () {
      ReadmitPatientRequest build() => ReadmitPatientRequest();
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RegisterPatientRequest equals by value', () {
      RegisterPatientRequest build() => RegisterPatientRequest(
        personId: 'p-1',
        initialDiagnoses: [],
        prRelationshipId: 'rel-1',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('DiagnosisDraftDto equals by value', () {
      DiagnosisDraftDto build() => DiagnosisDraftDto(
        icdCode: 'Q90.0',
        date: '2024-01-15',
        description: 'Down',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('PersonalDataDraftDto equals by value', () {
      PersonalDataDraftDto build() => PersonalDataDraftDto(
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

    test('CivilDocumentsDraftDto equals by value', () {
      CivilDocumentsDraftDto build() =>
          CivilDocumentsDraftDto(cpf: '12345678901');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('RgDocumentDraftDto equals by value', () {
      RgDocumentDraftDto build() => RgDocumentDraftDto(
        number: '12.345.678-9',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: '2022-05-10',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('CnsDraftDto equals by value', () {
      CnsDraftDto build() => CnsDraftDto(
        number: '898001234567890',
        cpf: '12345678901',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('AddressDraftDto equals by value', () {
      AddressDraftDto build() => AddressDraftDto(
        isShelter: false,
        residenceLocation: 'urbana',
        state: 'SP',
        city: 'Sao Paulo',
      );
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('SocialIdentityDraftDto equals by value', () {
      SocialIdentityDraftDto build() =>
          SocialIdentityDraftDto(typeId: 'type-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('UpdateSocialIdentityRequest equals by value', () {
      UpdateSocialIdentityRequest build() =>
          UpdateSocialIdentityRequest(typeId: 'type-1');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('WithdrawPatientRequest equals by value', () {
      WithdrawPatientRequest build() =>
          WithdrawPatientRequest(reason: 'duplicate');
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });
  });
}
