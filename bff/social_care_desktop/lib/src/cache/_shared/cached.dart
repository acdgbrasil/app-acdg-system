/// Generic envelope wrapping a cached DTO with the row metadata
/// (`cachedAt`, `version`) needed by orchestrating use cases.
///
/// A18b-v2 use cases need:
///   * `cachedAt` — to compute staleness against the configurable
///     `staleAfter` window.
///   * `version`  — to populate `expectedVersion` on optimistic-locking
///     mutations.
///
/// Lives in the cache layer (`lib/src/cache/_shared/`) so cache
/// contracts can import it without depending on the use case layer.
/// Use cases re-export it through `_shared/cached.dart`.
library;

class Cached<T> {
  const Cached({
    required this.dto,
    required this.cachedAt,
    required this.version,
  });

  /// The cached DTO. The cache contract preserves whatever the caller
  /// upserted; no auto-increment.
  final T dto;

  /// Wall-clock at which the row was upserted. Used by read use cases
  /// to compute `now - cachedAt > staleAfter`.
  final DateTime cachedAt;

  /// Optimistic-locking version. Bumped by the engine after backend
  /// confirms; A18b write use cases read it for `expectedVersion`.
  final int version;
}
