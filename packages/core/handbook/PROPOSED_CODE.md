# Proposed Code — Estrutura Técnica

Este documento detalha o código planejado para a refatoração, integrando a lógica de `Equatable` customizada e as melhorias de Dart 3.

## Fase 1: Infraestrutura de Igualdade

### 1. `lib/src/utils/equatable/equatable_utils.dart`
Funções puras para comparação e hash.

```dart
import 'package:collection/collection.dart';
import 'equatable.dart';

int mapPropsToHashCode(Iterable<Object?>? props) {
  return _finish(props == null ? 0 : props.fold(0, _combine));
}

@pragma('vm:prefer-inline')
bool iterableEquals(Iterable<Object?> a, Iterable<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  final itA = a.iterator;
  final itB = b.iterator;
  while (itA.moveNext() && itB.moveNext()) {
    if (!objectsEquals(itA.current, itB.current)) return false;
  }
  return true;
}

@pragma('vm:prefer-inline')
bool objectsEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is num && b is num) return a == b;
  if (a is Equatable && b is Equatable) return a == b;
  if (a is Set && b is Set) return const SetEquality().equals(a, b);
  if (a is Map && b is Map) return const MapEquality().equals(a, b);
  if (a is Iterable && b is Iterable) return iterableEquals(a, b);
  return a == b;
}

int _combine(int hash, Object? object) {
  if (object is Map) {
    object.keys
        .sorted((a, b) => a.hashCode.compareTo(b.hashCode))
        .forEach((key) {
      hash = hash ^ _combine(hash, [key, object[key]]);
    });
    return hash;
  }
  if (object is Set) {
    object = object.sorted((a, b) => a.hashCode.compareTo(b.hashCode));
  }
  if (object is Iterable) {
    for (final value in object) {
      hash = hash ^ _combine(hash, value);
    }
    return hash ^ object.length;
  }
  hash = 0x1fffffff & (hash + object.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

String mapPropsToString(Type runtimeType, List<Object?> props) {
  return '$runtimeType(${props.join(', ')})';
}
```

### 2. `lib/src/utils/equatable/equatable.dart`
A nova base unificada.

```dart
import 'package:meta/meta.dart';
import 'equatable_config.dart';
import 'equatable_utils.dart';

@immutable
abstract mixin class Equatable {
  const Equatable();

  List<Object?> get props;
  bool? get stringify => null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Equatable &&
            runtimeType == other.runtimeType &&
            iterableEquals(props, other.props);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode(props);

  @override
  String toString() {
    if (stringify ?? EquatableConfig.stringify) {
      return mapPropsToString(runtimeType, props);
    }
    return '$runtimeType';
  }
}
```

## Fase 2: Refatoração de Base

### 1. `lib/src/base/result.dart`
Uso do novo `Equatable` para reduzir boilerplate.

```dart
import '../utils/equatable/equatable.dart';

sealed class Result<T> extends Equatable {
  const Result();

  @override
  List<Object?> get props => [];
  
  // ... (métodos isSuccess, map, etc permanecem iguais)
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, {this.stackTrace});
  final Object error;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}
```
