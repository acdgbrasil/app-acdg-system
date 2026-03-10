import 'package:core/src/base/result.dart';

/// Base contract for all use cases.
///
/// Each use case represents a single application action.
/// [Input] is the command/query parameter type.
/// [Output] is the expected result type.
///
/// Always returns a [Result] to enforce explicit error handling.
abstract class BaseUseCase<Input, Output> {
  const BaseUseCase();

  Future<Result<Output>> execute(Input input);
}

/// Use case that takes no input parameters.
abstract class NoInputUseCase<Output> {
  const NoInputUseCase();

  Future<Result<Output>> execute();
}
