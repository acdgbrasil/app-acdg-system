/// RED-phase tests for [LookupFacade] (A18c-v2).
///
/// 10 public methods delegate to the 10 Lookup use cases (A18b-v2).
///
/// Locked contract:
///
///   class LookupFacade {
///     LookupFacade._({...10 use cases...});
///     // Tables (read)
///     Future<Result<List<LookupItemResponse>>> getLookupTable(String tableName);
///     Future<Result<Map<String, List<LookupItemResponse>>>> getLookupsBatch(List<String> tables);
///     // Items (write)
///     Future<Result<StandardIdResponse>> createLookupItem(String tableName, CreateLookupItemRequest req);
///     Future<Result<void>> updateLookupItem(String tableName, String itemId, UpdateLookupItemRequest req);
///     Future<Result<void>> toggleLookupItem(String tableName, String itemId, ToggleLookupItemRequest req);
///     // Requests (governance — register/list/find/approve/reject)
///     Future<Result<StandardIdResponse>> createLookupRequest(CreateLookupRequestRequest req);
///     Future<Result<List<LookupRequestResponse>>> listLookupRequests({
///       String? status, String? tableName, int? limit,
///     });
///     Future<Result<LookupRequestResponse?>> findLookupRequestById(String requestId);
///     Future<Result<void>> approveLookupRequest(String requestId);
///     Future<Result<void>> rejectLookupRequest(String requestId);
///   }
///
/// IMPORTANT (RED phase): the facade does NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  Future<SocialCareDesktop> build(FacadeTestContext ctx) =>
      SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );

  group('LookupFacade — table reads', () {
    test('getLookupTable returns Result<List<LookupItemResponse>>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.lookup.getLookupTable('relationship');
      expect(result, isA<Result<List<LookupItemResponse>>>());
    });

    test(
      'getLookupsBatch returns Result<Map<String, List<LookupItemResponse>>>',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        final result = await desktop.lookup.getLookupsBatch(const [
          'relationship',
          'maritalStatus',
        ]);
        expect(result, isA<Result<Map<String, List<LookupItemResponse>>>>());
      },
    );
  });

  group('LookupFacade — item writes', () {
    test('createLookupItem returns Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = CreateLookupItemRequest(codigo: 'AVO', descricao: 'Avô');
      final result = await desktop.lookup.createLookupItem('relationship', req);
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test(
      'toggleLookupItem returns Result<void> (proves item-level wiring)',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        const req = ToggleLookupItemRequest(active: false);
        final result = await desktop.lookup.toggleLookupItem(
          'relationship',
          kLookupItemUuid,
          req,
        );
        expect(result, isA<Result<void>>());
      },
    );
  });

  group('LookupFacade — request governance', () {
    test('createLookupRequest returns Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = CreateLookupRequestRequest(
        tableName: 'relationship',
        codigo: 'PRI',
        descricao: 'Primo',
      );
      final result = await desktop.lookup.createLookupRequest(req);
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test('approveLookupRequest takes (requestId) and returns Result<void> '
        '— proves governance methods wired', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.lookup.approveLookupRequest(
        kLookupRequestUuid,
      );
      expect(result, isA<Result<void>>());
    });
  });
}
