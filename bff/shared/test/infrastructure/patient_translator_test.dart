import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  // ─── Shared IDs ─────────────────────────────────────────────────────

  final patientId = PatientId.create(
    '550e8400-e29b-41d4-a716-000000000001',
  ).valueOrNull!;
  final personId = PersonId.create(
    '550e8400-e29b-41d4-a716-000000000002',
  ).valueOrNull!;
  final prRelationshipId = LookupId.create(
    '550e8400-e29b-41d4-a716-000000000010',
  ).valueOrNull!;
  final professionalId = ProfessionalId.create(
    '550e8400-e29b-41d4-a716-000000000020',
  ).valueOrNull!;

  // ─── Critical 1: CNS serialization round-trip ───────────────────────

  group('civilDocumentsToJson / civilDocumentsFromJson — CNS round-trip', () {
    test('Deve serializar CNS com number, cpf e qrCode', () {
      final cns = Cns.create(
        number: '700000000000005',
        cpf: Cpf.create('12345678909').valueOrNull,
        qrCode: 'QR-DATA-EXAMPLE',
      ).valueOrNull!;

      final docs = CivilDocuments.create(cns: cns).valueOrNull!;
      final json = PatientTranslator.civilDocumentsToJson(docs);

      expect(
        json.containsKey('cns'),
        isTrue,
        reason: 'civilDocumentsToJson deve incluir o campo cns',
      );

      final cnsJson = json['cns'] as Map<String, dynamic>;
      expect(cnsJson['number'], '700000000000005');
      expect(cnsJson['cpf'], '12345678909');
      expect(cnsJson['qrCode'], 'QR-DATA-EXAMPLE');
    });

    test('Deve desserializar CNS corretamente do JSON', () {
      final json = {
        'cpf': null,
        'nis': null,
        'rgDocument': null,
        'cns': {
          'number': '700000000000005',
          'cpf': '12345678909',
          'qrCode': 'QR-DATA-EXAMPLE',
        },
      };

      final result = PatientTranslator.civilDocumentsFromJson(json);
      expect(result.isSuccess, isTrue, reason: 'fromJson should succeed');
      final docs = result.valueOrNull!;

      expect(docs.cns, isNotNull, reason: 'CNS deve ser reconstituído');
      expect(docs.cns!.number, '700000000000005');
      expect(docs.cns!.cpf?.value, '12345678909');
      expect(docs.cns!.qrCode, 'QR-DATA-EXAMPLE');
    });

    test('Deve fazer round-trip completo com CNS', () {
      final cns = Cns.create(
        number: '700000000000005',
        cpf: Cpf.create('12345678909').valueOrNull,
      ).valueOrNull!;

      final original = CivilDocuments.create(
        cns: cns,
        cpf: Cpf.create('12345678909').valueOrNull,
      ).valueOrNull!;

      final json = PatientTranslator.civilDocumentsToJson(original);
      final result = PatientTranslator.civilDocumentsFromJson(json);
      expect(result.isSuccess, isTrue);
      final restored = result.valueOrNull!;

      expect(restored.cns?.number, original.cns?.number);
      expect(restored.cns?.cpf?.value, original.cns?.cpf?.value);
      expect(restored.cpf?.value, original.cpf?.value);
    });

    test('Deve serializar CNS como null quando ausente', () {
      final docs = CivilDocuments.create(
        cpf: Cpf.create('12345678909').valueOrNull,
      ).valueOrNull!;

      final json = PatientTranslator.civilDocumentsToJson(docs);

      expect(json['cns'], isNull);
    });
  });

  // ─── Critical 2: Missing IDs in toJson ──────────────────────────────

  group('appointmentToJson — deve incluir id', () {
    test('Deve serializar o id do appointment', () {
      final appointmentId = AppointmentId.create(
        '550e8400-e29b-41d4-a716-000000000030',
      ).valueOrNull!;
      final appointment = SocialCareAppointment.create(
        id: appointmentId,
        date: TimeStamp.now,
        professionalInChargeId: professionalId,
        type: AppointmentType.homeVisit,
        summary: 'Resumo',
        actionPlan: 'Plano',
      ).valueOrNull!;

      final json = PatientTranslator.appointmentToJson(appointment);

      expect(
        json['id'],
        appointmentId.value,
        reason: 'appointmentToJson deve incluir id',
      );
    });
  });

  group('violationReportToJson — deve incluir id', () {
    test('Deve serializar o id do violation report', () {
      final reportId = ViolationReportId.create(
        '550e8400-e29b-41d4-a716-000000000040',
      ).valueOrNull!;
      final report = RightsViolationReport.create(
        id: reportId,
        reportDate: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        victimId: personId,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Descrição do fato',
      ).valueOrNull!;

      final json = PatientTranslator.violationReportToJson(report);

      expect(
        json['id'],
        reportId.value,
        reason: 'violationReportToJson deve incluir id',
      );
    });
  });

  group('placementHistoryToJson — deve incluir id dos registries', () {
    test('Deve serializar o id de cada placement registry', () {
      final registry = PlacementRegistry.create(
        id: '550e8400-e29b-41d4-a716-000000000050',
        memberId: personId,
        startDate: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        reason: 'Motivo teste',
      ).valueOrNull!;

      final history = PlacementHistory(
        familyId: patientId,
        individualPlacements: [registry],
        collectiveSituations: const CollectiveSituations(homeLossReport: null),
        separationChecklist: const SeparationChecklist(
          adultInPrison: false,
          adolescentInInternment: false,
        ),
      );

      final json = PatientTranslator.placementHistoryToJson(history);
      final registries = json['registries'] as List;

      expect(
        registries.first['id'],
        registry.id,
        reason: 'placementHistoryToJson deve incluir id em cada registry',
      );
    });
  });

  group('referralToJson — deve incluir id e status', () {
    test('Deve serializar id e status do referral', () {
      final referralId = ReferralId.create(
        '550e8400-e29b-41d4-a716-000000000060',
      ).valueOrNull!;
      final referral = Referral.create(
        id: referralId,
        date: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        requestingProfessionalId: professionalId,
        referredPersonId: personId,
        destinationService: DestinationService.cras,
        reason: 'Motivo',
      ).valueOrNull!;

      final json = PatientTranslator.referralToJson(referral);

      expect(
        json['id'],
        referralId.value,
        reason: 'referralToJson deve incluir id',
      );
      expect(
        json['status'],
        'PENDING',
        reason: 'referralToJson deve incluir status',
      );
    });
  });

  // ─── Critical 3: violationTypeId round-trip ─────────────────────────

  group('RightsViolationReport — violationTypeId', () {
    test('Deve criar report com violationTypeId', () {
      final violationTypeId = LookupId.create(
        '550e8400-e29b-41d4-a716-000000000070',
      ).valueOrNull!;
      final reportId = ViolationReportId.create(
        '550e8400-e29b-41d4-a716-000000000040',
      ).valueOrNull!;

      final result = RightsViolationReport.create(
        id: reportId,
        reportDate: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        victimId: personId,
        violationType: ViolationType.neglect,
        violationTypeId: violationTypeId,
        descriptionOfFact: 'Descrição do fato',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.violationTypeId?.value, violationTypeId.value);
    });

    test('Deve serializar violationTypeId no JSON', () {
      final violationTypeId = LookupId.create(
        '550e8400-e29b-41d4-a716-000000000070',
      ).valueOrNull!;
      final reportId = ViolationReportId.create(
        '550e8400-e29b-41d4-a716-000000000040',
      ).valueOrNull!;

      final report = RightsViolationReport.create(
        id: reportId,
        reportDate: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        victimId: personId,
        violationType: ViolationType.neglect,
        violationTypeId: violationTypeId,
        descriptionOfFact: 'Descrição do fato',
      ).valueOrNull!;

      final json = PatientTranslator.violationReportToJson(report);

      expect(json['violationTypeId'], violationTypeId.value);
    });

    test('Deve desserializar violationTypeId do JSON', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-000000000040',
        'reportDate': '2025-01-01T00:00:00.000Z',
        'victimId': personId.value,
        'violationType': 'NEGLECT',
        'violationTypeId': '550e8400-e29b-41d4-a716-000000000070',
        'descriptionOfFact': 'Descrição do fato',
      };

      final result = PatientTranslator.violationReportFromJson(json);
      expect(result.isSuccess, isTrue);
      final report = result.valueOrNull!;

      expect(report.violationTypeId, isNotNull);
      expect(
        report.violationTypeId!.value,
        '550e8400-e29b-41d4-a716-000000000070',
      );
    });

    test('Deve aceitar violationTypeId como null', () {
      final reportId = ViolationReportId.create(
        '550e8400-e29b-41d4-a716-000000000040',
      ).valueOrNull!;

      final report = RightsViolationReport.create(
        id: reportId,
        reportDate: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        victimId: personId,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Descrição do fato',
      ).valueOrNull!;

      expect(report.violationTypeId, isNull);

      final json = PatientTranslator.violationReportToJson(report);
      expect(json.containsKey('violationTypeId'), isTrue);
      expect(json['violationTypeId'], isNull);
    });
  });

  // ─── Full round-trip through Patient aggregate ──────────────────────

  group('PatientTranslator.toJson / fromJson — round-trip completo', () {
    test('Deve preservar IDs de appointments no round-trip', () {
      final appointmentId = AppointmentId.create(
        '550e8400-e29b-41d4-a716-000000000030',
      ).valueOrNull!;
      final appointment = SocialCareAppointment.create(
        id: appointmentId,
        date: TimeStamp.now,
        professionalInChargeId: professionalId,
        type: AppointmentType.officeAppointment,
        summary: 'Teste',
      ).valueOrNull!;

      final patient = Patient.reconstitute(
        id: patientId,
        personId: personId,
        prRelationshipId: prRelationshipId,
        version: 1,
        diagnoses: [],
        familyMembers: [],
        appointments: [appointment],
      );

      final json = PatientTranslator.toJson(patient);
      final result = PatientTranslator.fromJson(json);
      expect(result.isSuccess, isTrue);
      final restored = result.valueOrNull!;

      expect(restored.appointments.first.id.value, appointmentId.value);
    });

    test('Deve preservar IDs de referrals e status no round-trip', () {
      final referralId = ReferralId.create(
        '550e8400-e29b-41d4-a716-000000000060',
      ).valueOrNull!;
      final referral = Referral.create(
        id: referralId,
        date: TimeStamp.fromIso('2025-01-01T00:00:00.000Z').valueOrNull!,
        requestingProfessionalId: professionalId,
        referredPersonId: personId,
        destinationService: DestinationService.creas,
        reason: 'Encaminhamento teste',
      ).valueOrNull!;

      final patient = Patient.reconstitute(
        id: patientId,
        personId: personId,
        prRelationshipId: prRelationshipId,
        version: 1,
        diagnoses: [],
        familyMembers: [],
        referrals: [referral],
      );

      final json = PatientTranslator.toJson(patient);
      final result = PatientTranslator.fromJson(json);
      expect(result.isSuccess, isTrue);
      final restored = result.valueOrNull!;

      expect(restored.referrals.first.id.value, referralId.value);
      expect(restored.referrals.first.status, ReferralStatus.pending);
    });
  });
}
