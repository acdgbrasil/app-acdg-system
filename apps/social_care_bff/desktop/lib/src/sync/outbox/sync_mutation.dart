import 'dart:convert';

import 'package:shared/shared.dart';

import 'outbox_repository.dart';

/// Normalizes the result of `Dto.toJson()` into a fully JSON-clean map.
///
/// `json_serializable` produces shallow `toJson()` output by default —
/// nested DTO instances are NOT recursively serialized. Round-tripping
/// through `jsonEncode/jsonDecode` forces every nested DTO to render
/// as a `Map<String, dynamic>`, which is what `OutboxEntry.payload`
/// promises and what `Dto.fromJson` expects on the way back.
Map<String, dynamic> _toJsonClean(Map<String, dynamic> raw) =>
    jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;

/// Sealed hierarchy describing every write operation that can ride the
/// Outbox.
///
/// Each final subclass corresponds 1:1 to a write method on a sub-contract
/// (`RegistryContract`, `AssessmentContract`, `CareContract`,
/// `ProtectionContract`, `LookupContract`). The pair
/// (`aggregateType`, `mutationType`) uniquely identifies the kind of
/// mutation; `mutationType` is the discriminator persisted in the
/// `Outbox.mutationType` column and used by [SyncMutation.fromOutboxEntry]
/// to round-trip a row back to its typed form.
///
/// **Adding a new mutation:** add a new final subclass + a new switch
/// arm in [SyncMutation.fromOutboxEntry]. The compiler catches missing
/// arms (sealed exhaustiveness) when [SyncEngine] dispatches.
sealed class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.aggregateId,
    required this.expectedVersion,
    required this.createdAt,
  });

  /// Outbox row ID — UUID v4, idempotency key.
  final String id;

  /// The entity being mutated (UUID for entity-scoped mutations; table
  /// name for `lookup_item` creates).
  final String aggregateId;

  /// Optimistic-locking version expected at the backend. Forward-compat
  /// (D1 (a)).
  final int expectedVersion;

  /// Wall-clock at enqueue. Drives FIFO ordering in the drain.
  final DateTime createdAt;

  /// Aggregate root the mutation targets. Const per subclass.
  String get aggregateType;

  /// Discriminator for the mutation kind. Const per subclass — one of
  /// the 27 canonical strings listed in STATE.md.
  String get mutationType;

  /// Serialized request body. Body-less mutations return `<String,
  /// dynamic>{}`.
  Map<String, dynamic> toPayload();

  /// Round-trips an [OutboxEntry] back to its typed [SyncMutation] form.
  ///
  /// Throws [StateError] if `entry.mutationType` is not one of the 27
  /// canonical discriminators — that would indicate a schema/code
  /// drift (e.g. a row written by a newer build that introduced a 28th
  /// mutation, read by an older build).
  static SyncMutation fromOutboxEntry(OutboxEntry entry) {
    switch (entry.mutationType) {
      // ── Registry (9) ─────────────────────────────────────────────────
      case 'register_patient':
        return RegisterPatientMutation._fromEntry(entry);
      case 'add_family_member':
        return AddFamilyMemberMutation._fromEntry(entry);
      case 'remove_family_member':
        return RemoveFamilyMemberMutation._fromEntry(entry);
      case 'assign_primary_caregiver':
        return AssignPrimaryCaregiverMutation._fromEntry(entry);
      case 'update_social_identity':
        return UpdateSocialIdentityMutation._fromEntry(entry);
      case 'discharge_patient':
        return DischargePatientMutation._fromEntry(entry);
      case 'readmit_patient':
        return ReadmitPatientMutation._fromEntry(entry);
      case 'admit_patient':
        return AdmitPatientMutation._fromEntry(entry);
      case 'withdraw_patient':
        return WithdrawPatientMutation._fromEntry(entry);
      // ── Assessment (7) ───────────────────────────────────────────────
      case 'update_health_status':
        return UpdateHealthStatusMutation._fromEntry(entry);
      case 'update_housing_condition':
        return UpdateHousingConditionMutation._fromEntry(entry);
      case 'update_educational_status':
        return UpdateEducationalStatusMutation._fromEntry(entry);
      case 'update_socio_economic_situation':
        return UpdateSocioEconomicSituationMutation._fromEntry(entry);
      case 'update_work_and_income':
        return UpdateWorkAndIncomeMutation._fromEntry(entry);
      case 'update_community_support_network':
        return UpdateCommunitySupportNetworkMutation._fromEntry(entry);
      case 'update_social_health_summary':
        return UpdateSocialHealthSummaryMutation._fromEntry(entry);
      // ── Care (2) ─────────────────────────────────────────────────────
      case 'register_appointment':
        return RegisterAppointmentMutation._fromEntry(entry);
      case 'update_intake_info':
        return UpdateIntakeInfoMutation._fromEntry(entry);
      // ── Protection (3) ───────────────────────────────────────────────
      case 'update_placement_history':
        return UpdatePlacementHistoryMutation._fromEntry(entry);
      case 'report_violation':
        return ReportViolationMutation._fromEntry(entry);
      case 'create_referral':
        return CreateReferralMutation._fromEntry(entry);
      // ── Lookup (6) ───────────────────────────────────────────────────
      case 'create_lookup_item':
        return CreateLookupItemMutation._fromEntry(entry);
      case 'update_lookup_item':
        return UpdateLookupItemMutation._fromEntry(entry);
      case 'toggle_lookup_item':
        return ToggleLookupItemMutation._fromEntry(entry);
      case 'create_lookup_request':
        return CreateLookupRequestMutation._fromEntry(entry);
      case 'approve_lookup_request':
        return ApproveLookupRequestMutation._fromEntry(entry);
      case 'reject_lookup_request':
        return RejectLookupRequestMutation._fromEntry(entry);
      default:
        throw StateError(
          'Unknown SyncMutation discriminator: ${entry.mutationType}',
        );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Registry (9)
// ═════════════════════════════════════════════════════════════════════════

final class RegisterPatientMutation extends SyncMutation {
  const RegisterPatientMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory RegisterPatientMutation._fromEntry(OutboxEntry e) =>
      RegisterPatientMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: RegisterPatientRequest.fromJson(e.payload),
      );

  final RegisterPatientRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'register_patient';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class AddFamilyMemberMutation extends SyncMutation {
  const AddFamilyMemberMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory AddFamilyMemberMutation._fromEntry(OutboxEntry e) =>
      AddFamilyMemberMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: AddFamilyMemberRequest.fromJson(e.payload),
      );

  final AddFamilyMemberRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'add_family_member';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class RemoveFamilyMemberMutation extends SyncMutation {
  const RemoveFamilyMemberMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.memberId,
  });

  factory RemoveFamilyMemberMutation._fromEntry(OutboxEntry e) =>
      RemoveFamilyMemberMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        memberId: e.payload['memberId'] as String,
      );

  /// Path-only mutation: the contract method takes
  /// `(patientId, memberId)` — both go on the path. We persist
  /// `memberId` in the payload as a single key.
  final String memberId;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'remove_family_member';

  @override
  Map<String, dynamic> toPayload() => {'memberId': memberId};
}

