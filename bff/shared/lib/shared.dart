/// Kernel compartilhado do BFF Social Care.
library shared;

// Utils
export 'src/utils/app_error.dart';
export 'src/utils/string_helpers.dart';

// Kernel
export 'src/domain/kernel/address.dart';
export 'src/domain/kernel/cep.dart';
export 'src/domain/kernel/cpf.dart';
export 'src/domain/kernel/ids.dart';
export 'src/domain/kernel/nis.dart';
export 'src/domain/kernel/rg_document.dart';
export 'src/domain/kernel/time_stamp.dart';

// Models
export 'src/domain/models/lookup.dart';

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

// Care
export 'src/domain/care/care_vos.dart';

// Protection
export 'src/domain/protection/protection_vos.dart';

// Analytics
export 'src/domain/analytics/housing_analytics_service.dart';
export 'src/domain/analytics/financial_analytics_service.dart';
export 'src/domain/analytics/family_analytics.dart';
export 'src/domain/analytics/education_analytics_service.dart';

// Contract
export 'src/contract/social_care_contract.dart';

// Testing
export 'src/testing/fake_social_care_bff.dart';
