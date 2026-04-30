/// Helpers to pull the optimistic-locking version off remote responses
/// before write-through caching.
///
/// Today's `StandardResponse<PatientResponse>` carries `version` on the
/// inner DTO (`response.data.version`). Other DTOs in `bff/shared/` may
/// not expose `version` directly — we fall back to `0` when the field
/// is absent.
library;

import 'package:shared/shared.dart';

/// Extracts the version from a `StandardResponse<PatientResponse>`.
/// Returns `0` if the embedded DTO has no `version` (defensive default).
int extractPatientVersion(StandardResponse<PatientResponse> response) =>
    response.data.version;
