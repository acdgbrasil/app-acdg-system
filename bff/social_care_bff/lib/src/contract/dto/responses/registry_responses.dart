/// Response types for Registry bounded context operations.
///
/// The contract returns domain models directly (not separate DTOs),
/// since the BFF acts as a typed proxy without transformation.
library;

export '../../../models/family_member.dart';
export '../../../models/patient.dart';
