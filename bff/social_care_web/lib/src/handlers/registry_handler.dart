import 'dart:developer' as dev;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import '../remote/people_context_client.dart';
import 'handler_utils.dart';

typedef RegistryContractFactory = SocialCareContract Function(Session session);
typedef RegistryPeopleContextFactory = PeopleContextClient Function(
  Session session,
);

void _log(String method, String msg) =>
    print('[BFF:Registry] $method — $msg');

class RegistryHandler {
  RegistryHandler({
    required RegistryContractFactory contractFactory,
    required RegistryPeopleContextFactory peopleContextFactory,
  }) : _contractFactory = contractFactory,
       _peopleContextFactory = peopleContextFactory;

  final RegistryContractFactory _contractFactory;
  final RegistryPeopleContextFactory _peopleContextFactory;

  Router get router {
    final r = Router();
    r.get('/patients', _fetchPatients);
    r.post('/patients', _registerPatient);
    r.get('/patients/<id>', _fetchPatient);
    r.post('/patients/<id>/family-members', _addFamilyMember);
    r.delete('/patients/<id>/family-members/<memberId>', _removeFamilyMember);
    r.put('/patients/<id>/primary-caregiver', _assignPrimaryCaregiver);
    r.put('/patients/<id>/social-identity', _updateSocialIdentity);
    r.get('/patients/<id>/audit-trail', _getAuditTrail);
    return r;
  }

  String _tokenSnippet(Session s) =>
      s.accessToken.isEmpty ? 'EMPTY' : '${s.accessToken.substring(0, 15)}...';

  Future<Response> _fetchPatients(Request request) async {
    _log('GET /patients', 'ENTER');
    final session = getSession(request);
    _log('GET /patients',
        'userId=${session.userId}, token=${_tokenSnippet(session)}, expired=${session.isExpired()}');
    final contract = _contractFactory(session);
    final result = await contract.fetchPatients();
    _log('GET /patients',
        'result=${result.isSuccess ? "SUCCESS(${(result as Success).value.length} items)" : "FAIL(${(result as Failure).error})"}');
    return switch (result) {
      Success(:final value) => jsonOk(value.map((p) => p.toJson()).toList()),
      Failure(:final error) => jsonError(500, error.toString()),
    };
  }

  Future<Response> _registerPatient(Request request) async {
    _log('POST /patients', 'ENTER');
    final session = getSession(request);
    _log('POST /patients',
        'userId=${session.userId}, token=${_tokenSnippet(session)}, expired=${session.isExpired()}');
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);
      _log('POST /patients', 'body keys: ${body.keys.toList()}');

