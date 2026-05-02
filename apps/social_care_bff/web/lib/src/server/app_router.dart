import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/oidc_server_client.dart';
import '../auth/session_store.dart';
import '../config/server_config.dart';
import '../handlers/assessment_handler.dart';
import '../handlers/auth_handler.dart';
import '../handlers/care_handler.dart';
import '../handlers/lookup_handler.dart';
import '../handlers/protection_handler.dart';
import '../handlers/registry_family_handler.dart';
import '../handlers/registry_patient_handler.dart';
import '../handlers/team_handler.dart';
import '../middleware/observability.dart';
import '../middleware/session_middleware.dart';
import '../use_cases/add_family_member_use_case.dart';
import '../use_cases/admit_patient_use_case.dart';
import '../use_cases/approve_lookup_request_use_case.dart';
import '../use_cases/assign_primary_caregiver_use_case.dart';
import '../use_cases/assign_role_use_case.dart';
import '../use_cases/auth_callback_use_case.dart';
import '../use_cases/create_lookup_item_use_case.dart';
import '../use_cases/create_lookup_request_use_case.dart';
import '../use_cases/create_referral_use_case.dart';
import '../use_cases/deactivate_role_use_case.dart';
import '../use_cases/deactivate_worker_use_case.dart';
import '../use_cases/discharge_patient_use_case.dart';
import '../use_cases/get_audit_trail_use_case.dart';
import '../use_cases/get_lookup_requests_use_case.dart';
import '../use_cases/get_lookup_table_use_case.dart';
import '../use_cases/get_lookups_batch_use_case.dart';
import '../use_cases/get_patient_use_case.dart';
import '../use_cases/get_team_member_use_case.dart';
import '../use_cases/list_patients_use_case.dart';
import '../use_cases/list_team_use_case.dart';
import '../use_cases/login_use_case.dart';
import '../use_cases/logout_use_case.dart';
import '../use_cases/me_use_case.dart';
import '../use_cases/reactivate_role_use_case.dart';
import '../use_cases/reactivate_worker_use_case.dart';
import '../use_cases/readmit_patient_use_case.dart';
import '../use_cases/refresh_use_case.dart';
import '../use_cases/register_appointment_use_case.dart';
import '../use_cases/register_patient_use_case.dart';
import '../use_cases/register_worker_use_case.dart';
import '../use_cases/reject_lookup_request_use_case.dart';
import '../use_cases/remove_family_member_use_case.dart';
import '../use_cases/report_rights_violation_use_case.dart';
import '../use_cases/reset_password_use_case.dart';
import '../use_cases/toggle_lookup_item_use_case.dart';
import '../use_cases/update_community_support_network_use_case.dart';
import '../use_cases/update_educational_status_use_case.dart';
import '../use_cases/update_health_status_use_case.dart';
import '../use_cases/update_housing_condition_use_case.dart';
import '../use_cases/update_intake_info_use_case.dart';
import '../use_cases/update_lookup_item_use_case.dart';
import '../use_cases/update_placement_history_use_case.dart';
import '../use_cases/update_social_health_summary_use_case.dart';
import '../use_cases/update_social_identity_use_case.dart';
import '../use_cases/update_socio_economic_situation_use_case.dart';
import '../use_cases/update_work_and_income_use_case.dart';
import '../use_cases/withdraw_patient_use_case.dart';

/// Builds the complete router for the BFF Web server.
///
/// Middleware chain:
/// 1. Observability middleware (requestId + breadcrumbs) applied to
///    auth + protected pipelines.
/// 2. Session middleware reads the `__Host-session` cookie and attaches
///    the resolved [Session] to the request context.
/// 3. Auth guard middleware rejects requests with no session on protected
///    routes.
///
/// Route groups:
/// - `/health/*`   — public (no auth, no session needed)
/// - `/auth/*`     — observability + session middleware; login/callback are
///                   public, me/logout need a session.
/// - `/patients/*` — observability + session + auth guard.
class AppRouter {
  AppRouter({
    required ServerConfig config,
    required SessionStore sessionStore,
    required OidcServerClient oidcClient,
    required AuthContract authContract,
    required RegistryContract registryContract,
    required PeopleContract peopleContract,
    required AuditContract auditContract,
    required AssessmentContract assessmentContract,
    required CareContract careContract,
    required ProtectionContract protectionContract,
    required LookupContract lookupContract,
    required TeamContract teamContract,
  }) : _sessionStore = sessionStore,
       _authContract = authContract,
       _registryContract = registryContract,
       _peopleContract = peopleContract,
       _auditContract = auditContract,
       _assessmentContract = assessmentContract,
       _careContract = careContract,
       _protectionContract = protectionContract,
       _lookupContract = lookupContract,
       _teamContract = teamContract;

