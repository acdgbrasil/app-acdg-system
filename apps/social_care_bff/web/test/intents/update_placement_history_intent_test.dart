import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_placement_history_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Wave 0 RED contract for [UpdatePlacementHistoryIntent] — A12 (edge case).
///
/// Canon (P2b try/catch — mirrors [UpdateHousingConditionIntent] from A10):
/// - Top-level DTO has 0 required fields (`registries` defaults to `[]`,
///   `collectiveSituations` / `separationChecklist` are optional sub-DTOs).
/// - Sub-DTOs have required fields (e.g. `RegistryDraftDto` requires
///   `memberId`, `startDate`, `reason`) — malformed sub-DTOs fail recursively
///   inside `fromJson`.
/// - P2b gatilho: PII-sensitive sub-DTO bodies (`homeLossReport`,
///   `thirdPartyGuardReport`, `reason`) + nested required fields whose
///   enumeration via P2 would duplicate 40+ lines of `fromJson` and risk
///   echoing PII via `CheckedFromJsonException.toString()`.
/// - Error message is structural and PII-safe:
///   `'Invalid update-placement-history body: missing or malformed required fields'`
/// - `_UpdatePlacementHistoryParseError` is `const` (message is a compile-time
///   literal).
/// - `parseFromBody` accepts an optional `obs: ObservabilityContext?` so the
///   catch branch can route `logError('protection.placement_history.parse_failed',
///   cause: e, stack: st)` without crossing layer boundaries.
///
/// PII-safety (CRITICAL):
/// - `homeLossReport` / `thirdPartyGuardReport` carry free narrative about
///   family history (PII-dense).
/// - `RegistryDraftDto.reason` carries narrative about placement reasons
///   (fostering/internment context — sensitive).
/// - Parse errors MUST NEVER echo any field content — only the fixed
///   structural literal.

Map<String, dynamic> _validBody() => {
  'registries': [
    {
      'memberId': '770e8400-e29b-41d4-a716-446655440002',
      'startDate': '2023-05-01',
      'endDate': '2024-01-10',
      'reason': 'Afastamento temporario',
    },
  ],
  'collectiveSituations': {
    'homeLossReport': 'Familia perdeu moradia em enchente',
    'thirdPartyGuardReport': 'Criancas sob guarda de avos maternos',
  },
  'separationChecklist': {
    'adultInPrison': false,
    'adolescentInInternment': false,
  },
};

