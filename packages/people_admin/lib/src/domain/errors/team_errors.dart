import 'package:equatable/equatable.dart';

sealed class TeamError extends Equatable implements Exception {
  const TeamError();

  @override
  List<Object?> get props => [];
}

final class TeamNetworkError extends TeamError {
  const TeamNetworkError(this.technicalDetail);
  final String technicalDetail;

  @override
  List<Object?> get props => [technicalDetail];

  @override
  String toString() => 'Sem conexao com o servidor. Verifique sua internet.';
}

final class TeamServerError extends TeamError {
  const TeamServerError({
    required this.httpStatus,
    required this.backendCode,
    required this.backendMessage,
  });

  final int httpStatus;
  final String backendCode;
  final String backendMessage;

  @override
  List<Object?> get props => [httpStatus, backendCode, backendMessage];

  @override
  String toString() =>
      backendMessage.isNotEmpty
          ? backendMessage
          : 'Erro no servidor (codigo $backendCode). Tente novamente.';
}

final class TeamNotFoundError extends TeamError {
  const TeamNotFoundError(this.id);
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'Membro da equipe nao encontrado: $id';
}

final class TeamConflictError extends TeamError {
  const TeamConflictError();

  @override
  String toString() =>
      'Este profissional ja se encontra registrado no sistema.';
}

final class UnexpectedTeamError extends TeamError {
  const UnexpectedTeamError(this.error);
  final Object error;

  @override
  List<Object?> get props => [error];

  @override
  String toString() =>
      'Ocorreu um erro inesperado. Tente novamente mais tarde.';
}