  final SessionStore _sessionStore;
  final AuthContract _authContract;
  final RegistryContract _registryContract;
  final PeopleContract _peopleContract;
  final AuditContract _auditContract;
  final AssessmentContract _assessmentContract;
  final CareContract _careContract;
  final ProtectionContract _protectionContract;
  final LookupContract _lookupContract;
  final TeamContract _teamContract;

  /// Returns the fully assembled shelf [Handler].
  Handler get handler {
    // --- Public health routes (no auth, no session) ---
    final healthRouter = Router();
    healthRouter.get('/health/live', _liveHandler);
    healthRouter.get('/health/ready', _readyHandler);

    // --- Auth routes (observability + session middleware, no auth guard) ---
    final authHandler = buildAuthHandler(_authContract);

    final authPipeline = const Pipeline()
        .addMiddleware(observabilityMiddleware())
        .addMiddleware(sessionMiddleware(_sessionStore))
        .addHandler(authHandler.router.call);

    // --- Protected routes (observability + session + auth guard) ---
    final registryPatientHandler = buildRegistryPatientHandler(
      registry: _registryContract,
      people: _peopleContract,
    );

    final registryFamilyHandler = buildRegistryFamilyHandler(
      registry: _registryContract,
      people: _peopleContract,
      audit: _auditContract,
    );

    final assessmentHandler = buildAssessmentHandler(
      assessment: _assessmentContract,
    );

    final careHandler = buildCareHandler(care: _careContract);

    final protectionHandler = buildProtectionHandler(
      protection: _protectionContract,
    );

    final lookupHandler = buildLookupHandler(lookup: _lookupContract);

    final teamHandler = buildTeamHandler(team: _teamContract);

    // Cascade the protected handlers so the router can match each handler's
    // routes in order without one swallowing the others. Order:
    //   patient → family → assessment → care → protection → lookup → team.
    final protectedRouter = Cascade()
        .add(registryPatientHandler.router.call)
        .add(registryFamilyHandler.router.call)
        .add(assessmentHandler.router.call)
        .add(careHandler.router.call)
        .add(protectionHandler.router.call)
        .add(lookupHandler.router.call)
        .add(teamHandler.router.call)
        .handler;

    final protectedPipeline = const Pipeline()
        .addMiddleware(observabilityMiddleware())
        .addMiddleware(sessionMiddleware(_sessionStore))
        .addHandler(protectedRouter);

    // Use Cascade to try handlers in order.
    final cascade = Cascade()
        .add(healthRouter.call)
        .add(authPipeline)
        .add(protectedPipeline);

    return cascade.handler;
  }

