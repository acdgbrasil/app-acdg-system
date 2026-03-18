import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:shared/shared.dart';
import 'package:persistence/persistence.dart';

/// Engine responsible for synchronizing local pending actions with the remote BFF.
class SyncEngine {
  final SyncQueueService _queueService;
  final ConnectivityService _connectivityService;
  final SocialCareContract _remoteBff;
  
  bool _isProcessing = false;
  Timer? _retryTimer;

  /// Notifies the current status of the sync engine to the UI.
  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncIdle());

  SyncEngine({
    required SyncQueueService queueService,
    required ConnectivityService connectivityService,
    required SocialCareContract remoteBff,
  })  : _queueService = queueService,
        _connectivityService = connectivityService,
        _remoteBff = remoteBff;

  bool get _isOnline => _connectivityService.isOnline.value;

  /// Starts the engine.
  void start() {
    _connectivityService.isOnline.addListener(_onConnectivityChange);
    // Periodic retry every 1 minute if online
    _retryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isOnline) unawaited(processQueue());
    });
    // Initial status check
    unawaited(refreshStatus());
  }

  /// Stops the engine.
  void stop() {
    _connectivityService.isOnline.removeListener(_onConnectivityChange);
    _retryTimer?.cancel();
  }

  void _onConnectivityChange() {
    if (_isOnline) {
      unawaited(processQueue());
    } else {
      unawaited(refreshStatus());
    }
  }

  /// Manually refreshes the status by scanning the queue.
  Future<void> refreshStatus() async {
    if (_isProcessing) return;

    final allActions = await _queueService.getAllActions(); // I need to add this method to SyncQueueService
    
    int pending = 0;
    int errors = 0;
    int conflicts = 0;

    for (final action in allActions) {
      switch (action.status) {
        case 'PENDING': pending++; break;
        case 'FAILED': errors++; break;
        case 'CONFLICT': conflicts++; break;
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
        _isProcessing = false; // Reset early to allow refreshStatus to work
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

      return await switch (result) {
        Success() => (() async {
            await _queueService.removeAction(action.id);
            return true;
          })(),
        Failure(:final error) => (() async {
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
            
            await _queueService.updateStatus(action.id, 'FAILED', error: error.toString());
            return true; 
          })(),
      };
    } catch (e) {
      await _queueService.updateStatus(action.id, 'FAILED', error: e.toString());
      return true;
    }
  }

  Future<Result<void>> _dispatchAction(SyncAction action) async {
    final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
    
    final patientIdRes = PatientId.create(action.patientId);
    if (patientIdRes case Failure(:final error)) return Failure(error);
    final patientId = (patientIdRes as Success<PatientId>).value;

    switch (action.actionType) {
      case 'REGISTER_PATIENT':
        return _remoteBff.registerPatient(PatientMapper.fromJson(payload));
      
      case 'ADD_FAMILY_MEMBER':
        final relIdRes = LookupId.create(payload['prRelationshipId']);
        if (relIdRes case Failure(:final error)) return Failure(error);
        return _remoteBff.addFamilyMember(
          patientId,
          PatientMapper.familyMemberFromJson(payload['member']),
          (relIdRes as Success<LookupId>).value,
        );
        
      case 'REMOVE_FAMILY_MEMBER':
        final memIdRes = PersonId.create(payload['memberId']);
        if (memIdRes case Failure(:final error)) return Failure(error);
        return _remoteBff.removeFamilyMember(patientId, (memIdRes as Success<PersonId>).value);
        
      case 'ASSIGN_CAREGIVER':
        final memIdRes = PersonId.create(payload['memberId']);
        if (memIdRes case Failure(:final error)) return Failure(error);
        return _remoteBff.assignPrimaryCaregiver(patientId, (memIdRes as Success<PersonId>).value);
        
      case 'UPDATE_SOCIAL_IDENTITY':
        return _remoteBff.updateSocialIdentity(
          patientId,
          PatientMapper.socialIdentityFromJson(payload['identity']),
        );
        
      case 'UPDATE_HOUSING':
        return _remoteBff.updateHousingCondition(
          patientId,
          PatientMapper.housingConditionFromJson(payload),
        );
        
      case 'UPDATE_SOCIOECONOMIC':
        return _remoteBff.updateSocioEconomicSituation(
          patientId,
          PatientMapper.socioEconomicFromJson(payload),
        );
        
      case 'UPDATE_WORK_INCOME':
        return _remoteBff.updateWorkAndIncome(
          patientId,
          PatientMapper.workAndIncomeFromJson(payload),
        );
        
      case 'UPDATE_EDUCATION':
        return _remoteBff.updateEducationalStatus(
          patientId,
          PatientMapper.educationalStatusFromJson(payload),
        );
        
      case 'UPDATE_HEALTH':
        return _remoteBff.updateHealthStatus(
          patientId,
          PatientMapper.healthStatusFromJson(payload),
        );
        
      case 'UPDATE_COMMUNITY_SUPPORT':
        return _remoteBff.updateCommunitySupportNetwork(
          patientId,
          PatientMapper.communitySupportFromJson(payload),
        );
        
      case 'UPDATE_SOCIAL_HEALTH':
        return _remoteBff.updateSocialHealthSummary(
          patientId,
          PatientMapper.socialHealthSummaryFromJson(payload),
        );
        
      case 'REGISTER_APPOINTMENT':
        return _remoteBff.registerAppointment(
          patientId,
          PatientMapper.appointmentFromJson(payload['appointment']),
        );
        
      case 'UPDATE_INTAKE':
        return _remoteBff.updateIntakeInfo(
          patientId,
          PatientMapper.intakeInfoFromJson(payload['info']),
        );
        
      case 'UPDATE_PLACEMENT':
        return _remoteBff.updatePlacementHistory(
          patientId,
          PatientMapper.placementHistoryFromJson(payload),
        );
        
      case 'REPORT_VIOLATION':
        return _remoteBff.reportViolation(
          patientId,
          PatientMapper.violationReportFromJson(payload['report']),
        );
        
      case 'CREATE_REFERRAL':
        return _remoteBff.createReferral(
          patientId,
          PatientMapper.referralFromJson(payload['referral']),
        );
        
      default:
        return Failure('Unknown action type: ${action.actionType}');
    }
  }
}
