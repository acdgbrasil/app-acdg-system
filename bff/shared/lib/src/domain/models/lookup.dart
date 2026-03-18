import 'package:core/core.dart';

/// Represents an item from a domain (lookup) table.
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
