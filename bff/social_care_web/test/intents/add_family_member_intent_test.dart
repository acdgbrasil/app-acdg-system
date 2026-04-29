import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/add_family_member_intent.dart';

/// Wave 0 RED contract for the REWRITTEN [AddFamilyMemberIntent].
///
/// The legacy factory `AddFamilyMemberIntent.fromJson` is deprecated —
/// Wave 1 MUST replace it with a `Result`-returning `parseFromBody` that
/// follows the A07+A08 canon:
/// - P2 if-case on required fields (`relationship`, `birthDate`,
///   `prRelationshipId`);
/// - private [_AddFamilyMemberParseError] with `with Equatable implements
///   Exception`;
/// - **PII-safe** error messages — never echo raw `cpf` or `fullName`.
///
/// The intent envelope carries:
/// - [patientId] from the route path;
/// - [cpf] + [fullName] from the body (so the UseCase can delegate People
///   Context resolution); both optional;
/// - [request] — a fully-constructed [AddFamilyMemberRequest] with
///   `memberPersonId` set to the body value (or empty string when the
///   UseCase must resolve it via People Context from CPF+fullName).

/// Representative happy-path body with CPF (triggers People Context
/// resolution in Wave 1 UseCase).
Map<String, dynamic> _validBodyWithCpf() => {
  'cpf': '11144477735',
  'fullName': 'Ana Silva',
  'birthDate': '2018-05-10',
  'relationship': 'CHILD',
  'isResiding': true,
  'isCaregiver': false,
  'hasDisability': false,
  'prRelationshipId': 'rel-child',
  'requiredDocuments': <String>[],
};

/// Body without CPF — UseCase must NOT touch People Context; direct
/// registry call with the supplied `memberPersonId`.
Map<String, dynamic> _validBodyWithPersonId() => {
  'memberPersonId': 'per-42',
  'birthDate': '2010-01-01',
  'relationship': 'SIBLING',
  'isResiding': false,
  'isCaregiver': false,
  'hasDisability': false,
  'prRelationshipId': 'rel-sibling',
  'requiredDocuments': <String>[],
};

void main() {
  group('AddFamilyMemberIntent', () {
    test('constructs with patientId + request + optional cpf/fullName', () {
      const request = AddFamilyMemberRequest(
        memberPersonId: 'per-1',
        relationship: 'CHILD',
        isResiding: true,
        isCaregiver: false,
        hasDisability: false,
        birthDate: '2018-05-10',
        prRelationshipId: 'rel-child',
      );

      const intent = AddFamilyMemberIntent(
        patientId: 'pat-1',
        request: request,
        cpf: '11144477735',
        fullName: 'Ana Silva',
      );

      expect(intent.patientId, equals('pat-1'));
      expect(intent.request, equals(request));
      expect(intent.cpf, equals('11144477735'));
      expect(intent.fullName, equals('Ana Silva'));
    });

    test('instances with equal payload are equal (Equatable)', () {
      const request = AddFamilyMemberRequest(
        memberPersonId: 'per-1',
        relationship: 'CHILD',
        isResiding: true,
        isCaregiver: false,
        hasDisability: false,
        birthDate: '2018-05-10',
        prRelationshipId: 'rel-child',
      );

      const a = AddFamilyMemberIntent(patientId: 'pat-1', request: request);
      const b = AddFamilyMemberIntent(patientId: 'pat-1', request: request);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different payloads are not equal', () {
      const request = AddFamilyMemberRequest(
        memberPersonId: 'per-1',
        relationship: 'CHILD',
        isResiding: true,
        isCaregiver: false,
        hasDisability: false,
        birthDate: '2018-05-10',
        prRelationshipId: 'rel-child',
      );

      const a = AddFamilyMemberIntent(patientId: 'pat-1', request: request);
      const b = AddFamilyMemberIntent(patientId: 'pat-2', request: request);

      expect(a, isNot(equals(b)));
    });

    group('parseFromBody — Result<AddFamilyMemberIntent> (P2 if-case)', () {
      test('returns Success when required fields are present (CPF path)', () {
        final result = AddFamilyMemberIntent.parseFromBody(
          'pat-1',
          _validBodyWithCpf(),
        );

        expect(result, isA<Success<AddFamilyMemberIntent>>());
      });

      test(
        'Success payload preserves relationship, birthDate, prRelationshipId, '
        'cpf and fullName',
        () {
          final result = AddFamilyMemberIntent.parseFromBody(
            'pat-1',
            _validBodyWithCpf(),
          );

          switch (result) {
            case Success(:final value):
              expect(value.patientId, equals('pat-1'));
              expect(value.request.relationship, equals('CHILD'));
              expect(value.request.birthDate, equals('2018-05-10'));
              expect(value.request.prRelationshipId, equals('rel-child'));
              expect(value.cpf, equals('11144477735'));
              expect(value.fullName, equals('Ana Silva'));
              // When CPF is present and memberPersonId absent, the request
              // starts with empty personId — Wave 1 UseCase fills it in.
              expect(value.request.memberPersonId, equals(''));
            case Failure():
              fail('Expected Success, got Failure');
          }
        },
      );

      test('Success preserves memberPersonId when provided (no-CPF path)', () {
        final result = AddFamilyMemberIntent.parseFromBody(
          'pat-1',
          _validBodyWithPersonId(),
        );

        switch (result) {
          case Success(:final value):
            expect(value.request.memberPersonId, equals('per-42'));
            expect(value.cpf, isNull);
          case Failure():
            fail('Expected Success');
        }
      });

      test('returns Failure when relationship is missing', () {
        final body = _validBodyWithCpf()..remove('relationship');

        final result = AddFamilyMemberIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<AddFamilyMemberIntent>>());
      });

      test('returns Failure when birthDate is missing', () {
        final body = _validBodyWithCpf()..remove('birthDate');

        final result = AddFamilyMemberIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<AddFamilyMemberIntent>>());
      });

      test('returns Failure when prRelationshipId is missing', () {
        final body = _validBodyWithCpf()..remove('prRelationshipId');

        final result = AddFamilyMemberIntent.parseFromBody('pat-1', body);

        expect(result, isA<Failure<AddFamilyMemberIntent>>());
      });

      test('returns Failure when body is empty', () {
        final result = AddFamilyMemberIntent.parseFromBody('pat-1', const {});

        expect(result, isA<Failure<AddFamilyMemberIntent>>());
      });

      test('returns Failure when patientId is empty', () {
        final result = AddFamilyMemberIntent.parseFromBody(
          '',
          _validBodyWithCpf(),
        );

        expect(result, isA<Failure<AddFamilyMemberIntent>>());
      });

      test('Failure message does NOT echo raw CPF (PII)', () {
        // Missing relationship forces failure while CPF is present in body.
        final body = _validBodyWithCpf()..remove('relationship');

        final result = AddFamilyMemberIntent.parseFromBody('pat-1', body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(
              error.toString(),
              isNot(contains('11144477735')),
              reason: 'Parse error must never echo raw CPF',
            );
        }
      });

      test('Failure message does NOT echo raw fullName (PII)', () {
        final body = _validBodyWithCpf()..remove('relationship');

        final result = AddFamilyMemberIntent.parseFromBody('pat-1', body);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(
              error.toString(),
              isNot(contains('Ana Silva')),
              reason: 'Parse error must never echo raw full name',
            );
        }
      });
    });
  });
}
