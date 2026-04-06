import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core_offline.dart';
import 'package:acdg_system/ui/atoms/sync_indicator.dart';

void main() {
  group('SyncIndicator Widget Tests', () {
    testWidgets('should display green cloud icon when Idle', (tester) async {
      final status = ValueNotifier<SyncStatus>(const SyncIdle());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncIndicator(status: status)),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.cloud_done_outlined);
      expect(icon.color, AppColors.primary);
    });

    testWidgets('should display progress indicator when InProgress', (
      tester,
    ) async {
      final status = ValueNotifier<SyncStatus>(
        const SyncInProgress(current: 1, total: 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncIndicator(status: status)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should display orange badge when Offline', (tester) async {
      final status = ValueNotifier<SyncStatus>(const SyncOffline(3));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncIndicator(status: status)),
        ),
      );

      expect(find.byType(Badge), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.orange);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should display red badge when Conflict occurs', (
      tester,
    ) async {
      final status = ValueNotifier<SyncStatus>(const SyncConflict(1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncIndicator(status: status)),
        ),
      );

      expect(find.byType(Badge), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.danger);
    });
  });
}
