/// Kernel compartilhado do BFF Social Care.
library;

// Utils
export 'src/utils/app_error.dart';
export 'src/utils/string_helpers.dart';
export 'src/utils/api_extensions.dart';

// Kernel
export 'src/domain/kernel/address.dart';
export 'src/domain/kernel/cep.dart';
export 'src/domain/kernel/cns.dart';
export 'src/domain/kernel/cpf.dart';
export 'src/domain/kernel/ids.dart';
export 'src/domain/kernel/nis.dart';
export 'src/domain/kernel/rg_document.dart';
export 'src/domain/kernel/time_stamp.dart';

// Models
export 'src/domain/models/lookup.dart';

// Audit
export 'src/domain/audit/audit_event.dart';

// Registry
export 'src/domain/registry/family_member.dart';
export 'src/domain/registry/patient.dart';
export 'src/domain/registry/registry_vos.dart';

// Assessment
export 'src/domain/assessment/assessment_vos.dart';
export 'src/domain/assessment/community_support.dart';
export 'src/domain/assessment/educational_status.dart';
export 'src/domain/assessment/health_status.dart';
export 'src/domain/assessment/social_health_summary.dart';
export 'src/domain/assessment/work_and_income.dart';

// Remote Models (legacy — consumed only by packages/social_care/ — to be deleted in Phase 4)
export 'src/infrastructure/dtos/patient_remote.dart';
export 'src/infrastructure/dtos/patient_overview.dart';

// People Context (alive — used by patient_enrichment_service)
export 'src/infrastructure/people_context_client.dart';

// Services
export 'src/services/patient_enrichment_service.dart';

// Care
export 'src/domain/care/care_vos.dart';

// Protection
export 'src/domain/protection/protection_vos.dart';

// Analytics
export 'src/domain/analytics/housing_analytics_service.dart';
export 'src/domain/analytics/financial_analytics_service.dart';
export 'src/domain/analytics/family_analytics.dart';
export 'src/domain/analytics/education_analytics_service.dart';

// Contract DTOs — Shared
export 'src/contract/dto/shared/backend_error.dart';
export 'src/contract/dto/shared/paginated_list.dart';
export 'src/contract/dto/shared/pagination_meta.dart';
export 'src/contract/dto/shared/standard_response.dart';

// Contract DTOs — Requests
export 'src/contract/dto/requests/registry/register_patient_request.dart';
export 'src/contract/dto/requests/registry/add_family_member_request.dart';
export 'src/contract/dto/requests/registry/assign_primary_caregiver_request.dart';
export 'src/contract/dto/requests/registry/update_social_identity_request.dart';
export 'src/contract/dto/requests/registry/admit_patient_request.dart';
export 'src/contract/dto/requests/registry/discharge_patient_request.dart';
export 'src/contract/dto/requests/registry/readmit_patient_request.dart';
export 'src/contract/dto/requests/registry/withdraw_patient_request.dart';
export 'src/contract/dto/requests/assessment/update_housing_condition_request.dart';
export 'src/contract/dto/requests/assessment/update_socio_economic_situation_request.dart';
export 'src/contract/dto/requests/assessment/update_work_and_income_request.dart';
export 'src/contract/dto/requests/assessment/update_educational_status_request.dart';
export 'src/contract/dto/requests/assessment/update_health_status_request.dart';
export 'src/contract/dto/requests/assessment/update_community_support_network_request.dart';
export 'src/contract/dto/requests/assessment/update_social_health_summary_request.dart';
export 'src/contract/dto/requests/care/register_appointment_request.dart';
export 'src/contract/dto/requests/care/register_intake_info_request.dart';
export 'src/contract/dto/requests/protection/update_placement_history_request.dart';
export 'src/contract/dto/requests/protection/report_rights_violation_request.dart';
export 'src/contract/dto/requests/protection/create_referral_request.dart';
export 'src/contract/dto/requests/people/register_person_request.dart';
export 'src/contract/dto/requests/people/register_person_with_login_request.dart';
export 'src/contract/dto/requests/people/assign_role_request.dart';
export 'src/contract/dto/requests/governance/create_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/update_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/toggle_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/create_lookup_request_request.dart';

