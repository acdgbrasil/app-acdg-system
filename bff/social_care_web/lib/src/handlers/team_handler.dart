import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [PeopleContextClient] for a given [Session].
typedef TeamPeopleContextFactory =
    PeopleContextClient Function(Session session);

/// Handles team management endpoints.
///
/// Proxies requests to the People Context service for:
/// - Listing team members (by role query)
/// - Registering new professionals (with Zitadel login)
/// - Deactivating/reactivating team members
/// - Requesting password resets
class TeamHandler {
  TeamHandler({required TeamPeopleContextFactory peopleContextFactory})
    : _peopleContextFactory = peopleContextFactory;

  final TeamPeopleContextFactory _peopleContextFactory;

  Router get router {
    final r = Router();
    r.get('/team', _listTeam);
    r.post('/team', _registerWorker);
    r.put('/team/<id>/deactivate', _deactivateWorker);
    r.put('/team/<id>/reactivate', _reactivateWorker);
    r.post('/team/<id>/reset-password', _resetPassword);
    r.get('/team/people', _fetchPeople);
    r.get('/team/people/by-cpf/<cpf>', _getPersonByCpf);
    r.get('/team/people/<id>', _getPerson);
    r.get('/team/people/<id>/roles', _fetchRolesForPerson);
    r.post('/team/people/<id>/roles', _assignRoleToPerson);
    r.put('/team/people/<id>/roles/<roleId>/deactivate', _deactivateRole);
    r.put('/team/people/<id>/roles/<roleId>/reactivate', _reactivateRole);
    return r;
  }

  // ── GET /team ──────────────────────────────────────────────────

  Future<Response> _listTeam(Request request) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.queryRoles(system: 'social-care')) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── POST /team ─────────────────────────────────────────────────

  Future<Response> _registerWorker(Request request) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);
      final fullName = body['fullName'] as String? ?? '';
      final rawBirthDate = body['birthDate'] as String? ?? '';
      final email = body['email'] as String? ?? '';
      final rawCpf = body['cpf'] as String?;
      final role = body['role'] as String? ?? 'worker';
      final initialPassword = body['initialPassword'] as String?;

      if (fullName.isEmpty || rawBirthDate.isEmpty || email.isEmpty) {
        return jsonError(400, 'fullName, birthDate and email are required');
      }

      // Sanitize CPF: remove mask characters (dots and dashes)
      final cpf = rawCpf != null
          ? rawCpf.replaceAll(RegExp(r'[^\d]'), '')
          : null;

      // Normalize birthDate: convert DD/MM/YYYY or DD / MM / YYYY to YYYY-MM-DD
      final birthDate = _normalizeDateToIso(rawBirthDate);

      // 1. Register person with Zitadel login
      final registerResult = await pc.registerPersonWithLogin(
        fullName: fullName,
        birthDate: birthDate,
        email: email,
        cpf: cpf,
        initialPassword: initialPassword,
      );

      switch (registerResult) {
        case Success(:final value):
          final personId = value;

          // 2. Assign role
          final roleResult = await pc.assignRole(
            personId: personId,
            system: 'social-care',
            role: role,
          );

          switch (roleResult) {
            case Success():
              return jsonOk({'id': personId});
            case Failure(:final error):
              return jsonError(
                502,
                'Person created ($personId) but role assignment failed: $error',
              );
          }

        case Failure(:final error):
          return backendError(error);
      }
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── PUT /team/<id>/deactivate ──────────────────────────────────

  Future<Response> _deactivateWorker(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.deactivatePerson(id)) {
      case Success():
        return jsonNoContent();
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── PUT /team/<id>/reactivate ──────────────────────────────────

  Future<Response> _reactivateWorker(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.reactivatePerson(id)) {
      case Success():
        return jsonNoContent();
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── POST /team/<id>/reset-password ─────────────────────────────

  Future<Response> _resetPassword(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.requestPasswordReset(id)) {
      case Success():
        return jsonNoContent();
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── GET /team/people ───────────────────────────────────────────

  Future<Response> _fetchPeople(Request request) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    final params = request.url.queryParameters;
    final limitStr = params['limit'];
    final limit = limitStr != null ? int.tryParse(limitStr) : null;

    switch (await pc.fetchPeople(
      limit: limit,
      name: params['name'],
      cpf: params['cpf'],
      cursor: params['cursor'],
    )) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── GET /team/people/<id> ──────────────────────────────────────

  Future<Response> _getPerson(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.getPerson(id)) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── GET /team/people/by-cpf/<cpf> ─────────────────────────────

  Future<Response> _getPersonByCpf(Request request, String cpf) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.findPersonByCpf(cpf)) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── GET /team/people/<id>/roles ────────────────────────────────

  Future<Response> _fetchRolesForPerson(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    final params = request.url.queryParameters;
    final activeStr = params['active'];
    final active = activeStr != null ? activeStr == 'true' : null;

    switch (await pc.listPersonRoles(id, active: active)) {
      case Success(:final value):
        return jsonOk(value);
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── POST /team/people/<id>/roles ───────────────────────────────

  Future<Response> _assignRoleToPerson(Request request, String id) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    try {
      final body = await readJsonBody(request);
      final system = body['system'] as String? ?? '';
      final role = body['role'] as String? ?? '';

      if (system.isEmpty || role.isEmpty) {
        return jsonError(400, 'system and role are required');
      }

      switch (await pc.assignRole(personId: id, system: system, role: role)) {
        case Success():
          return jsonNoContent();
        case Failure(:final error):
          return backendError(error);
      }
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  // ── PUT /team/people/<id>/roles/<roleId>/deactivate ────────────

  Future<Response> _deactivateRole(
    Request request,
    String id,
    String roleId,
  ) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.deactivateRole(personId: id, roleId: roleId)) {
      case Success():
        return jsonNoContent();
      case Failure(:final error):
        return backendError(error);
    }
  }

  // ── PUT /team/people/<id>/roles/<roleId>/reactivate ────────────

  Future<Response> _reactivateRole(
    Request request,
    String id,
    String roleId,
  ) async {
    final session = getSession(request);
    final pc = _peopleContextFactory(session);

    switch (await pc.reactivateRole(personId: id, roleId: roleId)) {
      case Success():
        return jsonNoContent();
      case Failure(:final error):
        return backendError(error);
    }
  }
}

/// Converts date strings like "DD/MM/YYYY" or "DD / MM / YYYY" to "YYYY-MM-DD".
/// If the input already looks like ISO format, returns it as-is.
String _normalizeDateToIso(String raw) {
  final cleaned = raw.replaceAll(' ', '');

  // Already ISO format
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cleaned)) {
    return cleaned.length > 10 ? cleaned.substring(0, 10) : cleaned;
  }

  // DD/MM/YYYY
  final parts = cleaned.split('/');
  if (parts.length == 3) {
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  return raw;
}
