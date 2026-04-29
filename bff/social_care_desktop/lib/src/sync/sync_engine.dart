import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:core/core_offline.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:persistence/persistence.dart';
import 'package:shared/shared.dart';

import '../storage/local_social_care_repository.dart';
import '../storage/offline_first_repository.dart';

/// Engine responsible for synchronizing local pending actions with the remote BFF.
///
/// Uses reactive Drift [watchPendingActions] stream instead of periodic polling.
/// When a new action enters the queue, the engine processes it immediately.
class SyncEngine implements SyncScheduler {
  final SyncQueueService _queueService;
  final ConnectivityService _connectivityService;
  final SocialCareContract _remoteBff;
  final LocalSocialCareRepository? _localRepo;
  final PatientEnrichmentService? _enrichmentService;

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
    PatientEnrichmentService? enrichmentService,
  }) : _queueService = queueService,
       _connectivityService = connectivityService,
       _remoteBff = remoteBff,
       _localRepo = localRepo,
       _enrichmentService = enrichmentService;

  bool get _isOnline => _connectivityService.isOnline.value;

  /// Starts the engine.
  ///
  /// Subscribes to the reactive pending actions stream from Drift.
  /// No more 1-minute polling timer — actions are processed as they arrive.
  void start() {
    _connectivityService.isOnline.addListener(_onConnectivityChange);

    // Reactive subscription: fires when sync_actions table changes.
    // Time filtering is done in Dart (fresh DateTime.now() each emission).
    _watchSubscription = _queueService.watchPendingActions().listen((pending) {
      if (pending.ready.isNotEmpty && _isOnline) {
        scheduleProcessQueue();
      }
      _scheduleRetry(pending.nextRetryAt);
      unawaited(refreshStatus());
    });

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
        await _localRepo.updateCacheFromSummaries(value.data);
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
  @override
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
    debugPrint(
      '[Sync Engine] Syncing Action ${action.id}: ${action.actionType}',
    );
    await _queueService.updateStatus(action.id, 'IN_PROGRESS');

    try {
      final result = await _dispatchAction(action);

      if (result case Success()) {
        debugPrint('[Sync Engine] Action ${action.id} SUCCESS. Removing.');
        await _queueService.removeAction(action.id);
        return true;
      }

      if (result case Failure(:final error)) {
        final errorStr = error.toString().toLowerCase();
        debugPrint('[Sync Engine] Action ${action.id} FAILED: $error');

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
      debugPrint('[Sync Engine] Action ${action.id} CRITICAL EXCEPTION: $e');
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
    debugPrint('[Sync Engine] Dispatching ${action.actionType}');

    final patientIdStr = action.patientId;

    switch (action.actionType) {
      case 'REGISTER_PATIENT':
        await _enrichmentService?.enrichPayload(payload);
        return _remoteBff.registerPatient(RegisterPatientRequest.fromJson(payload));

      case 'ADD_FAMILY_MEMBER':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.addFamilyMember(
          patientIdStr, 
          AddFamilyMemberRequest.fromJson(req), 
          cpf: payload['cpf'] as String?
        );

      case 'REMOVE_FAMILY_MEMBER':
        return _remoteBff.removeFamilyMember(patientIdStr, payload['memberId'] as String);

      case 'ASSIGN_CAREGIVER':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.assignPrimaryCaregiver(patientIdStr, AssignPrimaryCaregiverRequest.fromJson(req));

      case 'UPDATE_SOCIAL_IDENTITY':
        final req = payload['identity'] as Map<String, dynamic>;
        return _remoteBff.updateSocialIdentity(patientIdStr, UpdateSocialIdentityRequest.fromJson(req));

      case 'UPDATE_HOUSING':
        return _remoteBff.updateHousingCondition(patientIdStr, UpdateHousingConditionRequest.fromJson(payload));

      case 'UPDATE_SOCIOECONOMIC':
        return _remoteBff.updateSocioEconomicSituation(patientIdStr, UpdateSocioEconomicSituationRequest.fromJson(payload));

      case 'UPDATE_WORK_INCOME':
        return _remoteBff.updateWorkAndIncome(patientIdStr, UpdateWorkAndIncomeRequest.fromJson(payload));

      case 'UPDATE_EDUCATION':
        return _remoteBff.updateEducationalStatus(patientIdStr, UpdateEducationalStatusRequest.fromJson(payload));

      case 'UPDATE_HEALTH':
        return _remoteBff.updateHealthStatus(patientIdStr, UpdateHealthStatusRequest.fromJson(payload));

      case 'UPDATE_COMMUNITY_SUPPORT':
        return _remoteBff.updateCommunitySupportNetwork(patientIdStr, UpdateCommunitySupportNetworkRequest.fromJson(payload));

      case 'UPDATE_SOCIAL_HEALTH':
        return _remoteBff.updateSocialHealthSummary(patientIdStr, UpdateSocialHealthSummaryRequest.fromJson(payload));

      case 'REGISTER_APPOINTMENT':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.registerAppointment(patientIdStr, RegisterAppointmentRequest.fromJson(req));

      case 'UPDATE_INTAKE':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.updateIntakeInfo(patientIdStr, RegisterIntakeInfoRequest.fromJson(req));

      case 'UPDATE_PLACEMENT':
        return _remoteBff.updatePlacementHistory(patientIdStr, UpdatePlacementHistoryRequest.fromJson(payload));

      case 'REPORT_VIOLATION':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.reportViolation(patientIdStr, ReportRightsViolationRequest.fromJson(req));

      case 'CREATE_REFERRAL':
        final req = payload['request'] as Map<String, dynamic>;
        return _remoteBff.createReferral(patientIdStr, CreateReferralRequest.fromJson(req));

      default:
        return Failure(
          AppError(
            code: 'SYNC-400',
            message: 'Unknown action type: ${action.actionType}',
            module: 'social-care/sync-engine',
            kind: 'validation',
            observability: const Observability(
              category: ErrorCategory.domainRuleViolation,
              severity: ErrorSeverity.error,
            ),
          ),
        );
    }
  }
}
