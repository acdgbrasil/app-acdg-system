import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryPeopleStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryPeopleStore {
///   final Map<String, PersonResponse> people = {};
///   final Map<String, List<PersonRoleResponse>> rolesByPersonId = {};
///
///   void register(PersonResponse person);
///   PersonResponse? get(String id);
///   PersonResponse? findByCpf(String cpf);
///   void assignRole(String personId, PersonRoleResponse role);
///   List<PersonRoleResponse> listRoles(String personId);
///   void deactivateRole(String personId, String roleId);
///   void clear();
/// }
/// ```
void main() {
  group('InMemoryPeopleStore', () {
    PersonResponse buildPerson(
      String id, {
      String fullName = 'Alice',
      String? cpf,
    }) => PersonResponse(id: id, fullName: fullName, cpf: cpf);

    PersonRoleResponse buildRole(
      String roleId, {
      required String personId,
      String system = 'social-care',
      String role = 'social_worker',
      bool active = true,
    }) => PersonRoleResponse(
      id: roleId,
      personId: personId,
      system: system,
      role: role,
      active: active,
    );

    test('starts empty', () {
      final store = InMemoryPeopleStore();
      expect(store.people, isEmpty);
      expect(store.rolesByPersonId, isEmpty);
    });

    test('register then get returns the stored person', () {
      final store = InMemoryPeopleStore();
      final person = buildPerson('p-1', fullName: 'Alice');

      store.register(person);

      expect(store.get('p-1'), same(person));
    });

    test('findByCpf returns the person when cpf matches', () {
      final store = InMemoryPeopleStore();
      store.register(buildPerson('p-1', cpf: '12345678901'));
      store.register(buildPerson('p-2', cpf: '10987654321'));

      final found = store.findByCpf('10987654321');

      expect(found, isNotNull);
      expect(found?.id, equals('p-2'));
    });

    test('findByCpf returns null when no match', () {
      final store = InMemoryPeopleStore();
      store.register(buildPerson('p-1', cpf: '12345678901'));

      expect(store.findByCpf('missing'), isNull);
    });

    test('assignRole appends roles for person', () {
      final store = InMemoryPeopleStore();
      store.assignRole('p-1', buildRole('r-1', personId: 'p-1'));
      store.assignRole('p-1', buildRole('r-2', personId: 'p-1'));

      final roles = store.listRoles('p-1');
      expect(roles, hasLength(2));
      expect(roles.map((r) => r.id), containsAll(<String>['r-1', 'r-2']));
    });

    test('deactivateRole flips active flag', () {
      final store = InMemoryPeopleStore();
      store.assignRole('p-1', buildRole('r-1', personId: 'p-1'));

      store.deactivateRole('p-1', 'r-1');

      final roles = store.listRoles('p-1');
      expect(roles, hasLength(1));
      expect(roles.first.active, isFalse);
    });

    test('clear empties both maps', () {
      final store = InMemoryPeopleStore();
      store.register(buildPerson('p-1'));
      store.assignRole('p-1', buildRole('r-1', personId: 'p-1'));

      store.clear();

      expect(store.people, isEmpty);
      expect(store.rolesByPersonId, isEmpty);
    });
  });
}
