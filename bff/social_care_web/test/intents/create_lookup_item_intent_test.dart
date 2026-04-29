import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_lookup_item_intent.dart';

/// Wave 0 RED contract for [CreateLookupItemIntent] — A13.
///
/// Canon (P2 if-case, 2 required — mirrors [UpdateIntakeInfoIntent] from A11):
/// - `codigo`, `descricao` are REQUIRED non-empty strings.
/// - No optionals (DTO has only these two fields).
/// - Missing/empty required fields produce a [Failure] whose message
///   enumerates the missing names (dynamic string — `_CreateLookupItemParseError`
///   is NOT const):
///   `"Invalid create-lookup-item body: missing or empty [<names>]"`.
///
/// PII-safety: domain codes are not PII-dense, but the canon still forbids
/// echoing raw values; the error message MUST only enumerate missing field
/// names.
Map<String, dynamic> _validBody() => {'codigo': 'MAE', 'descricao': 'Mae'};

void main() {
  group('CreateLookupItemIntent', () {
    test('constructs with tableName + CreateLookupItemRequest payload', () {
      const request = CreateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const intent = CreateLookupItemIntent(
        tableName: 'dominio_parentesco',
        request: request,
      );

      expect(intent.tableName, equals('dominio_parentesco'));
      expect(intent.request, equals(request));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = CreateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const a = CreateLookupItemIntent(
        tableName: 'dominio_parentesco',
        request: request,
      );
      const b = CreateLookupItemIntent(
        tableName: 'dominio_parentesco',
        request: request,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different tableName are not equal', () {
      const request = CreateLookupItemRequest(codigo: 'MAE', descricao: 'Mae');

      const a = CreateLookupItemIntent(
        tableName: 'dominio_parentesco',
        request: request,
      );
      const b = CreateLookupItemIntent(
        tableName: 'dominio_grau_dependencia',
        request: request,
      );

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<CreateLookupItemIntent> (P2 if-case)', () {
      test('returns Success when both required fields are present', () {
        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          _validBody(),
        );

        expect(result, isA<Success<CreateLookupItemIntent>>());
      });

      test('Success payload preserves tableName + codigo + descricao', () {
        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          _validBody(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.tableName, equals('dominio_parentesco'));
            expect(value.request.codigo, equals('MAE'));
            expect(value.request.descricao, equals('Mae'));
          case Failure():
            fail('Expected Success, got Failure');
        }
      });

      test('returns Failure when codigo is missing', () {
        final body = _validBody()..remove('codigo');

        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          body,
        );

        expect(result, isA<Failure<CreateLookupItemIntent>>());
      });

      test('returns Failure when descricao is missing', () {
        final body = _validBody()..remove('descricao');

        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          body,
        );

        expect(result, isA<Failure<CreateLookupItemIntent>>());
      });

      test('returns Failure when codigo is empty string', () {
        final body = _validBody()..['codigo'] = '';

        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          body,
        );

        expect(result, isA<Failure<CreateLookupItemIntent>>());
      });

      test('returns Failure when descricao is empty string', () {
        final body = _validBody()..['descricao'] = '';

        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          body,
        );

        expect(result, isA<Failure<CreateLookupItemIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          const {},
        );

        expect(result, isA<Failure<CreateLookupItemIntent>>());
      });

      test(
        'Failure message enumerates ALL missing fields when body is empty',
        () {
          final result = CreateLookupItemIntent.parseFromBody(
            'dominio_parentesco',
            const {},
          );

          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              final msg = error.toString();
              expect(msg, contains('codigo'));
              expect(msg, contains('descricao'));
              expect(msg, startsWith('Invalid create-lookup-item body:'));
          }
        },
      );

      test('Failure message enumerates only missing (not present) fields', () {
        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          const {'codigo': 'MAE'},
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final msg = error.toString();
            expect(msg, isNot(contains('codigo')));
            expect(msg, contains('descricao'));
        }
      });

      test('Failure message NEVER echoes raw descricao value', () {
        final body = {
          // missing codigo — forces Failure
          'descricao': 'Avo materna que reside com a crianca',
        };

        final result = CreateLookupItemIntent.parseFromBody(
          'dominio_parentesco',
          body,
        );

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            final dumped = error.toString();
            expect(
              dumped,
              isNot(contains('Avo materna')),
              reason: 'Parse error must never echo raw descricao',
            );
            expect(
              dumped,
              isNot(contains('reside com a crianca')),
              reason: 'Parse error must never echo raw descricao',
            );
        }
      });
    });
  });
}
