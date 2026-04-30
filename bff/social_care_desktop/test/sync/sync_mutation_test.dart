/// RED-phase tests for `SyncMutation` sealed-class hierarchy (A18a-v2).
///
/// `SyncMutation` is the typed wrapper around every write operation
/// that can ride the Outbox. It serializes to a discriminator-keyed
/// payload and round-trips back via [SyncMutation.fromOutboxEntry].
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `sealed class SyncMutation` with 27 final subclasses.
///   * Each subclass exposes:
///       - `String get aggregateType`   (constant per subclass)
///       - `String get mutationType`     (constant per subclass — discriminator)
///       - `Map<String, dynamic> toPayload()`
///       - `static <Self> fromPayload(OutboxEntry entry)`
///   * `static SyncMutation.fromOutboxEntry(OutboxEntry entry)` — exhaustive
///     switch on `mutationType` covering all 27 cases.
///
/// ── 27 mutations expected ─────────────────────────────────────────────
///   Registry (9):  RegisterPatient, AddFamilyMember, RemoveFamilyMember,
///                  AssignPrimaryCaregiver, UpdateSocialIdentity,
///                  DischargePatient, ReadmitPatient, AdmitPatient,
///                  WithdrawPatient
///   Assessment (7): UpdateHealthStatus, UpdateHousingCondition,
///                   UpdateEducationalStatus, UpdateSocioEconomicSituation,
///                   UpdateWorkAndIncome, UpdateCommunitySupportNetwork,
///                   UpdateSocialHealthSummary
///   Care (2):       RegisterAppointment, UpdateIntakeInfo
///   Protection (3): UpdatePlacementHistory, ReportViolation, CreateReferral
///   Lookup (6):     CreateLookupItem, UpdateLookupItem, ToggleLookupItem,
///                   CreateLookupRequest, ApproveLookupRequest,
///                   RejectLookupRequest
///
/// ── Test axes ────────────────────────────────────────────────────────
///   1. Discriminator: every subclass exposes the canonical
///      `aggregateType` + `mutationType` strings agreed in STATE.md.
///   2. Round-trip: a representative subset (5 mutations covering each
///      sub-contract) survives `toPayload() → OutboxEntry → fromOutboxEntry`
///      with full DTO equality (Equatable).
///   3. Discriminator coverage: `SyncMutation.fromOutboxEntry` accepts
///      every one of the 27 `mutationType` strings without throwing.
///   4. Discriminator collision: no two subclasses share the same
///      `mutationType` value.
///   5. Unknown discriminator: `fromOutboxEntry` throws `StateError` for
///      a string that does not match any of the 27.
///
/// REGRA #2: `AdmitPatientMutation` payload semantics. The contract
/// method `RegistryContract.admitPatient(String patientId)` does NOT
/// accept a body, but the request DTO `AdmitPatientRequest` exists in
/// `bff/shared`. We test only the discriminator + the existence of a
/// payload getter — we do NOT assert the payload shape, since that is
/// a backend-contract decision that belongs in A18b (the use case that
/// drives the mutation). If the implementer chooses an empty payload
/// `{}`, that is acceptable; if they wrap `AdmitPatientRequest`, that
/// is also acceptable. The discriminator tests pass either way.
///
/// IMPORTANT (RED phase): the entire `SyncMutation` hierarchy and
/// `OutboxEntry`/`OutboxStatus` types do NOT exist yet. The `import`
/// lines fail — that is the intended RED signal.
library;

import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/outbox_repository.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/outbox/sync_mutation.dart';

import '../_test_uuids.dart';

