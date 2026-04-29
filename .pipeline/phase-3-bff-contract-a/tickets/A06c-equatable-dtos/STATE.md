# Ticket State: A06c-equatable-dtos

phase: implementation
agent: TDD (Wave 0 test-writer + Wave 1 implementer)
status: COMPLETED — both waves GREEN

## Wave 0 deliverables
- `bff/shared/test/contract/dto/equality/request_equality_test.dart` — 44 tests
- `bff/shared/test/contract/dto/equality/response_equality_test.dart` — 50 tests
- `bff/shared/test/contract/dto/equality/shared_equality_test.dart` — 8 tests
- Total: 102 tests (101 RED + 1 GREEN baseline for `LookupItemResponse`)

## Wave 1 deliverables
- `with Equatable` + `List<Object?> get props` added to 71 DTO classes across
  27 request files, 21 response files, and 4 shared wrapper files.
- Build artifacts (`*.g.dart`) untouched — `fromJson`/`toJson` preserved.
- Caveats documented inline on `StandardResponse<T>`, `PaginatedList<T>`,
  `BackendError`, and `AuditTrailEntryResponse`.

## Verification
- `dart test test/contract/dto/equality/` — 102 GREEN (101 flipped + 1 preserved)
- `dart test` (full suite) — **479 GREEN** (378 previous + 101 new flips)
- `dart analyze lib` — zero issues
