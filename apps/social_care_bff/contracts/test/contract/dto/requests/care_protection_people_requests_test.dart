import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Care
  // ---------------------------------------------------------------------------

  group('RegisterAppointmentRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'professionalId': '550e8400-e29b-41d4-a716-446655440100',
        'summary': 'Atendimento inicial com avaliacao socioeconomica completa',
        'actionPlan': 'Encaminhar para CRAS e solicitar inclusao no CadUnico',
        'date': '2026-04-16T14:30:00Z',
        'type': 'visita_domiciliar',
      };
      final dto = RegisterAppointmentRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only required field', () {
      final json = {
        'professionalId': '550e8400-e29b-41d4-a716-446655440100',
        'summary': null,
        'actionPlan': null,
        'date': null,
        'type': null,
      };
      final dto = RegisterAppointmentRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('ProgramLinkDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'programId': 'cc0e8400-e29b-41d4-a716-446655440110',
        'observation': 'Familia ja inscrita desde 2023',
      };
      final dto = ProgramLinkDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with observation null', () {
      final json = {
        'programId': 'cc0e8400-e29b-41d4-a716-446655440110',
        'observation': null,
      };
      final dto = ProgramLinkDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('RegisterIntakeInfoRequest', () {
    test('should round-trip with all fields and linked programs', () {
      final json = {
        'ingressTypeId': 'dd0e8400-e29b-41d4-a716-446655440120',
        'originName': 'CRAS Centro',
        'originContact': '(11) 3333-4444',
        'serviceReason': 'Familia em situacao de vulnerabilidade social',
        'linkedSocialPrograms': [
          {
            'programId': 'ee0e8400-e29b-41d4-a716-446655440130',
            'observation': 'Programa Crianca Feliz',
          },
          {
            'programId': 'ff0e8400-e29b-41d4-a716-446655440131',
            'observation': null,
          },
        ],
      };
      final dto = RegisterIntakeInfoRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with minimal fields', () {
      final json = {
        'ingressTypeId': 'dd0e8400-e29b-41d4-a716-446655440120',
        'originName': null,
        'originContact': null,
        'serviceReason': 'Demanda espontanea',
        'linkedSocialPrograms': <Map<String, dynamic>>[],
      };
      final dto = RegisterIntakeInfoRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  // ---------------------------------------------------------------------------
  // Protection
  // ---------------------------------------------------------------------------

  group('RegistryDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440200',
        'startDate': '2025-01-10',
        'endDate': '2025-06-30',
        'reason': 'Medida protetiva judicial',
      };
      final dto = RegistryDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with endDate null', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440200',
        'startDate': '2026-02-01',
        'endDate': null,
        'reason': 'Acolhimento institucional em andamento',
      };
      final dto = RegistryDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CollectiveDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'homeLossReport': 'Familia perdeu moradia em enchente de janeiro 2026',
        'thirdPartyGuardReport': 'Avo materna possui guarda provisoria',
      };
      final dto = CollectiveDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with all fields null', () {
      final json = {'homeLossReport': null, 'thirdPartyGuardReport': null};
      final dto = CollectiveDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SeparationDraftDto', () {
    test('should round-trip with all fields true', () {
      final json = {'adultInPrison': true, 'adolescentInInternment': true};
      final dto = SeparationDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with defaults (both false)', () {
      final json = {'adultInPrison': false, 'adolescentInInternment': false};
      final dto = SeparationDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdatePlacementHistoryRequest', () {
    test('should round-trip with all nested objects populated', () {
      final json = {
        'registries': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440200',
            'startDate': '2025-01-10',
            'endDate': '2025-06-30',
            'reason': 'Medida protetiva',
          },
        ],
        'collectiveSituations': {
          'homeLossReport': 'Enchente destruiu moradia',
          'thirdPartyGuardReport': null,
        },
        'separationChecklist': {
          'adultInPrison': true,
          'adolescentInInternment': false,
        },
      };
      final dto = UpdatePlacementHistoryRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with minimal fields', () {
      final json = {
        'registries': <Map<String, dynamic>>[],
        'collectiveSituations': null,
        'separationChecklist': null,
      };
      final dto = UpdatePlacementHistoryRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('ReportRightsViolationRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'victimId': '550e8400-e29b-41d4-a716-446655440300',
        'violationType': 'negligencia',
        'violationTypeId': 'aa0e8400-e29b-41d4-a716-446655440301',
        'reportDate': '2026-04-10',
        'incidentDate': '2026-04-05',
        'descriptionOfFact':
            'Crianca encontrada em situacao de abandono no domicilio',
        'actionsTaken':
            'Acionado Conselho Tutelar e encaminhamento para abrigo',
      };
      final dto = ReportRightsViolationRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only required fields', () {
      final json = {
        'victimId': '550e8400-e29b-41d4-a716-446655440300',
        'violationType': 'violencia_fisica',
        'violationTypeId': null,
        'reportDate': null,
        'incidentDate': null,
        'descriptionOfFact': 'Relato de agressao fisica contra menor',
        'actionsTaken': null,
      };
      final dto = ReportRightsViolationRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CreateReferralRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'referredPersonId': '550e8400-e29b-41d4-a716-446655440400',
        'professionalId': '660e8400-e29b-41d4-a716-446655440401',
        'destinationService': 'CAPS Infantojuvenil',
        'reason': 'Necessidade de acompanhamento psicologico especializado',
        'date': '2026-04-16',
      };
      final dto = CreateReferralRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only required fields', () {
      final json = {
        'referredPersonId': '550e8400-e29b-41d4-a716-446655440400',
        'professionalId': null,
        'destinationService': 'UBS Vila Maria',
        'reason': 'Encaminhamento para consulta medica',
        'date': null,
      };
      final dto = CreateReferralRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  // ---------------------------------------------------------------------------
  // People
  // ---------------------------------------------------------------------------

  group('RegisterPersonRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'fullName': 'Maria da Silva Santos',
        'birthDate': '1990-05-15',
        'cpf': '12345678901',
      };
      final dto = RegisterPersonRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with cpf null', () {
      final json = {
        'fullName': 'Joao Pedro Oliveira',
        'birthDate': '2022-08-20',
        'cpf': null,
      };
      final dto = RegisterPersonRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('RegisterPersonWithLoginRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'fullName': 'Dra. Fernanda Costa',
        'birthDate': '1985-03-22',
        'email': 'fernanda.costa@acdg.org.br',
        'cpf': '98765432100',
        'initialPassword': 'TempPass123!',
      };
      final dto = RegisterPersonWithLoginRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only required fields', () {
      final json = {
        'fullName': 'Carlos Eduardo Lima',
        'birthDate': '1992-11-10',
        'email': 'carlos.lima@acdg.org.br',
        'cpf': null,
        'initialPassword': null,
      };
      final dto = RegisterPersonWithLoginRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('AssignRoleRequest', () {
    test('should round-trip with social_worker role', () {
      final json = {'system': 'social_care', 'role': 'social_worker'};
      final dto = AssignRoleRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with admin role', () {
      final json = {'system': 'social_care', 'role': 'admin'};
      final dto = AssignRoleRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
