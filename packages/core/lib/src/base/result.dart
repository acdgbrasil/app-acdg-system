/// A discriminated union for success/failure handling.
///
/// Use pattern matching to handle both cases:
/// ```dart
/// final result = await useCase.execute(input);
/// switch (result) {
///   case Success(:final value): // handle value
///   case Failure(:final error): // handle error
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Failure(:final error, :final stackTrace) =>
      Failure(error, stackTrace: stackTrace),
  };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success(:final value) => transform(value),
    Failure(:final error, :final stackTrace) =>
      Failure(error, stackTrace: stackTrace),
  };

  T getOrElse(T Function(Object error) fallback) => switch (this) {
    Success(:final value) => value,
    Failure(:final error) => fallback(error),
  };
}

/// Represents a successful result containing a [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result containing an [error].
final class Failure<T> extends Result<T> {
  const Failure(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