// Contract DTOs — Responses
export 'src/contract/dto/responses/registry/patient_response.dart';
export 'src/contract/dto/responses/registry/patient_summary_response.dart';
export 'src/contract/dto/responses/registry/personal_data_response.dart';
export 'src/contract/dto/responses/registry/civil_documents_response.dart';
export 'src/contract/dto/responses/registry/address_response.dart';
export 'src/contract/dto/responses/registry/family_member_response.dart';
export 'src/contract/dto/responses/registry/diagnosis_response.dart';
export 'src/contract/dto/responses/registry/social_identity_response.dart';
export 'src/contract/dto/responses/registry/discharge_info_response.dart';
export 'src/contract/dto/responses/registry/withdraw_info_response.dart';
export 'src/contract/dto/responses/assessment/housing_condition_response.dart';
export 'src/contract/dto/responses/assessment/socio_economic_response.dart';
export 'src/contract/dto/responses/assessment/social_benefit_response.dart';
export 'src/contract/dto/responses/assessment/work_and_income_response.dart';
export 'src/contract/dto/responses/assessment/educational_status_response.dart';
export 'src/contract/dto/responses/assessment/health_status_response.dart';
export 'src/contract/dto/responses/assessment/community_support_network_response.dart';
export 'src/contract/dto/responses/assessment/social_health_summary_response.dart';
export 'src/contract/dto/responses/care/appointment_response.dart';
export 'src/contract/dto/responses/care/ingress_info_response.dart';
export 'src/contract/dto/responses/audit/audit_trail_entry_response.dart';
export 'src/contract/dto/responses/people/person_response.dart';
export 'src/contract/dto/responses/people/person_role_response.dart';
export 'src/contract/dto/responses/analytics/computed_analytics_response.dart';
export 'src/contract/dto/responses/analytics/indicator_response.dart';
export 'src/contract/dto/responses/analytics/axis_metadata_response.dart';
export 'src/contract/dto/responses/protection/placement_history_response.dart';
export 'src/contract/dto/responses/protection/violation_report_response.dart';
export 'src/contract/dto/responses/protection/referral_response.dart';
export 'src/contract/dto/responses/governance/lookup_item_response.dart';
export 'src/contract/dto/responses/governance/lookups_batch_response.dart';
export 'src/contract/dto/responses/governance/lookup_request_response.dart';
export 'src/contract/dto/responses/auth/me_response.dart';
export 'src/contract/dto/responses/team/team_member_response.dart';
export 'src/contract/dto/responses/team/team_member_detail_response.dart';

// Sub-contracts (Contract B — BFF ↔ backends)
export 'src/contract/sub_contracts/analytics_contract.dart';
export 'src/contract/sub_contracts/assessment_contract.dart';
export 'src/contract/sub_contracts/audit_contract.dart';
export 'src/contract/sub_contracts/auth_contract.dart';
export 'src/contract/sub_contracts/care_contract.dart';
export 'src/contract/sub_contracts/health_contract.dart';
export 'src/contract/sub_contracts/lookup_contract.dart';
export 'src/contract/sub_contracts/people_contract.dart';
export 'src/contract/sub_contracts/protection_contract.dart';
export 'src/contract/sub_contracts/registry_contract.dart';
export 'src/contract/sub_contracts/team_contract.dart';

// Testing — Fakes per sub-contract
export 'src/testing/fake_analytics_bff.dart';
export 'src/testing/fake_assessment_bff.dart';
export 'src/testing/fake_audit_bff.dart';
export 'src/testing/fake_auth_bff.dart';
export 'src/testing/fake_care_bff.dart';
export 'src/testing/fake_health_bff.dart';
export 'src/testing/fake_lookup_bff.dart';
export 'src/testing/fake_people_bff.dart';
export 'src/testing/fake_protection_bff.dart';
export 'src/testing/fake_registry_bff.dart';
export 'src/testing/fake_team_bff.dart';

// Testing — Stores (A06b)
export 'src/testing/stores/in_memory_care_store.dart';
export 'src/testing/stores/in_memory_lookup_store.dart';
export 'src/testing/stores/in_memory_patient_store.dart';
export 'src/testing/stores/in_memory_people_store.dart';
export 'src/testing/stores/in_memory_protection_store.dart';
export 'src/testing/stores/in_memory_team_store.dart';
