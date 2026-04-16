import 'package:core_contracts/core_contracts.dart';

import 'dto/responses/registry/patient_response.dart';
import 'dto/shared/standard_response.dart';
import 'sub_contracts/analytics_contract.dart';
import 'sub_contracts/assessment_contract.dart';
import 'sub_contracts/audit_contract.dart';
import 'sub_contracts/care_contract.dart';
import 'sub_contracts/health_contract.dart';
import 'sub_contracts/people_contract.dart';
import 'sub_contracts/protection_contract.dart';
import 'sub_contracts/registry_contract.dart';

export 'sub_contracts/analytics_contract.dart';
export 'sub_contracts/assessment_contract.dart';
export 'sub_contracts/audit_contract.dart';
export 'sub_contracts/care_contract.dart';
export 'sub_contracts/health_contract.dart';
export 'sub_contracts/people_contract.dart';
export 'sub_contracts/protection_contract.dart';
export 'sub_contracts/registry_contract.dart';

/// Main Backend For Frontend (BFF) contract for the Social Care module.
///
/// Composed of 8 sub-contracts by bounded context:
/// - [HealthContract] — liveness and readiness probes
/// - [RegistryContract] — patients, family members, social identity, lifecycle
/// - [AssessmentContract] — all 7 assessment fichas
/// - [CareContract] — appointments and intake information
/// - [ProtectionContract] — referrals, violations, and placement history
/// - [AuditContract] — audit trail for patient events
/// - [PeopleContract] — person CRUD and role management (People Context)
/// - [AnalyticsContract] — anonymized indicators (Analysis BI)
///
/// All methods use DTOs (Request/Response) instead of domain objects,
/// forming an Anti-Corruption Layer (ACL) that protects the domain model
/// from backend changes.
///
/// All implementations (Web/Desktop) must adhere to this interface,
/// ensuring the application logic layer remains platform agnostic.
abstract interface class SocialCareContract
    implements
        HealthContract,
        RegistryContract,
        AssessmentContract,
        CareContract,
        ProtectionContract,
        AuditContract,
        PeopleContract,
        AnalyticsContract {
  // ── Lookup (cross-cutting, not a sub-contract) ────────────────────────

  /// Fetches items from a domain lookup table (e.g., `dominio_parentesco`).
  ///
  /// Returns a list of lookup items wrapped in [StandardResponse].
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupTable(
    String tableName,
  );

  // ── Composite queries (cross-BC convenience) ──────────────────────────

  /// Fetches a full patient aggregate with people-context enrichment.
  ///
  /// This is a composite operation that:
  /// 1. Fetches the patient from social-care backend
  /// 2. Enriches family member names from people-context
  /// 3. Returns the fully hydrated [PatientResponse]
  ///
  /// Implementations may override [fetchPatient] from [RegistryContract]
  /// to include enrichment, or provide this as a separate method.
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientEnriched(
    String patientId,
  );
}
