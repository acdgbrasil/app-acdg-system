import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAnalyticsBff', () {
    test('implements AnalyticsContract', () {
      final AnalyticsContract fake = FakeAnalyticsBff();
      expect(fake, isA<AnalyticsContract>());
    });

    test('getIndicators: returns Success with IndicatorResponse payload',
        () async {
      final fake = FakeAnalyticsBff();

      final result = await fake.getIndicators('demographics');

      expect(result, isA<Success<StandardResponse<IndicatorResponse>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.axis, equals('demographics'));
          expect(value.data.rows, isEmpty);
        case Failure():
          fail('getIndicators should succeed for a fake');
      }
    });

    test('getAxesMetadata: returns Success with an (empty) list', () async {
      final fake = FakeAnalyticsBff();

      final result = await fake.getAxesMetadata();

      expect(result,
          isA<Success<StandardResponse<List<AxisMetadataResponse>>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data, isA<List<AxisMetadataResponse>>());
        case Failure():
          fail('getAxesMetadata should succeed for a fake');
      }
    });
  });
}
