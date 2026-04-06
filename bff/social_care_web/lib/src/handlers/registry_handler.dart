import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef RegistryContractFactory = SocialCareContract Function(Session session);

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
  RegistryHandler({required RegistryContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final RegistryContractFactory _contractFactory;

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

    try {
      final body = await readJsonBody(request);
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

    try {
      final body = await readJsonBody(request);
      final patientIdResult = PatientId.create(id);

      return switch (patientIdResult) {
        Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
        Success(:final value) => () async {
          final patientId = value;
          final prRelationshipIdStr = body['prRelationshipId'] as String?;
          if (prRelationshipIdStr == null) {
            return jsonError(400, 'Missing prRelationshipId');
          }

          final prRelResult = LookupId.create(prRelationshipIdStr);
          final memberResult = PatientTranslator.familyMemberFromJson(body);

          return switch ((prRelResult, memberResult)) {
            (Success(:final value), Success(value: final member)) =>
              switch (await contract.addFamilyMember(
                patientId,
                member,
                value,
              )) {
                Success() => jsonNoContent(),
                Failure(:final error) => jsonError(500, error.toString()),
              },
            (Failure(:final error), _) => jsonError(
              400,
              'Invalid prRelationshipId: $error',
            ),
            (_, Failure(:final error)) => jsonError(
              400,
              'Invalid family member: $error',
            ),
          };
        }(),
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
