/// Social Care module — domain, data, and UI layers for patient management.
library;

// Data — Repositories (interfaces)
export 'src/data/repositories/patient_repository.dart';
export 'src/data/repositories/bff_patient_repository.dart';
export 'src/data/repositories/lookup_repository.dart';
export 'src/data/repositories/bff_lookup_repository.dart';

// UI — Patient Registration
export 'src/ui/patient_registration/use_case/register_patient_use_case.dart';
export 'src/ui/patient_registration/use_case/get_patient_use_case.dart';
