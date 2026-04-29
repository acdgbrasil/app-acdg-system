import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_lookup_request_intent.dart';

/// Wave 0 RED contract for [CreateLookupRequestIntent] — A13.
///
/// Canon (P2 if-case, 3 required — mirrors [CreateReferralIntent] from A12):
/// - `tableName`, `codigo`, `descricao` are REQUIRED non-empty strings.
/// - `justificativa` is optional and may carry PII-dense narrative (user's
///   rationale for proposing the lookup item — e.g., mentioning the child's
///   condition or diagnosis).
/// - Missing/empty required fields produce a [Failure] whose message
///   enumerates the missing names (dynamic string —
///   `_CreateLookupRequestParseError` is NOT const):
///   `"Invalid create-lookup-request body: missing or empty [<names>]"`.
///
/// PII-safety (CRITICAL): parse errors NEVER echo `justificativa`, `codigo`,
/// or `descricao` content. The error message only enumerates the missing
/// STRUCTURAL field names.

Map<String, dynamic> _validBody() => {
  'tableName': 'dominio_diagnostico',
  'codigo': 'WILLIAMS',
  'descricao': 'Sindrome de Williams',
  'justificativa': 'Necessario adicionar este diagnostico raro',
};

void main() {
  group('CreateLookupRequestIntent', () {
    test('constructs with CreateLookupRequestRequest payload', () {
      const request = CreateLookupRequestRequest(
        tableName: 'dominio_diagnostico',
        codigo: 'WILLIAMS',
        descricao: 'Sindrome de Williams',
      );

      const intent = CreateLookupRequestIntent(request: request);

      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = CreateLookupRequestRequest(
        tableName: 'dominio_diagnostico',
        codigo: 'WILLIAMS',
        descricao: 'Sindrome de Williams',
      );

      const a = CreateLookupRequestIntent(request: request);
      const b = CreateLookupRequestIntent(request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payload are not equal', () {
      const a = CreateLookupRequestIntent(
        request: CreateLookupRequestRequest(
          tableName: 't1',
          codigo: 'A',
          descricao: 'a',
        ),
      );
      const b = CreateLookupRequestIntent(
        request: CreateLookupRequestRequest(
          tableName: 't2',
          codigo: 'A',
          descricao: 'a',
        ),
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<CreateLookupRequestIntent> (P2 if-case)', () {
      test('returns Success when all required fields are present', () {
        final result = CreateLookupRequestIntent.parseFromBody(_validBody());

        expect(result, isA<Success<CreateLookupRequestIntent>>());
      });

      test(
        'Success payload preserves all required + optional justificativa',
        () {
          final result = CreateLookupRequestIntent.parseFromBody(_validBody());

          switch (result) {
            case Success(:final value):
              expect(value.request.tableName, equals('dominio_diagnostico'));
              expect(value.request.codigo, equals('WILLIAMS'));
              expect(value.request.descricao, equals('Sindrome de Williams'));
              expect(
                value.request.justificativa,
                equals('Necessario adicionar este diagnostico raro'),
              );
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('Success with required only — justificativa null', () {
        final result = CreateLookupRequestIntent.parseFromBody(const {
          'tableName': 't1',
          'codigo': 'A',
          'descricao': 'a',
        });

        switch (result) {
          case Success(:final value):
            expect(value.request.justificativa, isNull);
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when tableName is missing', () {
        final body = _validBody()..remove('tableName');

        final result = CreateLookupRequestIntent.parseFromBody(body);

        expect(result, isA<Failure<CreateLookupRequestIntent>>());
      });

      test('returns Failure when codigo is missing', () {
        final body = _validBody()..remove('codigo');

        final result = CreateLookupRequestIntent.parseFromBody(body);

        expect(result, isA<Failure<CreateLookupRequestIntent>>());
      });

      test('returns Failure when descricao is missing', () {
        final body = _validBody()..remove('descricao');

        final result = CreateLookupRequestIntent.parseFromBody(body);

        expect(result, isA<Failure<CreateLookupRequestIntent>>());
      });

      test('returns Failure when tableName is empty string', () {
        final body = _validBody()..['tableName'] = '';

        final result = CreateLookupRequestIntent.parseFromBody(body);

        expect(result, isA<Failure<CreateLookupRequestIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = CreateLookupRequestIntent.parseFromBody(const {});

        expect(result, isA<Failure<CreateLookupRequestIntent>>());
      });

      test(
        'Failure message enumerates ALL missing fields when body is empty',
        () {
          final result = CreateLookupRequestIntent.parseFromBody(const {});

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('tableName'));
              expect(msg, contains('codigo'));
              expect(msg, contains('descricao'));
              expect(msg, startsWith('Invalid create-lookup-request body:'));
          }
        },
      );

      test('Failure message enumerates only missing (not present) fields', () {
        final result = CreateLookupRequestIntent.parseFromBody(const {
          'tableName': 't1',
        });

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, isNot(contains('tableName')));
            expect(msg, contains('codigo'));
            expect(msg, contains('descricao'));
        }
      });

      test(
        'Failure message NEVER echoes raw justificativa content (PII — CRITICAL)',
        () {
          final body = {
            // missing tableName — forces Failure
            'codigo': 'X',
            'descricao': 'Y',
            'justificativa': 'Preciso pois minha filha de 5 anos tem Williams',
          };

          final result = CreateLookupRequestIntent.parseFromBody(body);

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final dumped = error.toString();
              expect(
                dumped,
                isNot(contains('filha de 5 anos')),
                reason: 'Parse error must never echo raw justificativa',
              );
              expect(
                dumped,
                isNot(contains('Williams')),
                reason: 'Parse error must never echo raw justificativa',
              );
              expect(
                dumped,
                isNot(contains('Preciso pois')),
                reason: 'Parse error must never echo raw justificativa',
              );
          }
        },
      );

      test('Failure message NEVER echoes raw codigo / descricao values', () {
        final body = {
          // missing tableName — forces Failure
          'codigo': 'RARE_DIAGNOSIS_X',
          'descricao': 'Condicao clinica especifica do paciente',
        };

        final result = CreateLookupRequestIntent.parseFromBody(body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final dumped = error.toString();
            expect(dumped, isNot(contains('RARE_DIAGNOSIS_X')));
            expect(dumped, isNot(contains('Condicao clinica')));
            expect(dumped, isNot(contains('especifica do paciente')));
        }
      });
    });
  });
}
