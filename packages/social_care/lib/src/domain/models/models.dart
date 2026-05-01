/// Barrel file for the Social Care domain models.
///
/// Import this file in ViewModels / UseCases / Views to access the full set
/// of pure domain schemas. These models intentionally carry no serialization
/// logic; conversion from BFF payloads is handled by mappers in
/// `data/mappers/`.
library;

export 'address.dart';
export 'appointment.dart';
export 'audit_event.dart';
export 'civil_documents.dart';
export 'community_support.dart';
export 'diagnosis.dart';
export 'educational_status.dart';
export 'family_member.dart';
export 'health_status.dart';
export 'housing_condition.dart';
export 'intake_info.dart';
export 'patient.dart';
export 'person.dart';
export 'personal_data.dart';
export 'placement_history.dart';
export 'referral.dart';
export 'role.dart';
export 'social_health_summary.dart';
export 'social_identity.dart';
export 'socio_economic_situation.dart';
export 'violation_report.dart';
export 'work_and_income.dart';
