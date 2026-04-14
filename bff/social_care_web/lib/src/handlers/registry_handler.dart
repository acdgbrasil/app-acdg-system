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
    r.get('/people/by-cpf/<cpf>', _findPersonByCpf);
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

      // Separate PR member from extra members.
      // Backend RegisterPatient only accepts the PR — extra members
      // must be added via POST /patients/:id/family-members.
      final prRelationshipId = body['prRelationshipId'] as String?;
      final extraMembers = <Map<String, dynamic>>[];

      for (final m in familyMembers) {
        if (m is Map<String, dynamic>) {
          final rel = m['relationship'] as String?;
          if (rel != prRelationshipId) {
            extraMembers.add(m);
          }
        }
      }

      print('[BFF:Register] Total members: ${familyMembers.length}, PR rel: $prRelationshipId, extra: ${extraMembers.length}');

      // Keep only the PR member for the initial registration
      body['familyMembers'] = familyMembers
          .where((m) => m is Map<String, dynamic> && m['relationship'] == prRelationshipId)
          .toList();

      final patientResult = PatientTranslator.fromJson(body);

      if (patientResult case Failure(:final error)) {
        return jsonError(400, error.toString());
      }

      final patient = (patientResult as Success).value;
      final registerResult = await contract.registerPatient(patient);

      if (registerResult case Failure(:final error)) {
        return backendError(error);
      }

      final patientId = (registerResult as Success).value;

      // Now add each extra member via POST /patients/:id/family-members
      if (extraMembers.isNotEmpty && prRelationshipId != null) {
        final LookupId prRelId;
        switch (LookupId.create(prRelationshipId)) {
          case Success(:final value):
            prRelId = value;
          case Failure():
            print('[BFF:Register] ⚠️ Invalid prRelationshipId, skipping extra members');
            return jsonOk({'id': patientId.value});
        }

        for (final memberJson in extraMembers) {
          final memberName = memberJson['fullName'] as String? ?? '';
          final memberBirth = memberJson['birthDate'] as String? ?? '';
          final memberCpf = memberJson['cpf'] as String?;

          print('[BFF:Register] Adding extra member: rel=${memberJson['relationship']}, name=$memberName');

          // 1. Register in People Context (same logic as _addFamilyMember)
          if (memberName.isNotEmpty && memberBirth.isNotEmpty) {
            final pcResult = await peopleContext.registerPerson(
              fullName: memberName,
              birthDate: memberBirth,
              cpf: memberCpf,
            );
            switch (pcResult) {
              case Success(value: final canonicalId):
                print('[BFF:Register] People Context OK: personId=$canonicalId');
                memberJson['personId'] = canonicalId;
                memberJson['memberPersonId'] = canonicalId;
              case Failure(:final error):
                print('[BFF:Register] People Context failed (non-blocking): $error');
            }
          }

          // 2. Add to patient via contract
          memberJson['prRelationshipId'] = prRelationshipId;

          final memberResult = PatientTranslator.familyMemberFromJson(memberJson);
          switch (memberResult) {
            case Success(:final value):
              final addResult = await contract.addFamilyMember(patientId, value, prRelId);
              switch (addResult) {
                case Success():
                  print('[BFF:Register] ✅ Extra member added');
                case Failure(:final error):
                  print('[BFF:Register] ⚠️ Failed to add extra member: $error');
              }
            case Failure(:final error):
              print('[BFF:Register] ⚠️ Failed to parse extra member: $error');
          }
        }
      }

      // Persist optional sections that backend ignores during register
      // (intakeInfo, socialIdentity are attached via copyWith but not saved)

      final intakeInfoJson = body['intakeInfo'] as Map<String, dynamic>?;
      if (intakeInfoJson != null) {
        print('[BFF:Register] Saving intakeInfo via PUT');
        final intakeResult = PatientTranslator.intakeInfoFromJson(intakeInfoJson);
        switch (intakeResult) {
          case Success(:final value):
            final putResult = await contract.updateIntakeInfo(patientId, value);
            switch (putResult) {
              case Success():
                print('[BFF:Register] ✅ IntakeInfo saved');
              case Failure(:final error):
                print('[BFF:Register] ⚠️ IntakeInfo save failed: $error');
            }
          case Failure(:final error):
            print('[BFF:Register] ⚠️ IntakeInfo parse failed: $error');
        }
      }

      final socialIdentityJson = body['socialIdentity'] as Map<String, dynamic>?;
      if (socialIdentityJson != null) {
        print('[BFF:Register] Saving socialIdentity via PUT');
        final idResult = PatientTranslator.socialIdentityFromJson(socialIdentityJson);
        switch (idResult) {
          case Success(:final value):
            final putResult = await contract.updateSocialIdentity(patientId, value);
            switch (putResult) {
              case Success():
                print('[BFF:Register] ✅ SocialIdentity saved');
              case Failure(:final error):
                print('[BFF:Register] ⚠️ SocialIdentity save failed: $error');
            }
          case Failure(:final error):
            print('[BFF:Register] ⚠️ SocialIdentity parse failed: $error');
        }
      }

      return jsonOk({'id': patientId.value});
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── GET /patients/<id> ────────────────────────────────────────

  Future<Response> _fetchPatient(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    final patientIdResult = PatientId.create(id);
    return switch (patientIdResult) {
      Success(:final value) => switch (await contract.fetchPatient(value)) {
        Success(:final value) => () async {
          final json = value.toJson();
          await _enrichFamilyMembers(json, peopleContext);
          return jsonOk(json);
        }(),
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
      print('[BFF:AddMember] body keys: ${body.keys.toList()}');
      print('[BFF:AddMember] fullName="$fullName", birthDate="$memberBirthDate", sex=${body['sex']}');

      if (fullName.isNotEmpty && memberBirthDate.isNotEmpty) {
        final pcResult = await peopleContext.registerPerson(
          fullName: fullName,
          birthDate: memberBirthDate,
          cpf: cpf,
        );
        switch (pcResult) {
          case Success(value: final canonicalPersonId):
            print('[BFF:AddMember] people-context OK: personId=$canonicalPersonId');
            body['personId'] = canonicalPersonId;
            body['memberPersonId'] = canonicalPersonId;
          case Failure(:final error):
            print('[BFF:AddMember] people-context FAILED: $error');
            break;
        }
      } else {
        print('[BFF:AddMember] SKIPPED people-context: fullName or birthDate empty');
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

  // ── GET /people/by-cpf/<cpf> ──────────────────────────────────

  Future<Response> _findPersonByCpf(Request request, String cpf) async {
    final session = getSession(request);
    final peopleContext = _peopleContextFactory(session);

    switch (await peopleContext.findPersonByCpf(cpf)) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        if (error == 'not_found') {
          return jsonError(404, 'Person not found');
        }
        return jsonError(502, error.toString());
    }
  }

  // ── Enrichment ────────────────────────────────────────────────

  /// Enriches family members in a patient JSON with names from people-context.
  ///
  /// Also enriches the root `personId` (reference person).
  /// Gracefully degrades — if people-context fails, the member
  /// is returned without enrichment.
  Future<void> _enrichFamilyMembers(
    Map<String, dynamic> patientJson,
    PeopleContextClient peopleContext,
  ) async {
    // Enrich reference person
    final personId = patientJson['personId'] as String?;
    if (personId != null) {
      switch (await peopleContext.getPerson(personId)) {
        case Success(:final value):
          final pd = patientJson['personalData'] as Map<String, dynamic>? ?? {};
          if (pd['firstName'] == null || pd['lastName'] == null) {
            final fullName = value['fullName'] as String? ?? '';
            final parts = fullName.split(' ');
            pd['firstName'] ??= parts.first;
            pd['lastName'] ??= parts.skip(1).join(' ');
            patientJson['personalData'] = pd;
          }
        case Failure():
          break;
      }
    }

    // Enrich family members with people-context data
    final members = patientJson['familyMembers'] as List<dynamic>? ?? [];
    for (final member in members) {
      if (member is Map<String, dynamic>) {
        final memberId = member['personId'] as String?;
        if (memberId != null && member['fullName'] == null) {
          switch (await peopleContext.getPerson(memberId)) {
            case Success(:final value):
              member['fullName'] = value['fullName'];
            case Failure():
              break;
          }
        }
      }
    }
  }

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
