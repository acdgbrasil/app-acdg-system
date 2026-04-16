import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/session_store.dart';
import 'handler_utils.dart';

/// Factory that creates a [SocialCareContract] for a given [Session].
typedef CareContractFactory = SocialCareContract Function(Session session);

/// Handles care-related endpoints (appointments and intake).
///
/// Routes:
/// - `POST /patients/<id>/appointments` — register appointment
/// - `PUT  /patients/<id>/intake`       — update intake info
class CareHandler {
  CareHandler({required CareContractFactory contractFactory})
    : _contractFactory = contractFactory;

  final CareContractFactory _contractFactory;

  Router get router {
    final r = Router();
    r.post('/patients/<id>/appointments', _registerAppointment);
    r.put('/patients/<id>/intake', _updateIntakeInfo);
    return r;
  }

  Future<Response> _registerAppointment(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = RegisterAppointmentRequest.fromJson(body);

      return switch (await contract.registerAppointment(id, dto)) {
        Success(:final value) => jsonOk({
          'data': {'id': value.data.id},
          'meta': {'timestamp': value.meta.timestamp},
        }),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }

  Future<Response> _updateIntakeInfo(Request request, String id) async {
    final session = getSession(request);
    final contract = _contractFactory(session);

    try {
      final body = await readJsonBody(request);
      final dto = RegisterIntakeInfoRequest.fromJson(body);

      return switch (await contract.updateIntakeInfo(id, dto)) {
        Success() => jsonNoContent(),
        Failure(:final error) => backendError(error),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
