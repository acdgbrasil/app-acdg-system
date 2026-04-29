# A06c Wave 0 REPORT — Test Writer (Equality)

## Status: COMPLETED (RED)

3 arquivos de teste de value-equality criados para os ~72 DTOs. 101 RED + 1 GREEN (LookupItemResponse já tem Equatable).

## Insight crítico
Testes **omitem `const`** nos construtores. Dart canonicaliza const literals para mesma instância → `a == b` passaria por IDENTIDADE mesmo sem Equatable, mascarando o bug. Sem const, força value equality real.

## 3 files criados
- `bff/shared/test/contract/dto/equality/request_equality_test.dart` — 44 tests
- `bff/shared/test/contract/dto/equality/response_equality_test.dart` — 50 tests
- `bff/shared/test/contract/dto/equality/shared_equality_test.dart` — 8 tests
- **Total: 102 tests (101 RED + 1 GREEN)**

## Resultado `dart test test/contract/dto/equality/`
```
00:00 +1 -101: Some tests failed.
```

Failures mostram:
```
Expected: <Instance of 'XxxRequest/Response'>
  Actual: <Instance of 'XxxRequest/Response'>
```
Estruturalmente idênticos mas `a != b` (reference equality).

## Baseline mantida
378 testes pré-existentes continuam GREEN (377 de A01–A06b + 1 LookupItemResponse).

## Notes para Wave 1 implementer

### Escopo: ~72 arquivos, organizados por folder

**Requests (43 classes em 27 files):**
- `requests/assessment/` — 7 arquivos + nested drafts (ProfileDraftDto, OccurrenceDraftDto, DeficiencyDraftDto, PregnantDraftDto, SocialBenefitDraftDto, IncomeDraftDto)
- `requests/care/` — 2 + nested ProgramLinkDraftDto
- `requests/governance/` — 4 (CreateLookupItem, Update, Toggle, CreateLookupRequest)
- `requests/people/` — 3
- `requests/protection/` — 3 + nested (RegistryDraftDto, CollectiveDraftDto, SeparationDraftDto)
- `requests/registry/` — 8 + nested (DiagnosisDraftDto, PersonalDataDraftDto, CivilDocumentsDraftDto, RgDocumentDraftDto, CnsDraftDto, AddressDraftDto, SocialIdentityDraftDto)

**Responses (49 classes em 34 files; 1 já feito):**
- `responses/analytics/` — 3 + nested (HousingAnalyticsResponse, FinancialIndicatorsResponse, AgeProfileResponse, EducationalVulnerabilityResponse, IndicatorRowResponse, IndicatorMetaResponse)
- `responses/assessment/` — 8 + nested (EducationalProfileResponse, ProgramOccurrenceResponse, MemberDeficiencyResponse, PregnantMemberResponse, WorkIncomeResponse)
- `responses/audit/` — 1 (AuditTrailEntryResponse)
- `responses/auth/` — 1 (MeResponse)
- `responses/care/` — 2 + nested ProgramLinkResponse
- `responses/governance/` — 3 (LookupItemResponse já feito; LookupRequestResponse, LookupsBatchResponse)
- `responses/people/` — 2 (PersonResponse, PersonRoleResponse)
- `responses/protection/` — 3 + nested PlacementRegistryResponse
- `responses/registry/` — 10 + nested (RgDocumentResponse, CnsResponse)
- `responses/team/` — 2 (TeamMemberResponse, TeamMemberDetailResponse)

**Shared (8 classes em 4 files):**
- `shared/backend_error.dart` — BackendError (recursivo via `cause`), ErrorObservability, BackendErrorResponse
- `shared/paginated_list.dart` — PaginatedList<T>
- `shared/pagination_meta.dart` — PaginationMeta
- `shared/standard_response.dart` — StandardResponse<T>, ResponseMeta, IdData

### Transitividade de Equatable

Nested DTOs precisam TODOS de Equatable senão a lista/objeto aninhado cai em reference equality:

**Top-level types com nesteds:**
- `RegisterPatientRequest` → initialDiagnoses, personalData (+ civil docs recursivo), address, socialIdentity
- `UpdateHealthStatusRequest` → DeficiencyDraftDto, PregnantDraftDto
- `UpdateEducationalStatusRequest` → ProfileDraftDto, OccurrenceDraftDto
- `UpdateSocioEconomicSituationRequest` / `UpdateWorkAndIncomeRequest` → SocialBenefitDraftDto, IncomeDraftDto
- `UpdatePlacementHistoryRequest` → RegistryDraftDto, CollectiveDraftDto, SeparationDraftDto
- `RegisterIntakeInfoRequest` / `IngressInfoResponse` → ProgramLink*
- `PatientResponse` → agregado gigante transitivo
- `TeamMemberDetailResponse` → List<PersonRoleResponse>
- `IndicatorResponse` → IndicatorRowResponse, IndicatorMetaResponse
- `ComputedAnalyticsResponse` → Housing, Financial, AgeProfile, Educational
- `PlacementHistoryResponse` → PlacementRegistryResponse
- `CivilDocumentsResponse/Draft` → RgDocument*, Cns*
- `LookupsBatchResponse` → Map<String, List<LookupItemResponse>> (funciona via map equality + LookupItem Equatable ✅)
- `BackendError` → self-recursive BackendError? cause

### Caveats
- `StandardResponse<T>` / `PaginatedList<T>` genéricos — `props => [data, meta]` só transitivo se T for Equatable. Para primitivos (String, int) funciona nativo.
- `BackendError.context: Map<String, dynamic>?` — Equatable map equality é estrutural mas não olha through `dynamic` — documentar como limitação aceita.

## Wave 1 checklist
- [ ] ~72 arquivos com `with Equatable` + `props` cobrindo todos os campos finais
- [ ] Nested types também Equatable (transitividade)
- [ ] 101 testes equality viram GREEN
- [ ] 378 testes anteriores continuam GREEN
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] Não alterar fromJson/toJson (gerados)
