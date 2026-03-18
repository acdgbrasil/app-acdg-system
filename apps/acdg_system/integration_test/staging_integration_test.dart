import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:acdg_system/root.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:dio/dio.dart';

String generateValidCpf() {
  final random = DateTime.now().millisecondsSinceEpoch.toString();
  final base = random.substring(random.length - 9).split('').map(int.parse).toList();
  
  int sum1 = 0;
  for (int i = 0; i < 9; i++) sum1 += base[i] * (10 - i);
  int rem1 = sum1 % 11;
  int d1 = (rem1 < 2) ? 0 : 11 - rem1;
  base.add(d1);

  int sum2 = 0;
  for (int i = 0; i < 10; i++) sum2 += base[i] * (11 - i);
  int rem2 = sum2 % 11;
  int d2 = (rem2 < 2) ? 0 : 11 - rem2;
  base.add(d2);

  return base.join('');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Staging Integration Test', () {
    late String accessToken;
    late String userId;
    final hmlBaseUrl = 'https://social-care-hml.acdgbrasil.com.br';

    setUpAll(() async {
      print('Initializing Staging Integration Test...');
      
      final authHelper = HmlAuthHelper.fromEnv();
      if (authHelper.userId.isEmpty || authHelper.privateKey.isEmpty) {
        fail('Environment variables for service account not found.');
      }
      
      userId = authHelper.userId;
      print('Authenticating with Zitadel Staging...');
      accessToken = await authHelper.getAccessToken();
      print('Authentication successful. Using Actor ID (userId): $userId');
    });

    testWidgets('Verify Staging API Connectivity (Health & Ready)', (tester) async {
      final dio = Dio();
      final healthResponse = await dio.get('$hmlBaseUrl/health');
      expect(healthResponse.statusCode, 200);
      
      final readyResponse = await dio.get('$hmlBaseUrl/ready');
      expect(readyResponse.statusCode, 200);
    });

    testWidgets('BFF Remote: Register and Get Patient in Staging', (tester) async {
      final bff = SocialCareBffRemote(
        baseUrl: hmlBaseUrl,
        authToken: accessToken,
        actorId: userId, // Correct Actor ID (Machine User)
      );

      print('Fetching lookup table: dominio_parentesco...');
      final lookupResult = await bff.getLookupTable('dominio_parentesco');
      if (lookupResult.isFailure) {
        print('Lookup table fetch failed: ${(lookupResult as Failure).error}');
      }
      expect(lookupResult.isSuccess, isTrue);
      
      final lookups = lookupResult.valueOrNull!;
      final prRelId = LookupId.create(lookups[0].id).valueOrNull!;
      final otherRelId = LookupId.create(lookups[1].id).valueOrNull!;

      // 1. Prepare a Patient model with valid VOs
      final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12);
      
      final personIdRes = PersonId.create('550e8400-e29b-41d4-a716-$uniqueSuffix');
      if (personIdRes.isFailure) fail('PersonId creation failed: ${(personIdRes as Failure).error}');
      final personId = personIdRes.valueOrNull!;

      final patientIdRes = PatientId.create('550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '1')}');
      if (patientIdRes.isFailure) fail('PatientId creation failed: ${(patientIdRes as Failure).error}');
      final patientId = patientIdRes.valueOrNull!;
      
      final pDataResult = PersonalData.create(
        firstName: 'Integration',
        lastName: 'Test',
        motherName: 'Automation',
        nationality: 'Brazilian',
        sex: Sex.feminino,
        birthDate: TimeStamp.fromIso('1990-01-01T00:00:00.000Z').valueOrNull!,
      );
      if (pDataResult.isFailure) fail('PersonalData creation failed: ${(pDataResult as Failure).error}');
      final personalData = pDataResult.valueOrNull!;

      final icdResult = IcdCode.create('B20');
      if (icdResult.isFailure) fail('IcdCode creation failed: ${(icdResult as Failure).error}');
      
      final diagResult = Diagnosis.create(
        id: icdResult.valueOrNull!,
        date: TimeStamp.now,
        description: 'Initial diagnosis from integration test',
      );
      if (diagResult.isFailure) fail('Diagnosis creation failed: ${(diagResult as Failure).error}');
      final diagnoses = [diagResult.valueOrNull!];

      final cepRes = Cep.create('01001000');
      if (cepRes.isFailure) fail('Cep creation failed: ${(cepRes as Failure).error}');

      final addrResult = Address.create(
        cep: cepRes.valueOrNull!,
        state: 'SP',
        city: 'São Paulo',
        street: 'Praça da Sé',
        neighborhood: 'Sé',
        number: '1',
        residenceLocation: ResidenceLocation.urbano,
        isShelter: false,
      );
      if (addrResult.isFailure) fail('Address creation failed: ${(addrResult as Failure).error}');

      final cpfRes = Cpf.create(generateValidCpf());
      if (cpfRes.isFailure) fail('Cpf creation failed: ${(cpfRes as Failure).error}');

      final civilDocsRes = CivilDocuments.create(
        cpf: cpfRes.valueOrNull!,
      );
      if (civilDocsRes.isFailure) fail('CivilDocuments creation failed: ${(civilDocsRes as Failure).error}');

      final familyMemberRes = FamilyMember.create(
        personId: personId,
        relationshipId: prRelId,
        residesWithPatient: true,
        requiredDocuments: [RequiredDocument.cpf],
        birthDate: personalData.birthDate,
      );
      if (familyMemberRes.isFailure) fail('FamilyMember creation failed: ${(familyMemberRes as Failure).error}');

      final patientResult = Patient.create(
        id: patientId,
        personId: personId,
        personalData: personalData,
        civilDocuments: civilDocsRes.valueOrNull!,
        address: addrResult.valueOrNull!,
        diagnoses: diagnoses,
        prRelationshipId: prRelId,
        familyMembers: [familyMemberRes.valueOrNull!],
      );
      
      if (patientResult.isFailure) {
        final error = (patientResult as Failure).error;
        fail('Patient creation failed: $error');
      }
      final patient = patientResult.valueOrNull!;

      // 2. Perform Registration
      print('Registering patient in Staging...');
      final regResult = await bff.registerPatient(patient);
      
      if (regResult.isFailure) {
        final error = (regResult as Failure).error;
        print('Registration failure: $error');
      }

      expect(regResult.isSuccess, isTrue);
      
      final newId = regResult.valueOrNull!;
      print('Registration successful. ID: ${newId.value}');

      // 3. Fetch the patient back
      print('Fetching patient back...');
      final getResult = await bff.getPatient(newId);
      
      if (getResult.isFailure) {
        final error = (getResult as Failure).error;
        print('Get patient failure: $error');
      }

      expect(getResult.isSuccess, isTrue, reason: 'Failed to fetch patient after registration');
      final fetchedPatient = getResult.valueOrNull!;
      expect(fetchedPatient.id, newId);

      // 4. Fetch the patient by personId
      print('Fetching patient by personId: ${personId.value}...');
      final getByPersonResult = await bff.getPatientByPersonId(personId);
      
      if (getByPersonResult.isFailure) {
        final error = (getByPersonResult as Failure).error;
        print('Get patient by personId failure: $error');
      }

      expect(getByPersonResult.isSuccess, isTrue, reason: 'Failed to fetch patient by personId');
      expect(getByPersonResult.valueOrNull!.id, newId);
      expect(getByPersonResult.valueOrNull!.personId, personId);

      // 5. Add a new family member
      print('Adding a new family member to patient ${newId.value}...');
      // Ensure a distinct personId by changing the suffix more reliably
      final memberSuffix = (int.parse(uniqueSuffix) + 1).toString().padLeft(12, '0');
      final newMemberPersonId = PersonId.create('550e8400-e29b-41d4-a716-$memberSuffix').valueOrNull!;
      
      final newMember = FamilyMember.create(
        personId: newMemberPersonId,
        relationshipId: otherRelId,
        residesWithPatient: false,
        requiredDocuments: [RequiredDocument.rg],
        birthDate: TimeStamp.fromIso('2000-01-01T00:00:00.000Z').valueOrNull!,
      ).valueOrNull!;

      final addMemberResult = await bff.addFamilyMember(newId, newMember, prRelId);
      
      if (addMemberResult.isFailure) {
        final error = (addMemberResult as Failure).error;
        print('Add family member failure: $error');
      }

      expect(addMemberResult.isSuccess, isTrue, reason: 'Failed to add family member');
      print('Family member added successfully.');

      // 6. Verify family member was added by fetching the patient again
      print('Verifying family composition...');
      final finalGetResult = await bff.getPatient(newId);
      expect(finalGetResult.isSuccess, isTrue);
      final updatedPatient = finalGetResult.valueOrNull!;
      
      expect(updatedPatient.familyMembers.length, greaterThan(1), 
        reason: 'Patient should have more than 1 family member now');
      
      final addedOne = updatedPatient.familyMembers.any((m) => m.personId == newMemberPersonId);
      expect(addedOne, isTrue, reason: 'The newly added family member should be present in the family list');

      // 7. Assign the new member as primary caregiver
      print('Assigning family member ${newMemberPersonId.value} as primary caregiver...');
      final assignResult = await bff.assignPrimaryCaregiver(newId, newMemberPersonId);
      
      if (assignResult.isFailure) {
        final error = (assignResult as Failure).error;
        print('Assign primary caregiver failure: $error');
      }

      expect(assignResult.isSuccess, isTrue, reason: 'Failed to assign primary caregiver');
      print('Primary caregiver assigned successfully.');

      // 8. Update Social Identity
      print('Fetching lookup table: dominio_tipo_identidade...');
      final socialIdLookupResult = await bff.getLookupTable('dominio_tipo_identidade');
      expect(socialIdLookupResult.isSuccess, isTrue);
      final socialIdTypeId = LookupId.create(socialIdLookupResult.valueOrNull!.first.id).valueOrNull!;
      
      print('Updating social identity for patient ${newId.value}...');
      final socialIdentity = SocialIdentity.create(
        typeId: socialIdTypeId,
        otherDescription: 'Identidade testada via integração',
      ).valueOrNull!;

      final updateSocialIdResult = await bff.updateSocialIdentity(newId, socialIdentity);
      if (updateSocialIdResult.isFailure) {
        print('Update social identity failure: ${(updateSocialIdResult as Failure).error}');
      }
      expect(updateSocialIdResult.isSuccess, isTrue, reason: 'Failed to update social identity');
      print('Social identity updated successfully.');

      // 8.1 Update Housing Condition
      print('Updating housing condition for patient ${newId.value}...');
      final housingConditionRes = HousingCondition.create(
        type: ConditionType.rented,
        wallMaterial: WallMaterial.masonry,
        numberOfRooms: 4,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: WaterSupply.publicNetwork,
        hasPipedWater: true,
        electricityAccess: ElectricityAccess.meteredConnection,
        sewageDisposal: SewageDisposal.publicSewer,
        wasteCollection: WasteCollection.directCollection,
        accessibilityLevel: AccessibilityLevel.fullyAccessible,
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );
      if (housingConditionRes.isFailure) fail('HousingCondition creation failed: ${(housingConditionRes as Failure).error}');
      
      final updateHousingResult = await bff.updateHousingCondition(newId, housingConditionRes.valueOrNull!);
      if (updateHousingResult.isFailure) {
        print('Update housing condition failure: ${(updateHousingResult as Failure).error}');
      }
      expect(updateHousingResult.isSuccess, isTrue, reason: 'Failed to update housing condition');
      print('Housing condition updated successfully.');

      // 8.2 Update Socio-Economic Situation
      print('Updating socio-economic situation for patient ${newId.value}...');
      final benefitRes = SocialBenefit.create(
        benefitName: 'Bolsa Família',
        amount: 600.0,
        beneficiaryId: personId,
      );
      if (benefitRes.isFailure) fail('SocialBenefit creation failed: ${(benefitRes as Failure).error}');
      
      final benefitsCollRes = SocialBenefitsCollection.create([benefitRes.valueOrNull!]);
      if (benefitsCollRes.isFailure) fail('SocialBenefitsCollection creation failed: ${(benefitsCollRes as Failure).error}');

      final socioEconomicRes = SocioEconomicSituation.create(
        totalFamilyIncome: 1200.0,
        incomePerCapita: 300.0,
        receivesSocialBenefit: true,
        socialBenefits: benefitsCollRes.valueOrNull!,
        mainSourceOfIncome: 'Trabalho Informal',
        hasUnemployed: true,
      );
      if (socioEconomicRes.isFailure) fail('SocioEconomicSituation creation failed: ${(socioEconomicRes as Failure).error}');

      final updateSocioResult = await bff.updateSocioEconomicSituation(newId, socioEconomicRes.valueOrNull!);
      if (updateSocioResult.isFailure) {
        print('Update socio-economic situation failure: ${(updateSocioResult as Failure).error}');
      }
      expect(updateSocioResult.isSuccess, isTrue, reason: 'Failed to update socio-economic situation');
      print('Socio-economic situation updated successfully.');

      // 8.3 Update Work and Income
      print('Updating work and income for patient ${newId.value}...');
      final occLookupRes = await bff.getLookupTable('dominio_condicao_ocupacao');
      if (occLookupRes.isFailure) fail('Failed to fetch dominio_condicao_ocupacao');
      
      final occupationId = LookupId.create(occLookupRes.valueOrNull!.first.id).valueOrNull!;

      final individualIncomeRes = WorkIncomeVO.create(
        memberId: personId,
        occupationId: occupationId,
        hasWorkCard: true,
        monthlyAmount: 1200.0,
      );
      if (individualIncomeRes.isFailure) fail('WorkIncomeVO creation failed: ${(individualIncomeRes as Failure).error}');

      final workAndIncome = WorkAndIncome(
        familyId: newId,
        individualIncomes: [individualIncomeRes.valueOrNull!],
        socialBenefits: [benefitRes.valueOrNull!],
        hasRetiredMembers: false,
      );

      final updateWorkResult = await bff.updateWorkAndIncome(newId, workAndIncome);
      if (updateWorkResult.isFailure) {
        final error = (updateWorkResult as Failure).error;
        print('Update work and income failure: $error');
      }
      expect(updateWorkResult.isSuccess, isTrue, reason: 'Failed to update work and income');
      print('Work and income updated successfully.');

      // 8.4 Update Educational Status
      print('Updating educational status for patient ${newId.value}...');
      final eduLevelLookupRes = await bff.getLookupTable('dominio_escolaridade');
      if (eduLevelLookupRes.isFailure) fail('Failed to fetch dominio_escolaridade');
      final eduLevelId = LookupId.create(eduLevelLookupRes.valueOrNull!.first.id).valueOrNull!;

      final effectLookupRes = await bff.getLookupTable('dominio_efeito_condicionalidade');
      if (effectLookupRes.isFailure) fail('Failed to fetch dominio_efeito_condicionalidade');
      final effectId = LookupId.create(effectLookupRes.valueOrNull!.first.id).valueOrNull!;

      final eduStatus = EducationalStatus(
        familyId: newId,
        memberProfiles: [
          MemberEducationalProfile(
            memberId: personId,
            canReadWrite: true,
            attendsSchool: true,
            educationLevelId: eduLevelId,
          ),
        ],
        programOccurrences: [
          ProgramOccurrence(
            memberId: personId,
            date: TimeStamp.now,
            effectId: effectId,
            isSuspensionRequested: false,
          ),
        ],
      );

      final updateEduResult = await bff.updateEducationalStatus(newId, eduStatus);
      if (updateEduResult.isFailure) {
        print('Update educational status failure: ${(updateEduResult as Failure).error}');
      }
      expect(updateEduResult.isSuccess, isTrue, reason: 'Failed to update educational status');
      print('Educational status updated successfully.');

      // 8.5 Register Appointment
      print('Registering appointment for patient ${newId.value}...');
      final appointmentIdRes = AppointmentId.create('550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '5')}');
      if (appointmentIdRes.isFailure) fail('AppointmentId creation failed');
      
      // Use a valid UUID for professionalId (backend might reject non-UUID actorIds)
      final profIdRes = ProfessionalId.create('550e8400-e29b-41d4-a716-999999999999');
      if (profIdRes.isFailure) fail('ProfessionalId creation failed');

      final appointmentRes = SocialCareAppointment.create(
        id: appointmentIdRes.valueOrNull!,
        date: TimeStamp.now,
        professionalInChargeId: profIdRes.valueOrNull!,
        type: AppointmentType.officeAppointment,
        summary: 'Atendimento de teste via integração',
        actionPlan: 'Plano de ação de teste',
      );
      if (appointmentRes.isFailure) fail('SocialCareAppointment creation failed: ${(appointmentRes as Failure).error}');

      final regApptResult = await bff.registerAppointment(newId, appointmentRes.valueOrNull!);
      if (regApptResult.isFailure) {
        print('Register appointment failure: ${(regApptResult as Failure).error}');
      }
      expect(regApptResult.isSuccess, isTrue, reason: 'Failed to register appointment');
      print('Appointment registered successfully.');

      // 8.6 Update Intake Info
      print('Updating intake info for patient ${newId.value}...');
      final ingressLookupRes = await bff.getLookupTable('dominio_tipo_ingresso');
      if (ingressLookupRes.isFailure) fail('Failed to fetch dominio_tipo_ingresso');
      final ingressTypeId = LookupId.create(ingressLookupRes.valueOrNull!.first.id).valueOrNull!;

      final programLookupRes = await bff.getLookupTable('dominio_programa_social');
      if (programLookupRes.isFailure) fail('Failed to fetch dominio_programa_social');
      final programId = LookupId.create(programLookupRes.valueOrNull!.first.id).valueOrNull!;

      final intakeInfo = IngressInfo.create(
        ingressTypeId: ingressTypeId,
        serviceReason: 'Motivo de teste via integração',
        linkedSocialPrograms: [
          ProgramLink(programId: programId, observation: 'Observação de teste'),
        ],
      ).valueOrNull!;

      final updateIntakeResult = await bff.updateIntakeInfo(newId, intakeInfo);
      if (updateIntakeResult.isFailure) {
        print('Update intake info failure: ${(updateIntakeResult as Failure).error}');
      }
      expect(updateIntakeResult.isSuccess, isTrue, reason: 'Failed to update intake info');
      print('Intake info updated successfully.');

      // 8.7 Update Placement History
      print('Updating placement history for patient ${newId.value}...');
      final placementHistory = PlacementHistory(
        familyId: newId,
        individualPlacements: [
          PlacementRegistry.create(
            memberId: personId,
            startDate: TimeStamp.now,
            reason: 'Necessidade de acolhimento temporário via integração',
          ).valueOrNull!,
        ],
        collectiveSituations: const CollectiveSituations(
          homeLossReport: 'Relato de perda de moradia para teste',
        ),
        separationChecklist: const SeparationChecklist(
          adultInPrison: false,
          adolescentInInternment: false,
        ),
      );

      final updatePlacementResult = await bff.updatePlacementHistory(newId, placementHistory);
      if (updatePlacementResult.isFailure) {
        print('Update placement history failure: ${(updatePlacementResult as Failure).error}');
      }
      expect(updatePlacementResult.isSuccess, isTrue, reason: 'Failed to update placement history');
      print('Placement history updated successfully.');

      // 8.8 Report Rights Violation
      print('Reporting rights violation for patient ${newId.value}...');
      final now = TimeStamp.now;
      final vriRes = ViolationReportId.create('550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '6')}');
      if (vriRes.isFailure) fail('ViolationReportId creation failed');

      final violationReportRes = RightsViolationReport.create(
        id: vriRes.valueOrNull!,
        reportDate: now,
        incidentDate: now,
        victimId: personId,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Relato de negligência para teste via integração',
        actionsTaken: 'Encaminhamento para rede de proteção',
      );
      if (violationReportRes.isFailure) fail('RightsViolationReport creation failed: ${(violationReportRes as Failure).error}');

      final reportViolationResult = await bff.reportViolation(newId, violationReportRes.valueOrNull!);
      if (reportViolationResult.isFailure) {
        print('Report violation failure: ${(reportViolationResult as Failure).error}');
      }
      expect(reportViolationResult.isSuccess, isTrue, reason: 'Failed to report violation');
      print('Rights violation reported successfully.');

      // 8.9 Create Referral
      print('Creating referral for patient ${newId.value}...');
      final referral = Referral.create(
        id: ReferralId.create('550e8400-e29b-41d4-a716-${uniqueSuffix.replaceAll('0', '7')}').valueOrNull!,
        date: TimeStamp.now,
        requestingProfessionalId: profIdRes.valueOrNull!,
        referredPersonId: personId,
        destinationService: DestinationService.creas,
        reason: 'Encaminhamento para acompanhamento especializado via integração',
      ).valueOrNull!;

      final createReferralResult = await bff.createReferral(newId, referral);
      if (createReferralResult.isFailure) {
        print('Create referral failure: ${(createReferralResult as Failure).error}');
      }
      expect(createReferralResult.isSuccess, isTrue, reason: 'Failed to create referral');
      print('Referral created successfully.');

      // 8.10 Update Health Status
      print('Updating health status for patient ${newId.value}...');
      final deficiencyLookupRes = await bff.getLookupTable('dominio_tipo_deficiencia');
      if (deficiencyLookupRes.isFailure) fail('Failed to fetch dominio_tipo_deficiencia');
      final deficiencyTypeId = LookupId.create(deficiencyLookupRes.valueOrNull!.first.id).valueOrNull!;

      final healthStatus = HealthStatus(
        familyId: newId,
        deficiencies: [
          MemberDeficiency(
            memberId: personId,
            deficiencyTypeId: deficiencyTypeId,
            needsConstantCare: true,
            responsibleCaregiverName: 'Cuidador Teste',
          ),
        ],
        gestatingMembers: [
          PregnantMember(
            memberId: personId,
            monthsGestation: 5,
            startedPrenatalCare: true,
          ),
        ],
        constantCareNeeds: [personId],
        foodInsecurity: false,
      );

      final updateHealthResult = await bff.updateHealthStatus(newId, healthStatus);
      if (updateHealthResult.isFailure) {
        print('Update health status failure: ${(updateHealthResult as Failure).error}');
      }
      expect(updateHealthResult.isSuccess, isTrue, reason: 'Failed to update health status');
      print('Health status updated successfully.');

      // 8.11 Update Community Support Network
      print('Updating community support network for patient ${newId.value}...');
      final supportNetwork = CommunitySupportNetwork.create(
        hasRelativeSupport: true,
        hasNeighborSupport: true,
        familyConflicts: 'Nenhum conflito relevante para teste',
        patientParticipatesInGroups: true,
        familyParticipatesInGroups: false,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      ).valueOrNull!;

      final updateSupportResult = await bff.updateCommunitySupportNetwork(newId, supportNetwork);
      if (updateSupportResult.isFailure) {
        print('Update community support failure: ${(updateSupportResult as Failure).error}');
      }
      expect(updateSupportResult.isSuccess, isTrue, reason: 'Failed to update community support network');
      print('Community support network updated successfully.');

      // 8.12 Update Social Health Summary
      print('Updating social health summary for patient ${newId.value}...');
      final summary = SocialHealthSummary.create(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        functionalDependencies: ['Alimentação', 'Higiene'],
        hasRelevantDrugTherapy: true,
      ).valueOrNull!;

      final updateSummaryResult = await bff.updateSocialHealthSummary(newId, summary);
      if (updateSummaryResult.isFailure) {
        print('Update social health summary failure: ${(updateSummaryResult as Failure).error}');
      }
      expect(updateSummaryResult.isSuccess, isTrue, reason: 'Failed to update social health summary');
      print('Social health summary updated successfully.');

      // 9. Verify all records in audit trail
      print('Verifying records in audit trail...');
      final finalPatientResult = await bff.getPatient(newId);
      expect(finalPatientResult.isSuccess, isTrue);
      
      // 10. Fetch Audit Trail
      print('Waiting for audit trail relay (2s)...');
      await Future.delayed(const Duration(seconds: 2));
      
      print('Fetching audit trail for patient ${newId.value}...');
      final auditResult = await bff.getAuditTrail(newId);
      if (auditResult.isFailure) {
        print('Fetch audit trail failure: ${(auditResult as Failure).error}');
      }
      expect(auditResult.isSuccess, isTrue, reason: 'Failed to fetch audit trail');
      
      final auditEvents = auditResult.valueOrNull!;
      print('Retrieved ${auditEvents.length} audit events.');
      
      expect(auditEvents.any((e) => e.eventType == 'PatientCreatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'HousingConditionUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'SocioEconomicSituationUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'WorkAndIncomeUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'EducationalStatusUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'SocialCareAppointmentRegisteredEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'IntakeInfoUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'PlacementHistoryUpdatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'RightsViolationReportedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'ReferralCreatedEvent'), isTrue);
      expect(auditEvents.any((e) => e.eventType == 'HealthStatusUpdatedEvent'), isTrue, reason: 'HealthStatusUpdatedEvent should be in the audit trail');
      expect(auditEvents.any((e) => e.eventType == 'CommunitySupportNetworkUpdatedEvent'), isTrue, reason: 'CommunitySupportNetworkUpdatedEvent should be in the audit trail');
      expect(auditEvents.any((e) => e.eventType == 'SocialHealthSummaryUpdatedEvent'), isTrue, reason: 'SocialHealthSummaryUpdatedEvent should be in the audit trail');

      // 11. Remove the family member
      print('Removing family member ${newMemberPersonId.value} from patient ${newId.value}...');
      final removeResult = await bff.removeFamilyMember(newId, newMemberPersonId);
      
      if (removeResult.isFailure) {
        final error = (removeResult as Failure).error;
        print('Remove family member failure: $error');
      }

      expect(removeResult.isSuccess, isTrue, reason: 'Failed to remove family member');
      print('Family member removed successfully.');

      // 8. Verify family member was removed
      print('Verifying final family composition...');
      final lastGetResult = await bff.getPatient(newId);
      expect(lastGetResult.isSuccess, isTrue);
      final finalPatient = lastGetResult.valueOrNull!;
      
      final stillThere = finalPatient.familyMembers.any((m) => m.personId == newMemberPersonId);
      expect(stillThere, isFalse, reason: 'The removed family member should NOT be present in the family list');

      print('BFF Integration Success: End-to-end Registry flow validated (Add & Remove).');
    });

    testWidgets('App starts and restores session using staging token', (tester) async {
      final realUser = AuthUser(
        id: userId,
        name: 'Social Care Integration Tests',
        roles: {AuthRole.socialWorker},
      );

      final fakeRepository = _RealTokenAuthRepository(accessToken, realUser);

      await tester.pumpWidget(Root(authRepository: fakeRepository));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao ACDG System'), findsOneWidget);
      expect(find.text('Social Care Integration Tests'), findsOneWidget);
    });
  });
}

class _RealTokenAuthRepository extends ChangeNotifier implements AuthRepository {
  _RealTokenAuthRepository(this.token, this.user);
  final String token;
  final AuthUser user;
  final _statusController = StreamController<AuthStatus>.broadcast();
  AuthStatus _status = const AuthLoading();

  @override
  Stream<AuthStatus> get statusStream => _statusController.stream;
  @override
  AuthStatus get currentStatus => _status;
  @override
  AuthUser? get currentUser => _status is Authenticated ? (this._status as Authenticated).user : null;
  @override
  AuthToken? get currentToken => _status is Authenticated ? AuthToken(accessToken: token, expiresAt: DateTime.now().add(const Duration(hours: 1))) : null;
  @override
  Future<Result<void>> login() async => const Success(null);
  @override
  Future<Result<void>> logout() async => const Success(null);
  @override
  Future<Result<void>> tryRestoreSession() async {
    _status = Authenticated(user);
    _statusController.add(_status);
    notifyListeners();
    return const Success(null);
  }
  @override
  void dispose() {
    _statusController.close();
    super.dispose();
  }
}
