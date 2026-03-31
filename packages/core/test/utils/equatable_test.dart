import 'package:core/src/utils/equatable/equatable.dart';
import 'package:core/src/utils/equatable/equatable_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class _SimpleEquatable extends Equatable {
  const _SimpleEquatable(this.id, {this.name});
  final int id;
  final String? name;

  @override
  List<Object?> get props => [id, name];
}

class _MixinEquatable with Equatable {
  const _MixinEquatable(this.data);
  final List<int> data;

  @override
  List<Object?> get props => [data];
}

void main() {
  group('Equatable Utils', () {
    group('objectsEquals', () {
      test('should return true for identical objects', () {
        final list = [1, 2];
        expect(objectsEquals(list, list), isTrue);
      });

      test('should return true for equal primitives', () {
        expect(objectsEquals(1, 1), isTrue);
        expect(objectsEquals('a', 'a'), isTrue);
        expect(objectsEquals(true, true), isTrue);
      });

      test('should return true for equal Lists (deep)', () {
        expect(objectsEquals([1, 2], [1, 2]), isTrue);
        expect(
          objectsEquals(
            [
              1,
              [2],
            ],
            [
              1,
              [2],
            ],
          ),
          isTrue,
        );
      });

      test('should return true for equal Sets (unordered)', () {
        expect(objectsEquals({1, 2}, {2, 1}), isTrue);
      });

      test('should return true for equal Maps (unordered keys)', () {
        expect(objectsEquals({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
      });

      test('should return false for different types', () {
        expect(objectsEquals(1, '1'), isFalse);
      });
    });

    group('mapPropsToHashCode', () {
      test('should be consistent for identical props', () {
        final props = [
          1,
          'a',
          [2],
        ];
        expect(mapPropsToHashCode(props), equals(mapPropsToHashCode(props)));
      });

      test('should be order-independent for Maps and Sets in props', () {
        final h1 = mapPropsToHashCode([
          {'a': 1, 'b': 2},
          {1, 2},
        ]);
        final h2 = mapPropsToHashCode([
          {'b': 2, 'a': 1},
          {2, 1},
        ]);
        expect(h1, equals(h2));
      });
    });
  });

  group('Equatable Class', () {
    test('supports extends', () {
      expect(
        const _SimpleEquatable(1, name: 'Test'),
        const _SimpleEquatable(1, name: 'Test'),
      );
    });

    test('supports mixin', () {
      expect(const _MixinEquatable([1, 2]), const _MixinEquatable([1, 2]));
    });

    test('different values are not equal', () {
      expect(const _SimpleEquatable(1), isNot(const _SimpleEquatable(2)));
    });

    test('toString output follows props', () {
      const obj = _SimpleEquatable(1, name: 'ACDG');
      // Assumindo que EquatableConfig.stringify seja true por padrão em testes
      expect(obj.toString(), contains('_SimpleEquatable(1, ACDG)'));
    });
  });
}
