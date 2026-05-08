import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/assessment_handler.dart';
import 'package:social_care_web/src/use_cases/update_community_support_network_use_case.dart';
import 'package:social_care_web/src/use_cases/update_educational_status_use_case.dart';
import 'package:social_care_web/src/use_cases/update_health_status_use_case.dart';
import 'package:social_care_web/src/use_cases/update_housing_condition_use_case.dart';
import 'package:social_care_web/src/use_cases/update_social_health_summary_use_case.dart';
import 'package:social_care_web/src/use_cases/update_socio_economic_situation_use_case.dart';
import 'package:social_care_web/src/use_cases/update_work_and_income_use_case.dart';

import '../_test_uuids.dart';

/// Wave 0 RED for the new unified [AssessmentHandler] (A10).
///
/// Routes (mounted on `/` — real server prefixes `/api`):
/// - `PUT /patients/<id>/assessment/housing`
/// - `PUT /patients/<id>/assessment/socioeconomic`
/// - `PUT /patients/<id>/assessment/work-income`
/// - `PUT /patients/<id>/assessment/education`
/// - `PUT /patients/<id>/assessment/health`
/// - `PUT /patients/<id>/assessment/community-support`
/// - `PUT /patients/<id>/assessment/social-health-summary`
///
/// Canon helpers copied verbatim from [RegistryPatientHandler]:
/// `_readJsonBody`, `_wrapVoidResult`, `_extractError`, `_badRequest`,
/// `_jsonHeaders`. Non-`BackendError` failures collapse to a sanitized
/// `500 INTERNAL` response — inner Dart exception messages MUST NEVER leak.
///
/// Pinned 400 codes (one per ficha + shared):
/// - `INVALID_HOUSING_BODY`
/// - `INVALID_SOCIO_ECONOMIC_BODY`
/// - `INVALID_WORK_AND_INCOME_BODY`
/// - `INVALID_EDUCATIONAL_STATUS_BODY`
/// - `INVALID_HEALTH_STATUS_BODY`
/// - `INVALID_COMMUNITY_SUPPORT_BODY`
/// - `INVALID_SOCIAL_HEALTH_SUMMARY_BODY`
/// - `INVALID_JSON` (shared)

/// Forces every assessment mutation to fail with [error]. Used for upstream
/// status passthrough tests.
class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async => Failure(error);
}

/// Assessment contract that returns a non-[BackendError] failure (a raw
/// `Exception` with an obvious leak marker). Used to pin the 500 `INTERNAL`
/// path — the handler MUST NOT echo the inner message in the JSON body.
class _ExplodingAssessment extends FakeAssessmentBff {
  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async => Failure(Exception('leak marker xyz'));
}

AssessmentHandler _buildHandler({AssessmentContract? assessment}) {
  final a = assessment ?? FakeAssessmentBff();
  return AssessmentHandler(
    housing: UpdateHousingConditionUseCase(assessment: a),
    socioEconomic: UpdateSocioEconomicSituationUseCase(assessment: a),
    workAndIncome: UpdateWorkAndIncomeUseCase(assessment: a),
    educationalStatus: UpdateEducationalStatusUseCase(assessment: a),
    healthStatus: UpdateHealthStatusUseCase(assessment: a),
    communitySupport: UpdateCommunitySupportNetworkUseCase(assessment: a),
    socialHealthSummary: UpdateSocialHealthSummaryUseCase(assessment: a),
  );
}

Map<String, dynamic> _validHousingBody() => {
  'type': 'OWNED',
  'wallMaterial': 'BRICK',
  'numberOfRooms': 3,
  'numberOfBedrooms': 2,
  'numberOfBathrooms': 1,
  'waterSupply': 'PUBLIC_NETWORK',
  'hasPipedWater': true,
  'electricityAccess': 'REGULAR',
  'sewageDisposal': 'PUBLIC_NETWORK',
  'wasteCollection': 'COLLECTED',
  'accessibilityLevel': 'FULLY_ACCESSIBLE',
  'isInGeographicRiskArea': false,
  'hasDifficultAccess': false,
  'isInSocialConflictArea': false,
  'hasDiagnosticObservations': false,
};

