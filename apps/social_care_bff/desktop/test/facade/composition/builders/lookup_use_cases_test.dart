/// RED-phase tests for `LookupUseCases` builder (D02 W0.5).
///
/// `LookupUseCases` groups the 10 Lookup use cases — a mix of reads
/// (cache + remote + staleAfter) and writes (cache + outbox + engine):
///   Reads (5):
///     * `GetLookupTableUseCase`, `GetLookupsBatchUseCase`,
///       `ListLookupRequestsUseCase`, `FindLookupRequestByIdUseCase`
///   Writes (5):
///     * `CreateLookupItemUseCase`, `UpdateLookupItemUseCase`,
///       `ToggleLookupItemUseCase`, `CreateLookupRequestUseCase`,
///       `ApproveLookupRequestUseCase`, `RejectLookupRequestUseCase`
///
/// Builder takes: `lookupCache`, `lookupRemote`, `outbox`, `engine`,
/// `clock`, `staleAfter`.
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class LookupUseCases`
///       - 10 final fields (see ticket D02 000-request.md for ordering):
///         `getLookupTable`, `getLookupsBatch`, `createLookupItem`,
///         `updateLookupItem`, `toggleLookupItem`, `createLookupRequest`,
///         `listLookupRequests`, `findLookupRequestById`,
///         `approveLookupRequest`, `rejectLookupRequest`
///       - `static LookupUseCases build({...})` factory
///
/// IMPORTANT (RED phase): builder file does not exist yet. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/lookup/approve_lookup_request_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/create_lookup_item_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/create_lookup_request_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/find_lookup_request_by_id_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/get_lookup_table_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/get_lookups_batch_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/list_lookup_requests_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/reject_lookup_request_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/toggle_lookup_item_use_case.dart';
import 'package:social_care_desktop/src/use_cases/lookup/update_lookup_item_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/lookup_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('LookupUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 10 fields populated and non-null',
      () {
        final useCases = LookupUseCases.build(
          lookupCache: deps.lookupCache,
          remote: deps.lookupRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(useCases, isNotNull);
        // Reads
        expect(useCases.getLookupTable, isNotNull);
        expect(useCases.getLookupsBatch, isNotNull);
        expect(useCases.listLookupRequests, isNotNull);
        expect(useCases.findLookupRequestById, isNotNull);
        // Writes
        expect(useCases.createLookupItem, isNotNull);
        expect(useCases.updateLookupItem, isNotNull);
        expect(useCases.toggleLookupItem, isNotNull);
        expect(useCases.createLookupRequest, isNotNull);
        expect(useCases.approveLookupRequest, isNotNull);
        expect(useCases.rejectLookupRequest, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = LookupUseCases.build(
        lookupCache: deps.lookupCache,
        remote: deps.lookupRemote,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      );

      expect(useCases.getLookupTable, isA<GetLookupTableUseCase>());
      expect(useCases.getLookupsBatch, isA<GetLookupsBatchUseCase>());
      expect(useCases.listLookupRequests, isA<ListLookupRequestsUseCase>());
      expect(
        useCases.findLookupRequestById,
        isA<FindLookupRequestByIdUseCase>(),
      );
      expect(useCases.createLookupItem, isA<CreateLookupItemUseCase>());
      expect(useCases.updateLookupItem, isA<UpdateLookupItemUseCase>());
      expect(useCases.toggleLookupItem, isA<ToggleLookupItemUseCase>());
      expect(useCases.createLookupRequest, isA<CreateLookupRequestUseCase>());
      expect(useCases.approveLookupRequest, isA<ApproveLookupRequestUseCase>());
      expect(useCases.rejectLookupRequest, isA<RejectLookupRequestUseCase>());
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = LookupUseCases.build(
          lookupCache: deps.lookupCache,
          remote: deps.lookupRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );
        final b = LookupUseCases.build(
          lookupCache: deps.lookupCache,
          remote: deps.lookupRemote,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(identical(a, b), isFalse);
        expect(identical(a.getLookupTable, b.getLookupTable), isFalse);
        expect(identical(a.createLookupItem, b.createLookupItem), isFalse);
        expect(
          identical(a.rejectLookupRequest, b.rejectLookupRequest),
          isFalse,
        );

        expect(
          a.getLookupTable.runtimeType,
          equals(b.getLookupTable.runtimeType),
        );
        expect(
          a.createLookupItem.runtimeType,
          equals(b.createLookupItem.runtimeType),
        );
        expect(
          a.rejectLookupRequest.runtimeType,
          equals(b.rejectLookupRequest.runtimeType),
        );
      },
    );
  });
}
