import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('PersonalDataResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'firstName': 'Maria',
        'lastName': 'Silva',
        'motherName': 'Ana Paula',
        'nationality': 'Brasileira',
        'sex': 'feminino',
        'birthDate': '1990-05-15',
        'socialName': 'Mari',
        'phone': '11999990000',
      };
      final dto = PersonalDataResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'firstName': 'Joao',
        'lastName': 'Santos',
        'motherName': 'Clara Santos',
        'nationality': 'Brasileira',
        'sex': 'masculino',
        'birthDate': '1985-11-20',
        'socialName': null,
        'phone': null,
      };
      final dto = PersonalDataResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('RgDocumentResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'number': '12.345.678-9',
        'issuingState': 'SP',
        'issuingAgency': 'SSP',
        'issueDate': '2010-03-20',
      };
      final dto = RgDocumentResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CnsResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'number': '898001234567890',
        'cpf': '12345678901',
        'qrCode': 'data:image/png;base64,abc123',
      };
      final dto = CnsResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional qrCode null', () {
      final json = {
        'number': '898001234567890',
        'cpf': '12345678901',
        'qrCode': null,
      };
      final dto = CnsResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('CivilDocumentsResponse', () {
    test('should round-trip with all nested objects populated', () {
      final json = {
        'cpf': '12345678901',
        'nis': '12345678901',
        'rgDocument': {
          'number': '12.345.678-9',
          'issuingState': 'RJ',
          'issuingAgency': 'DETRAN',
          'issueDate': '2015-07-10',
        },
        'cns': {
          'number': '898001234567890',
          'cpf': '12345678901',
          'qrCode': null,
        },
      };
      final dto = CivilDocumentsResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with all optional fields null', () {
      final json = {'cpf': null, 'nis': null, 'rgDocument': null, 'cns': null};
      final dto = CivilDocumentsResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('AddressResponse', () {
    test('should round-trip with full address', () {
      final json = {
        'cep': '01001000',
        'isShelter': false,
        'isHomeless': false,
        'residenceLocation': 'urbana',
        'street': 'Rua da Consolacao',
        'neighborhood': 'Centro',
        'number': '1500',
        'complement': 'Apto 42',
        'state': 'SP',
        'city': 'Sao Paulo',
      };
      final dto = AddressResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with shelter address', () {
      final json = {
        'cep': '20040020',
        'isShelter': true,
        'isHomeless': false,
        'residenceLocation': 'urbana',
        'street': 'Av. Rio Branco',
        'neighborhood': 'Centro',
        'number': '100',
        'complement': null,
        'state': 'RJ',
        'city': 'Rio de Janeiro',
      };
      final dto = AddressResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with homeless address', () {
      final json = {
        'cep': null,
        'isShelter': false,
        'isHomeless': true,
        'residenceLocation': 'urbana',
        'street': null,
        'neighborhood': null,
        'number': null,
        'complement': null,
        'state': 'MG',
        'city': 'Belo Horizonte',
      };
      final dto = AddressResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('FamilyMemberResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'personId': '550e8400-e29b-41d4-a716-446655440000',
        'relationshipId': '660e8400-e29b-41d4-a716-446655440001',
        'isPrimaryCaregiver': true,
        'residesWithPatient': true,
        'hasDisability': false,
        'requiredDocuments': ['CPF', 'RG'],
        'birthDate': '1965-08-12',
      };
      final dto = FamilyMemberResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with defaults when booleans omitted', () {
      final json = {
        'personId': '550e8400-e29b-41d4-a716-446655440000',
        'relationshipId': '660e8400-e29b-41d4-a716-446655440001',
        'birthDate': '2000-01-01',
      };
      final dto = FamilyMemberResponse.fromJson(json);
      final result = dto.toJson();
      expect(result['isPrimaryCaregiver'], equals(false));
      expect(result['residesWithPatient'], equals(false));
      expect(result['hasDisability'], equals(false));
      expect(result['requiredDocuments'], equals([]));
    });
  });

  group('DiagnosisResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'icdCode': 'E70.0',
        'description': 'Fenilcetonuria classica',
        'date': '2024-03-15',
      };
      final dto = DiagnosisResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SocialIdentityResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'typeId': '550e8400-e29b-41d4-a716-446655440000',
        'otherDescription': 'Quilombola',
      };
      final dto = SocialIdentityResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional otherDescription null', () {
      final json = {
        'typeId': '550e8400-e29b-41d4-a716-446655440000',
        'otherDescription': null,
      };
      final dto = SocialIdentityResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('DischargeInfoResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'reason': 'Alta medica',
        'notes': 'Paciente estavel',
        'dischargedAt': '2024-03-15T10:30:00Z',
        'dischargedBy': '550e8400-e29b-41d4-a716-446655440000',
      };
      final dto = DischargeInfoResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional notes null', () {
      final json = {
        'reason': 'Transferencia',
        'notes': null,
        'dischargedAt': '2024-03-15T10:30:00Z',
        'dischargedBy': '550e8400-e29b-41d4-a716-446655440000',
      };
      final dto = DischargeInfoResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('WithdrawInfoResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'reason': 'Desistencia voluntaria',
        'notes': 'Paciente solicitou desligamento',
        'withdrawnAt': '2024-03-15T10:30:00Z',
        'withdrawnBy': '550e8400-e29b-41d4-a716-446655440000',
      };
      final dto = WithdrawInfoResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional notes null', () {
      final json = {
        'reason': 'Mudanca de cidade',
        'notes': null,
        'withdrawnAt': '2024-06-01T14:00:00Z',
        'withdrawnBy': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = WithdrawInfoResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PatientSummaryResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'firstName': 'Maria',
        'lastName': 'Silva',
        'fullName': 'Maria Silva',
        'primaryDiagnosis': 'Fenilcetonuria',
        'memberCount': 4,
        'status': 'admitted',
      };
      final dto = PatientSummaryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null and defaults', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'firstName': null,
        'lastName': null,
        'fullName': null,
        'primaryDiagnosis': null,
        'memberCount': 0,
        'status': 'admitted',
      };
      final dto = PatientSummaryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should default status to admitted when omitted', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = PatientSummaryResponse.fromJson(json);
      expect(dto.status, equals('admitted'));
    });

    test('should accept discharged status', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'status': 'discharged',
      };
      final dto = PatientSummaryResponse.fromJson(json);
      expect(dto.status, equals('discharged'));
    });
  });

  group('PatientResponse', () {
    test('should round-trip full aggregate with all nested objects', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'version': 5,
        'status': 'admitted',
        'prRelationshipId': '770e8400-e29b-41d4-a716-446655440002',
        'dischargeInfo': null,
        'withdrawInfo': null,
        'personalData': {
          'firstName': 'Maria',
          'lastName': 'Silva',
          'motherName': 'Ana Paula Silva',
          'nationality': 'Brasileira',
          'sex': 'feminino',
          'birthDate': '1990-05-15',
          'socialName': null,
          'phone': '11999990000',
        },
        'civilDocuments': {
          'cpf': '12345678901',
          'nis': '12345678901',
          'rgDocument': {
            'number': '12.345.678-9',
            'issuingState': 'SP',
            'issuingAgency': 'SSP',
            'issueDate': '2010-03-20',
          },
          'cns': {
            'number': '898001234567890',
            'cpf': '12345678901',
            'qrCode': null,
          },
        },
        'address': {
          'cep': '01001000',
          'isShelter': false,
          'isHomeless': false,
          'residenceLocation': 'urbana',
          'street': 'Rua da Consolacao',
          'neighborhood': 'Centro',
          'number': '1500',
          'complement': 'Apto 42',
          'state': 'SP',
          'city': 'Sao Paulo',
        },
        'socialIdentity': {
          'typeId': '880e8400-e29b-41d4-a716-446655440003',
          'otherDescription': null,
        },
        'familyMembers': [
          {
            'personId': '990e8400-e29b-41d4-a716-446655440004',
            'relationshipId': 'aa0e8400-e29b-41d4-a716-446655440005',
            'isPrimaryCaregiver': true,
            'residesWithPatient': true,
            'hasDisability': false,
            'requiredDocuments': ['CPF'],
            'birthDate': '1965-08-12',
          },
        ],
        'diagnoses': [
          {
            'icdCode': 'E70.0',
            'description': 'Fenilcetonuria classica',
            'date': '2024-01-10',
          },
        ],
        'housingCondition': {
          'type': 'propria',
          'wallMaterial': 'alvenaria',
          'numberOfRooms': 5,
          'numberOfBedrooms': 2,
          'numberOfBathrooms': 1,
          'waterSupply': 'rede_publica',
          'hasPipedWater': true,
          'electricityAccess': 'rede_publica',
          'sewageDisposal': 'rede_coletora',
          'wasteCollection': 'coleta_regular',
          'accessibilityLevel': 'total',
          'isInGeographicRiskArea': false,
          'hasDifficultAccess': false,
          'isInSocialConflictArea': false,
          'hasDiagnosticObservations': true,
        },
        'socioeconomicSituation': {
          'totalFamilyIncome': 3500.0,
          'incomePerCapita': 875.0,
          'receivesSocialBenefit': true,
          'socialBenefits': [
            {
              'benefitName': 'Bolsa Familia',
              'amount': 600.0,
              'beneficiaryId': 'bb0e8400-e29b-41d4-a716-446655440006',
              'benefitTypeId': 'cc0e8400-e29b-41d4-a716-446655440007',
              'birthCertificateNumber': null,
              'deceasedCpf': null,
            },
          ],
          'mainSourceOfIncome': 'trabalho_formal',
          'hasUnemployed': false,
        },
        'workAndIncome': {
          'hasRetiredMembers': false,
          'individualIncomes': [
            {
              'memberId': '990e8400-e29b-41d4-a716-446655440004',
              'occupationId': 'dd0e8400-e29b-41d4-a716-446655440008',
              'hasWorkCard': true,
              'monthlyAmount': 2900.0,
            },
          ],
          'socialBenefits': [],
        },
        'educationalStatus': {
          'memberProfiles': [
            {
              'memberId': '990e8400-e29b-41d4-a716-446655440004',
              'canReadWrite': true,
              'attendsSchool': false,
              'educationLevelId': 'ee0e8400-e29b-41d4-a716-446655440009',
            },
          ],
          'programOccurrences': [],
        },
        'healthStatus': {
          'foodInsecurity': false,
          'deficiencies': [
            {
              'memberId': '550e8400-e29b-41d4-a716-446655440000',
              'deficiencyTypeId': 'ff0e8400-e29b-41d4-a716-446655440010',
              'needsConstantCare': true,
              'responsibleCaregiverName': 'Ana Paula Silva',
            },
          ],
          'gestatingMembers': [],
          'constantCareNeeds': ['medicacao_diaria'],
        },
        'communitySupportNetwork': {
          'hasRelativeSupport': true,
          'hasNeighborSupport': false,
          'familyConflicts': 'nenhum',
          'patientParticipatesInGroups': false,
          'familyParticipatesInGroups': true,
          'patientHasAccessToLeisure': true,
          'facesDiscrimination': false,
        },
        'socialHealthSummary': {
          'requiresConstantCare': true,
          'hasMobilityImpairment': false,
          'hasRelevantDrugTherapy': true,
          'functionalDependencies': ['alimentacao', 'higiene'],
        },
        'appointments': [
          {
            'id': '110e8400-e29b-41d4-a716-446655440011',
            'date': '2024-03-15T10:30:00Z',
            'professionalId': '220e8400-e29b-41d4-a716-446655440012',
            'type': 'atendimento_individual',
            'summary': 'Avaliacao inicial do paciente',
            'actionPlan': 'Agendar exames complementares',
          },
        ],
        'intakeInfo': {
          'ingressTypeId': '330e8400-e29b-41d4-a716-446655440013',
          'originName': 'UBS Central',
          'originContact': '1133334444',
          'serviceReason': 'Diagnostico recente de doenca rara',
          'linkedSocialPrograms': [
            {
              'programId': '440e8400-e29b-41d4-a716-446655440014',
              'observation': 'Beneficio ativo',
            },
          ],
        },
        'placementHistory': {
          'individualPlacements': [
            {
              'id': '550e8400-e29b-41d4-a716-446655440015',
              'memberId': '990e8400-e29b-41d4-a716-446655440004',
              'startDate': '2023-01-01',
              'endDate': '2023-06-30',
              'reason': 'Acolhimento institucional temporario',
            },
          ],
          'homeLossReport': null,
          'thirdPartyGuardReport': 'Guarda concedida a avo materna',
          'adultInPrison': false,
          'adolescentInInternment': false,
        },
        'violationReports': [
          {
            'id': '660e8400-e29b-41d4-a716-446655440016',
            'reportDate': '2024-02-20',
            'incidentDate': '2024-02-18',
            'victimId': '550e8400-e29b-41d4-a716-446655440000',
            'violationType': 'negligencia',
            'descriptionOfFact': 'Falta de acesso a medicacao',
            'actionsTaken': 'Encaminhamento ao CRAS',
          },
        ],
        'referrals': [
          {
            'id': '770e8400-e29b-41d4-a716-446655440017',
            'date': '2024-03-01',
            'professionalId': '220e8400-e29b-41d4-a716-446655440012',
            'referredPersonId': '550e8400-e29b-41d4-a716-446655440000',
            'destinationService': 'CRAS Regional Norte',
            'reason': 'Acompanhamento socioassistencial',
            'status': 'pendente',
          },
        ],
        'computedAnalytics': {
          'housing': {'density': 2.5, 'isOvercrowded': false},
          'financial': {
            'totalWorkIncome': 2900.0,
            'perCapitaWorkIncome': 725.0,
            'totalGlobalIncome': 3500.0,
            'perCapitaGlobalIncome': 875.0,
          },
          'ageProfile': {
            'range0to6': 0,
            'range7to14': 0,
            'range15to17': 0,
            'range18to29': 1,
            'range30to59': 1,
            'range60to64': 1,
            'range65to69': 0,
            'range70Plus': 0,
            'totalMembers': 3,
          },
          'educationalVulnerabilities': {
            'notInSchool0to5': 0,
            'notInSchool6to14': 0,
            'notInSchool15to17': 0,
            'illiteracy10to17': 0,
            'illiteracy18to59': 0,
            'illiteracy60Plus': 0,
          },
        },
      };

      final dto = PatientResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
    });

    test('should round-trip minimal patient with only required fields', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'version': 0,
        'status': 'admitted',
        'prRelationshipId': null,
        'dischargeInfo': null,
        'withdrawInfo': null,
        'personalData': null,
        'civilDocuments': null,
        'address': null,
        'socialIdentity': null,
        'familyMembers': [],
        'diagnoses': [],
        'housingCondition': null,
        'socioeconomicSituation': null,
        'workAndIncome': null,
        'educationalStatus': null,
        'healthStatus': null,
        'communitySupportNetwork': null,
        'socialHealthSummary': null,
        'appointments': [],
        'intakeInfo': null,
        'placementHistory': null,
        'violationReports': [],
        'referrals': [],
        'computedAnalytics': null,
      };

      final dto = PatientResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
    });

    test('should read diagnoses from initialDiagnoses key', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'initialDiagnoses': [
          {
            'icdCode': 'Q90.0',
            'description': 'Sindrome de Down',
            'date': '2024-01-01',
          },
        ],
      };
      final dto = PatientResponse.fromJson(json);
      expect(dto.diagnoses, hasLength(1));
      expect(dto.diagnoses[0].icdCode, equals('Q90.0'));
    });

    test('should default version to 0 and status to admitted when omitted', () {
      final json = {
        'patientId': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = PatientResponse.fromJson(json);
      expect(dto.version, equals(0));
      expect(dto.status, equals('admitted'));
    });
  });
}
