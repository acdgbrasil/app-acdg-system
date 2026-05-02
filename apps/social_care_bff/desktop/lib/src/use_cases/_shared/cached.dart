/// Re-export of the cache-layer `Cached<T>` envelope so use cases can
/// reference it through the same path the W0 tests use.
///
/// The canonical type lives in `lib/src/cache/_shared/cached.dart` to
/// keep cache contracts free of use-case-layer imports.
library;

export '../../cache/_shared/cached.dart';
