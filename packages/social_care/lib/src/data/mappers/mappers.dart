/// Barrel file for the Social Care data-layer mappers.
///
/// Mappers are split one-per-endpoint and named after the operation they
/// serve. They translate between wire/shape models (Intents from the UI,
/// Detail models parsed from the patient aggregate) and the pure domain
/// value objects / aggregates defined in `package:shared`.
///
/// Mappers live in `data/mappers/` (Contract A compliant) so that ViewModels
/// and UseCases depend only on the dedicated operation they need.
library;

// Add / Remove / Primary Caregiver family endpoints
export 'add_family_member_mapper.dart';

// Assessment endpoints
export 'community_support_detail_mapper.dart';
export 'community_support_mapper.dart';
export 'educational_status_detail_mapper.dart';
export 'educational_status_mapper.dart';
export 'health_status_detail_mapper.dart';
export 'health_status_mapper.dart';
export 'housing_condition_detail_mapper.dart';
export 'housing_condition_mapper.dart';
export 'social_health_summary_detail_mapper.dart';
export 'social_health_summary_mapper.dart';
export 'socio_economic_detail_mapper.dart';
export 'socio_economic_mapper.dart';
export 'work_and_income_detail_mapper.dart';

// Care / Intake endpoints
export 'appointment_mapper.dart';
export 'intake_info_detail_mapper.dart';

// Protection endpoints
export 'placement_history_detail_mapper.dart';
export 'referral_mapper.dart';
export 'violation_report_mapper.dart';

// Registry endpoints
export 'patient_register_mapper.dart';

// Shared helpers
export 'shared/social_benefit_detail_mapper.dart';
