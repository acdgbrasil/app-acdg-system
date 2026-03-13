import 'package:core/core.dart';

/// Representa um item retornado pelas tabelas de domínio (Lookup).
final class LookupItem with Equatable {
  const LookupItem({
    required this.id,
    required this.codigo,
    required this.descricao,
  });

  final String id;
  final String codigo;
  final String descricao;

  @override
  List<Object?> get props => [id, codigo, descricao];

  LookupItem copyWith({
    String? id,
    String? codigo,
    String? descricao,
  }) {
    return LookupItem(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
    );
  }
}
