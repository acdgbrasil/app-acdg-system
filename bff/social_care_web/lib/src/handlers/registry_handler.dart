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
        final enriched = await _enrichSummaries(value.data, peopleContext);
        return jsonOk({
          'data': enriched,
          'meta': value.meta.toJson(),
        });
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

      final registerRequest = RegisterPatientRequest.fromJson(body);
      final registerResult = await contract.registerPatient(registerRequest);

      if (registerResult case Failure(:final error)) {
        return backendError(error);
      }

      final idResponse = (registerResult as Success<StandardIdResponse>).value;
      final patientId = idResponse.data.id;

      // Now add each extra member via POST /patients/:id/family-members
      if (extraMembers.isNotEmpty && prRelationshipId != null) {
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

          try {
            final memberDto = AddFamilyMemberRequest.fromJson(memberJson);
            final addResult = await contract.addFamilyMember(patientId, memberDto);
            switch (addResult) {
              case Success():
                print('[BFF:Register] Extra member added');
              case Failure(:final error):
                print('[BFF:Register] Failed to add extra member: $error');
            }
          } catch (e) {
            print('[BFF:Register] Failed to parse extra member: $e');
          }
        }
      }

      // Persist optional sections that backend ignores during register
      final intakeInfoJson = body['intakeInfo'] as Map<String, dynamic>?;
      if (intakeInfoJson != null) {
        print('[BFF:Register] Saving intakeInfo via PUT');
        try {
          final intakeDto = RegisterIntakeInfoRequest.fromJson(intakeInfoJson);
          final putResult = await contract.updateIntakeInfo(patientId, intakeDto);
          switch (putResult) {
            case Success():
              print('[BFF:Register] IntakeInfo saved');
            case Failure(:final error):
              print('[BFF:Register] IntakeInfo save failed: $error');
          }
        } catch (e) {
          print('[BFF:Register] IntakeInfo parse failed: $e');
        }
      }

      final socialIdentityJson = body['socialIdentity'] as Map<String, dynamic>?;
      if (socialIdentityJson != null) {
        print('[BFF:Register] Saving socialIdentity via PUT');
        try {
          final identityDto = UpdateSocialIdentityRequest.fromJson(socialIdentityJson);
          final putResult = await contract.updateSocialIdentity(patientId, identityDto);
          switch (putResult) {
            case Success():
              print('[BFF:Register] SocialIdentity saved');
            case Failure(:final error):
              print('[BFF:Register] SocialIdentity save failed: $error');
          }
        } catch (e) {
          print('[BFF:Register] SocialIdentity parse failed: $e');
        }
      }

      return jsonOk({
        'data': {'id': patientId},
        'meta': {'timestamp': idResponse.meta.timestamp},
      });
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── GET /patients/<id> ────────────────────────────────────────

  Future<Response> _fetchPatient(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    return switch (await contract.fetchPatient(id)) {
      Success(:final value) => () async {
        final json = value.data.toJson();
        await _enrichFamilyMembers(json, peopleContext);
        return jsonOk({
          'data': json,
          'meta': {'timestamp': value.meta.timestamp},
        });
      }(),
      Failure(:final error) => backendError(error),
    };
  }

  // ── POST /patients/<id>/family-members ────────────────────────

  Future<Response> _addFamilyMember(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final peopleContext = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);

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

      final dto = AddFamilyMemberRequest.fromJson(body);

      return switch (await contract.addFamilyMember(id, dto, cpf: cpf)) {
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

    return switch (await contract.removeFamilyMember(id, memberId)) {
      Success() => jsonNoContent(),
      Failure(:final error) => backendError(error),
    };
  }

  // ── PUT /patients/<id>/primary-caregiver ──────────────────────

  Future<Response> _assignPrimaryCaregiver(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = AssignPrimaryCaregiverRequest.fromJson(body);

      return switch (await contract.assignPrimaryCaregiver(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
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
      final dto = UpdateSocialIdentityRequest.fromJson(body);

      return switch (await contract.updateSocialIdentity(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── GET /patients/<id>/audit-trail ────────────────────────────

  Future<Response> _getAuditTrail(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);
    final eventType = request.requestedUri.queryParameters['eventType'];

    return switch (await contract.getAuditTrail(id, eventType: eventType)) {
      Success(:final value) => jsonOk({
        'data': value.data.map((e) => e.toJson()).toList(),
        'meta': {'timestamp': value.meta.timestamp},
      }),
      Failure(:final error) => backendError(error),
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

  Future<List<Map<String, dynamic>>> _enrichSummaries(
    List<PatientSummaryResponse> summaries,
    PeopleContextClient peopleContext,
  ) async {
    final enriched = <Map<String, dynamic>>[];
    for (final summary in summaries) {
      final json = summary.toJson();
      switch (await peopleContext.getPerson(summary.personId)) {
        case Success(:final value):
          json['fullName'] = value['fullName'];
          json['birthDate'] = value['birthDate'];
        case Failure():
          break;
      }
      enriched.add(json);
    }
    return enriched;
  }
}
