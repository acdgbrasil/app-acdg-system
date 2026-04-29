import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_worker_intent.dart';

/// Wave 0 RED contract for [RegisterWorkerIntent] — A15 (P2 if-case manual,
/// 3 required strings).
///
/// Pinned PII safety:
/// - Failure messages MUST NOT echo any field VALUE — only the missing
///   field NAMES.
/// - `initialPassword` is a secret and MUST never appear in error output
///   even when it is the only field provided.
void main() {
  group('RegisterWorkerIntent', () {
    Map<String, dynamic> validBody({
      String fullName = 'Maria Silva',
      String birthDate = '1990-05-12',
      String email = 'maria.silva@acdgbrasil.com.br',
      String? cpf,
      String? initialPassword,
    }) => {
      'fullName': fullName,
      'birthDate': birthDate,
      'email': email,
      if (cpf != null) 'cpf': cpf,
      if (initialPassword != null) 'initialPassword': initialPassword,
    };

    test('parseFromBody returns Success on full happy path', () {
      final result = RegisterWorkerIntent.parseFromBody(validBody());

      switch (result) {
        case Success(:final value):
          expect(value.request.fullName, equals('Maria Silva'));
          expect(value.request.birthDate, equals('1990-05-12'));
          expect(value.request.email, equals('maria.silva@acdgbrasil.com.br'));
          expect(value.request.cpf, isNull);
          expect(value.request.initialPassword, isNull);
        case Failure():
          fail('Expected Success');
      }
    });

    test('parseFromBody preserves optional cpf and initialPassword', () {
      final result = RegisterWorkerIntent.parseFromBody(
        validBody(cpf: '12345678901', initialPassword: 'TempPass!2026'),
      );

      switch (result) {
        case Success(:final value):
          expect(value.request.cpf, equals('12345678901'));
          expect(value.request.initialPassword, equals('TempPass!2026'));
        case Failure():
          fail('Expected Success');
      }
    });

    test('Equatable wraps the underlying request DTO', () {
      const r = RegisterPersonWithLoginRequest(
        fullName: 'Maria Silva',
        birthDate: '1990-05-12',
        email: 'maria.silva@acdgbrasil.com.br',
      );
      const a = RegisterWorkerIntent(request: r);
      const b = RegisterWorkerIntent(request: r);
      expect(a, equals(b));
    });

    test('parseFromBody fails on empty body — message lists every required field', () {
      final result = RegisterWorkerIntent.parseFromBody(<String, dynamic>{});

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          final msg = error.toString();
          expect(msg, contains('fullName'));
          expect(msg, contains('birthDate'));
          expect(msg, contains('email'));
      }
    });

    test('parseFromBody fails when fullName is missing', () {
      final body = validBody()..remove('fullName');
      final result = RegisterWorkerIntent.parseFromBody(body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error.toString(), contains('fullName'));
      }
    });

    test('parseFromBody fails when birthDate is missing', () {
      final body = validBody()..remove('birthDate');
      final result = RegisterWorkerIntent.parseFromBody(body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error.toString(), contains('birthDate'));
      }
    });

    test('parseFromBody fails when email is missing', () {
      final body = validBody()..remove('email');
      final result = RegisterWorkerIntent.parseFromBody(body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error.toString(), contains('email'));
      }
    });

    test('parseFromBody fails when fullName is empty string', () {
      final body = validBody(fullName: '');
      final result = RegisterWorkerIntent.parseFromBody(body);

      expect(result, isA<Failure<RegisterWorkerIntent>>());
    });

    test('parseFromBody Failure NEVER echoes raw fullName / email content', () {
      final body = validBody(fullName: '');
      final result = RegisterWorkerIntent.parseFromBody(body);

      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          final msg = error.toString();
          expect(msg, isNot(contains('Maria Silva')));
          expect(msg, isNot(contains('maria.silva@acdgbrasil.com.br')));
      }
    });

    test(
      'parseFromBody Failure NEVER echoes initialPassword (secret-safety)',
      () {
        // Even when only initialPassword is provided, the error must not
        // include its value.
        final body = <String, dynamic>{
          'initialPassword': 'TempPass!2026',
        };
        final result = RegisterWorkerIntent.parseFromBody(body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error.toString(), isNot(contains('TempPass!2026')));
        }
      },
    );
  });
}
