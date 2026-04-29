import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/protection/create_referral_request.dart';
import '../contract/dto/requests/protection/report_rights_violation_request.dart';
import '../contract/dto/requests/protection/update_placement_history_request.dart';
import '../contract/dto/responses/protection/placement_history_response.dart';
import '../contract/dto/responses/protection/referral_response.dart';
import '../contract/dto/responses/protection/violation_report_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/protection_contract.dart';
import 'stores/in_memory_protection_store.dart';

/// In-memory fake for [ProtectionContract].
///
/// State is held in an [InMemoryProtectionStore] — a public collaborator
/// the tests can inspect via `fake.store.violations`, etc.
class FakeProtectionBff implements ProtectionContract {
  FakeProtectionBff({InMemoryProtectionStore? store})
      : store = store ?? InMemoryProtectionStore();

  final InMemoryProtectionStore store;

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async {
    final separation = request.separationChecklist;
    final collective = request.collectiveSituations;
    store.setPlacement(
      patientId,
      PlacementHistoryResponse(
        individualPlacements: request.registries
            .asMap()
            .entries
            .map(
              (entry) => PlacementRegistryResponse(
                id: '$patientId-${entry.key}',
                memberId: entry.value.memberId,
                startDate: entry.value.startDate,
                endDate: entry.value.endDate,
                reason: entry.value.reason,
              ),
            )
            .toList(),
        homeLossReport: collective?.homeLossReport,
        thirdPartyGuardReport: collective?.thirdPartyGuardReport,
        adultInPrison: separation?.adultInPrison ?? false,
        adolescentInInternment: separation?.adolescentInInternment ?? false,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async {
    final id = _nextId();
    store.reportViolation(
      ViolationReportResponse(
        id: id,
        reportDate: request.reportDate ?? DateTime.now().toIso8601String(),
        victimId: request.victimId,
        violationType: request.violationType,
        descriptionOfFact: request.descriptionOfFact,
        actionsTaken: request.actionsTaken ?? '',
        incidentDate: request.incidentDate,
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async {
    final id = _nextId();
    store.createReferral(
      ReferralResponse(
        id: id,
        date: request.date ?? DateTime.now().toIso8601String(),
        referredPersonId: request.referredPersonId,
        destinationService: request.destinationService,
        reason: request.reason,
        status: 'pending',
        professionalId: request.professionalId,
      ),
    );
    return Success(_wrapId(id));
  }
}
