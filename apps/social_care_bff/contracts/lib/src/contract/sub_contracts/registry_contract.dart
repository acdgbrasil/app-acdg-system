import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/registry/add_family_member_request.dart';
import '../dto/requests/registry/assign_primary_caregiver_request.dart';
import '../dto/requests/registry/discharge_patient_request.dart';
import '../dto/requests/registry/readmit_patient_request.dart';
import '../dto/requests/registry/register_patient_request.dart';
import '../dto/requests/registry/update_social_identity_request.dart';
import '../dto/requests/registry/withdraw_patient_request.dart';
import '../dto/responses/registry/patient_response.dart';
import '../dto/responses/registry/patient_summary_response.dart';
import '../dto/shared/paginated_list.dart';
import '../dto/shared/standard_response.dart';

/// Registry contract — patients, family members, social identity, lifecycle.
abstract interface class RegistryContract {
  // ── Patients ──────────────────────────────────────────────────────────

  /// Lists all patients with cursor-based pagination.
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  });

  /// Registers a new patient. Returns [StandardIdResponse] with the generated ID.
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  );

  /// Retrieves a patient by their unique [patientId].
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  );

  /// Retrieves a patient by their associated [personId].
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  );

  // ── Family Members ────────────────────────────────────────────────────

  /// Adds a new family member to a patient's record.
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  });

  /// Removes a family member from a patient's record.
  Future<Result<void>> removeFamilyMember(String patientId, String memberId);

  /// Assigns a primary caregiver for the patient.
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  );

  // ── Social Identity ───────────────────────────────────────────────────

  /// Updates the social identity of a patient.
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  );

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Discharges a patient.
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  );

  /// Readmits a previously discharged patient.
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  );

  /// Admits a patient from the waitlist.
  Future<Result<void>> admitPatient(String patientId);

  /// Withdraws a patient from the waitlist.
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  );
}
