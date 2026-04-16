import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('UpdateHousingConditionRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'type': 'apartamento',
        'wallMaterial': 'alvenaria',
        'numberOfRooms': 5,
        'numberOfBedrooms': 2,
        'numberOfBathrooms': 1,
        'waterSupply': 'rede_publica',
        'hasPipedWater': true,
        'electricityAccess': 'regular',
        'sewageDisposal': 'rede_coletora',
        'wasteCollection': 'coleta_regular',
        'accessibilityLevel': 'parcial',
        'isInGeographicRiskArea': false,
        'hasDifficultAccess': false,
        'isInSocialConflictArea': true,
        'hasDiagnosticObservations': true,
      };
      final dto = UpdateHousingConditionRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with all booleans false and minimal values', () {
      final json = {
        'type': 'barraco',
        'wallMaterial': 'madeira',
        'numberOfRooms': 1,
        'numberOfBedrooms': 0,
        'numberOfBathrooms': 0,
        'waterSupply': 'poco',
        'hasPipedWater': false,
        'electricityAccess': 'irregular',
        'sewageDisposal': 'fossa',
        'wasteCollection': 'queima',
        'accessibilityLevel': 'nenhuma',
        'isInGeographicRiskArea': false,
        'hasDifficultAccess': false,
        'isInSocialConflictArea': false,
        'hasDiagnosticObservations': false,
      };
      final dto = UpdateHousingConditionRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('SocialBenefitDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'benefitName': 'Bolsa Familia',
        'amount': 600.0,
        'beneficiaryId': '550e8400-e29b-41d4-a716-446655440030',
        'benefitTypeId': '770e8400-e29b-41d4-a716-446655440031',
        'birthCertificateNumber': '123456789012',
        'deceasedCpf': '98765432100',
      };
      final dto = SocialBenefitDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'benefitName': 'BPC',
        'amount': 1412.0,
        'beneficiaryId': '550e8400-e29b-41d4-a716-446655440030',
        'benefitTypeId': null,
        'birthCertificateNumber': null,
        'deceasedCpf': null,
      };
      final dto = SocialBenefitDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateSocioEconomicSituationRequest', () {
    test('should round-trip with all fields and social benefits', () {
      final json = {
        'totalFamilyIncome': 3500.50,
        'incomePerCapita': 875.13,
        'receivesSocialBenefit': true,
        'socialBenefits': [
          {
            'benefitName': 'Bolsa Familia',
            'amount': 600.0,
            'beneficiaryId': '550e8400-e29b-41d4-a716-446655440030',
            'benefitTypeId': '770e8400-e29b-41d4-a716-446655440031',
            'birthCertificateNumber': null,
            'deceasedCpf': null,
          },
        ],
        'mainSourceOfIncome': 'trabalho_informal',
        'hasUnemployed': true,
      };
      final dto = UpdateSocioEconomicSituationRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with empty social benefits', () {
      final json = {
        'totalFamilyIncome': 1500.0,
        'incomePerCapita': 500.0,
        'receivesSocialBenefit': false,
        'socialBenefits': <Map<String, dynamic>>[],
        'mainSourceOfIncome': 'salario',
        'hasUnemployed': false,
      };
      final dto = UpdateSocioEconomicSituationRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('IncomeDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440040',
        'occupationId': '880e8400-e29b-41d4-a716-446655440041',
        'hasWorkCard': true,
        'monthlyAmount': 2800.0,
      };
      final dto = IncomeDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateWorkAndIncomeRequest', () {
    test('should round-trip with all nested lists populated', () {
      final json = {
        'individualIncomes': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440040',
            'occupationId': '880e8400-e29b-41d4-a716-446655440041',
            'hasWorkCard': true,
            'monthlyAmount': 2800.0,
          },
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440042',
            'occupationId': '880e8400-e29b-41d4-a716-446655440043',
            'hasWorkCard': false,
            'monthlyAmount': 1200.0,
          },
        ],
        'socialBenefits': [
          {
            'benefitName': 'BPC',
            'amount': 1412.0,
            'beneficiaryId': '550e8400-e29b-41d4-a716-446655440044',
            'benefitTypeId': null,
            'birthCertificateNumber': null,
            'deceasedCpf': null,
          },
        ],
        'hasRetiredMembers': true,
      };
      final dto = UpdateWorkAndIncomeRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with empty lists', () {
      final json = {
        'individualIncomes': <Map<String, dynamic>>[],
        'socialBenefits': <Map<String, dynamic>>[],
        'hasRetiredMembers': false,
      };
      final dto = UpdateWorkAndIncomeRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('ProfileDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440050',
        'canReadWrite': true,
        'attendsSchool': true,
        'educationLevelId': '990e8400-e29b-41d4-a716-446655440051',
      };
      final dto = ProfileDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('OccurrenceDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440060',
        'date': '2026-03-15',
        'effectId': 'aa0e8400-e29b-41d4-a716-446655440061',
        'isSuspensionRequested': true,
      };
      final dto = OccurrenceDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateEducationalStatusRequest', () {
    test('should round-trip with populated profiles and occurrences', () {
      final json = {
        'memberProfiles': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440050',
            'canReadWrite': true,
            'attendsSchool': true,
            'educationLevelId': '990e8400-e29b-41d4-a716-446655440051',
          },
        ],
        'programOccurrences': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440060',
            'date': '2026-03-15',
            'effectId': 'aa0e8400-e29b-41d4-a716-446655440061',
            'isSuspensionRequested': false,
          },
        ],
      };
      final dto = UpdateEducationalStatusRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with empty lists', () {
      final json = {
        'memberProfiles': <Map<String, dynamic>>[],
        'programOccurrences': <Map<String, dynamic>>[],
      };
      final dto = UpdateEducationalStatusRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('DeficiencyDraftDto', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440070',
        'deficiencyTypeId': 'bb0e8400-e29b-41d4-a716-446655440071',
        'needsConstantCare': true,
        'responsibleCaregiverName': 'Ana Paula Silva',
      };
      final dto = DeficiencyDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with responsibleCaregiverName null', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440070',
        'deficiencyTypeId': 'bb0e8400-e29b-41d4-a716-446655440071',
        'needsConstantCare': false,
        'responsibleCaregiverName': null,
      };
      final dto = DeficiencyDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PregnantDraftDto', () {
    test('should round-trip with all fields', () {
      final json = {
        'memberId': '550e8400-e29b-41d4-a716-446655440080',
        'monthsGestation': 7,
        'startedPrenatalCare': true,
      };
      final dto = PregnantDraftDto.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateHealthStatusRequest', () {
    test('should round-trip with all nested lists populated', () {
      final json = {
        'deficiencies': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440070',
            'deficiencyTypeId': 'bb0e8400-e29b-41d4-a716-446655440071',
            'needsConstantCare': true,
            'responsibleCaregiverName': 'Ana Paula',
          },
        ],
        'gestatingMembers': [
          {
            'memberId': '550e8400-e29b-41d4-a716-446655440080',
            'monthsGestation': 5,
            'startedPrenatalCare': true,
          },
        ],
        'constantCareNeeds': ['fisioterapia', 'fonoaudiologia'],
        'foodInsecurity': true,
      };
      final dto = UpdateHealthStatusRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with empty lists and minimal fields', () {
      final json = {
        'deficiencies': <Map<String, dynamic>>[],
        'gestatingMembers': <Map<String, dynamic>>[],
        'constantCareNeeds': <String>[],
        'foodInsecurity': false,
      };
      final dto = UpdateHealthStatusRequest.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('UpdateCommunitySupportNetworkRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'hasRelativeSupport': true,
        'hasNeighborSupport': false,
        'familyConflicts': 'conflitos_leves',
        'patientParticipatesInGroups': true,
        'familyParticipatesInGroups': false,
        'patientHasAccessToLeisure': true,
        'facesDiscrimination': false,
      };
      final dto = UpdateCommunitySupportNetworkRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with all booleans in opposite state', () {
      final json = {
        'hasRelativeSupport': false,
        'hasNeighborSupport': true,
        'familyConflicts': 'sem_conflitos',
        'patientParticipatesInGroups': false,
        'familyParticipatesInGroups': true,
        'patientHasAccessToLeisure': false,
        'facesDiscrimination': true,
      };
      final dto = UpdateCommunitySupportNetworkRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('UpdateSocialHealthSummaryRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'requiresConstantCare': true,
        'hasMobilityImpairment': true,
        'hasRelevantDrugTherapy': false,
        'functionalDependencies': ['alimentacao', 'higiene', 'locomocao'],
      };
      final dto = UpdateSocialHealthSummaryRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with empty functionalDependencies', () {
      final json = {
        'requiresConstantCare': false,
        'hasMobilityImpairment': false,
        'hasRelevantDrugTherapy': false,
        'functionalDependencies': <String>[],
      };
      final dto = UpdateSocialHealthSummaryRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