Map<String, dynamic> _validSocioEconomicBody() => {
  'totalFamilyIncome': 1500.0,
  'incomePerCapita': 500.0,
  'receivesSocialBenefit': true,
  'mainSourceOfIncome': 'FORMAL_EMPLOYMENT',
  'hasUnemployed': false,
  'socialBenefits': <Map<String, dynamic>>[],
};

Map<String, dynamic> _validWorkAndIncomeBody() => {
  'hasRetiredMembers': false,
  'individualIncomes': <Map<String, dynamic>>[],
  'socialBenefits': <Map<String, dynamic>>[],
};

Map<String, dynamic> _validEducationalStatusBody() => {
  'memberProfiles': <Map<String, dynamic>>[],
  'programOccurrences': <Map<String, dynamic>>[],
};

Map<String, dynamic> _validHealthStatusBody() => {
  'foodInsecurity': false,
  'deficiencies': <Map<String, dynamic>>[],
  'gestatingMembers': <Map<String, dynamic>>[],
  'constantCareNeeds': <String>[],
};

Map<String, dynamic> _validCommunitySupportBody() => {
  'hasRelativeSupport': true,
  'hasNeighborSupport': false,
  'familyConflicts': 'NONE',
  'patientParticipatesInGroups': true,
  'familyParticipatesInGroups': false,
  'patientHasAccessToLeisure': true,
  'facesDiscrimination': false,
};

Map<String, dynamic> _validSocialHealthSummaryBody() => {
  'requiresConstantCare': true,
  'hasMobilityImpairment': false,
  'hasRelevantDrugTherapy': true,
  'functionalDependencies': <String>[],
};

