# Discuss Context: Phase 1 — BFF DTO Realignment

## Mode: assumptions (confirmed by user)

## Decisions

### Architecture
- **ACL boundary via DTOs**: Contract methods receive/return DTOs, not domain objects. This protects domain from backend changes.
- **@JsonSerializable**: Use json_serializable + build_runner for all DTOs. Reduces boilerplate and human errors.
- **Lifecycle endpoints included**: Discharge, readmit, admit, withdraw DTOs created in this phase even though implementation is Phase 2.
- **Lookup governance excluded**: NOT part of social_care's core responsibility. Will be separate.

### Contract Design (8 sub-contracts)
1. **HealthContract** — liveness/readiness probes
2. **RegistryContract** — patients, family members, social identity, lifecycle
3. **AssessmentContract** — all 7 assessment fichas
4. **CareContract** — appointments, intake info
5. **ProtectionContract** — referrals, violations, placement history
6. **AuditContract** — audit trail (paginated)
7. **PeopleContract** — person CRUD, CPF lookup, role management (people-context interaction)
8. **AnalyticsContract** — indicators by axis, axes metadata, dataset export (analysis-bi interaction)

### DTO Organization
```
bff/shared/lib/src/contract/
  social_care_contract.dart          — composed (implements all sub-contracts)
  sub_contracts/
    health_contract.dart
    registry_contract.dart
    assessment_contract.dart
    care_contract.dart
    protection_contract.dart
    audit_contract.dart
    people_contract.dart
    analytics_contract.dart
  dto/
    shared/
      paginated_list.dart            — cursor-based pagination envelope
      backend_error.dart             — structured error (id, code, message, severity)
      standard_response.dart         — { data: T, meta: { timestamp } }
      standard_id_response.dart      — { data: { id }, meta: { timestamp } }
      pagination_meta.dart           — { pageSize, totalCount, hasMore, nextCursor }
    requests/
      registry/
        register_patient_request.dart
        add_family_member_request.dart
        assign_primary_caregiver_request.dart
        update_social_identity_request.dart
        discharge_patient_request.dart
        readmit_patient_request.dart
        withdraw_patient_request.dart
      assessment/
        update_housing_condition_request.dart
        update_socio_economic_situation_request.dart
        update_work_and_income_request.dart
        update_educational_status_request.dart
        update_health_status_request.dart
        update_community_support_network_request.dart
        update_social_health_summary_request.dart
      care/
        register_appointment_request.dart
        register_intake_info_request.dart
      protection/
        update_placement_history_request.dart
        report_rights_violation_request.dart
        create_referral_request.dart
      people/
        register_person_request.dart
        register_person_with_login_request.dart
        assign_role_request.dart
    responses/
      registry/
        patient_response.dart          — full aggregate (replaces PatientRemote)
        patient_summary_response.dart  — list view (replaces PatientOverview)
        personal_data_response.dart
        civil_documents_response.dart
        address_response.dart
        family_member_response.dart
        diagnosis_response.dart
        social_identity_response.dart
        discharge_info_response.dart
        withdraw_info_response.dart
      assessment/
        housing_condition_response.dart
        socio_economic_response.dart
        social_benefit_response.dart
        work_and_income_response.dart
        educational_status_response.dart
        health_status_response.dart
        community_support_network_response.dart
        social_health_summary_response.dart
      care/
        appointment_response.dart
        ingress_info_response.dart
        program_link_response.dart
      protection/
        placement_history_response.dart
        violation_report_response.dart
        referral_response.dart
      audit/
        audit_trail_entry_response.dart
      people/
        person_response.dart
        person_role_response.dart
      analytics/
        indicator_response.dart
        axis_metadata_response.dart
        computed_analytics_response.dart
```

### Key Alignment Points with Swift Backend
- All IDs are String (UUID format) in DTOs
- Dates: ISO 8601 (YYYY-MM-DD for dates, full ISO for timestamps)
- Enums: SCREAMING_SNAKE_CASE strings in JSON
- Pagination: cursor-based for lists, offset-based for audit trail
- Error format: structured with id, code, message, bc, module, severity
- Response envelope: always { data, meta: { timestamp } }

## Open Items
(none — all resolved)

## User Preferences
- Use @JsonSerializable for all DTOs (boilerplate reduction)
- Lifecycle DTOs included proactively
- Contract should reflect real interactions with People Context and Analysis BI
- Execution order: #49 -> #47 + #48 (parallel) -> #50 -> #59
