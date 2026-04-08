import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

typedef RegistryContractFactory = SocialCareContract Function(Session session);
typedef RegistryPeopleContextFactory =
    PeopleContextClient Function(Session session);

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

  // ── GET /patients ─────────────────────────────────────────────

  Future<Response> _fetchPatients(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);
    final result = await contract.fetchPatients();

    return switch (result) {
      Success(:final value) => () async {
        final enriched = await _enrichOverviews(value, peopleContext);
        return jsonOk(enriched);
      }(),
      Failure(:final error) => backendError(error),
    };
  }

  // ── POST /patients ────────────────────────────────────────────

  Future<Response> _registerPatient(Request request) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);

      // Extract person data from nested structure for people-context
      final personalData = body['personalData'] as Map<String, dynamic>? ?? {};
      final civilDocs = body['civilDocuments'] as Map<String, dynamic>? ?? {};
      final firstName = personalData['firstName'] as String? ?? '';
      final lastName = personalData['lastName'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      final birthDate =
          personalData['birthDate'] as String? ??
          civilDocs['birthDate'] as String? ??
          '';
      final cpf = civilDocs['cpf'] as String?;

      // Register reference person in people-context (non-blocking on failure)
      if (fullName.isNotEmpty && birthDate.isNotEmpty) {
        switch (await peopleContext.registerPerson(
          fullName: fullName,
          birthDate: birthDate,
          cpf: cpf,
        )) {
          case Success(value: final canonicalPersonId):
            body['personId'] = canonicalPersonId;
          case Failure():
            break;
        }
      }

      // Register each family member in people-context (if name available)
      final familyMembers = body['familyMembers'] as List<dynamic>? ?? [];
      for (final member in familyMembers) {
        if (member is Map<String, dynamic>) {
          final memberName = member['fullName'] as String? ?? '';
          final memberBirth = member['birthDate'] as String? ?? '';
          final memberCpf = member['cpf'] as String?;

          if (memberName.isNotEmpty && memberBirth.isNotEmpty) {
            switch (await peopleContext.registerPerson(
              fullName: memberName,
              birthDate: memberBirth,
              cpf: memberCpf,
            )) {
              case Success(value: final id):
                member['personId'] = id;
                member['memberPersonId'] = id;
              case Failure():
                break;
            }
          }
        }
      }

      final patientResult = PatientTranslator.fromJson(body);

      return switch (patientResult) {
        Success(:final value) => switch (await contract.registerPatient(
          value,
        )) {
          Success(:final value) => jsonOk({'id': value.value}),
          Failure(:final error) => backendError(error),
        },
        Failure(:final error) => jsonError(400, error.toString()),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── GET /patients/<id> ────────────────────────────────────────

  Future<Response> _fetchPatient(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    final patientIdResult = PatientId.create(id);
    return switch (patientIdResult) {
      Success(:final value) => switch (await contract.fetchPatient(value)) {
        Success(:final value) => jsonOk(value.toJson()),
        Failure(:final error) => backendError(error),
      },
      Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
    };
  }

  // ── POST /patients/<id>/family-members ────────────────────────

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

      // Register person in people-context if name available (non-blocking)
      final fullName = body['fullName'] as String? ?? '';
      final memberBirthDate = body['birthDate'] as String? ?? '';
      final cpf = body['cpf'] as String?;

      if (fullName.isNotEmpty && memberBirthDate.isNotEmpty) {
        switch (await peopleContext.registerPerson(
          fullName: fullName,
          birthDate: memberBirthDate,
          cpf: cpf,
        )) {
          case Success(value: final canonicalPersonId):
            body['personId'] = canonicalPersonId;
            body['memberPersonId'] = canonicalPersonId;
          case Failure():
            break;
        }
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
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── DELETE /patients/<id>/family-members/<memberId> ───────────

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
          Failure(:final error) => backendError(error),
        },
      (Failure(:final error), _) => jsonError(
        400,
        'Invalid patient ID: $error',
      ),
      (_, Failure(:final error)) => jsonError(400, 'Invalid member ID: $error'),
    };
  }

  // ── PUT /patients/<id>/primary-caregiver ──────────────────────

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
            Failure(:final error) => backendError(error),
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

  // ── PUT /patients/<id>/social-identity ────────────────────────

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
            Failure(:final error) => backendError(error),
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

  // ── GET /patients/<id>/audit-trail ────────────────────────────

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
        Failure(:final error) => backendError(error),
      },
      Failure(:final error) => jsonError(400, 'Invalid patient ID: $error'),
    };
  }

  // ── Enrichment ────────────────────────────────────────────────

  /// Enriches patient overviews with person data from people-context.
  ///
  /// For each overview, calls `getPerson(personId)` and injects
  /// `fullName` and `birthDate` into the JSON response.
  /// Gracefully degrades — if people-context fails, the overview
  /// is returned without enrichment.
  Future<List<Map<String, dynamic>>> _enrichOverviews(
    List<PatientOverview> overviews,
    PeopleContextClient peopleContext,
  ) async {
    final enriched = <Map<String, dynamic>>[];
    for (final overview in overviews) {
      final json = overview.toJson();
      switch (await peopleContext.getPerson(overview.personId)) {
        case Success(:final value):
          json['fullName'] = value['fullName'];
          json['birthDate'] = value['birthDate'];
        case Failure():
          break; // Graceful degradation
      }
      enriched.add(json);
    }
    return enriched;
  }
}