final class AssignPrimaryCaregiverMutation extends SyncMutation {
  const AssignPrimaryCaregiverMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory AssignPrimaryCaregiverMutation._fromEntry(OutboxEntry e) =>
      AssignPrimaryCaregiverMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: AssignPrimaryCaregiverRequest.fromJson(e.payload),
      );

  final AssignPrimaryCaregiverRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'assign_primary_caregiver';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateSocialIdentityMutation extends SyncMutation {
  const UpdateSocialIdentityMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateSocialIdentityMutation._fromEntry(OutboxEntry e) =>
      UpdateSocialIdentityMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateSocialIdentityRequest.fromJson(e.payload),
      );

  final UpdateSocialIdentityRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_social_identity';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class DischargePatientMutation extends SyncMutation {
  const DischargePatientMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory DischargePatientMutation._fromEntry(OutboxEntry e) =>
      DischargePatientMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: DischargePatientRequest.fromJson(e.payload),
      );

  final DischargePatientRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'discharge_patient';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class ReadmitPatientMutation extends SyncMutation {
  const ReadmitPatientMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory ReadmitPatientMutation._fromEntry(OutboxEntry e) =>
      ReadmitPatientMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: ReadmitPatientRequest.fromJson(e.payload),
      );

  final ReadmitPatientRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'readmit_patient';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

/// Body-less mutation. The contract method `RegistryContract.admitPatient`
/// takes `(patientId)` only — no DTO. Payload is `{}` and round-trip
/// preserves only the discriminator + path id.
final class AdmitPatientMutation extends SyncMutation {
  const AdmitPatientMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
  });

  factory AdmitPatientMutation._fromEntry(OutboxEntry e) =>
      AdmitPatientMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
      );

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'admit_patient';

  @override
  Map<String, dynamic> toPayload() => const <String, dynamic>{};
}

final class WithdrawPatientMutation extends SyncMutation {
  const WithdrawPatientMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory WithdrawPatientMutation._fromEntry(OutboxEntry e) =>
      WithdrawPatientMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: WithdrawPatientRequest.fromJson(e.payload),
      );

  final WithdrawPatientRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'withdraw_patient';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

// ═════════════════════════════════════════════════════════════════════════
// Assessment (7) — all fichas live on the Patient aggregate.
// ═════════════════════════════════════════════════════════════════════════

