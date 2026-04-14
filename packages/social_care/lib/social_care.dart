/// Social Care module — domain, data, and UI layers for patient management.
library;

// Intention / Requests (DTOs)
export 'src/data/commands/assessment_intents.dart';
export 'src/data/commands/family_intents.dart';
export 'src/data/commands/intervention_intents.dart';
export 'src/data/commands/register_patient_intent.dart';
export 'src/data/commands/registry_intents.dart';
// Repositories
export 'src/data/repositories/bff_lookup_repository.dart';
export 'src/data/repositories/bff_patient_repository.dart';
export 'src/data/repositories/lookup_repository.dart';
export 'src/data/repositories/patient_repository.dart';
export 'src/data/services/http_social_care_client.dart';
// Services
export 'src/data/services/patient_service.dart';
// Errors
export 'src/domain/errors/social_care_errors.dart';
// Use Cases
export 'src/logic/use_case/assessment/update_community_support_use_case.dart';
export 'src/logic/use_case/assessment/update_educational_status_use_case.dart';
export 'src/logic/use_case/assessment/update_health_status_use_case.dart';
export 'src/logic/use_case/assessment/update_housing_condition_use_case.dart';
export 'src/logic/use_case/assessment/update_social_health_summary_use_case.dart';
export 'src/logic/use_case/assessment/update_socio_economic_use_case.dart';
export 'src/logic/use_case/assessment/update_work_and_income_use_case.dart';
export 'src/logic/use_case/audit/get_audit_trail_use_case.dart';
export 'src/logic/use_case/care/register_appointment_use_case.dart';
export 'src/logic/use_case/care/update_intake_info_use_case.dart';
export 'src/logic/use_case/family/add_family_member_use_case.dart';
export 'src/logic/use_case/family/remove_family_member_use_case.dart';
export 'src/logic/use_case/family/update_primary_caregiver_use_case.dart';
export 'src/logic/use_case/protection/create_referral_use_case.dart';
export 'src/logic/use_case/protection/report_violation_use_case.dart';
export 'src/logic/use_case/protection/update_placement_history_use_case.dart';
export 'src/logic/use_case/registry/get_patient_use_case.dart';
export 'src/logic/use_case/registry/list_patients_use_case.dart';
export 'src/logic/use_case/registry/register_patient_use_case.dart';
export 'src/logic/use_case/registry/update_social_identity_use_case.dart';
export 'src/logic/use_case/shared/get_lookup_table_use_case.dart';
// UI — Community Support
export 'src/ui/community_support/di/community_support_providers.dart';
export 'src/ui/community_support/view/page/community_support_page.dart';
export 'src/ui/community_support/view_models/community_support_view_model.dart';
// UI — Educational Status
export 'src/ui/educational_status/di/educational_status_providers.dart';
export 'src/ui/educational_status/view/page/educational_status_page.dart';
export 'src/ui/educational_status/view_models/educational_status_view_model.dart';
// UI — Family Composition
export 'src/ui/family_composition/di/family_composition_providers.dart';
export 'src/ui/family_composition/view/page/family_composition_page.dart';
export 'src/ui/family_composition/view_models/family_composition_view_model.dart';
// UI — Health Status
export 'src/ui/health_status/di/health_status_providers.dart';
export 'src/ui/health_status/view/page/health_status_page.dart';
export 'src/ui/health_status/view_models/health_status_view_model.dart';
// UI — Home
export 'src/ui/home/di/home_providers.dart';
export 'src/ui/home/view/page/home_page.dart';
export 'src/ui/home/viewModel/home_view_model.dart';
// UI — Housing Condition
export 'src/ui/housing_condition/di/housing_condition_providers.dart';
export 'src/ui/housing_condition/view/page/housing_condition_page.dart';
export 'src/ui/housing_condition/view_models/housing_condition_view_model.dart';
// UI — Intake Info
export 'src/ui/intake_info/di/intake_info_providers.dart';
export 'src/ui/intake_info/view/page/intake_info_page.dart';
export 'src/ui/intake_info/view_models/intake_info_view_model.dart';
// UI — Patient Registration
export 'src/ui/patient_registration/di/patient_registration_providers.dart';
export 'src/ui/patient_registration/view/page/patient_registration_page.dart';
export 'src/ui/patient_registration/viewModel/patient_registration_view_model.dart';
// UI — Social Identity
export 'src/ui/social_identity/di/social_identity_providers.dart';
export 'src/ui/social_identity/view/page/social_identity_page.dart';
export 'src/ui/social_identity/view_models/social_identity_view_model.dart';
// UI — Socio Economic
export 'src/ui/socio_economic/di/socio_economic_providers.dart';
export 'src/ui/socio_economic/view/page/socio_economic_page.dart';
export 'src/ui/socio_economic/view_models/socio_economic_view_model.dart';
// UI — Violation Report
export 'src/ui/violation_report/di/violation_report_providers.dart';
export 'src/ui/violation_report/view/page/violation_report_page.dart';
export 'src/ui/violation_report/view_models/violation_report_view_model.dart';
// UI — Work and Income
export 'src/ui/work_and_income/di/work_and_income_providers.dart';
export 'src/ui/work_and_income/view/page/work_and_income_page.dart';
export 'src/ui/work_and_income/view_models/work_and_income_view_model.dart';
