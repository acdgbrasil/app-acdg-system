import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryLookupStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryLookupStore {
///   final Map<String, List<LookupItemResponse>> tables = {};
///   final List<LookupRequestResponse> requests = [];
///
///   void addItem(String tableName, LookupItemResponse item);
///   List<LookupItemResponse> getTable(String tableName);
///   void toggleItem(String tableName, String itemId, bool active);
///   void addRequest(LookupRequestResponse request);
///   void approveRequest(String id);
///   void rejectRequest(String id);
///   void clear();
/// }
/// ```
void main() {
  group('InMemoryLookupStore', () {
    LookupItemResponse buildItem(
      String id, {
      String codigo = 'CODE-1',
      String descricao = 'Desc',
    }) =>
        LookupItemResponse(id: id, codigo: codigo, descricao: descricao);

    LookupRequestResponse buildRequest(
      String id, {
      String tableName = 'diagnoses',
      String codigo = 'CODE',
      String descricao = 'Desc',
      String status = 'pending',
    }) => LookupRequestResponse(
      id: id,
      tableName: tableName,
      codigo: codigo,
      descricao: descricao,
      justificativa: null,
      status: status,
      createdAt: '2026-04-16T00:00:00Z',
      requestedBy: 'test-user',
    );

    test('starts empty', () {
      final store = InMemoryLookupStore();
      expect(store.tables, isEmpty);
      expect(store.requests, isEmpty);
    });

    test('addItem then getTable returns the item', () {
      final store = InMemoryLookupStore();
      store.addItem('diagnoses', buildItem('i-1'));
      store.addItem('diagnoses', buildItem('i-2'));

      final items = store.getTable('diagnoses');

      expect(items, hasLength(2));
      expect(items.map((i) => i.id), containsAll(<String>['i-1', 'i-2']));
    });

    test('getTable returns empty list for unknown table', () {
      final store = InMemoryLookupStore();
      expect(store.getTable('missing'), isEmpty);
    });

    test('addRequest stores governance request', () {
      final store = InMemoryLookupStore();
      store.addRequest(buildRequest('req-1'));
      store.addRequest(buildRequest('req-2'));

      expect(store.requests, hasLength(2));
      expect(
        store.requests.map((r) => r.id),
        containsAll(<String>['req-1', 'req-2']),
      );
    });

    test('approveRequest flips status to approved', () {
      final store = InMemoryLookupStore();
      store.addRequest(buildRequest('req-1'));

      store.approveRequest('req-1');

      final updated = store.requests.firstWhere((r) => r.id == 'req-1');
      expect(updated.status, equals('approved'));
    });

    test('rejectRequest flips status to rejected', () {
      final store = InMemoryLookupStore();
      store.addRequest(buildRequest('req-1'));

      store.rejectRequest('req-1');

      final updated = store.requests.firstWhere((r) => r.id == 'req-1');
      expect(updated.status, equals('rejected'));
    });

    test('clear empties tables and requests', () {
      final store = InMemoryLookupStore();
      store.addItem('diagnoses', buildItem('i-1'));
      store.addRequest(buildRequest('req-1'));

      store.clear();

      expect(store.tables, isEmpty);
      expect(store.requests, isEmpty);
    });
  });
}
