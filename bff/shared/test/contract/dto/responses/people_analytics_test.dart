import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('PersonResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'fullName': 'Maria Clara Silva',
        'birthDate': '1990-05-15',
        'cpf': '12345678901',
      };
      final dto = PersonResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'fullName': 'Joao Pedro Santos',
        'birthDate': null,
        'cpf': null,
      };
      final dto = PersonResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PersonRoleResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'system': 'social-care',
        'role': 'social_worker',
        'active': true,
        'fullName': 'Fernanda Oliveira',
        'assignedAt': '2024-01-15T08:00:00Z',
      };
      final dto = PersonRoleResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'system': 'social-care',
        'role': 'owner',
        'active': false,
        'fullName': null,
        'assignedAt': null,
      };
      final dto = PersonRoleResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('HousingAnalyticsResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {'density': 3.5, 'isOvercrowded': true};
      final dto = HousingAnalyticsResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields omitted', () {
      final json = <String, dynamic>{};
      final dto = HousingAnalyticsResponse.fromJson(json);
      expect(dto.density, equals(0));
      expect(dto.isOvercrowded, equals(false));
    });
  });

  group('FinancialIndicatorsResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'totalWorkIncome': 5000.0,
        'perCapitaWorkIncome': 1250.0,
        'totalGlobalIncome': 6200.0,
        'perCapitaGlobalIncome': 1550.0,
      };
      final dto = FinancialIndicatorsResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields omitted', () {
      final json = <String, dynamic>{};
      final dto = FinancialIndicatorsResponse.fromJson(json);
      expect(dto.totalWorkIncome, equals(0));
      expect(dto.perCapitaWorkIncome, equals(0));
      expect(dto.totalGlobalIncome, equals(0));
      expect(dto.perCapitaGlobalIncome, equals(0));
    });
  });

  group('AgeProfileResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'range0to6': 1,
        'range7to14': 2,
        'range15to17': 0,
        'range18to29': 1,
        'range30to59': 2,
        'range60to64': 0,
        'range65to69': 1,
        'range70Plus': 0,
        'totalMembers': 7,
      };
      final dto = AgeProfileResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields omitted', () {
      final json = <String, dynamic>{};
      final dto = AgeProfileResponse.fromJson(json);
      expect(dto.totalMembers, equals(0));
      expect(dto.range0to6, equals(0));
    });
  });

  group('EducationalVulnerabilityResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'notInSchool0to5': 1,
        'notInSchool6to14': 0,
        'notInSchool15to17': 1,
        'illiteracy10to17': 0,
        'illiteracy18to59': 2,
        'illiteracy60Plus': 1,
      };
      final dto = EducationalVulnerabilityResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields omitted', () {
      final json = <String, dynamic>{};
      final dto = EducationalVulnerabilityResponse.fromJson(json);
      expect(dto.notInSchool0to5, equals(0));
      expect(dto.illiteracy60Plus, equals(0));
    });
  });

  group('ComputedAnalyticsResponse', () {
    test('should round-trip with all nested analytics populated', () {
      final json = {
        'housing': {'density': 2.0, 'isOvercrowded': false},
        'financial': {
          'totalWorkIncome': 3000.0,
          'perCapitaWorkIncome': 750.0,
          'totalGlobalIncome': 4000.0,
          'perCapitaGlobalIncome': 1000.0,
        },
        'ageProfile': {
          'range0to6': 0,
          'range7to14': 1,
          'range15to17': 0,
          'range18to29': 1,
          'range30to59': 1,
          'range60to64': 0,
          'range65to69': 0,
          'range70Plus': 1,
          'totalMembers': 4,
        },
        'educationalVulnerabilities': {
          'notInSchool0to5': 0,
          'notInSchool6to14': 0,
          'notInSchool15to17': 0,
          'illiteracy10to17': 0,
          'illiteracy18to59': 0,
          'illiteracy60Plus': 1,
        },
      };
      final dto = ComputedAnalyticsResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with all nested analytics null', () {
      final json = {
        'housing': null,
        'financial': null,
        'ageProfile': null,
        'educationalVulnerabilities': null,
      };
      final dto = ComputedAnalyticsResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('IndicatorRowResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'dimensions': {'sexo': 'feminino', 'faixa_etaria': '18-29'},
        'count': 42,
        'period': '2024-Q1',
      };
      final dto = IndicatorRowResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional period null', () {
      final json = {
        'dimensions': {'status': 'admitted'},
        'count': 15,
        'period': null,
      };
      final dto = IndicatorRowResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('IndicatorMetaResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'total': 100,
        'suppressedGroups': 3,
        'generalizationLevel': 'municipio',
      };
      final dto = IndicatorMetaResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional generalizationLevel null', () {
      final json = {
        'total': 50,
        'suppressedGroups': 0,
        'generalizationLevel': null,
      };
      final dto = IndicatorMetaResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields omitted', () {
      final json = <String, dynamic>{};
      final dto = IndicatorMetaResponse.fromJson(json);
      expect(dto.total, equals(0));
      expect(dto.suppressedGroups, equals(0));
    });
  });

  group('IndicatorResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'axis': 'diagnostico_por_sexo',
        'rows': [
          {
            'dimensions': {'sexo': 'feminino'},
            'count': 25,
            'period': '2024-Q1',
          },
          {
            'dimensions': {'sexo': 'masculino'},
            'count': 18,
            'period': '2024-Q1',
          },
        ],
        'meta': {
          'total': 43,
          'suppressedGroups': 0,
          'generalizationLevel': null,
        },
      };
      final dto = IndicatorResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with empty rows and null meta', () {
      final json = {'axis': 'vazio', 'rows': [], 'meta': null};
      final dto = IndicatorResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('AxisMetadataResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'name': 'diagnostico_por_faixa_etaria',
        'description': 'Distribuicao de diagnosticos por faixa etaria',
        'availableDimensions': ['faixa_etaria', 'sexo', 'municipio'],
        'availablePeriods': ['2023-Q4', '2024-Q1', '2024-Q2'],
      };
      final dto = AxisMetadataResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null and empty lists', () {
      final json = {
        'name': 'contagem_simples',
        'description': null,
        'availableDimensions': [],
        'availablePeriods': [],
      };
      final dto = AxisMetadataResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
