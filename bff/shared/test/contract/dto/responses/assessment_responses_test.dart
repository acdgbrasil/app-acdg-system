import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('HousingConditionResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'type': 'propria',
        'wallMaterial': 'alvenaria',
        'numberOfRooms': 6,
        'numberOfBedrooms': 3,
        'numberOfBathrooms': 2,
        'waterSupply': 'rede_publica',
        'hasPipedWater': true,
        'electricityAccess': 'rede_publica',
        'sewageDisposal': 'rede_coletora',
        'wasteCollection': 'coleta_regular',
        'accessibilityLevel': 'parcial',
        'isInGeographicRiskArea': false,
        'hasDifficultAccess': false,
        'isInSocialConflictArea': true,
        'hasDiagnosticObservations': false,
      };
      final dto = HousingConditionResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with all risk flags true', () {
      final json = {
        'type': 'alugada',
        'wallMaterial': 'madeira',
        'numberOfRooms': 2,
        'numberOfBedrooms': 1,
        'numberOfBathrooms': 1,
        'waterSupply': 'poco',
        'hasPipedWater': false,
        'electricityAccess': 'gambiarra',
        'sewageDisposal': 'fossa',
        'wasteCollection': 'nenhuma',
        'accessibilityLevel': 'nenhum',
        'isInGeographicRiskArea': true,
        'hasDifficultAccess': true,
        'isInSocialConflictArea': true,
        'hasDiagnosticObservations': true,
      };
      final dto = HousingConditionResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SocialBenefitResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'benefitName': 'Bolsa Familia',
        'amount': 600.0,
        'beneficiaryId': '550e8400-e29b-41d4-a716-446655440000',
        'benefitTypeId': '660e8400-e29b-41d4-a716-446655440001',
        'birthCertificateNumber': '123456',
        'deceasedCpf': '98765432100',
      };
      final dto = SocialBenefitResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'benefitName': 'BPC/LOAS',
        'amount': 1412.0,
        'beneficiaryId': '550e8400-e29b-41d4-a716-446655440000',
        'benefitTypeId': null,
        'birthCertificateNumber': null,
        'deceasedCpf': null,
      };
      final dto = SocialBenefitResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SocioEconomicResponse', () {
    test('should round-trip with nested socialBenefits list', () {
      final json = {
        'totalFamilyIncome': 4500.0,
        'incomePerCapita': 1125.0,
        'receivesSocialBenefit': true,
        'socialBenefits': [
          {
            'benefitName': 'Bolsa Familia',
            'amount': 600.0,
            'beneficiaryId': '550e8400-e29b-41d4-a716-446655440000',
            'benefitTypeId': null,
            'birthCertificateNumber': null,
            'deceasedCpf': null,
          },
        ],
        'mainSourceOfIncome': 'trabalho_informal',
        'hasUnemployed': true,
      };
      final dto = SocioEconomicResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with empty benefits and null income source', () {
      final json = {
        'totalFamilyIncome': 0.0,
        'incomePerCapita': 0.0,
        'receivesSocialBenefit': false,
        'socialBenefits': [],
        'mainSourceOfIncome': null,
        'hasUnemployed': true,
      };
      final dto = SocioEconomicResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('WorkIncomeResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'occupationId': '660e8400-e29b-41d4-a716-446655440001',
        'hasWorkCard': true,
        'monthlyAmount': 2500.0,
      };
      final dto = WorkIncomeResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('WorkAndIncomeResponse', () {
    test('should round-trip with nested incomes and benefits', () {
      final json = {
        'hasRetiredMembers': true,
        'individualIncomes': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440000',
            'occupationId': '660e8400-e29b-41d4-a716-446655440001',
            'hasWorkCard': false,
            'monthlyAmount': 1800.0,
          },
        ],
        'socialBenefits': [
          {
            'benefitName': 'Aposentadoria',
            'amount': 1412.0,
            'beneficiaryId': '770e8400-e29b-41d4-a716-446655440002',
            'benefitTypeId': null,
            'birthCertificateNumber': null,
            'deceasedCpf': null,
          },
        ],
      };
      final dto = WorkAndIncomeResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with empty lists', () {
      final json = {
        'hasRetiredMembers': false,
        'individualIncomes': [],
        'socialBenefits': [],
      };
      final dto = WorkAndIncomeResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('EducationalProfileResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'canReadWrite': true,
        'attendsSchool': false,
        'educationLevelId': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = EducationalProfileResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('ProgramOccurrenceResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'date': '2024-03-15',
        'effectId': '660e8400-e29b-41d4-a716-446655440001',
        'isSuspensionRequested': true,
      };
      final dto = ProgramOccurrenceResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('EducationalStatusResponse', () {
    test('should round-trip with nested profiles and occurrences', () {
      final json = {
        'memberProfiles': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440000',
            'canReadWrite': true,
            'attendsSchool': true,
            'educationLevelId': '660e8400-e29b-41d4-a716-446655440001',
          },
        ],
        'programOccurrences': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440000',
            'date': '2024-06-01',
            'effectId': '770e8400-e29b-41d4-a716-446655440002',
            'isSuspensionRequested': false,
          },
        ],
      };
      final dto = EducationalStatusResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with empty lists', () {
      final json = {'memberProfiles': [], 'programOccurrences': []};
      final dto = EducationalStatusResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('MemberDeficiencyResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'deficiencyTypeId': '660e8400-e29b-41d4-a716-446655440001',
        'needsConstantCare': true,
        'responsibleCaregiverName': 'Ana Paula Silva',
      };
      final dto = MemberDeficiencyResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional caregiver name null', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'deficiencyTypeId': '660e8400-e29b-41d4-a716-446655440001',
        'needsConstantCare': false,
        'responsibleCaregiverName': null,
      };
      final dto = MemberDeficiencyResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PregnantMemberResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440000',
        'monthsGestation': 7,
        'startedPrenatalCare': true,
      };
      final dto = PregnantMemberResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('HealthStatusResponse', () {
    test(
      'should round-trip with nested deficiencies and gestating members',
      () {
        final json = {
          'foodInsecurity': true,
          'deficiencies': [
            {
              'memberId': '550e8400-e29b-41d4-a716-446655440000',
              'deficiencyTypeId': '660e8400-e29b-41d4-a716-446655440001',
              'needsConstantCare': true,
              'responsibleCaregiverName': 'Jose Santos',
            },
          ],
          'gestatingMembers': [
            {
              'memberId': '770e8400-e29b-41d4-a716-446655440002',
              'monthsGestation': 5,
              'startedPrenatalCare': true,
            },
          ],
          'constantCareNeeds': ['medicacao_diaria', 'fisioterapia'],
        };
        final dto = HealthStatusResponse.fromJson(json);
        final result = jsonDecode(jsonEncode(dto));
        expect(result, equals(json));
      },
    );

    test('should round-trip with empty lists', () {
      final json = {
        'foodInsecurity': false,
        'deficiencies': [],
        'gestatingMembers': [],
        'constantCareNeeds': [],
      };
      final dto = HealthStatusResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('CommunitySupportNetworkResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'hasRelativeSupport': true,
        'hasNeighborSupport': false,
        'familyConflicts': 'nenhum',
        'patientParticipatesInGroups': true,
        'familyParticipatesInGroups': true,
        'patientHasAccessToLeisure': false,
        'facesDiscrimination': true,
      };
      final dto = CommunitySupportNetworkResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with all flags false', () {
      final json = {
        'hasRelativeSupport': false,
        'hasNeighborSupport': false,
        'familyConflicts': 'frequente',
        'patientParticipatesInGroups': false,
        'familyParticipatesInGroups': false,
        'patientHasAccessToLeisure': false,
        'facesDiscrimination': false,
      };
      final dto = CommunitySupportNetworkResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SocialHealthSummaryResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'requiresConstantCare': true,
        'hasMobilityImpairment': true,
        'hasRelevantDrugTherapy': true,
        'functionalDependencies': ['alimentacao', 'higiene', 'locomocao'],
      };
      final dto = SocialHealthSummaryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with empty dependencies', () {
      final json = {
        'requiresConstantCare': false,
        'hasMobilityImpairment': false,
        'hasRelevantDrugTherapy': false,
        'functionalDependencies': [],
      };
      final dto = SocialHealthSummaryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
