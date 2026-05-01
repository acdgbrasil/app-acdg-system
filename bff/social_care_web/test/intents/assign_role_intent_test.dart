import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/assign_role_intent.dart';
import 'package:social_care_web/src/intents/uuid_validation.dart';

import '../_test_uuids.dart';

/// Contract for [AssignRoleIntent] post-A23 (Template C-P2 V2 — path UUID
/// + P2 if-case body).
///
/// `parseFromBody(rawMemberId, body)` validates the path UUID first via
/// the canonical [validateUuidPathParam] helper, then chains body
/// parsing via `flatMap`. UUID failure short-circuits BEFORE body
/// parsing — confirmed by passing a body that would also fail.
/// Body-level failures continue to surface the existing
/// `_AssignRoleParseError`. PII safety is enforced — the raw input is
/// never echoed in the error.
void main() {
  group('AssignRoleIntent', () {
    Map<String, dynamic> validBody({
      String system = 'social-care',
      String role = 'social_worker',
    }) => {'system': system, 'role': role};

    group('parseFromBody — Result<AssignRoleIntent> (Template C-P2)', () {
      test('returns Success on happy path with valid memberId UUID', () {
        final result = AssignRoleIntent.parseFromBody(
          kMemberUuid,
          validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
            expect(value.request.system, equals('social-care'));
            expect(value.request.role, equals('social_worker'));
          case Failure():
            fail('Expected Success');
        }
      });

      test('normalizes uppercase memberId to lowercase', () {
        final result = AssignRoleIntent.parseFromBody(
          kMemberUuid.toUpperCase(),
          validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.memberId, equals(kMemberUuid));
          case Failure():
            fail('Expected Success — uppercase should be normalized');
        }
      });

      test('Equatable considers memberId + request', () {
        final a = AssignRoleIntent.parseFromBody(kMemberUuid, validBody());
        final b = AssignRoleIntent.parseFromBody(kMemberUuid, validBody());

        expect(a, isA<Success<AssignRoleIntent>>());
        expect(b, isA<Success<AssignRoleIntent>>());
        switch ((a, b)) {
          case (Success(value: final av), Success(value: final bv)):
            expect(av, equals(bv));
            expect(av.hashCode, equals(bv.hashCode));
          default:
            fail('Expected both Success');
        }
      });

      test(
        'parseFromBody fails on empty body — lists both required fields',
        () {
          final result = AssignRoleIntent.parseFromBody(
            kMemberUuid,
            <String, dynamic>{},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('system'));
              expect(msg, contains('role'));
          }
        },
      );

      test('parseFromBody fails when system is missing', () {
        final body = validBody()..remove('system');
        final result = AssignRoleIntent.parseFromBody(kMemberUuid, body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error.toString(), contains('system'));
        }
      });

      test('parseFromBody fails when role is missing', () {
        final body = validBody()..remove('role');
        final result = AssignRoleIntent.parseFromBody(kMemberUuid, body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error.toString(), contains('role'));
        }
      });

      test('parseFromBody fails when role is empty string', () {
        final body = validBody(role: '');
        final result = AssignRoleIntent.parseFromBody(kMemberUuid, body);

        expect(result, isA<Failure<AssignRoleIntent>>());
      });

      test(
        'returns Failure with UuidPathParamError when path id is not UUID v4 — '
        'short-circuits BEFORE body parsing (body that would also fail)',
        () {
          // Body is empty — body parser would also produce a Failure.
          // The UUID gate must fire first so the surfaced error is a
          // UuidPathParamError, NOT _AssignRoleParseError.
          final result = AssignRoleIntent.parseFromBody(
            kNonUuid,
            <String, dynamic>{},
          );

          switch (result) {
            case Success():
              fail('Expected Failure for non-UUID path id');
            case Failure(:final error):
              expect(
                error,
                isA<UuidPathParamError>(),
                reason: 'UUID gate must short-circuit before body parsing',
              );
              expect(
                (error as UuidPathParamError).fieldName,
                equals('memberId'),
              );
              // PII safety — must not echo raw input.
              expect(error.toString(), isNot(contains(kNonUuid)));
              // Confirms it is NOT the body-parse error path.
              expect(error.toString(), isNot(contains('system')));
              expect(error.toString(), isNot(contains('role')));
          }
        },
      );

      test('returns Failure for empty memberId (UUID gate rejects it)', () {
        final result = AssignRoleIntent.parseFromBody('', validBody());

        switch (result) {
          case Success():
            fail('Expected Failure for empty path id');
          case Failure(:final error):
            expect(error, isA<UuidPathParamError>());
        }
      });

      test('returns Failure for UUID v1 in path (rejects non-v4)', () {
        final result = AssignRoleIntent.parseFromBody(kUuidV1, validBody());

        expect(result, isA<Failure<AssignRoleIntent>>());
      });
    });
  });
}
