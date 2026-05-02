import 'result.dart';

/// Combinators for parallel (independent) [Result] validations.
///
/// These extensions exist because Dart 3 lacks subtractive type promotion:
/// after `if (r case Failure(...)) return Failure(error);` the compiler
/// does NOT narrow `r` from `Result<T>` to `Success<T>`. The historical
/// workaround was a manual downcast (`(r as Success<T>).value`) which
/// bypasses sealed-class exhaustiveness and is now banned by
/// `PATTERN_MATCHING_POLICY.md §P5` and by the `acdg_lints`
/// `no_sealed_class_downcast` rule.
///
/// Use these combinators when you have **independent** [Result] producers
/// (e.g. validating two unrelated path params, or a path param plus a body
/// field). For **dependent** chains (the second producer needs the first
/// value), use [Result.flatMap] instead — that path already exists on the
/// base type.
///
/// Both combinators short-circuit on the FIRST failure encountered (left to
/// right) and preserve `error` + `stackTrace` from that failure into the
/// returned [Failure]. Subsequent failures are discarded — only the first
/// failure surfaces, mirroring early-return semantics.
///
/// Example — two independent path params (Template B):
/// ```dart
/// final p = validateUuidPathParam(rawPatientId, fieldName: 'patientId');
/// final m = validateUuidPathParam(rawMemberId, fieldName: 'memberId');
/// return (p, m).combineWith((patientId, memberId) =>
///     RemoveFamilyMemberIntent(patientId: patientId, memberId: memberId));
/// ```
///
/// Example — three independent producers:
/// ```dart
/// return (resultA, resultB, resultC).combineWith((a, b, c) =>
///     SomeAggregate(a: a, b: b, c: c));
/// ```
extension Result2Combinator<A, B> on (Result<A>, Result<B>) {
  /// Combines two independent [Result] values via [transform].
  ///
  /// - If both are [Success], invokes [transform] with the unwrapped values
  ///   and wraps the result in a new [Success].
  /// - If the first is [Failure], short-circuits to that failure
  ///   (preserving `error` + `stackTrace`).
  /// - Otherwise the second [Failure] surfaces (preserving its
  ///   `error` + `stackTrace`).
  ///
  /// [transform] is invoked **at most once** and never with partial data.
  Result<R> combineWith<R>(R Function(A a, B b) transform) {
    return switch (this) {
      (Success(value: final a), Success(value: final b)) => Success(
        transform(a, b),
      ),
      (Failure(:final error, :final stackTrace), _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, Failure(:final error, :final stackTrace)) => Failure(
        error,
        stackTrace: stackTrace,
      ),
    };
  }

  /// Combines two independent [Result] values via [transform], where
  /// [transform] itself returns a [Result] (monadic flatten).
  ///
  /// Useful when the combined transformation can also fail — e.g. a path
  /// param plus a body field that only become an Intent after a third
  /// structural check.
  Result<R> flatCombineWith<R>(Result<R> Function(A a, B b) transform) {
    return switch (this) {
      (Success(value: final a), Success(value: final b)) => transform(a, b),
      (Failure(:final error, :final stackTrace), _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, Failure(:final error, :final stackTrace)) => Failure(
        error,
        stackTrace: stackTrace,
      ),
    };
  }
}

/// 3-ary variant of [Result2Combinator]. See that extension for semantics.
///
/// Short-circuits on the first failure (left to right) and preserves its
/// `error` + `stackTrace`.
extension Result3Combinator<A, B, C> on (Result<A>, Result<B>, Result<C>) {
  /// Combines three independent [Result] values via [transform].
  Result<R> combineWith<R>(R Function(A a, B b, C c) transform) {
    return switch (this) {
      (
        Success(value: final a),
        Success(value: final b),
        Success(value: final c),
      ) =>
        Success(transform(a, b, c)),
      (Failure(:final error, :final stackTrace), _, _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, Failure(:final error, :final stackTrace), _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, _, Failure(:final error, :final stackTrace)) => Failure(
        error,
        stackTrace: stackTrace,
      ),
    };
  }

  /// Monadic 3-ary flatten — see [Result2Combinator.flatCombineWith].
  Result<R> flatCombineWith<R>(Result<R> Function(A a, B b, C c) transform) {
    return switch (this) {
      (
        Success(value: final a),
        Success(value: final b),
        Success(value: final c),
      ) =>
        transform(a, b, c),
      (Failure(:final error, :final stackTrace), _, _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, Failure(:final error, :final stackTrace), _) => Failure(
        error,
        stackTrace: stackTrace,
      ),
      (_, _, Failure(:final error, :final stackTrace)) => Failure(
        error,
        stackTrace: stackTrace,
      ),
    };
  }
}
