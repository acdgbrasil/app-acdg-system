import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/care/register_appointment_request.dart';
import '../contract/dto/requests/care/register_intake_info_request.dart';
import '../contract/dto/responses/care/appointment_response.dart';
import '../contract/dto/responses/care/ingress_info_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/care_contract.dart';
import 'stores/in_memory_care_store.dart';

/// In-memory fake for [CareContract].
///
/// State is held in an [InMemoryCareStore] — a public collaborator the
/// tests can inspect via `fake.store.appointments[patientId]`.
class FakeCareBff implements CareContract {
  FakeCareBff({InMemoryCareStore? store})
      : store = store ?? InMemoryCareStore();

  final InMemoryCareStore store;

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async {
    final id = _nextId();
    store.addAppointment(
      patientId,
      AppointmentResponse(
        id: id,
        date: request.date ?? DateTime.now().toIso8601String(),
        professionalId: request.professionalId,
        type: request.type ?? 'intake',
        summary: request.summary ?? '',
        actionPlan: request.actionPlan ?? '',
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async {
    store.setIntake(
      patientId,
      IngressInfoResponse(
        ingressTypeId: request.ingressTypeId,
        serviceReason: request.serviceReason,
        originName: request.originName,
        originContact: request.originContact,
        linkedSocialPrograms: request.linkedSocialPrograms
            .map(
              (draft) => ProgramLinkResponse(
                programId: draft.programId,
                observation: draft.observation,
              ),
            )
            .toList(),
      ),
    );
    return const Success(null);
  }
}
