import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/home/models/patient_detail_translator.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  late FakeSocialCareBff fakeBff;
  late BffPatientRepository repository;

  setUp(() {
    fakeBff = FakeSocialCareBff(delay: Duration.zero);
    repository = BffPatientRepository(
      bff: fakeBff,
      patientService: PatientService(bff: fakeBff),
    );
  });

  group('BffPatientRepository Regression Tests (BUGS_CODE_REVIEW_2026_04_02)', () {

    test('BUG-1: should map referrals fields correctly from domain to detail', () async {
      // Arrange — create domain objects via factory methods with guard cases
      final ReferralId refId;
      switch (ReferralId.create('550e8400-e29b-41d4-a716-446655440001')) {
        case Success(:final value): refId = value;
        case Failure(): fail('ReferralId.create failed');
      }

      final ProfessionalId profId;
      switch (ProfessionalId.create('550e8400-e29b-41d4-a716-446655440002')) {
        case Success(:final value): profId = value;
        case Failure(): fail('ProfessionalId.create failed');
      }

      final PersonId referredId;
      switch (PersonId.create('550e8400-e29b-41d4-a716-446655440003')) {
        case Success(:final value): referredId = value;
        case Failure(): fail('PersonId.create failed');
      }

      final TimeStamp refDate;
      switch (TimeStamp.fromIso('2026-03-10T00:00:00.000Z')) {
        case Success(:final value): refDate = value;
        case Failure(): fail('TimeStamp.fromIso failed');
      }

      final Referral referral;
      switch (Referral.create(
        id: refId,
        date: refDate,
        requestingProfessionalId: profId,
        referredPersonId: referredId,
        destinationService: DestinationService.cras,
        reason: 'Test reason for referral',
      )) {
        case Success(:final value): referral = value;
        case Failure(:final error): fail('Referral.create failed: $error');
      }

      final patient = PatientFixtures.validPatient;
      final patientWithReferral = patient.copyWith(referrals: [referral]);
      await fakeBff.registerPatient(patientWithReferral);

      // Act
      final result = await repository.getPatient(patient.id);

      // Assert
      final Patient domainPatient;
      switch (result) {
        case Success(:final value): domainPatient = value;
        case Failure(:final error): fail('getPatient failed: $error');
      }

      final detailResult = PatientDetailTranslator.toDetailResult(domainPatient);
      final detail = detailResult.patientDetail;
      expect(detail.referrals, isNotEmpty);

      final firstReferral = detail.referrals.first;
      expect(firstReferral.json['id'], refId.value);
      expect(firstReferral.json['reason'], 'Test reason for referral');
      expect(firstReferral.json['destinationService'], 'CRAS');
    });

    test('BUG-2: should map violation reports fields correctly from domain to detail', () async {
      // Arrange
      final ViolationReportId reportId;
      switch (ViolationReportId.create('550e8400-e29b-41d4-a716-446655441001')) {
        case Success(:final value): reportId = value;
        case Failure(): fail('ViolationReportId.create failed');
      }

      final PersonId victimId;
      switch (PersonId.create('550e8400-e29b-41d4-a716-446655441002')) {
        case Success(:final value): victimId = value;
        case Failure(): fail('PersonId.create failed');
      }

      final TimeStamp reportDate;
      switch (TimeStamp.fromIso('2026-04-01T00:00:00.000Z')) {
        case Success(:final value): reportDate = value;
        case Failure(): fail('TimeStamp.fromIso failed');
      }

      final RightsViolationReport report;
      switch (RightsViolationReport.create(
        id: reportId,
        reportDate: reportDate,
        victimId: victimId,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Description of neglect incident',
      )) {
        case Success(:final value): report = value;
        case Failure(:final error): fail('RightsViolationReport.create failed: $error');
      }

      final patient = PatientFixtures.validPatient;
      final patientWithReport = patient.copyWith(violationReports: [report]);
      await fakeBff.registerPatient(patientWithReport);

      // Act
      final result = await repository.getPatient(patient.id);

      // Assert
      final Patient domainPatient;
      switch (result) {
        case Success(:final value): domainPatient = value;
        case Failure(:final error): fail('getPatient failed: $error');
      }

      final detailResult = PatientDetailTranslator.toDetailResult(domainPatient);
      final detail = detailResult.patientDetail;
      expect(detail.violationReports, isNotEmpty);

      final firstReport = detail.violationReports.first;
      expect(firstReport.json['id'], reportId.value);
      expect(firstReport.json['descriptionOfFact'], 'Description of neglect incident');
      expect(firstReport.json['violationType'], 'NEGLECT');
    });

    test('BUG-3: should calculate age precisely considering if birthday passed this year', () async {
      // Arrange — birth date where birthday hasn't passed yet this year
      final patient = PatientFixtures.validPatient;
      final now = DateTime.now();
      // Birthday is tomorrow — age should be (now.year - 2000 - 1)
      final tomorrowBirthDate = DateTime(2000, now.month, now.day + 1);

      final TimeStamp birthTs;
      switch (TimeStamp.fromDate(tomorrowBirthDate)) {
        case Success(:final value): birthTs = value;
        case Failure(): fail('TimeStamp.fromDate failed');
      }

      final PersonalData pdWithBirth;
      switch (PersonalData.create(
        firstName: patient.personalData!.firstName,
        lastName: patient.personalData!.lastName,
        motherName: patient.personalData!.motherName,
        nationality: patient.personalData!.nationality,
        sex: patient.personalData!.sex,
        birthDate: birthTs,
      )) {
        case Success(:final value): pdWithBirth = value;
        case Failure(:final error): fail('PersonalData.create failed: $error');
      }

      final modifiedPatient = patient.copyWith(
        personalData: () => pdWithBirth,
      );
      await fakeBff.registerPatient(modifiedPatient);

      // Act
      final result = await repository.getPatient(patient.id);

      // Assert
      final Patient domainPatient;
      switch (result) {
        case Success(:final value): domainPatient = value;
        case Failure(:final error): fail('getPatient failed: $error');
      }

      final detailResult = PatientDetailTranslator.toDetailResult(domainPatient);
      final detail = detailResult.patientDetail;
      final expectedAge = now.year - 2000 - 1;
      expect(detail.age, expectedAge, reason: 'Age should be $expectedAge because birthday has not passed yet');
    });

    test('BUG-4: should have correct FichaStatus name for housing conditions', () async {
      // Arrange
      final patient = PatientFixtures.validPatient;
      await fakeBff.registerPatient(patient);

      // Act
      final result = await repository.getPatient(patient.id);

      // Assert
      final Patient domainPatient;
      switch (result) {
        case Success(:final value): domainPatient = value;
        case Failure(:final error): fail('getPatient failed: $error');
      }

      final detailResult = PatientDetailTranslator.toDetailResult(domainPatient);
      final fichas = detailResult.fichas;
      final housingFicha = fichas.where(
        (f) => f.name.contains('habita') || f.name.contains('convivência'),
      ).first;

      expect(housingFicha.name, 'Condições habitacionais da família',
        reason: 'Ficha name should reflect housing content, not community service');
    });
  });
}