final class UpdateHealthStatusMutation extends SyncMutation {
  const UpdateHealthStatusMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateHealthStatusMutation._fromEntry(OutboxEntry e) =>
      UpdateHealthStatusMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateHealthStatusRequest.fromJson(e.payload),
      );

  final UpdateHealthStatusRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_health_status';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateHousingConditionMutation extends SyncMutation {
  const UpdateHousingConditionMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateHousingConditionMutation._fromEntry(OutboxEntry e) =>
      UpdateHousingConditionMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateHousingConditionRequest.fromJson(e.payload),
      );

  final UpdateHousingConditionRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_housing_condition';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateEducationalStatusMutation extends SyncMutation {
  const UpdateEducationalStatusMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateEducationalStatusMutation._fromEntry(OutboxEntry e) =>
      UpdateEducationalStatusMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateEducationalStatusRequest.fromJson(e.payload),
      );

  final UpdateEducationalStatusRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_educational_status';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateSocioEconomicSituationMutation extends SyncMutation {
  const UpdateSocioEconomicSituationMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateSocioEconomicSituationMutation._fromEntry(OutboxEntry e) =>
      UpdateSocioEconomicSituationMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateSocioEconomicSituationRequest.fromJson(e.payload),
      );

  final UpdateSocioEconomicSituationRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_socio_economic_situation';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateWorkAndIncomeMutation extends SyncMutation {
  const UpdateWorkAndIncomeMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateWorkAndIncomeMutation._fromEntry(OutboxEntry e) =>
      UpdateWorkAndIncomeMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateWorkAndIncomeRequest.fromJson(e.payload),
      );

  final UpdateWorkAndIncomeRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_work_and_income';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateCommunitySupportNetworkMutation extends SyncMutation {
  const UpdateCommunitySupportNetworkMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateCommunitySupportNetworkMutation._fromEntry(OutboxEntry e) =>
      UpdateCommunitySupportNetworkMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateCommunitySupportNetworkRequest.fromJson(e.payload),
      );

  final UpdateCommunitySupportNetworkRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_community_support_network';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateSocialHealthSummaryMutation extends SyncMutation {
  const UpdateSocialHealthSummaryMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateSocialHealthSummaryMutation._fromEntry(OutboxEntry e) =>
      UpdateSocialHealthSummaryMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdateSocialHealthSummaryRequest.fromJson(e.payload),
      );

  final UpdateSocialHealthSummaryRequest request;

  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_social_health_summary';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

// ═════════════════════════════════════════════════════════════════════════
// Care (2)
// ═════════════════════════════════════════════════════════════════════════

final class RegisterAppointmentMutation extends SyncMutation {
  const RegisterAppointmentMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory RegisterAppointmentMutation._fromEntry(OutboxEntry e) =>
      RegisterAppointmentMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: RegisterAppointmentRequest.fromJson(e.payload),
      );

  final RegisterAppointmentRequest request;

  /// Aggregate is `appointment` (a new ID is generated server-side).
  @override
  String get aggregateType => 'appointment';

  @override
  String get mutationType => 'register_appointment';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class UpdateIntakeInfoMutation extends SyncMutation {
  const UpdateIntakeInfoMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdateIntakeInfoMutation._fromEntry(OutboxEntry e) =>
      UpdateIntakeInfoMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: RegisterIntakeInfoRequest.fromJson(e.payload),
      );

  final RegisterIntakeInfoRequest request;

  /// Intake info hangs off the patient aggregate (acolhimento data).
  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_intake_info';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

// ═════════════════════════════════════════════════════════════════════════
// Protection (3)
// ═════════════════════════════════════════════════════════════════════════

final class UpdatePlacementHistoryMutation extends SyncMutation {
  const UpdatePlacementHistoryMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory UpdatePlacementHistoryMutation._fromEntry(OutboxEntry e) =>
      UpdatePlacementHistoryMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: UpdatePlacementHistoryRequest.fromJson(e.payload),
      );

  final UpdatePlacementHistoryRequest request;

  /// Placement history hangs off the patient aggregate.
  @override
  String get aggregateType => 'patient';

  @override
  String get mutationType => 'update_placement_history';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class ReportViolationMutation extends SyncMutation {
  const ReportViolationMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory ReportViolationMutation._fromEntry(OutboxEntry e) =>
      ReportViolationMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: ReportRightsViolationRequest.fromJson(e.payload),
      );

  final ReportRightsViolationRequest request;

  @override
  String get aggregateType => 'violation_report';

  @override
  String get mutationType => 'report_violation';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