      // Extract person data from nested structure
      final personalData =
          body['personalData'] as Map<String, dynamic>? ?? {};
      final civilDocs =
          body['civilDocuments'] as Map<String, dynamic>? ?? {};
      final firstName = personalData['firstName'] as String? ?? '';
      final lastName = personalData['lastName'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final birthDate = personalData['birthDate'] as String? ??
          civilDocs['birthDate'] as String? ?? '';
      final cpf = civilDocs['cpf'] as String?;

      _log('POST /patients', 'Registering person in people-context: $fullName, birthDate=$birthDate');
      final personIdResult = await peopleContext.registerPerson(
        fullName: fullName,
        birthDate: birthDate,
        cpf: cpf,
      );

      switch (personIdResult) {
        case Failure(:final error):
          _log('POST /patients', 'people-context FAILED: $error');
          return jsonError(
            502,
            'Failed to register person in people-context: $error',
          );
        case Success(value: final canonicalPersonId):
          _log('POST /patients', 'people-context OK: personId=$canonicalPersonId');
          body['personId'] = canonicalPersonId;
      }

      // Register each family member in people-context (if name available)
      final familyMembers = body['familyMembers'] as List<dynamic>? ?? [];
      _log('POST /patients', 'familyMembers count: ${familyMembers.length}');
      for (var i = 0; i < familyMembers.length; i++) {
        final member = familyMembers[i];
        if (member is Map<String, dynamic>) {
          final memberName = member['fullName'] as String? ?? '';
          final memberBirth = member['birthDate'] as String? ?? '';
          final memberCpf = member['cpf'] as String?;

          if (memberName.isNotEmpty && memberBirth.isNotEmpty) {
            _log('POST /patients', 'Registering family member[$i] in people-context: $memberName');
            final memberPersonId = await peopleContext.registerPerson(
              fullName: memberName,
              birthDate: memberBirth,
              cpf: memberCpf,
            );

            switch (memberPersonId) {
              case Success(value: final id):
                _log('POST /patients', 'family member[$i] people-context OK: personId=$id');
                member['personId'] = id;
                member['memberPersonId'] = id;
              case Failure(:final error):
                _log('POST /patients', 'family member[$i] people-context FAILED: $error (non-blocking)');
            }
          } else {
            _log('POST /patients', 'family member[$i] skipping people-context — name or birthDate missing');
          }
        }
      }

      _log('POST /patients', 'Calling PatientTranslator.fromJson...');
      final patientResult = PatientTranslator.fromJson(body);

      return switch (patientResult) {
        Success(:final value) => () async {
          _log('POST /patients', 'PatientTranslator OK. Calling backend registerPatient...');
          final regResult = await contract.registerPatient(value);
          _log('POST /patients',
              'backend result=${regResult.isSuccess ? "SUCCESS" : "FAIL(${(regResult as Failure).error})"}');
          return switch (regResult) {
            Success(:final value) => jsonOk({'id': value.value}),
            Failure(:final error) => jsonError(500, error.toString()),
          };
        }(),
        Failure(:final error) => () {
          _log('POST /patients', 'PatientTranslator FAILED: $error');
          return jsonError(400, error.toString());
        }(),
      };
    } catch (e, st) {
      _log('POST /patients', 'EXCEPTION: $e\n$st');
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _fetchPatient(Request request, String id) async {
    _log('GET /patients/$id', 'ENTER');
    final session = getSession(request);
    _log('GET /patients/$id',
        'userId=${session.userId}, token=${_tokenSnippet(session)}');
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    return switch (patientIdResult) {
      Success(:final value) => () async {
        final result = await contract.fetchPatient(value);
        _log('GET /patients/$id',
            'result=${result.isSuccess ? "SUCCESS" : "FAIL(${(result as Failure).error})"}');
        return switch (result) {
          Success(:final value) => jsonOk(value.toJson()),
          Failure(:final error) => jsonError(500, error.toString()),
        };
      }(),
      Failure(:final error) => () {
        _log('GET /patients/$id', 'Invalid ID: $error');
        return jsonError(400, 'Invalid patient ID: $error');
      }(),
    };
  }

  Future<Response> _addFamilyMember(Request request, String id) async {
    _log('POST /patients/$id/family-members', 'ENTER');
    final session = getSession(request);
    _log('POST /patients/$id/family-members',
        'userId=${session.userId}, token=${_tokenSnippet(session)}, expired=${session.isExpired()}');
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);
      _log('POST /patients/$id/family-members', 'body keys: ${body.keys.toList()}');

      final PatientId patientId;
      switch (PatientId.create(id)) {
        case Success(:final value):
          patientId = value;
        case Failure(:final error):
          _log('POST /patients/$id/family-members', 'Invalid patient ID: $error');
          return jsonError(400, 'Invalid patient ID: $error');
      }

      final prRelationshipIdStr = body['prRelationshipId'] as String?;
      if (prRelationshipIdStr == null) {
        _log('POST /patients/$id/family-members', 'Missing prRelationshipId');
        return jsonError(400, 'Missing prRelationshipId');
      }

      // Register person in people-context if name is available
      final fullName = body['fullName'] as String? ?? '';
      final memberBirthDate = body['birthDate'] as String? ?? '';
      final cpf = body['cpf'] as String?;

      if (fullName.isNotEmpty && memberBirthDate.isNotEmpty) {
        _log('POST /patients/$id/family-members',
            'Registering in people-context: $fullName');
        switch (await peopleContext.registerPerson(
          fullName: fullName,
          birthDate: memberBirthDate,
          cpf: cpf,
        )) {
          case Success(value: final canonicalPersonId):
            _log('POST /patients/$id/family-members',
                'people-context OK: personId=$canonicalPersonId');
            body['personId'] = canonicalPersonId;
            body['memberPersonId'] = canonicalPersonId;
          case Failure(:final error):
            _log('POST /patients/$id/family-members',
                'people-context FAILED: $error (non-blocking)');
        }
      } else {
        _log('POST /patients/$id/family-members',
            'Skipping people-context — fullName or birthDate missing');
      }

      final LookupId prRelId;
      switch (LookupId.create(prRelationshipIdStr)) {
        case Success(:final value):
          prRelId = value;
        case Failure(:final error):
          _log('POST /patients/$id/family-members',
              'Invalid prRelationshipId: $error');
          return jsonError(400, 'Invalid prRelationshipId: $error');
      }

      _log('POST /patients/$id/family-members',
          'Calling PatientTranslator.familyMemberFromJson...');
      final FamilyMember member;
      switch (PatientTranslator.familyMemberFromJson(body)) {
        case Success(:final value):
          member = value;
          _log('POST /patients/$id/family-members', 'FamilyMember parsed OK');
        case Failure(:final error):
          _log('POST /patients/$id/family-members',
              'FamilyMember parse FAILED: $error');
          return jsonError(400, 'Invalid family member: $error');
      }

      _log('POST /patients/$id/family-members',
          'Calling backend addFamilyMember...');
      final result = await contract.addFamilyMember(patientId, member, prRelId);
      _log('POST /patients/$id/family-members',
          'backend result=${result.isSuccess ? "SUCCESS" : "FAIL(${(result as Failure).error})"}');

      return switch (result) {
        Success() => jsonNoContent(),
        Failure(:final error) => jsonError(500, error.toString()),
      };
    } catch (e, st) {
      _log('POST /patients/$id/family-members', 'EXCEPTION: $e\n$st');
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _removeFamilyMember(
    Request request,
    String id,
    String memberId,
  ) async {
    _log('DELETE /patients/$id/family-members/$memberId', 'ENTER');
    final session = getSession(request);
    _log('DELETE /patients/$id/family-members/$memberId',
        'token=${_tokenSnippet(session)}');
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    final memberIdResult = PersonId.create(memberId);

    return switch ((patientIdResult, memberIdResult)) {
      (Success(:final value), Success(value: final member)) => () async {
        final result = await contract.removeFamilyMember(value, member);
        _log('DELETE /patients/$id/family-members/$memberId',
            'result=${result.isSuccess ? "SUCCESS" : "FAIL"}');
        return switch (result) {
          Success() => jsonNoContent(),
          Failure(:final error) => jsonError(500, error.toString()),
        };
      }(),
      (Failure(:final error), _) => jsonError(400, 'Invalid patient ID: $error'),
      (_, Failure(:final error)) => jsonError(400, 'Invalid member ID: $error'),
    };
  }

  Future<Response> _assignPrimaryCaregiver(Request request, String id) async {
    _log('PUT /patients/$id/primary-caregiver', 'ENTER');
    final session = getSession(request);
    _log('PUT /patients/$id/primary-caregiver',
        'token=${_tokenSnippet(session)}');
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final patientIdResult = PatientId.create(id);
      final memberPersonId = body['memberPersonId'] as String?;

      if (memberPersonId == null) {
        return jsonError(400, 'Missing memberPersonId');
      }

      final memberIdResult = PersonId.create(memberPersonId);

      return switch ((patientIdResult, memberIdResult)) {
        (Success(:final value), Success(value: final member)) => () async {
          final result = await contract.assignPrimaryCaregiver(value, member);
          _log('PUT /patients/$id/primary-caregiver',
              'result=${result.isSuccess ? "SUCCESS" : "FAIL"}');
          return switch (result) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          };
        }(),
        (Failure(:final error), _) =>
          jsonError(400, 'Invalid patient ID: $error'),
        (_, Failure(:final error)) =>
          jsonError(400, 'Invalid member person ID: $error'),
      };
    } catch (e, st) {
      _log('PUT /patients/$id/primary-caregiver', 'EXCEPTION: $e\n$st');
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateSocialIdentity(Request request, String id) async {
    _log('PUT /patients/$id/social-identity', 'ENTER');
    final session = getSession(request);
    _log('PUT /patients/$id/social-identity',
        'token=${_tokenSnippet(session)}');
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final patientIdResult = PatientId.create(id);
      final identityResult = PatientTranslator.socialIdentityFromJson(body);

      return switch ((patientIdResult, identityResult)) {
        (Success(:final value), Success(value: final identity)) => () async {
          final result = await contract.updateSocialIdentity(value, identity);
          _log('PUT /patients/$id/social-identity',
              'result=${result.isSuccess ? "SUCCESS" : "FAIL"}');
          return switch (result) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          };
        }(),
        (Failure(:final error), _) =>
          jsonError(400, 'Invalid patient ID: $error'),
        (_, Failure(:final error)) =>
          jsonError(400, 'Invalid social identity: $error'),
      };
    } catch (e, st) {
      _log('PUT /patients/$id/social-identity', 'EXCEPTION: $e\n$st');
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _getAuditTrail(Request request, String id) async {
    _log('GET /patients/$id/audit-trail', 'ENTER');
    final session = getSession(request);
    _log('GET /patients/$id/audit-trail', 'token=${_tokenSnippet(session)}');
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    final eventType = request.requestedUri.queryParameters['eventType'];

    return switch (patientIdResult) {
      Success(:final value) => () async {
        final result = await contract.getAuditTrail(
          value,
          eventType: eventType,
        );
        _log('GET /patients/$id/audit-trail',
            'result=${result.isSuccess ? "SUCCESS" : "FAIL"}');
        return switch (result) {
          Success(:final value) => jsonOk(
            value
                .map(
                  (e) => {
                    'id': e.id,
                    'aggregateId': e.aggregateId,
                    'eventType': e.eventType,
                    'actorId': e.actorId,
                    'payload': e.payload,
                    'occurredAt': e.occurredAt.toISOString(),
                    'recordedAt': e.recordedAt.toISOString(),
                  },
                )
                .toList(),
          ),
          Failure(:final error) => jsonError(500, error.toString()),
        };
      }(),
      Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
    };
  }
}
