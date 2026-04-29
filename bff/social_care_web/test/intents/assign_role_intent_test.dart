import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/assign_role_intent.dart';

/// Wave 0 RED contract for [AssignRoleIntent] — A15 (P2 if-case manual,
/// 2 required strings + path param).
void main() {
  group('AssignRoleIntent', () {
    Map<String, dynamic> validBody({
      String system = 'social-care',
      String role = 'social_worker',
    }) => {'system': system, 'role': role};

    test('parseFromBody returns Success on happy path', () {
      final result = AssignRoleIntent.parseFromBody('m-1', validBody());

      switch (result) {
        case Success(:final value):
          expect(value.memberId, equals('m-1'));
          expect(value.request.system, equals('social-care'));
          expect(value.request.role, equals('social_worker'));
        case Failure():
          fail('Expected Success');
      }
    });

    test('Equatable considers memberId + request', () {
      final a = AssignRoleIntent.parseFromBody('m-1', validBody());
      final b = AssignRoleIntent.parseFromBody('m-1', validBody());

      expect(a is Success, isTrue);
      expect(b is Success, isTrue);
      expect(
        (a as Success<AssignRoleIntent>).value,
        equals((b as Success<AssignRoleIntent>).value),
      );
    });

    test('parseFromBody fails on empty body — lists both required fields', () {
      final result = AssignRoleIntent.parseFromBody(
        'm-1',
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
    });

    test('parseFromBody fails when system is missing', () {
      final body = validBody()..remove('system');
      final result = AssignRoleIntent.parseFromBody('m-1', body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error.toString(), contains('system'));
      }
    });

    test('parseFromBody fails when role is missing', () {
      final body = validBody()..remove('role');
      final result = AssignRoleIntent.parseFromBody('m-1', body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error.toString(), contains('role'));
      }
    });

    test('parseFromBody fails when role is empty string', () {
      final body = validBody(role: '');
      final result = AssignRoleIntent.parseFromBody('m-1', body);

      expect(result, isA<Failure<AssignRoleIntent>>());
    });
  });
}
