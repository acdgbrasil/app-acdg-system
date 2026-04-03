import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:persistence/persistence.dart';
import 'package:shared/shared.dart';

import '../storage/local_social_care_repository.dart';

/// Engine responsible for synchronizing local pending actions with the remote BFF.
///
/// Uses reactive Drift [watchPendingActions] stream instead of periodic polling.
/// When a new action enters the queue, the engine processes it immediately.
class SyncEngine {
  final SyncQueueService _queueService;
  final ConnectivityService _connectivityService;
  final SocialCareContract _remoteBff;
  final LocalSocialCareRepository? _localRepo;

  bool _isProcessing = false;
  StreamSubscription<({List<SyncAction> ready, DateTime? nextRetryAt})>?
      _watchSubscription;
  Timer? _retryTimer;
  Timer? _debounceTimer;

  /// Notifies the current status of the sync engine to the UI.
  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncIdle());

  SyncEngine({
    required SyncQueueService queueService,
    required ConnectivityService connectivityService,
    required SocialCareContract remoteBff,
    LocalSocialCareRepository? localRepo,
  })  : _queueService = queueService,
        _connectivityService = connectivityService,
        _remoteBff = remoteBff,
        _localRepo = localRepo;

  bool get _isOnline => _connectivityService.isOnline.value;

  /// Starts the engine.
  ///
  /// Subscribes to the reactive pending actions stream from Drift.
  /// No more 1-minute polling timer — actions are processed as they arrive.
  void start() {
    _connectivityService.isOnline.addListener(_onConnectivityChange);

    // Reactive subscription: fires when sync_actions table changes.
    // Time filtering is done in Dart (fresh DateTime.now() each emission).
    _watchSubscription = _queueService.watchPendingActions().listen(
      (pending) {
        if (pending.ready.isNotEmpty && _isOnline) {
          scheduleProcessQueue();
        }
        _scheduleRetry(pending.nextRetryAt);
        unawaited(refreshStatus());
      },
    );

    // Initial pull when starting online
    if (_isOnline) unawaited(pullPatients());
  }

  /// Stops the engine and cleans up subscriptions.
  void stop() {
    _connectivityService.isOnline.removeListener(_onConnectivityChange);
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Schedules a single delayed callback for the earliest pending retry.
  ///
  /// When a failed action has `nextRetryAt` in the future, no table change
  /// will occur to trigger the Drift stream. This timer fires exactly when
  /// the earliest retry becomes eligible, then calls [processQueue].
  void _scheduleRetry(DateTime? nextRetryAt) {
    _retryTimer?.cancel();
    _retryTimer = null;

    if (nextRetryAt == null) return;

    final delay = nextRetryAt.difference(DateTime.now().toUtc());
    if (delay.isNegative) {
      // Already eligible — process immediately
      if (_isOnline) unawaited(processQueue());
      return;
    }

    _retryTimer = Timer(delay, () {
      if (_isOnline) unawaited(processQueue());
    });
  }

  void _onConnectivityChange() {
    if (_isOnline) {
      scheduleProcessQueue();
    } else {
      unawaited(refreshStatus());
    }
  }

  /// Manually refreshes the status by scanning the queue.
  Future<void> refreshStatus() async {
    if (_isProcessing) return;

    final allActions = await _queueService.getAllActions();

    int pending = 0;
    int errors = 0;
    int conflicts = 0;

    for (final action in allActions) {
      switch (action.status) {
        case 'PENDING':
          pending++;
        case 'FAILED':
          errors++;
        case 'CONFLICT':
          conflicts++;
      }
    }

    if (conflicts > 0) {
      status.value = SyncConflict(conflicts);
    } else if (errors > 0) {
      status.value = SyncError(errors);
    } else if (pending > 0) {
      status.value = _isOnline ? SyncPending(pending) : SyncOffline(pending);
    } else {
      status.value = const SyncIdle();
    }
  }

  /// Pulls all patients from the remote BFF and updates local cache.
  Future<void> pullPatients() async {
    if (_localRepo == null || !_isOnline) return;
    try {
      final result = await _remoteBff.fetchPatients();
      if (result case Success(:final value)) {
        await _localRepo.updateCacheFromSummaries(value);
      }
    } catch (_) {
      // Pull failure is non-critical — local data remains available
    }
  }

  /// Forces sync immediately, bypassing connectivity check.
  Future<void> forceSyncNow() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final actions = await _queueService.getPendingActions();
      final total = actions.length;
      if (total == 0) return;
      for (int i = 0; i < total; i++) {
        status.value = SyncInProgress(current: i + 1, total: total);
        final success = await _syncAction(actions[i]);
        if (!success) break;
      }
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  /// Schedules [processQueue] with a 500ms debounce.
  ///
  /// Coalesces rapid-fire calls from multiple sources (watch stream,
  /// connectivity change, write handlers) into a single queue drain.
  /// Prefer this over calling [processQueue] directly for non-urgent triggers.
  void scheduleProcessQueue() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(processQueue());
    });
  }

  /// Drains the pending sync queue.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (!_isOnline) {
      await refreshStatus();
      return;
    }

    _isProcessing = true;
    try {
      final actions = await _queueService.getPendingActions();
      final total = actions.length;

      if (total == 0) {
        _isProcessing = false;
        await refreshStatus();
        return;
      }

      for (int i = 0; i < total; i++) {
        status.value = SyncInProgress(current: i + 1, total: total);
        final success = await _syncAction(actions[i]);
        if (!success) break;
      }
    } finally {
      _isProcessing = false;
      await refreshStatus();
    }
  }

  Future<bool> _syncAction(SyncAction action) async {
    await _queueService.updateStatus(action.id, 'IN_PROGRESS');

    try {
      final result = await _dispatchAction(action);

      if (result case Success()) {
        await _queueService.removeAction(action.id);
        return true;
      }

      if (result case Failure(:final error)) {
        final errorStr = error.toString().toLowerCase();

        if (errorStr.contains('409') || errorStr.contains('conflict')) {
          await _queueService.markConflict(action.id, error.toString());
          return true;
        }

        if (errorStr.contains('socketexception') ||
            errorStr.contains('timeout') ||
            errorStr.contains('network')) {
          await _queueService.markFailed(action.id, error.toString());
          return false;
        }

        await _queueService.updateStatus(
          action.id,
          'FAILED',
          error: error.toString(),
        );
        return true;
      }

      return true;
    } catch (e) {
      await _queueService.updateStatus(
        action.id,
        'FAILED',
        error: e.toString(),
      );
      return true;
    }
  }

  Future<Result<void>> _dispatchAction(SyncAction action) async {
    final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;

    final PatientId patientId;
    switch (PatientId.create(action.patientId)) {
      case Success(:final value): patientId = value;
      case Failure(:final error): return Failure(error);
    }

    switch (action.actionType) {
      case 'REGISTER_PATIENT':
        final Patient patient;
        switch (PatientTranslator.fromJson(payload)) {
          case Success(:final value): patient = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.registerPatient(patient);

      case 'ADD_FAMILY_MEMBER':
        final LookupId relId;
        switch (LookupId.create(payload['prRelationshipId'])) {
          case Success(:final value): relId = value;
          case Failure(:final error): return Failure(error);
        }
        final FamilyMember member;
        switch (PatientTranslator.familyMemberFromJson(payload['member'] as Map<String, dynamic>)) {
          case Success(:final value): member = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.addFamilyMember(patientId, member, relId);

      case 'REMOVE_FAMILY_MEMBER':
        final PersonId memberId;
        switch (PersonId.create(payload['memberId'])) {
          case Success(:final value): memberId = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.removeFamilyMember(patientId, memberId);

      case 'ASSIGN_CAREGIVER':
        final PersonId memberId;
        switch (PersonId.create(payload['memberId'])) {
          case Success(:final value): memberId = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.assignPrimaryCaregiver(patientId, memberId);

      case 'UPDATE_SOCIAL_IDENTITY':
        final SocialIdentity identity;
        switch (PatientTranslator.socialIdentityFromJson(payload['identity'] as Map<String, dynamic>)) {
          case Success(:final value): identity = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateSocialIdentity(patientId, identity);

      case 'UPDATE_HOUSING':
        final HousingCondition condition;
        switch (PatientTranslator.housingConditionFromJson(payload)) {
          case Success(:final value): condition = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateHousingCondition(patientId, condition);

      case 'UPDATE_SOCIOECONOMIC':
        final SocioEconomicSituation situation;
        switch (PatientTranslator.socioEconomicFromJson(payload)) {
          case Success(:final value): situation = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateSocioEconomicSituation(patientId, situation);

      case 'UPDATE_WORK_INCOME':
        final WorkAndIncome data;
        switch (PatientTranslator.workAndIncomeFromJson(payload)) {
          case Success(:final value): data = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateWorkAndIncome(patientId, data);

      case 'UPDATE_EDUCATION':
        final EducationalStatus status;
        switch (PatientTranslator.educationalStatusFromJson(payload)) {
          case Success(:final value): status = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateEducationalStatus(patientId, status);

      case 'UPDATE_HEALTH':
        final HealthStatus status;
        switch (PatientTranslator.healthStatusFromJson(payload)) {
          case Success(:final value): status = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateHealthStatus(patientId, status);

      case 'UPDATE_COMMUNITY_SUPPORT':
        final CommunitySupportNetwork network;
        switch (PatientTranslator.communitySupportFromJson(payload)) {
          case Success(:final value): network = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateCommunitySupportNetwork(patientId, network);

      case 'UPDATE_SOCIAL_HEALTH':
        final SocialHealthSummary summary;
        switch (PatientTranslator.socialHealthSummaryFromJson(payload)) {
          case Success(:final value): summary = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateSocialHealthSummary(patientId, summary);

      case 'REGISTER_APPOINTMENT':
        final SocialCareAppointment appointment;
        switch (PatientTranslator.appointmentFromJson(payload['appointment'] as Map<String, dynamic>)) {
          case Success(:final value): appointment = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.registerAppointment(patientId, appointment);

      case 'UPDATE_INTAKE':
        final IngressInfo info;
        switch (PatientTranslator.intakeInfoFromJson(payload['info'] as Map<String, dynamic>)) {
          case Success(:final value): info = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updateIntakeInfo(patientId, info);

      case 'UPDATE_PLACEMENT':
        final PlacementHistory history;
        switch (PatientTranslator.placementHistoryFromJson(payload)) {
          case Success(:final value): history = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.updatePlacementHistory(patientId, history);

      case 'REPORT_VIOLATION':
        final RightsViolationReport report;
        switch (PatientTranslator.violationReportFromJson(payload['report'] as Map<String, dynamic>)) {
          case Success(:final value): report = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.reportViolation(patientId, report);

      case 'CREATE_REFERRAL':
        final Referral referral;
        switch (PatientTranslator.referralFromJson(payload['referral'] as Map<String, dynamic>)) {
          case Success(:final value): referral = value;
          case Failure(:final error): return Failure(error);
        }
        return _remoteBff.createReferral(patientId, referral);

      default:
        return Failure(AppError(
          code: 'SYNC-400',
          message: 'Unknown action type: ${action.actionType}',
          module: 'social-care/sync-engine',
          kind: 'validation',
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.error,
          ),
        ));
    }
  }
}
