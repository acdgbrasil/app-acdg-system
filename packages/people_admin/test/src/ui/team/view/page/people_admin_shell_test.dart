import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/ui/team/di/team_providers.dart';
import 'package:people_admin/src/ui/team/view/page/people_admin_shell.dart';
import 'package:people_admin/src/ui/team/view_models/people_list_view_model.dart';
import 'package:people_admin/src/ui/team/view_models/person_detail_view_model.dart';

class MockPeopleListViewModel extends Mock implements PeopleListViewModel {}
class MockPersonDetailViewModel extends Mock implements PersonDetailViewModel {}

void main() {
  late MockPeopleListViewModel mockListViewModel;
  late MockPersonDetailViewModel mockDetailViewModel;

  setUp(() {
    mockListViewModel = MockPeopleListViewModel();
    mockDetailViewModel = MockPersonDetailViewModel();

    // Stub initial states for list
    when(() => mockListViewModel.people).thenReturn([]);
    when(() => mockListViewModel.hasMore).thenReturn(false);
    
    // Stub commands
    final searchCmd = Command1<void, String>(
      (_) async => const Success(null),
    );
    final loadMoreCmd = Command0<void>(
      () async => const Success(null),
    );
    when(() => mockListViewModel.searchCommand).thenReturn(searchCmd);
    when(() => mockListViewModel.loadMoreCommand).thenReturn(loadMoreCmd);
    
    // Listeners mock behavior (since they extend ChangeNotifier)
    when(() => mockListViewModel.addListener(any())).thenAnswer((_) {});
    when(() => mockListViewModel.removeListener(any())).thenAnswer((_) {});

    // Stub initial states for detail
    when(() => mockDetailViewModel.person).thenReturn(null);
    when(() => mockDetailViewModel.roles).thenReturn([]);

    // Listeners mock behavior (since they extend ChangeNotifier)
    when(() => mockDetailViewModel.addListener(any())).thenAnswer((_) {});
    when(() => mockDetailViewModel.removeListener(any())).thenAnswer((_) {});
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        peopleListViewModelProvider.overrideWithValue(mockListViewModel),
        personDetailViewModelProvider.overrideWithValue(mockDetailViewModel),
      ],
      child: const MaterialApp(
        home: PeopleAdminShell(),
      ),
    );
  }

  group('PeopleAdminShell', () {
    testWidgets('renders successfully and shows Master layout', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // We expect some main components or text to be rendered
      // Note: This test will fail (Red Phase) because shell throws UnimplementedError
      expect(find.byType(Scaffold), findsOneWidget);
      // Wait for master list component or "Equipe" title to appear
      expect(find.text('Equipe'), findsOneWidget);
    });
  });
}
