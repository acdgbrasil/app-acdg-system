import 'package:core/core.dart';
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
      final patientIdResult = PatientId.create(id);
      final appointmentResult = PatientTranslator.appointmentFromJson(body);

      return switch ((patientIdResult, appointmentResult)) {
        (Success(:final value), Success(value: final appointment)) =>
          switch (await contract.registerAppointment(value, appointment)) {
            Success(:final value) => jsonOk({'id': value.value}),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid appointment: $error',
        ),
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
      final patientIdResult = PatientId.create(id);
      final intakeResult = PatientTranslator.intakeInfoFromJson(body);

      return switch ((patientIdResult, intakeResult)) {
        (Success(:final value), Success(value: final intake)) =>
          switch (await contract.updateIntakeInfo(value, intake)) {
            Success() => jsonNoContent(),
            Failure(:final error) => jsonError(500, error.toString()),
          },
        (Failure(:final error), _) => jsonError(
          400,
          'Invalid patient ID: $error',
        ),
        (_, Failure(:final error)) => jsonError(
          400,
          'Invalid intake info: $error',
        ),
      };
    } catch (e) {
      return jsonError(400, 'Invalid request body: $e');
    }
  }
}