final class CreateReferralMutation extends SyncMutation {
  const CreateReferralMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory CreateReferralMutation._fromEntry(OutboxEntry e) =>
      CreateReferralMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: CreateReferralRequest.fromJson(e.payload),
      );

  final CreateReferralRequest request;

  @override
  String get aggregateType => 'referral';

  @override
  String get mutationType => 'create_referral';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

// ═════════════════════════════════════════════════════════════════════════
// Lookup (6)
// ═════════════════════════════════════════════════════════════════════════

final class CreateLookupItemMutation extends SyncMutation {
  const CreateLookupItemMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.tableName,
    required this.request,
  });

  factory CreateLookupItemMutation._fromEntry(OutboxEntry e) =>
      CreateLookupItemMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        tableName: e.payload['_tableName'] as String,
        request: CreateLookupItemRequest.fromJson(
          Map<String, dynamic>.from(e.payload)..remove('_tableName'),
        ),
      );

  /// Lookup table name (e.g. `dominio_parentesco`). Persisted alongside
  /// the request payload under `_tableName` so the round-trip can recover
  /// it without requiring a separate column.
  final String tableName;
  final CreateLookupItemRequest request;

  @override
  String get aggregateType => 'lookup_item';

  @override
  String get mutationType => 'create_lookup_item';

  @override
  Map<String, dynamic> toPayload() =>
      _toJsonClean({...request.toJson(), '_tableName': tableName});
}

final class UpdateLookupItemMutation extends SyncMutation {
  const UpdateLookupItemMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.tableName,
    required this.request,
  });

  factory UpdateLookupItemMutation._fromEntry(OutboxEntry e) =>
      UpdateLookupItemMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        tableName: e.payload['_tableName'] as String,
        request: UpdateLookupItemRequest.fromJson(
          Map<String, dynamic>.from(e.payload)..remove('_tableName'),
        ),
      );

  final String tableName;
  final UpdateLookupItemRequest request;

  @override
  String get aggregateType => 'lookup_item';

  @override
  String get mutationType => 'update_lookup_item';

  @override
  Map<String, dynamic> toPayload() =>
      _toJsonClean({...request.toJson(), '_tableName': tableName});
}

final class ToggleLookupItemMutation extends SyncMutation {
  const ToggleLookupItemMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.tableName,
    required this.request,
  });

  factory ToggleLookupItemMutation._fromEntry(OutboxEntry e) =>
      ToggleLookupItemMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        tableName: e.payload['_tableName'] as String,
        request: ToggleLookupItemRequest.fromJson(
          Map<String, dynamic>.from(e.payload)..remove('_tableName'),
        ),
      );

  final String tableName;
  final ToggleLookupItemRequest request;

  @override
  String get aggregateType => 'lookup_item';

  @override
  String get mutationType => 'toggle_lookup_item';

  @override
  Map<String, dynamic> toPayload() =>
      _toJsonClean({...request.toJson(), '_tableName': tableName});
}

final class CreateLookupRequestMutation extends SyncMutation {
  const CreateLookupRequestMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
    required this.request,
  });

  factory CreateLookupRequestMutation._fromEntry(OutboxEntry e) =>
      CreateLookupRequestMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
        request: CreateLookupRequestRequest.fromJson(e.payload),
      );

  final CreateLookupRequestRequest request;

  @override
  String get aggregateType => 'lookup_request';

  @override
  String get mutationType => 'create_lookup_request';

  @override
  Map<String, dynamic> toPayload() => _toJsonClean(request.toJson());
}

/// Body-less mutation. The contract method
/// `LookupContract.approveLookupRequest` takes `(requestId)` only.
final class ApproveLookupRequestMutation extends SyncMutation {
  const ApproveLookupRequestMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
  });

  factory ApproveLookupRequestMutation._fromEntry(OutboxEntry e) =>
      ApproveLookupRequestMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
      );

  @override
  String get aggregateType => 'lookup_request';

  @override
  String get mutationType => 'approve_lookup_request';

  @override
  Map<String, dynamic> toPayload() => const <String, dynamic>{};
}

/// Body-less mutation. The contract method
/// `LookupContract.rejectLookupRequest` takes `(requestId)` only.
final class RejectLookupRequestMutation extends SyncMutation {
  const RejectLookupRequestMutation({
    required super.id,
    required super.aggregateId,
    required super.expectedVersion,
    required super.createdAt,
  });

  factory RejectLookupRequestMutation._fromEntry(OutboxEntry e) =>
      RejectLookupRequestMutation(
        id: e.id,
        aggregateId: e.aggregateId,
        expectedVersion: e.expectedVersion,
        createdAt: e.createdAt,
      );

  @override
  String get aggregateType => 'lookup_request';

  @override
  String get mutationType => 'reject_lookup_request';

  @override
  Map<String, dynamic> toPayload() => const <String, dynamic>{};
}
