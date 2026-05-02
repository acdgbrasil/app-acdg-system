import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/src/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockConnectivity mockConnectivity;
  late MockDio mockDio;
  late ConnectivityService service;
  late StreamController<List<ConnectivityResult>> connectivityStreamController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockDio = MockDio();
    connectivityStreamController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityStreamController.stream);

    service = ConnectivityService(
      connectivity: mockConnectivity,
      dio: mockDio,
      checkInterval: Duration.zero, // Disable throttling for tests
    );
  });

  tearDown(() {
    connectivityStreamController.close();
    service.dispose();
  });

  group('ConnectivityService', () {
    test('initializes as offline when no interface is available', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      await service.initialize();

      expect(service.isOnline.value, isFalse);
    });

    test('is offline when interface is available but ping fails', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(() => mockDio.head<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await service.initialize();

      expect(service.isOnline.value, isFalse);
    });

    test('is online when interface is available and ping succeeds', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(() => mockDio.head<void>(any())).thenAnswer(
        (_) async =>
            Response<void>(requestOptions: RequestOptions(), statusCode: 200),
      );

      await service.initialize();

      expect(service.isOnline.value, isTrue);
    });

    test(
      'updates status when interface changes from none to wifi with internet',
      () async {
        // Start offline
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);
        await service.initialize();
        expect(service.isOnline.value, isFalse);

        // Change to wifi with successful ping
        when(() => mockDio.head<void>(any())).thenAnswer(
          (_) async =>
              Response<void>(requestOptions: RequestOptions(), statusCode: 200),
        );

        connectivityStreamController.add([ConnectivityResult.wifi]);

        // Wait for async check to complete
        await Future<void>.delayed(Duration.zero);

        expect(service.isOnline.value, isTrue);
      },
    );

    test('emits status changes via onStatusChange stream', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      await service.initialize();

      final states = <bool>[];
      final sub = service.onStatusChange.listen(states.add);

      when(() => mockDio.head<void>(any())).thenAnswer(
        (_) async =>
            Response<void>(requestOptions: RequestOptions(), statusCode: 200),
      );

      connectivityStreamController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(true));
      await sub.cancel();
    });
  });
}
