/// Canonical UUID v4 fixtures for tests across the BFF Web suite.
///
/// Established in A23 (UUID Path Validation Canon). Replaces synthetic
/// path params like `'m-1'`, `'p-1'`, `'r-1'` that A23's
/// `validateUuidPathParam` would now reject as 400 INVALID_*_PARAMS.
///
/// All values are RFC 4122 v4 (version nibble `4`, variant nibble in
/// `[89ab]`), lowercase, hyphenated. Stable across runs — DO NOT
/// regenerate; tests may match against the literal string.
///
/// Reuse policy: prefer importing these constants over inlining UUID
/// literals in tests. Adding a new fixture is fine when the existing
/// ones don't capture the intent (e.g. a "second patient", a
/// "deactivated worker"). Keep names semantic, not numeric.
library;

// ── Patients ──────────────────────────────────────────────────────────
const kPatientUuid = 'a1b2c3d4-e5f6-4789-a012-3456789abcde';
const kPatientUuidAlt = 'b2c3d4e5-f6a7-4890-b123-456789abcdef';

// ── Family members ────────────────────────────────────────────────────
const kFamilyMemberUuid = 'c3d4e5f6-a7b8-4901-9234-56789abcdef0';
const kFamilyMemberUuidAlt = 'd4e5f6a7-b8c9-4012-a345-6789abcdef01';

// ── Team members (workers/professionals) ──────────────────────────────
const kMemberUuid = 'e5f6a7b8-c9d0-4123-b456-789abcdef012';
const kMemberUuidAlt = 'f6a7b8c9-d0e1-4234-9567-89abcdef0123';

// ── Roles ─────────────────────────────────────────────────────────────
const kRoleUuid = 'a7b8c9d0-e1f2-4345-a678-9abcdef01234';
const kRoleUuidAlt = 'b8c9d0e1-f2a3-4456-b789-abcdef012345';

// ── Lookup items / requests ───────────────────────────────────────────
const kLookupItemUuid = 'c9d0e1f2-a3b4-4567-989a-bcdef0123456';
const kLookupRequestUuid = 'd0e1f2a3-b4c5-4678-9a9b-cdef01234567';

// ── Appointments (Care) ───────────────────────────────────────────────
const kAppointmentUuid = 'e1f2a3b4-c5d6-4789-a0bc-def012345678';

// ── Referrals / violation reports (Protection) ────────────────────────
const kReferralUuid = 'f2a3b4c5-d6e7-4890-b1cd-ef0123456789';
const kViolationReportUuid = 'a3b4c5d6-e7f8-4901-9def-012345678901';

// ── Audit ─────────────────────────────────────────────────────────────
const kAuditUuid = 'b4c5d6e7-f8a9-4012-bef0-123456789012';

// ── Sentinel values for negative testing ──────────────────────────────

/// A canonical NON-UUID string used to verify rejection paths. Picked
/// to mirror the literal scenario that triggered A23: a legacy URL
/// `/team/people` was being routed to GetTeamMember(id='people').
const kNonUuid = 'people';

/// A path-traversal attempt used in security-focused tests.
const kPathTraversalAttempt = '../../etc/passwd';

/// A UUID v1 (timestamp-based) — must be rejected by v4-strict
/// validation. Differs from a v4 only by the version nibble.
const kUuidV1 = 'a1b2c3d4-e5f6-1789-a012-3456789abcde';
