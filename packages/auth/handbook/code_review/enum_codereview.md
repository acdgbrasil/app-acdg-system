O seu código já está muito bom e bem estruturado! Você já está utilizando **Enhanced Enums** (Enums aprimorados), que foram introduzidos no Dart 2.17, permitindo ter propriedades (`value`), construtores e métodos diretamente dentro do enum.

No entanto, com o **Dart 3**, nós ganhamos alguns métodos utilitários em listas e iteráveis que nos permitem trocar os laços `for` imperativos por uma abordagem muito mais declarativa, limpa e concisa.

Aqui está como o seu enum fica aplicando as melhores práticas do Dart mais moderno:


## OLD VERSION
```dart
/// Roles available in the ACDG Zitadel project.
///
/// Extracted from the JWT claim `urn:zitadel:iam:org:project:roles`.
/// Each role maps to a set of permissions in the social-care API.
enum AuthRole {
  /// Full CRUD access to all social-care modules.
  socialWorker('social_worker'),

  /// Read-only access to social-care data.
  owner('owner'),

  /// Read access to social-care + admin area.
  admin('admin');

  const AuthRole(this.value);

  /// The raw string value as it appears in the JWT claim.
  final String value;

  /// Resolves an [AuthRole] from its JWT string representation.
  ///
  /// Returns `null` if the value does not match any known role.
  static AuthRole? fromString(String value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }

  /// Extracts all known roles from the raw JWT roles map.
  ///
  /// The JWT claim format is `Map<String, Map<String, String>>` where
  /// outer keys are role names. Unknown roles are silently ignored.
  static Set<AuthRole> fromJwtClaim(Map<String, dynamic>? claim) {
    if (claim == null) return {};
    final roles = <AuthRole>{};
    for (final key in claim.keys) {
      final role = fromString(key);
      if (role != null) roles.add(role);
    }
    return roles;
  }
}
```



## NEW VERSION
```dart
/// Roles available in the ACDG Zitadel project.
///
/// Extracted from the JWT claim `urn:zitadel:iam:org:project:roles`.
/// Each role maps to a set of permissions in the social-care API.
enum AuthRole {
  /// Full CRUD access to all social-care modules.
  socialWorker('social_worker'),

  /// Read-only access to social-care data.
  owner('owner'),

  /// Read access to social-care + admin area.
  admin('admin');

  const AuthRole(this.value);

  /// The raw string value as it appears in the JWT claim.
  final String value;

  /// Resolves an [AuthRole] from its JWT string representation.
  ///
  /// Returns `null` if the value does not match any known role.
  static AuthRole? fromString(String value) =>
      values.where((role) => role.value == value).firstOrNull;

  /// Extracts all known roles from the raw JWT roles map.
  ///
  /// The JWT claim format is `Map<String, Map<String, String>>` where
  /// outer keys are role names. Unknown roles are silently ignored.
  static Set<AuthRole> fromJwtClaim(Map<String, dynamic>? claim) {
    if (claim == null) return const {};
    
    return claim.keys
        .map(fromString)
        .nonNulls
        .toSet();
  }
}

```

### O que mudou e por que é melhor?

* **Uso de `.firstOrNull` (Dart 3):** No método `fromString`, em vez de iterar com um `for` manualmente e retornar `null` no final, usamos `.where(...).firstOrNull`. Isso busca o primeiro elemento que bate com a condição, ou retorna `null` caso a busca não encontre nada. O código fica resolvido em uma única linha (usando *arrow function* `=>`).
* **Uso de `.nonNulls` (Dart 3):** No método `fromJwtClaim`, em vez de criar um `Set` vazio, iterar sobre as chaves, verificar se não é nulo e adicionar ao *Set*, usamos uma cadeia funcional:
1. `.map(fromString)` converte as chaves do Map em `AuthRole?` (que pode conter nulos).
2. `.nonNulls` é uma extensão nativa e fantástica do Dart 3 que filtra automaticamente tudo que for `null` e já faz o *cast* da lista para o tipo não-nulo (de `Iterable<AuthRole?>` para `Iterable<AuthRole>`).
3. `.toSet()` converte de volta para o formato esperado.


* **Retorno `const {}`:** Quando o claim é nulo, retornar `const {}` evita alocar um novo objeto vazio na memória toda vez que a função for chamada com erro/nulo.

*(Nota: O Dart possui um método nativo `AuthRole.values.byName('admin')`, porém ele busca pelo nome exato da variável no código. Como você tem `socialWorker` mapeado para a string `social_worker`, manter o seu `fromString` customizado comparando com `role.value` é exatamente a abordagem correta a se fazer aqui).*
