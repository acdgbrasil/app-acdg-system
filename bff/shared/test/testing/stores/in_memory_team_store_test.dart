import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Smoke tests for [InMemoryTeamStore] (A06b Wave 0 — RED).
///
/// Shape expected (Wave 1 implementer will create):
/// ```
/// class InMemoryTeamStore {
///   final Map<String, TeamMemberResponse> members = {};
///   final Map<String, List<PersonRoleResponse>> rolesByMemberId = {};
///
///   void register(TeamMemberResponse member);
///   TeamMemberResponse? get(String id);
///   List<TeamMemberResponse> list({String? role, bool? active, String? search});
///   void deactivate(String id);
///   void reactivate(String id);
///   void assignRole(String memberId, PersonRoleResponse role);
///   void clear();
/// }
/// ```
void main() {
  group('InMemoryTeamStore', () {
    TeamMemberResponse buildMember(
      String id, {
      String fullName = 'Alice Silva',
      String? email = 'alice@acdg.com',
      String? primaryRole,
      bool active = true,
    }) => TeamMemberResponse(
      id: id,
      personId: id,
      fullName: fullName,
      email: email,
      phone: null,
      active: active,
      primaryRole: primaryRole,
    );

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
      final store = InMemoryTeamStore();
      expect(store.members, isEmpty);
      expect(store.rolesByMemberId, isEmpty);
    });

    test('register then get returns the stored member', () {
      final store = InMemoryTeamStore();
      final member = buildMember('m-1');

      store.register(member);

      expect(store.get('m-1'), same(member));
    });

    test('list filters by active flag', () {
      final store = InMemoryTeamStore();
      store.register(buildMember('m-1', active: true));
      store.register(buildMember('m-2', active: false));

      final activeOnly = store.list(active: true);

      expect(activeOnly, hasLength(1));
      expect(activeOnly.first.id, equals('m-1'));
    });

    test('deactivate flips member active flag to false', () {
      final store = InMemoryTeamStore();
      store.register(buildMember('m-1', active: true));

      store.deactivate('m-1');

      expect(store.get('m-1')?.active, isFalse);
    });

    test('reactivate flips member active flag back to true', () {
      final store = InMemoryTeamStore();
      store.register(buildMember('m-1', active: false));

      store.reactivate('m-1');

      expect(store.get('m-1')?.active, isTrue);
    });

    test('assignRole appends role for member', () {
      final store = InMemoryTeamStore();
      store.register(buildMember('m-1'));
      store.assignRole('m-1', buildRole('r-1', personId: 'm-1'));
      store.assignRole('m-1', buildRole('r-2', personId: 'm-1'));

      final roles = store.rolesByMemberId['m-1'] ?? const <PersonRoleResponse>[];
      expect(roles, hasLength(2));
      expect(roles.map((r) => r.id), containsAll(<String>['r-1', 'r-2']));
    });

    test('clear empties both members and roles', () {
      final store = InMemoryTeamStore();
      store.register(buildMember('m-1'));
      store.assignRole('m-1', buildRole('r-1', personId: 'm-1'));

      store.clear();

      expect(store.members, isEmpty);
      expect(store.rolesByMemberId, isEmpty);
    });
  });
}
