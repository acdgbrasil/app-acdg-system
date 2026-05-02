import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeLookupBff', () {
    test('implements LookupContract', () {
      final LookupContract fake = FakeLookupBff();
      expect(fake, isA<LookupContract>());
    });

    test(
        'createLookupItem + getLookupTable: created item is returned by table '
        'query (state preserved)', () async {
      final fake = FakeLookupBff();
      const tableName = 'dominio_parentesco';
      const request = CreateLookupItemRequest(
        codigo: 'pai',
        descricao: 'Pai',
      );

      final createResult = await fake.createLookupItem(tableName, request);
      expect(createResult, isA<Success<StandardIdResponse>>());

      final listResult = await fake.getLookupTable(tableName);
      expect(
        listResult,
        isA<Success<StandardResponse<List<LookupItemResponse>>>>(),
      );
      switch (listResult) {
        case Success(:final value):
          expect(value.data, hasLength(1));
          expect(value.data.first.codigo, equals('pai'));
          expect(value.data.first.descricao, equals('Pai'));
        case Failure():
          fail('getLookupTable should return the created item');
      }
    });
  });
}
