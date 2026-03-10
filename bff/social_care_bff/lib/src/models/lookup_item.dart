/// A single item from a domain lookup table.
final class LookupItem {
  const LookupItem({
    required this.id,
    required this.codigo,
    required this.descricao,
  });

  final String id;
  final String codigo;
  final String descricao;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupItem &&
          other.id == id &&
          other.codigo == codigo &&
          other.descricao == descricao;

  @override
  int get hashCode => Object.hash(id, codigo, descricao);

  @override
  String toString() => 'LookupItem(id: $id, codigo: $codigo)';
}
