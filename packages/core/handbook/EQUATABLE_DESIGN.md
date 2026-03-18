# Equatable Design — Custom Equality Engine

Implementação interna de comparação por valor para evitar dependência do package `equatable` externo.

## Mudanças Dart 3.0.0+
-   **Abstract Mixin Class:** A classe `Equatable` será definida como `abstract mixin class`.
    -   *Motivo:* Permite que classes de domínio herdem dela (`extends`) para uma estrutura mais limpa ou a utilizem como mixin (`with`) se já possuírem outra classe pai.
-   **Depreciação de `EquatableMixin`:** Com a introdução de `mixin class`, o `EquatableMixin` separado torna-se redundante. Ele será mantido como `@deprecated` apontando para a nova classe base.

## Algoritmo de Hash (Jenkins)
Utilizamos o *Jenkins Hash Function* para garantir baixa colisão em coleções complexas.
-   Mapeamento recursivo de `props`.
-   Suporte nativo para `Map`, `Set` e `Iterable`.
-   Ordenação automática de chaves em `Map` e `Set` para garantir que a ordem de inserção não afete a igualdade.

## Implementação Proposta (Snippets)

### Equatable (Base)
```dart
@immutable
abstract mixin class Equatable {
  const Equatable();
  List<Object?> get props;
  bool? get stringify => null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Equatable &&
            runtimeType == other.runtimeType &&
            iterableEquals(props, other.props);
  }
  // ... (hashCode e toString)
}
```
