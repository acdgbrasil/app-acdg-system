/// Social Care module — domain, data, and UI layers for patient management.
library;

// Intention / Requests (DTOs)
export 'src/data/commands/assessment_intents.dart';
export 'src/data/commands/family_intents.dart';
export 'src/data/commands/intervention_intents.dart';
export 'src/data/commands/register_patient_intent.dart';
export 'src/data/commands/registry_intents.dart';
// Services
export 'src/data/services/patient_service.dart';
// Repositories
export 'src/data/repositories/bff_lookup_repository.dart';
export 'src/data/repositories/bff_patient_repository.dart';
export 'src/data/repositories/lookup_repository.dart';
export 'src/data/repositories/patient_repository.dart';
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
// UI — Patient Registration
export 'src/ui/patient_registration/view/page/patient_registration_page.dart';
export 'src/ui/patient_registration/viewModel/patient_registration_view_model.dart';
// UI — Home
export 'src/ui/home/view/page/home_page.dart';
export 'src/ui/home/viewModel/home_view_model.dart';