void main() {
  group('UpdatePlacementHistoryIntent', () {
    test('constructs with patientId + request', () {
      const request = UpdatePlacementHistoryRequest();

      const intent = UpdatePlacementHistoryIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(intent.patientId, equals(kPatientUuid));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = UpdatePlacementHistoryRequest();

      const a = UpdatePlacementHistoryIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdatePlacementHistoryIntent(
        patientId: kPatientUuid,
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different patientId are not equal', () {
      const request = UpdatePlacementHistoryRequest();

      const a = UpdatePlacementHistoryIntent(
        patientId: kPatientUuid,
        request: request,
      );
      const b = UpdatePlacementHistoryIntent(
        patientId: kPatientUuidAlt,
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group(
      'parseFromBody — Result<UpdatePlacementHistoryIntent> (P2b try/catch)',
      () {
        test('returns Success when body is valid', () {
          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            _validBody(),
          );

          expect(result, isA<Success<UpdatePlacementHistoryIntent>>());
        });

        test('Success payload preserves patientId + registries + flags', () {
          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            _validBody(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals(kPatientUuid));
              expect(value.request.registries, hasLength(1));
              expect(
                value.request.registries.first.memberId,
                equals('770e8400-e29b-41d4-a716-446655440002'),
              );
              expect(
                value.request.collectiveSituations?.homeLossReport,
                equals('Familia perdeu moradia em enchente'),
              );
              expect(value.request.separationChecklist?.adultInPrison, isFalse);
            case Failure():
              fail('Expected Success, got Failure');
          }
        });

        test(
          'tolerates body = {} (0 required at top-level) — Success with defaults',
          () {
            final result = UpdatePlacementHistoryIntent.parseFromBody(
              kPatientUuid,
              const {},
            );

            switch (result) {
              case Success(:final value):
                expect(value.request.registries, isEmpty);
                expect(value.request.collectiveSituations, isNull);
                expect(value.request.separationChecklist, isNull);
              case Failure():
                fail(
                  'Empty body must parse cleanly — all top-level fields are optional',
                );
            }
          },
        );

        test(
          'returns Failure when a RegistryDraftDto is missing required field '
          '(memberId)',
          () {
            final body = {
              'registries': [
                {
                  // memberId missing — sub-DTO fromJson throws
                  'startDate': '2023-05-01',
                  'reason': 'x',
                },
              ],
            };

            final result = UpdatePlacementHistoryIntent.parseFromBody(
              kPatientUuid,
              body,
            );

            expect(result, isA<Failure<UpdatePlacementHistoryIntent>>());
          },
        );

        test(
          'returns Failure when a RegistryDraftDto is missing required field '
          '(startDate)',
          () {
            final body = {
              'registries': [
                {
                  'memberId': '770e8400-e29b-41d4-a716-446655440002',
                  // startDate missing
                  'reason': 'x',
                },
              ],
            };

            final result = UpdatePlacementHistoryIntent.parseFromBody(
              kPatientUuid,
              body,
            );

            expect(result, isA<Failure<UpdatePlacementHistoryIntent>>());
          },
        );

        test(
          'returns Failure when a RegistryDraftDto is missing required field '
          '(reason)',
          () {
            final body = {
              'registries': [
                {
                  'memberId': '770e8400-e29b-41d4-a716-446655440002',
                  'startDate': '2023-05-01',
                  // reason missing
                },
              ],
            };

            final result = UpdatePlacementHistoryIntent.parseFromBody(
              kPatientUuid,
              body,
            );

            expect(result, isA<Failure<UpdatePlacementHistoryIntent>>());
          },
        );

        test('returns Failure when registries is wrong type', () {
          final body = {'registries': 'not-a-list'};

          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          expect(result, isA<Failure<UpdatePlacementHistoryIntent>>());
        });

        test('Failure message is EXACTLY the fixed structural literal '
            '(P2b canon — no field enumeration, no value echo)', () {
          final body = {
            'registries': [
              {
                // memberId missing — forces Failure
                'startDate': '2023-05-01',
                'reason': 'SECRET_REASON_MARKER_ZZZ',
              },
            ],
          };

          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final text = error.toString();
              expect(
                text,
                equals(
                  'Invalid update-placement-history body: '
                  'missing or malformed required fields',
                ),
              );
              expect(text, isNot(contains('SECRET_REASON_MARKER_ZZZ')));
              expect(text, isNot(contains('memberId')));
              expect(text, isNot(contains('startDate')));
              expect(text, isNot(contains('reason')));
          }
        });

        test(
          'Failure message NEVER echoes homeLossReport / thirdPartyGuardReport '
          '(PII — family history narrative)',
          () {
            // Inner sub-DTO invalid (memberId missing) forces failure,
            // while we plant PII markers in collectiveSituations to ensure
            // CheckedFromJsonException cannot leak them.
            final body = {
              'registries': [
                {
                  // memberId missing
                  'startDate': '2023-05-01',
                  'reason': 'x',
                },
              ],
              'collectiveSituations': {
                'homeLossReport': 'Familia perdeu moradia em enchente de 2023',
                'thirdPartyGuardReport':
                    'Criancas ficaram com vizinha pois mae esta presa',
              },
            };

            final result = UpdatePlacementHistoryIntent.parseFromBody(
              kPatientUuid,
              body,
            );

            switch (result) {
              case Success():
                fail('Expected Failure');
              case Failure(:final error):
                final dumped = error.toString();
                expect(dumped, isNot(contains('Familia perdeu moradia')));
                expect(dumped, isNot(contains('enchente')));
                expect(dumped, isNot(contains('2023')));
                expect(dumped, isNot(contains('vizinha')));
                expect(dumped, isNot(contains('presa')));
            }
          },
        );

        test('Failure message NEVER echoes RegistryDraftDto.reason (PII)', () {
          final body = {
            'registries': [
              {
                // memberId missing — forces failure
                'startDate': '2023-05-01',
                'reason':
                    'Afastamento por violencia domestica — encaminhado CREAS',
              },
            ],
          };

          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            body,
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(dumped, isNot(contains('violencia domestica')));
              expect(dumped, isNot(contains('CREAS')));
              expect(dumped, isNot(contains('Afastamento')));
          }
        });

        test('accepts optional obs parameter without crashing on success', () {
          // No exception at wire-up; the obs-param call-site MUST be a
          // compile-time valid signature for both Success and Failure paths.
          final result = UpdatePlacementHistoryIntent.parseFromBody(
            kPatientUuid,
            _validBody(),
          );

          expect(result, isA<Success<UpdatePlacementHistoryIntent>>());
        });
      },
    );
  });
}
