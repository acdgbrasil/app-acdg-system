import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('RegisterPatientRequest', () {
    test('should round-trip with all nested drafts populated', () {
      final json = {
        'personId': '550e8400-e29b-41d4-a716-446655440000',
        'initialDiagnoses': [
          {
            'icdCode': 'Q90.0',
            'date': '2024-01-15',
            'description': 'Sindrome de Down por nao-disjuncao',
          },
          {
            'icdCode': 'E70.0',
            'date': '2023-06-20',
            'description': 'Fenilcetonuria classica',
          },
        ],
        'prRelationshipId': '660e8400-e29b-41d4-a716-446655440001',
        'personalData': {
          'firstName': 'Maria',
          'lastName': 'Silva',
          'motherName': 'Ana Paula Silva',
          'nationality': 'Brasileira',
          'sex': 'feminino',
          'birthDate': '2020-03-10',
          'socialName': 'Mari',
          'phone': '11999990000',
        },
        'civilDocuments': {
          'cpf': '12345678901',
          'nis': '12345678901',
          'rgDocument': {
            'number': '12.345.678-9',
            'issuingState': 'SP',
            'issuingAgency': 'SSP',
            'issueDate': '2022-05-10',
          },
          'cns': {
            'number': '898001234567890',
            'cpf': '12345678901',
            'qrCode': 'data:image/png;base64,abc123',
          },
        },
        'address': {
          'cep': '01001000',
          'isShelter': false,
          'isHomeless': false,
          'residenceLocation': 'urbana',
          'street': 'Rua das Flores',
          'neighborhood': 'Centro',
          'number': '123',
          'complement': 'Apto 4B',
          'state': 'SP',
          'city': 'Sao Paulo',
        },
        'socialIdentity': {
          'typeId': '770e8400-e29b-41d4-a716-446655440002',
          'description': 'Quilombola',
        },
      };
      final dto = RegisterPatientRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with only required fields', () {
      final json = {
        'personId': '550e8400-e29b-41d4-a716-446655440000',
        'initialDiagnoses': [
          {
            'icdCode': 'Q90.0',
            'date': '2024-01-15',
            'description': 'Sindrome de Down',
          },
        ],
        'prRelationshipId': '660e8400-e29b-41d4-a716-446655440001',
        'personalData': null,
        'civilDocuments': null,
        'address': null,
        'socialIdentity': null,
      };
      final dto = RegisterPatientRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('DiagnosisDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'icdCode': 'G71.0',
        'date': '2025-02-28',
        'description': 'Distrofia muscular',
      };
      final dto = DiagnosisDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PersonalDataDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'firstName': 'Joao',
        'lastName': 'Santos',
        'motherName': 'Clara Santos',
        'nationality': 'Brasileira',
        'sex': 'masculino',
        'birthDate': '1985-11-20',
        'socialName': 'Jo',
        'phone': '21988880000',
      };
      final dto = PersonalDataDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'firstName': 'Ana',
        'lastName': 'Oliveira',
        'motherName': 'Rosa Oliveira',
        'nationality': 'Brasileira',
        'sex': 'feminino',
        'birthDate': '1995-07-04',
        'socialName': null,
        'phone': null,
      };
      final dto = PersonalDataDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CivilDocumentsDraftDto', () {
    test('should round-trip with all nested documents', () {
      final json = {
        'cpf': '98765432100',
        'nis': '11122233344',
        'rgDocument': {
          'number': '44.555.666-7',
          'issuingState': 'RJ',
          'issuingAgency': 'DETRAN',
          'issueDate': '2018-09-15',
        },
        'cns': {
          'number': '700012345678901',
          'cpf': '98765432100',
          'qrCode': null,
        },
      };
      final dto = CivilDocumentsDraftDto.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with all fields null', () {
      final json = {'cpf': null, 'nis': null, 'rgDocument': null, 'cns': null};
      final dto = CivilDocumentsDraftDto.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('RgDocumentDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'number': '11.222.333-4',
        'issuingState': 'MG',
        'issuingAgency': 'SSP',
        'issueDate': '2015-12-01',
      };
      final dto = RgDocumentDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CnsDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'number': '898007654321098',
        'cpf': '12345678901',
        'qrCode': 'data:image/png;base64,xyz789',
      };
      final dto = CnsDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with qrCode null', () {
      final json = {
        'number': '898007654321098',
        'cpf': '12345678901',
        'qrCode': null,
      };
      final dto = CnsDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('AddressDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'cep': '01001000',
        'isShelter': false,
        'isHomeless': false,
        'residenceLocation': 'urbana',
        'street': 'Av. Paulista',
        'neighborhood': 'Bela Vista',
        'number': '1578',
        'complement': 'Sala 301',
        'state': 'SP',
        'city': 'Sao Paulo',
      };
      final dto = AddressDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'cep': null,
        'isShelter': true,
        'isHomeless': false,
        'residenceLocation': 'rural',
        'street': null,
        'neighborhood': null,
        'number': null,
        'complement': null,
        'state': 'AM',
        'city': 'Manaus',
      };
      final dto = AddressDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should default isHomeless to false when absent from JSON', () {
      final json = {
        'isShelter': false,
        'residenceLocation': 'urbana',
        'state': 'BA',
        'city': 'Salvador',
      };
      final dto = AddressDraftDto.fromJson(json);
      expect(dto.isHomeless, isFalse);
    });
  });

  group('SocialIdentityDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'typeId': '880e8400-e29b-41d4-a716-446655440003',
        'description': 'Comunidade indigena Xavante',
      };
      final dto = SocialIdentityDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with description null', () {
      final json = {
        'typeId': '880e8400-e29b-41d4-a716-446655440003',
        'description': null,
      };
      final dto = SocialIdentityDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('AddFamilyMemberRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberPersonId': '550e8400-e29b-41d4-a716-446655440010',
        'relationship': 'mae',
        'isResiding': true,
        'isCaregiver': true,
        'hasDisability': false,
        'requiredDocuments': ['RG', 'CPF', 'Comprovante de residencia'],
        'birthDate': '1975-08-22',
        'prRelationshipId': '660e8400-e29b-41d4-a716-446655440011',
      };
      final dto = AddFamilyMemberRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with empty requiredDocuments', () {
      final json = {
        'memberPersonId': '550e8400-e29b-41d4-a716-446655440010',
        'relationship': 'pai',
        'isResiding': false,
        'isCaregiver': false,
        'hasDisability': true,
        'requiredDocuments': <String>[],
        'birthDate': '1970-01-01',
        'prRelationshipId': '660e8400-e29b-41d4-a716-446655440011',
      };
      final dto = AddFamilyMemberRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('AssignPrimaryCaregiverRequest', () {
    test('should round-trip with memberPersonId', () {
      final json = {'memberPersonId': '550e8400-e29b-41d4-a716-446655440020'};
      final dto = AssignPrimaryCaregiverRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateSocialIdentityRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'typeId': '990e8400-e29b-41d4-a716-446655440004',
        'description': 'Comunidade ribeirinha',
      };
      final dto = UpdateSocialIdentityRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with description null', () {
      final json = {
        'typeId': '990e8400-e29b-41d4-a716-446655440004',
        'description': null,
      };
      final dto = UpdateSocialIdentityRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('DischargePatientRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'reason': 'Alta por melhora clinica',
        'notes': 'Paciente apresentou evolucao satisfatoria',
      };
      final dto = DischargePatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with notes null', () {
      final json = {
        'reason': 'Transferencia para outro servico',
        'notes': null,
      };
      final dto = DischargePatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('ReadmitPatientRequest', () {
    test('should round-trip with notes populated', () {
      final json = {'notes': 'Readmissao apos recidiva dos sintomas'};
      final dto = ReadmitPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with notes null', () {
      final json = {'notes': null};
      final dto = ReadmitPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('WithdrawPatientRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'reason': 'Desistencia voluntaria',
        'notes': 'Familia optou por tratamento em outra cidade',
      };
      final dto = WithdrawPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with notes null', () {
      final json = {'reason': 'Mudanca de municipio', 'notes': null};
      final dto = WithdrawPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
