import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:network/network.dart';
import 'package:persistence/persistence.dart';
import 'package:acdg_system/ui/atoms/sync_indicator.dart';
import 'package:social_care_desktop/social_care_desktop.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSyncQueue extends Mock implements SyncQueueService {}
class MockRemoteBff extends Mock implements SocialCareContract {}

void main() {
  late MockSyncQueue syncQueueService;
  late MockRemoteBff remoteBff;
  late ConnectivityService connectivityService;
  late SyncEngine syncEngine;

  setUpAll(() {
    registerFallbackValue(SyncAction());
  });

  setUp(() {
    syncQueueService = MockSyncQueue();
    remoteBff = MockRemoteBff();
    connectivityService = ConnectivityService();
    connectivityService.setOnlineForTesting(true);

    syncEngine = SyncEngine(
      queueService: syncQueueService,
      connectivityService: connectivityService,
      remoteBff: remoteBff,
    );

    when(() => syncQueueService.getAllActions()).thenAnswer((_) async => []);
  });

  testWidgets('SyncIndicator Integration: Reage a mudanças no SyncEngine', (tester) async {
    // 1. Build a simple test app with the SyncEngine
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            SyncIndicator(status: syncEngine.status),
          ],
        ),
        body: const Center(child: Text('Test Body')),
      ),
    ));

    // Verify Initial State (Idle)
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);

    // 2. Simulate pending actions in the queue
    when(() => syncQueueService.getAllActions()).thenAnswer((_) async => [
      SyncAction()..status = 'PENDING'..timestamp = DateTime.now()
    ]);
    
    await syncEngine.refreshStatus();
    await tester.pump();

    // Verify UI reflects pending state
    expect(find.byIcon(Icons.cloud_queue_outlined), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // 3. Simulate conflict
    when(() => syncQueueService.getAllActions()).thenAnswer((_) async => [
      SyncAction()..status = 'CONFLICT'..timestamp = DateTime.now()
    ]);
    
    await syncEngine.refreshStatus();
    await tester.pump();

    // Verify UI reflects conflict (red)
    expect(find.byIcon(Icons.sync_problem_outlined), findsOneWidget);
  });
}
