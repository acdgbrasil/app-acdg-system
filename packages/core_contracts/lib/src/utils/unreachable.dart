import 'package:logging/logging.dart';

/// Exceção sinalizando que uma condição de domínio logicamente inatingível
/// foi alcançada em runtime.
///
/// Use via [unreachable]. Não instancie diretamente — isso garante que todo
/// caminho inatingível passa pelo mesmo logging.
final class DomainUnreachableException implements Exception {
  DomainUnreachableException(this.reason, {this.module, this.cause});

  final String reason;
  final String? module;
  final Object? cause;

  @override
  String toString() {
    final buf = StringBuffer('DomainUnreachableException: $reason');
    if (module != null) buf.write(' [module: $module]');
    if (cause != null) buf.write(' (cause: $cause)');
    return buf.toString();
  }
}

/// Marca um ponto do código que **nunca** deveria ser alcançado em execução
/// correta. Retorna [Never] — o compilador trata as linhas seguintes como
/// inatingíveis, habilitando **type promotion** automaticamente.
///
/// Uso canônico em switches exhaustivos onde um caso é logicamente
/// impossível:
///
/// ```dart
/// final occurredAt = switch (occurredAtResult) {
///   Success(:final value) => value,
///   Failure(:final error) => unreachable(
///     'Invalid occurredAt: $error',
///     module: 'social-care/audit-event',
///     cause: error,
///   ),
/// };
/// // ^ aqui `occurredAt` é tipado como não-nulo automaticamente.
/// ```
///
/// ### Observabilidade
/// Qualquer chamada a [unreachable] é registrada via [Logger.root] em nível
/// `severe`. Em apps Flutter que usam `AcdgLogger` + Sentry, o caso inatingível
/// vira evento correlacionável em produção (diferente de um `throw` genérico).
/// No BFF Dart puro, ainda é logado estruturadamente via `package:logging`.
///
/// ### Princípio (PATTERN_MATCHING_POLICY.md §P4)
/// Preferir [unreachable] a `throw StateError('Unreachable')` para:
/// - observabilidade centralizada
/// - mensagem estruturada com `module` e `cause`
/// - type promotion consistente em switches
///
/// ### Localização
/// Mora em `core_contracts` (Dart puro). Acessível a:
/// - Flutter apps (via `package:core/core.dart` que re-exporta)
/// - BFF Dart server (via `package:core_contracts/core_contracts.dart`)
/// - qualquer outro package sem dependência de Flutter
///
/// [reason] — mensagem humana descrevendo por que este ponto não deveria
/// ter sido alcançado.
/// [module] — identifica a camada/bounded context (ex: `social-care/audit-event`).
/// [cause] — erro ou objeto original que expôs a situação (se houver).
Never unreachable(
  String reason, {
  String? module,
  Object? cause,
}) {
  Logger.root.severe(
    'Unreachable path hit: $reason${module != null ? ' [$module]' : ''}',
    cause,
  );
  throw DomainUnreachableException(reason, module: module, cause: cause);
}
