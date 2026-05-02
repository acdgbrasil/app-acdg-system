import 'equatable.dart';

/// Returns a `hashCode` for [props] using Jenkins Hash.
int mapPropsToHashCode(Iterable<Object?>? props) {
  return _finish(props == null ? 0 : props.fold(0, _combine));
}

/// Determines whether two objects are equal by value or identity.
@pragma('vm:prefer-inline')
bool objectsEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is num && b is num) return a == b;
  if (a is Equatable && b is Equatable) return a == b;
  if (a is Set && b is Set) return setEquals(a, b);
  if (a is Map && b is Map) return mapEquals(a, b);
  if (a is Iterable && b is Iterable) return iterableEquals(a, b);
  if (a?.runtimeType != b?.runtimeType) return false;
  return a == b;
}

/// Deeply compares two iterables.
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

/// Deeply compares two sets.
bool setEquals(Set<Object?> a, Set<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final element in a) {
    if (!b.any((e) => objectsEquals(element, e))) return false;
  }
  return true;
}

/// Deeply compares two maps.
bool mapEquals(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || !objectsEquals(a[key], b[key])) return false;
  }
  return true;
}

/// Jenkins Hash Functions
int _combine(int hash, Object? object) {
  if (object is Map) {
    final keys = object.keys.toList()
      ..sort((a, b) => a.hashCode.compareTo(b.hashCode));
    for (final key in keys) {
      hash = hash ^ _combine(hash, [key, object[key]]);
    }
    return hash;
  }
  if (object is Set) {
    final list = object.toList()
      ..sort((a, b) => a.hashCode.compareTo(b.hashCode));
    object = list;
  }
  if (object is Iterable) {
    for (final value in object) {
      hash = hash ^ _combine(hash, value);
    }
    return hash ^ object.length;
  }

  hash = 0x1fffffff & (hash + (object?.hashCode ?? 0));
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Formats the props list into a readable string.
String mapPropsToString(Type runtimeType, List<Object?> props) {
  return '$runtimeType(${props.join(', ')})';
}
