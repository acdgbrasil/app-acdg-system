import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import '../remote/people_context_client.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef RegistryContractFactory = SocialCareContract Function(Session session);

/// Factory that creates a [PeopleContextClient] for a given [Session].
typedef RegistryPeopleContextFactory = PeopleContextClient Function(
  Session session,
);

/// Handles patient registry endpoints.
///
/// Routes:
/// - `GET    /patients`                              — list patients
/// - `POST   /patients`                              — register patient
/// - `GET    /patients/<id>`                          — get patient detail
/// - `POST   /patients/<id>/family-members`           — add family member
/// - `DELETE  /patients/<id>/family-members/<memberId>` — remove family member
/// - `PUT    /patients/<id>/primary-caregiver`         — assign primary caregiver
/// - `PUT    /patients/<id>/social-identity`           — update social identity
/// - `GET    /patients/<id>/audit-trail`               — get audit trail
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

  Future<Response> _fetchPatients(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final result = await contract.fetchPatients();

    return switch (result) {
      Success(:final value) => jsonOk(value.map((p) => p.toJson()).toList()),
      Failure(:final error) => jsonError(500, error.toString()),
    };
  }

  Future<Response> _registerPatient(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);

      // Register the reference person in people-context
      final firstName = body['firstName'] as String? ?? '';
      final lastName = body['lastName'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final birthDate = body['birthDate'] as String? ?? '';
      final cpf = body['cpf'] as String?;

      final personIdResult = await peopleContext.registerPerson(
        fullName: fullName,
        birthDate: birthDate,
        cpf: cpf,
      );

      switch (personIdResult) {
        case Failure(:final error):
          return jsonError(
            502,
            'Failed to register person in people-context: $error',
          );
        case Success(value: final canonicalPersonId):
          body['personId'] = canonicalPersonId;
      }

      // Register each family member in people-context
      final familyMembers = body['familyMembers'] as List<dynamic>? ?? [];
      for (final member in familyMembers) {
        if (member is Map<String, dynamic>) {
          final memberName = member['fullName'] as String? ?? '';
          final memberBirth = member['birthDate'] as String? ?? '';
          final memberCpf = member['cpf'] as String?;

          final memberPersonId = await peopleContext.registerPerson(
            fullName: memberName,
            birthDate: memberBirth,
            cpf: memberCpf,
          );

          switch (memberPersonId) {
            case Success(value: final id):
              member['personId'] = id;
              member['memberPersonId'] = id;
            case Failure():
              break; // Non-blocking — member keeps generated ID
          }
        }
      }

      final patientResult = PatientTranslator.fromJson(body);

      return switch (patientResult) {
        Success(:final value) => switch (await contract.registerPatient(
          value,
        )) {
          Success(:final value) => jsonOk({'id': value.value}),
          Failure(:final error) => jsonError(500, error.toString()),
        },
        Failure(:final error) => jsonError(400, error.toString()),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _fetchPatient(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    return switch (patientIdResult) {
      Success(:final value) => switch (await contract.fetchPatient(value)) {
        Success(:final value) => jsonOk(value.toJson()),
        Failure(:final error) => jsonError(500, error.toString()),
      },
      Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
    };
  }

  Future<Response> _addFamilyMember(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);

      final PatientId patientId;
      switch (PatientId.create(id)) {
        case Success(:final value):
          patientId = value;
        case Failure(:final error):
          return jsonError(400, 'Invalid patient ID: $error');
      }

      final prRelationshipIdStr = body['prRelationshipId'] as String?;
      if (prRelationshipIdStr == null) {
        return jsonError(400, 'Missing prRelationshipId');
      }

      // Register person in people-context first to get canonical PersonId
      final fullName = body['fullName'] as String? ?? '';
      final birthDate = body['birthDate'] as String? ?? '';
      final cpf = body['cpf'] as String?;

      switch (await peopleContext.registerPerson(
        fullName: fullName,
        birthDate: birthDate,
        cpf: cpf,
      )) {
        case Success(value: final canonicalPersonId):
          body['personId'] = canonicalPersonId;
          body['memberPersonId'] = canonicalPersonId;
        case Failure(:final error):
          return jsonError(
            502,
            'Failed to register person in people-context: $error',
          );
      }

      final LookupId prRelId;
      switch (LookupId.create(prRelationshipIdStr)) {
        case Success(:final value):
          prRelId = value;
        case Failure(:final error):
          return jsonError(400, 'Invalid prRelationshipId: $error');
      }

      final FamilyMember member;
      switch (PatientTranslator.familyMemberFromJson(body)) {
        case Success(:final value):
          member = value;
        case Failure(:final error):
          return jsonError(400, 'Invalid family member: $error');
      }

      return switch (await contract.addFamilyMember(
        patientId,
        member,
        prRelId,
      )) {
        Success() => jsonNoContent(),
        Failure(:final error) => jsonError(500, error.toString()),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _removeFamilyMember(
    Request request,
    String id,
    String memberId,
  ) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    final memberIdResult = PersonId.create(memberId);

    return switch ((patientIdResult, memberIdResult)) {
      (Success(:final value), Success(value: final member)) =>
        switch (await contract.removeFamilyMember(value, member)) {
          Success() => jsonNoContent(),
          Failure(:final error) => jsonError(500, error.toString()),
        },
      (Failure(:final error), _) => jsonError(
        400,
        'Invalid patient ID: $error',
      ),
      (_, Failure(:final error)) => jsonError(400, 'Invalid member ID: $error'),
    };
  }

  Future<Response> _assignPrimaryCaregiver(Request request, String id) async {
    final session = getSession(request);
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
        (Success(:final value), Success(value: final member)) =>
          switch (await contract.assignPrimaryCaregiver(value, member)) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid member person ID: $error',
        ),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateSocialIdentity(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final patientIdResult = PatientId.create(id);
      final identityResult = PatientTranslator.socialIdentityFromJson(body);

      return switch ((patientIdResult, identityResult)) {
        (Success(:final value), Success(value: final identity)) =>
          switch (await contract.updateSocialIdentity(value, identity)) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid social identity: $error',
        ),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _getAuditTrail(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    final eventType = request.requestedUri.queryParameters['eventType'];

    return switch (patientIdResult) {
      Success(:final value) => switch (await contract.getAuditTrail(
        value,
        eventType: eventType,
      )) {
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
      },
      Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
    };
  }
}