  /// GET /health/live — liveness probe.
  Future<Response> _liveHandler(Request request) async {
    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// GET /health/ready — readiness probe.
  Future<Response> _readyHandler(Request request) async {
    return Response.ok(
      jsonEncode({'status': 'ready'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// Wires the 5 auth UseCases around a single [AuthContract] and returns a
/// fully-assembled [AuthHandler].
///
/// Canonical factory referenced by production wiring and integration tests.
AuthHandler buildAuthHandler(AuthContract auth) {
  return AuthHandler(
    login: LoginUseCase(auth: auth),
    callback: AuthCallbackUseCase(auth: auth),
    logout: LogoutUseCase(auth: auth),
    me: MeUseCase(auth: auth),
    refresh: RefreshUseCase(auth: auth),
  );
}

/// Wires the 7 Registry (Patient) UseCases and returns a fully-assembled
/// [RegistryPatientHandler].
///
/// The [registry] contract owns patient persistence + lifecycle; [people]
/// is consumed by the composed `POST /patients` saga to resolve / register
/// the canonical personId in the People Context before handing the request
/// off to the Registry. See `RegisterPatientUseCase` for details.
RegistryPatientHandler buildRegistryPatientHandler({
  required RegistryContract registry,
  required PeopleContract people,
}) {
  return RegistryPatientHandler(
    register: RegisterPatientUseCase(registry: registry, people: people),
    list: ListPatientsUseCase(registry: registry, people: people),
    get: GetPatientUseCase(registry: registry, people: people),
    admit: AdmitPatientUseCase(registry: registry),
    discharge: DischargePatientUseCase(registry: registry),
    readmit: ReadmitPatientUseCase(registry: registry),
    withdraw: WithdrawPatientUseCase(registry: registry),
  );
}

/// Wires the 5 Registry (Family + Social Identity + Audit) UseCases and
/// returns a fully-assembled [RegistryFamilyHandler].
///
/// - [registry] owns family persistence + social identity updates.
/// - [people] is consumed by the composed
///   `POST /patients/{id}/family-members` saga to resolve a CPF into the
///   canonical personId before handing off to the Registry. See
///   [AddFamilyMemberUseCase] for details.
/// - [audit] backs the read-only audit trail endpoint.
RegistryFamilyHandler buildRegistryFamilyHandler({
  required RegistryContract registry,
  required PeopleContract people,
  required AuditContract audit,
}) {
  return RegistryFamilyHandler(
    add: AddFamilyMemberUseCase(registry: registry, people: people),
    remove: RemoveFamilyMemberUseCase(registry: registry),
    assignCaregiver: AssignPrimaryCaregiverUseCase(registry: registry),
    updateIdentity: UpdateSocialIdentityUseCase(registry: registry),
    getAudit: GetAuditTrailUseCase(audit: audit),
  );
}

/// Wires the 7 Assessment (ficha) UseCases and returns a fully-assembled
/// [AssessmentHandler].
///
/// The [assessment] contract owns the 7 ficha updates (housing,
/// socioeconomic, work-and-income, education, health, community-support,
/// social-health-summary). Canonical factory referenced by production
/// wiring and integration tests.
AssessmentHandler buildAssessmentHandler({
  required AssessmentContract assessment,
}) {
  return AssessmentHandler(
    housing: UpdateHousingConditionUseCase(assessment: assessment),
    socioEconomic: UpdateSocioEconomicSituationUseCase(assessment: assessment),
    workAndIncome: UpdateWorkAndIncomeUseCase(assessment: assessment),
    educationalStatus: UpdateEducationalStatusUseCase(assessment: assessment),
    healthStatus: UpdateHealthStatusUseCase(assessment: assessment),
    communitySupport: UpdateCommunitySupportNetworkUseCase(
      assessment: assessment,
    ),
    socialHealthSummary: UpdateSocialHealthSummaryUseCase(
      assessment: assessment,
    ),
  );
}

/// Wires the 2 Care UseCases (appointment + intake) and returns a
/// fully-assembled [CareHandler].
///
/// The [care] contract owns appointment persistence and intake (acolhimento)
/// metadata. Canonical factory referenced by production wiring and
/// integration tests.
CareHandler buildCareHandler({required CareContract care}) {
  return CareHandler(
    registerAppointment: RegisterAppointmentUseCase(care: care),
    updateIntakeInfo: UpdateIntakeInfoUseCase(care: care),
  );
}

/// Wires the 3 Protection UseCases (referral, violation, placement-history)
/// and returns a fully-assembled [ProtectionHandler].
///
/// The [protection] contract owns referrals, rights-violation reports and
/// institutional placement history. Canonical factory referenced by
/// production wiring and integration tests.
ProtectionHandler buildProtectionHandler({
  required ProtectionContract protection,
}) {
  return ProtectionHandler(
    createReferral: CreateReferralUseCase(protection: protection),
    reportViolation: ReportRightsViolationUseCase(protection: protection),
    updatePlacementHistory: UpdatePlacementHistoryUseCase(
      protection: protection,
    ),
  );
}

/// Wires the 8 Lookup UseCases (table reads + item admin + governance
/// requests) and returns a fully-assembled [LookupHandler].
///
/// The [lookup] contract owns domain-table reads (`dominio_*`), item
/// admin (create/update/toggle), and governance requests (list/create/
/// approve/reject). Canonical factory referenced by production wiring
/// and integration tests.
LookupHandler buildLookupHandler({required LookupContract lookup}) {
  return LookupHandler(
    getLookupTable: GetLookupTableUseCase(lookup: lookup),
    getLookupsBatch: GetLookupsBatchUseCase(lookup: lookup),
    createLookupItem: CreateLookupItemUseCase(lookup: lookup),
    updateLookupItem: UpdateLookupItemUseCase(lookup: lookup),
    toggleLookupItem: ToggleLookupItemUseCase(lookup: lookup),
    getLookupRequests: GetLookupRequestsUseCase(lookup: lookup),
    createLookupRequest: CreateLookupRequestUseCase(lookup: lookup),
    approveLookupRequest: ApproveLookupRequestUseCase(lookup: lookup),
    rejectLookupRequest: RejectLookupRequestUseCase(lookup: lookup),
  );
}

/// Wires the 9 Team UseCases (list + register + lifecycle + roles) and
/// returns a fully-assembled [TeamHandler].
///
/// The [team] contract owns team-member persistence + role assignment.
/// Note: this handler exposes ONLY `/team/*` routes — the legacy
/// `/team/people/*` and `/people/by-cpf/*` surfaces are intentionally
/// gone. Composite operations (registerWorker spans PeopleContext +
/// Registry + initial role) are encapsulated behind [TeamContract] so
/// the APP never sees the topology.
TeamHandler buildTeamHandler({required TeamContract team}) {
  return TeamHandler(
    listTeam: ListTeamUseCase(team: team),
    registerWorker: RegisterWorkerUseCase(team: team),
    getTeamMember: GetTeamMemberUseCase(team: team),
    deactivateWorker: DeactivateWorkerUseCase(team: team),
    reactivateWorker: ReactivateWorkerUseCase(team: team),
    resetPassword: ResetPasswordUseCase(team: team),
    assignRole: AssignRoleUseCase(team: team),
    deactivateRole: DeactivateRoleUseCase(team: team),
    reactivateRole: ReactivateRoleUseCase(team: team),
  );
}
