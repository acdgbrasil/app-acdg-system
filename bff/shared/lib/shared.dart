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

// Remote Models (legacy — to be replaced by contract DTOs)
export 'src/infrastructure/dtos/patient_remote.dart';
export 'src/infrastructure/dtos/patient_overview.dart';

// Translator (legacy — to be replaced by contract mappers)
export 'src/infrastructure/patient_translator.dart';

// People Context
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

// Contract (new — sub-contracts + DTOs)
export 'src/contract/social_care_contract.dart';

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

// Testing
export 'src/testing/fake_social_care_bff.dart';