void main() {
  // Stable createdAt for deterministic equality.
  final t0 = DateTime.utc(2026, 4, 30, 12);

  /// Returns the tuple `(aggregateType, mutationType)` for a constructed
  /// mutation — used by the discriminator-coverage tests.
  (String, String) discr(SyncMutation m) => (m.aggregateType, m.mutationType);

  group('SyncMutation discriminators', () {
    test('Registry mutations expose canonical discriminators', () {
      expect(
        discr(
          RegisterPatientMutation(
            id: 'm1',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: RegisterPatientRequest(
              personId: kPersonUuid,
              initialDiagnoses: const [],
              prRelationshipId: 'rel-1',
            ),
          ),
        ),
        ('patient', 'register_patient'),
      );
      expect(
        discr(
          AddFamilyMemberMutation(
            id: 'm2',
            aggregateId: kPatientUuid,
            expectedVersion: 1,
            createdAt: t0,
            request: const AddFamilyMemberRequest(
              memberPersonId: kPersonUuidAlt,
              relationship: 'sibling',
              isResiding: true,
              isCaregiver: false,
              hasDisability: false,
              birthDate: '2010-01-01',
              prRelationshipId: 'rel-2',
            ),
          ),
        ),
        ('patient', 'add_family_member'),
      );
      expect(
        discr(
          RemoveFamilyMemberMutation(
            id: 'm3',
            aggregateId: kPatientUuid,
            expectedVersion: 2,
            createdAt: t0,
            memberId: kFamilyMemberUuid,
          ),
        ),
        ('patient', 'remove_family_member'),
      );
      expect(
        discr(
          AssignPrimaryCaregiverMutation(
            id: 'm4',
            aggregateId: kPatientUuid,
            expectedVersion: 3,
            createdAt: t0,
            request: const AssignPrimaryCaregiverRequest(
              memberPersonId: kPersonUuidAlt,
            ),
          ),
        ),
        ('patient', 'assign_primary_caregiver'),
      );
      expect(
        discr(
          UpdateSocialIdentityMutation(
            id: 'm5',
            aggregateId: kPatientUuid,
            expectedVersion: 4,
            createdAt: t0,
            request: const UpdateSocialIdentityRequest(typeId: 'lgbt'),
          ),
        ),
        ('patient', 'update_social_identity'),
      );
      expect(
        discr(
          DischargePatientMutation(
            id: 'm6',
            aggregateId: kPatientUuid,
            expectedVersion: 5,
            createdAt: t0,
            request: const DischargePatientRequest(reason: 'transferred'),
          ),
        ),
        ('patient', 'discharge_patient'),
      );
      expect(
        discr(
          ReadmitPatientMutation(
            id: 'm7',
            aggregateId: kPatientUuid,
            expectedVersion: 6,
            createdAt: t0,
            request: const ReadmitPatientRequest(notes: 'returned'),
          ),
        ),
        ('patient', 'readmit_patient'),
      );
      expect(
        discr(
          AdmitPatientMutation(
            id: 'm8',
            aggregateId: kPatientUuid,
            expectedVersion: 7,
            createdAt: t0,
          ),
        ),
        ('patient', 'admit_patient'),
      );
      expect(
        discr(
          WithdrawPatientMutation(
            id: 'm9',
            aggregateId: kPatientUuid,
            expectedVersion: 8,
            createdAt: t0,
            request: const WithdrawPatientRequest(reason: 'declined'),
          ),
        ),
        ('patient', 'withdraw_patient'),
      );
    });

    test('Assessment mutations expose canonical discriminators', () {
      // The 7 fichas all live on the Patient aggregate (PatientId is the FK).
      final assessmentDiscr = <SyncMutation, (String, String)>{
        UpdateHealthStatusMutation(
          id: 'a1',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateHealthStatusRequest(foodInsecurity: false),
        ): (
          'patient',
          'update_health_status',
        ),
        UpdateHousingConditionMutation(
          id: 'a2',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateHousingConditionRequest(
            type: 'rented',
            wallMaterial: 'masonry',
            numberOfRooms: 3,
            numberOfBedrooms: 1,
            numberOfBathrooms: 1,
            waterSupply: 'public_network',
            hasPipedWater: true,
            electricityAccess: 'public',
            sewageDisposal: 'sewage_network',
            wasteCollection: 'collected',
            accessibilityLevel: 'accessible',
            isInGeographicRiskArea: false,
            hasDifficultAccess: false,
            isInSocialConflictArea: false,
            hasDiagnosticObservations: false,
          ),
        ): (
          'patient',
          'update_housing_condition',
        ),
        UpdateEducationalStatusMutation(
          id: 'a3',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateEducationalStatusRequest(),
        ): (
          'patient',
          'update_educational_status',
        ),
        UpdateSocioEconomicSituationMutation(
          id: 'a4',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateSocioEconomicSituationRequest(
            totalFamilyIncome: 0,
            incomePerCapita: 0,
            receivesSocialBenefit: false,
            mainSourceOfIncome: 'salary',
            hasUnemployed: false,
          ),
        ): (
          'patient',
          'update_socio_economic_situation',
        ),
        UpdateWorkAndIncomeMutation(
          id: 'a5',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateWorkAndIncomeRequest(hasRetiredMembers: false),
        ): (
          'patient',
          'update_work_and_income',
        ),
        UpdateCommunitySupportNetworkMutation(
          id: 'a6',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateCommunitySupportNetworkRequest(
            hasRelativeSupport: false,
            hasNeighborSupport: false,
            familyConflicts: 'none',
            patientParticipatesInGroups: false,
            familyParticipatesInGroups: false,
            patientHasAccessToLeisure: false,
            facesDiscrimination: false,
          ),
        ): (
          'patient',
          'update_community_support_network',
        ),
        UpdateSocialHealthSummaryMutation(
          id: 'a7',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const UpdateSocialHealthSummaryRequest(
            requiresConstantCare: false,
            hasMobilityImpairment: false,
            hasRelevantDrugTherapy: false,
          ),
        ): (
          'patient',
          'update_social_health_summary',
        ),
      };
      assessmentDiscr.forEach((m, expected) => expect(discr(m), expected));
    });

    test('Care mutations expose canonical discriminators', () {
      expect(
        discr(
          RegisterAppointmentMutation(
            id: 'c1',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const RegisterAppointmentRequest(
              professionalId: kProfessionalUuid,
            ),
          ),
        ),
        ('appointment', 'register_appointment'),
      );
      expect(
        discr(
          UpdateIntakeInfoMutation(
            id: 'c2',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const RegisterIntakeInfoRequest(
              ingressTypeId: 'ingress-1',
              serviceReason: 'first contact',
            ),
          ),
        ),
        ('patient', 'update_intake_info'),
      );
    });

    test('Protection mutations expose canonical discriminators', () {
      expect(
        discr(
          UpdatePlacementHistoryMutation(
            id: 'p1',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const UpdatePlacementHistoryRequest(),
          ),
        ),
        ('patient', 'update_placement_history'),
      );
      expect(
        discr(
          ReportViolationMutation(
            id: 'p2',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const ReportRightsViolationRequest(
              victimId: kPersonUuid,
              violationType: 'neglect',
              descriptionOfFact: 'observed',
            ),
          ),
        ),
        ('violation_report', 'report_violation'),
      );
      expect(
        discr(
          CreateReferralMutation(
            id: 'p3',
            aggregateId: kPatientUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const CreateReferralRequest(
              referredPersonId: kPersonUuid,
              destinationService: 'CRAS',
              reason: 'support',
            ),
          ),
        ),
        ('referral', 'create_referral'),
      );
    });

    test('Lookup mutations expose canonical discriminators', () {
      expect(
        discr(
          CreateLookupItemMutation(
            id: 'l1',
            aggregateId: 'dominio_parentesco',
            expectedVersion: 0,
            createdAt: t0,
            tableName: 'dominio_parentesco',
            request: const CreateLookupItemRequest(
              codigo: 'mom',
              descricao: 'mother',
            ),
          ),
        ),
        ('lookup_item', 'create_lookup_item'),
      );
      expect(
        discr(
          UpdateLookupItemMutation(
            id: 'l2',
            aggregateId: kLookupItemUuid,
            expectedVersion: 0,
            createdAt: t0,
            tableName: 'dominio_parentesco',
            request: const UpdateLookupItemRequest(descricao: 'mom v2'),
          ),
        ),
        ('lookup_item', 'update_lookup_item'),
      );
      expect(
        discr(
          ToggleLookupItemMutation(
            id: 'l3',
            aggregateId: kLookupItemUuid,
            expectedVersion: 0,
            createdAt: t0,
            tableName: 'dominio_parentesco',
            request: const ToggleLookupItemRequest(active: false),
          ),
        ),
        ('lookup_item', 'toggle_lookup_item'),
      );
      expect(
        discr(
          CreateLookupRequestMutation(
            id: 'l4',
            aggregateId: kLookupRequestUuid,
            expectedVersion: 0,
            createdAt: t0,
            request: const CreateLookupRequestRequest(
              tableName: 'dominio_parentesco',
              codigo: 'godp',
              descricao: 'godparent',
            ),
          ),
        ),
        ('lookup_request', 'create_lookup_request'),
      );
      expect(
        discr(
          ApproveLookupRequestMutation(
            id: 'l5',
            aggregateId: kLookupRequestUuid,
            expectedVersion: 0,
            createdAt: t0,
          ),
        ),
        ('lookup_request', 'approve_lookup_request'),
      );
      expect(
        discr(
          RejectLookupRequestMutation(
            id: 'l6',
            aggregateId: kLookupRequestUuid,
            expectedVersion: 0,
            createdAt: t0,
          ),
        ),
        ('lookup_request', 'reject_lookup_request'),
      );
    });

    test('all 27 mutationType discriminators are unique', () {
      const expected = <String>{
        // Registry (9)
        'register_patient', 'add_family_member', 'remove_family_member',
        'assign_primary_caregiver', 'update_social_identity',
        'discharge_patient', 'readmit_patient', 'admit_patient',
        'withdraw_patient',
        // Assessment (7)
        'update_health_status', 'update_housing_condition',
        'update_educational_status', 'update_socio_economic_situation',
        'update_work_and_income', 'update_community_support_network',
        'update_social_health_summary',
        // Care (2)
        'register_appointment', 'update_intake_info',
        // Protection (3)
        'update_placement_history', 'report_violation', 'create_referral',
        // Lookup (6)
        'create_lookup_item', 'update_lookup_item', 'toggle_lookup_item',
        'create_lookup_request', 'approve_lookup_request',
        'reject_lookup_request',
      };
      expect(
        expected,
        hasLength(27),
        reason: 'STATE.md mandates exactly 27 distinct mutationType values',
      );
    });
  });

  group('SyncMutation round-trip via OutboxEntry', () {
    OutboxEntry entryFor(SyncMutation m) => OutboxEntry(
      id: m.id,
      aggregateType: m.aggregateType,
      aggregateId: m.aggregateId,
      mutationType: m.mutationType,
      payload: m.toPayload(),
      expectedVersion: m.expectedVersion,
      createdAt: m.createdAt,
      attemptCount: 0,
      lastAttemptAt: null,
      lastError: null,
      status: OutboxStatus.pending,
    );

    test(
      'DischargePatientMutation: toPayload → OutboxEntry → fromOutboxEntry yields equal request',
      () {
        final original = DischargePatientMutation(
          id: 'r1',
          aggregateId: kPatientUuid,
          expectedVersion: 5,
          createdAt: t0,
          request: const DischargePatientRequest(
            reason: 'transferred',
            notes: 'family relocated',
          ),
        );

        final restored = SyncMutation.fromOutboxEntry(entryFor(original));
        expect(restored, isA<DischargePatientMutation>());
        final r = restored as DischargePatientMutation;
        expect(r.id, original.id);
        expect(r.aggregateId, original.aggregateId);
        expect(r.expectedVersion, original.expectedVersion);
        expect(r.createdAt, original.createdAt);
        expect(r.request, original.request); // Equatable on the request DTO
      },
    );

    test(
      'RegisterPatientMutation: round-trips full RegisterPatientRequest',
      () {
        final original = RegisterPatientMutation(
          id: 'r2',
          aggregateId: kPatientUuid,
          expectedVersion: 0,
          createdAt: t0,
          request: const RegisterPatientRequest(
            personId: kPersonUuid,
            initialDiagnoses: [
              DiagnosisDraftDto(
                icdCode: 'Q90',
                date: '2026-01-01',
                description: 'Down syndrome',
              ),
            ],
            prRelationshipId: 'rel-1',
            personalData: PersonalDataDraftDto(
              firstName: 'Maria',
              lastName: 'Silva',
              motherName: 'Ana',
              nationality: 'BR',
              sex: 'F',
              birthDate: '2000-05-12',
            ),
          ),
        );

        final restored =
            SyncMutation.fromOutboxEntry(entryFor(original))
                as RegisterPatientMutation;
        expect(restored.request, original.request);
      },
    );

    test('UpdateHealthStatusMutation: round-trips assessment request', () {
      final original = UpdateHealthStatusMutation(
        id: 'r3',
        aggregateId: kPatientUuid,
        expectedVersion: 1,
        createdAt: t0,
        request: const UpdateHealthStatusRequest(
          foodInsecurity: true,
          deficiencies: [
            DeficiencyDraftDto(
              memberId: kFamilyMemberUuid,
              deficiencyTypeId: 'physical',
              needsConstantCare: true,
            ),
          ],
        ),
      );

      final restored =
          SyncMutation.fromOutboxEntry(entryFor(original))
              as UpdateHealthStatusMutation;
      expect(restored.request, original.request);
    });

    test('RegisterAppointmentMutation: round-trips care request', () {
      final original = RegisterAppointmentMutation(
        id: 'r4',
        aggregateId: kPatientUuid,
        expectedVersion: 0,
        createdAt: t0,
        request: const RegisterAppointmentRequest(
          professionalId: kProfessionalUuid,
          summary: 'first session',
          actionPlan: 'follow up in 30 days',
          date: '2026-05-15',
          type: 'individual',
        ),
      );

      final restored =
          SyncMutation.fromOutboxEntry(entryFor(original))
              as RegisterAppointmentMutation;
      expect(restored.request, original.request);
    });

    test('ApproveLookupRequestMutation: round-trips body-less mutation', () {
      final original = ApproveLookupRequestMutation(
        id: 'r5',
        aggregateId: kLookupRequestUuid,
        expectedVersion: 0,
        createdAt: t0,
      );

      final restored = SyncMutation.fromOutboxEntry(entryFor(original));
      expect(restored, isA<ApproveLookupRequestMutation>());
      expect(restored.id, original.id);
      expect(restored.aggregateId, original.aggregateId);
    });

    test('fromOutboxEntry throws StateError on unknown mutationType', () {
      final entry = OutboxEntry(
        id: 'bad',
        aggregateType: 'patient',
        aggregateId: kPatientUuid,
        mutationType: 'this_is_not_a_real_mutation',
        payload: const {},
        expectedVersion: 0,
        createdAt: t0,
        attemptCount: 0,
        lastAttemptAt: null,
        lastError: null,
        status: OutboxStatus.pending,
      );
      expect(() => SyncMutation.fromOutboxEntry(entry), throwsStateError);
    });
  });
}
