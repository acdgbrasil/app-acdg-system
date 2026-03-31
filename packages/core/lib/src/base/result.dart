import '../utils/equatable/equatable.dart';

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
sealed class Result<T> extends Equatable {
  const Result();

  @override
  List<Object?> get props => [];

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Failure(:final error, :final stackTrace) => Failure(
      error,
      stackTrace: stackTrace,
    ),
  };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success(:final value) => transform(value),
    Failure(:final error, :final stackTrace) => Failure(
      error,
      stackTrace: stackTrace,
    ),
  };

  Result<T> mapFailure(Object Function(Object error) transform) =>
      switch (this) {
        Success(:final value) => Success(value),
        Failure(:final error, :final stackTrace) => Failure(
          transform(error),
          stackTrace: stackTrace,
        ),
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
  List<Object?> get props => [value];
}

/// Represents a failed result containing an [error].
final class Failure<T> extends Result<T> {
  const Failure(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}