Request _put(String path, Object body) => Request(
  'PUT',
  Uri.parse('http://localhost$path'),
  body: body is String ? body : jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

void main() {
  group('AssessmentHandler — PUT /patients/<id>/assessment/housing', () {
    test('returns 200 on happy path', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/housing', _validHousingBody()),
      );

      expect(response.statusCode, lessThan(300));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['data'], isNull);
      expect(body['meta'], isA<Map<String, dynamic>>());
    });

    test('returns 400 INVALID_JSON when body is not JSON', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/housing', 'not json'),
      );

      expect(response.statusCode, equals(400));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
    });

    test(
      'returns 400 INVALID_HOUSING_BODY when required field missing',
      () async {
        final handler = _buildHandler();
        final body = _validHousingBody()..remove('type');

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/housing', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_HOUSING_BODY'),
        );
      },
    );

    test('propagates upstream status code on BackendError', () async {
      final failing = _FailingAssessment(
        const BackendError(
          id: 'err-1',
          code: 'CONFLICT',
          message: 'ficha already updated',
          http: 409,
        ),
      );
      final handler = _buildHandler(assessment: failing);

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/housing', _validHousingBody()),
      );

      expect(response.statusCode, equals(409));
    });
  });

  group('AssessmentHandler — PUT /patients/<id>/assessment/socioeconomic', () {
    test('returns 200 on happy path', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/socioeconomic',
          _validSocioEconomicBody(),
        ),
      );

      expect(response.statusCode, lessThan(300));
    });

    test('returns 400 INVALID_JSON when body is not JSON', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/socioeconomic', 'not json'),
      );

      expect(response.statusCode, equals(400));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
    });

    test(
      'returns 400 INVALID_SOCIO_ECONOMIC_BODY when required field missing',
      () async {
        final handler = _buildHandler();
        final body = _validSocioEconomicBody()..remove('mainSourceOfIncome');

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/socioeconomic', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_SOCIO_ECONOMIC_BODY'),
        );
      },
    );

    test('propagates upstream status code on BackendError', () async {
      final failing = _FailingAssessment(
        const BackendError(
          id: 'err-1',
          code: 'CONFLICT',
          message: 'ficha already updated',
          http: 409,
        ),
      );
      final handler = _buildHandler(assessment: failing);

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/socioeconomic',
          _validSocioEconomicBody(),
        ),
      );

      expect(response.statusCode, equals(409));
    });
  });

  group('AssessmentHandler — PUT /patients/<id>/assessment/work-income', () {
    test('returns 200 on happy path', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/work-income',
          _validWorkAndIncomeBody(),
        ),
      );

      expect(response.statusCode, lessThan(300));
    });

    test('returns 400 INVALID_JSON when body is not JSON', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/work-income', 'not json'),
      );

      expect(response.statusCode, equals(400));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
    });

    test(
      'returns 400 INVALID_WORK_AND_INCOME_BODY when required field missing',
      () async {
        final handler = _buildHandler();
        final body = _validWorkAndIncomeBody()..remove('hasRetiredMembers');

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/work-income', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_WORK_AND_INCOME_BODY'),
        );
      },
    );

    test('propagates upstream status code on BackendError', () async {
      final failing = _FailingAssessment(
        const BackendError(
          id: 'err-1',
          code: 'CONFLICT',
          message: 'ficha already updated',
          http: 409,
        ),
      );
      final handler = _buildHandler(assessment: failing);

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/work-income',
          _validWorkAndIncomeBody(),
        ),
      );

      expect(response.statusCode, equals(409));
    });
  });

  group('AssessmentHandler — PUT /patients/<id>/assessment/education', () {
    test('returns 200 on happy path', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/education',
          _validEducationalStatusBody(),
        ),
      );

      expect(response.statusCode, lessThan(300));
    });

    test('returns 400 INVALID_JSON when body is not JSON', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/education', 'not json'),
      );

      expect(response.statusCode, equals(400));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
    });

    test(
      'returns 400 INVALID_EDUCATIONAL_STATUS_BODY on malformed nested entry',
      () async {
        final handler = _buildHandler();
        final body = _validEducationalStatusBody()
          ..['memberProfiles'] = <Map<String, dynamic>>[
            {
              'memberId': 'm-1',
              'canReadWrite': true,
              'attendsSchool': false,
              // educationLevelId missing -> nested fromJson fails
            },
          ];

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/education', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_EDUCATIONAL_STATUS_BODY'),
        );
      },
    );

    test('propagates upstream status code on BackendError', () async {
      final failing = _FailingAssessment(
        const BackendError(
          id: 'err-1',
          code: 'CONFLICT',
          message: 'ficha already updated',
          http: 409,
        ),
      );
      final handler = _buildHandler(assessment: failing);

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/education',
          _validEducationalStatusBody(),
        ),
      );

      expect(response.statusCode, equals(409));
    });
  });

  group('AssessmentHandler — PUT /patients/<id>/assessment/health', () {
    test('returns 200 on happy path', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/health',
          _validHealthStatusBody(),
        ),
      );

      expect(response.statusCode, lessThan(300));
    });

    test('returns 400 INVALID_JSON when body is not JSON', () async {
      final handler = _buildHandler();

      final response = await handler.router.call(
        _put('/patients/$kPatientUuid/assessment/health', 'not json'),
      );

      expect(response.statusCode, equals(400));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
    });

    test(
      'returns 400 INVALID_HEALTH_STATUS_BODY when required field missing',
      () async {
        final handler = _buildHandler();
        final body = _validHealthStatusBody()..remove('foodInsecurity');

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/health', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_HEALTH_STATUS_BODY'),
        );
      },
    );

    test('propagates upstream status code on BackendError', () async {
      final failing = _FailingAssessment(
        const BackendError(
          id: 'err-1',
          code: 'CONFLICT',
          message: 'ficha already updated',
          http: 409,
        ),
      );
      final handler = _buildHandler(assessment: failing);

      final response = await handler.router.call(
        _put(
          '/patients/$kPatientUuid/assessment/health',
          _validHealthStatusBody(),
        ),
      );

      expect(response.statusCode, equals(409));
    });
  });

  group(
    'AssessmentHandler — PUT /patients/<id>/assessment/community-support',
    () {
      test('returns 200 on happy path', () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/community-support',
            _validCommunitySupportBody(),
          ),
        );

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 INVALID_JSON when body is not JSON', () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/community-support',
            'not json',
          ),
        );

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test('returns 400 INVALID_COMMUNITY_SUPPORT_BODY when required field '
          'missing', () async {
        final handler = _buildHandler();
        final body = _validCommunitySupportBody()..remove('familyConflicts');

        final response = await handler.router.call(
          _put('/patients/$kPatientUuid/assessment/community-support', body),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_COMMUNITY_SUPPORT_BODY'),
        );
      });

      test('propagates upstream status code on BackendError', () async {
        final failing = _FailingAssessment(
          const BackendError(
            id: 'err-1',
            code: 'CONFLICT',
            message: 'ficha already updated',
            http: 409,
          ),
        );
        final handler = _buildHandler(assessment: failing);

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/community-support',
            _validCommunitySupportBody(),
          ),
        );

        expect(response.statusCode, equals(409));
      });
    },
  );

  group(
    'AssessmentHandler — PUT /patients/<id>/assessment/social-health-summary',
    () {
      test('returns 200 on happy path', () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/social-health-summary',
            _validSocialHealthSummaryBody(),
          ),
        );

        expect(response.statusCode, lessThan(300));
      });

      test('returns 400 INVALID_JSON when body is not JSON', () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/social-health-summary',
            'not json',
          ),
        );

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test('returns 400 INVALID_SOCIAL_HEALTH_SUMMARY_BODY when required field '
          'missing', () async {
        final handler = _buildHandler();
        final body = _validSocialHealthSummaryBody()
          ..remove('requiresConstantCare');

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/social-health-summary',
            body,
          ),
        );

        expect(response.statusCode, equals(400));
        final payload =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_SOCIAL_HEALTH_SUMMARY_BODY'),
        );
      });

      test('propagates upstream status code on BackendError', () async {
        final failing = _FailingAssessment(
          const BackendError(
            id: 'err-1',
            code: 'CONFLICT',
            message: 'ficha already updated',
            http: 409,
          ),
        );
        final handler = _buildHandler(assessment: failing);

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/social-health-summary',
            _validSocialHealthSummaryBody(),
          ),
        );

        expect(response.statusCode, equals(409));
      });
    },
  );

  group('AssessmentHandler — sanitized 500 on non-BackendError failures', () {
    test(
      '500 INTERNAL on non-BackendError does NOT leak inner message',
      () async {
        final handler = _buildHandler(assessment: _ExplodingAssessment());

        final response = await handler.router.call(
          _put(
            '/patients/$kPatientUuid/assessment/housing',
            _validHousingBody(),
          ),
        );

        expect(response.statusCode, equals(500));
        final body = await response.readAsString();
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception')));
        expect(body, isNot(contains('#0')));

        final payload = jsonDecode(body) as Map<String, dynamic>;
        expect((payload['error'] as Map)['code'], equals('INTERNAL'));
      },
    );
  });

  // ── A23 W3 — UUID v4 path validation per route ────────────────────────
  //
  // Each Assessment endpoint relies on the intent-level UUID gate
  // (`validateUuidPathParam` inside `parseFromBody`). When the path id
  // is not a canonical UUID v4 the intent's `parseFromBody` short-circuits
  // with a `UuidPathParamError`; the handler then emits the matching
  // `INVALID_<X>_BODY` 400 (single code per ficha — A23 Template D).
  //
  // PII safety: the error message must NEVER echo the raw path input.
  group('AssessmentHandler — UUID v4 path validation', () {
    Future<Map<String, dynamic>> expect400AndDecode(Response response) async {
      expect(response.statusCode, equals(400));
      final payload =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final message = (payload['error'] as Map)['message'] as String;
      expect(message, isNot(contains(kNonUuid)));
      return payload;
    }

    test(
      'returns 400 INVALID_HOUSING_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put('/patients/$kNonUuid/assessment/housing', _validHousingBody()),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_HOUSING_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_SOCIO_ECONOMIC_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/socioeconomic',
            _validSocioEconomicBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_SOCIO_ECONOMIC_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_WORK_AND_INCOME_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/work-income',
            _validWorkAndIncomeBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_WORK_AND_INCOME_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_EDUCATIONAL_STATUS_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/education',
            _validEducationalStatusBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_EDUCATIONAL_STATUS_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_HEALTH_STATUS_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/health',
            _validHealthStatusBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_HEALTH_STATUS_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_COMMUNITY_SUPPORT_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/community-support',
            _validCommunitySupportBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_COMMUNITY_SUPPORT_BODY'),
        );
      },
    );

    test(
      'returns 400 INVALID_SOCIAL_HEALTH_SUMMARY_BODY when path id is not UUID v4',
      () async {
        final handler = _buildHandler();

        final response = await handler.router.call(
          _put(
            '/patients/$kNonUuid/assessment/social-health-summary',
            _validSocialHealthSummaryBody(),
          ),
        );

        final payload = await expect400AndDecode(response);
        expect(
          (payload['error'] as Map)['code'],
          equals('INVALID_SOCIAL_HEALTH_SUMMARY_BODY'),
        );
      },
    );
  });
}
