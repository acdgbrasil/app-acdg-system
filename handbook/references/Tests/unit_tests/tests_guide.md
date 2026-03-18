# Guia Completo: Testes Unitários em Dart/Flutter

> **Propósito:** Este documento é um guia de referência para IAs e desenvolvedores sobre como escrever testes unitários de alta qualidade em Dart e Flutter, cobrindo desde o básico até mocking avançado com Mockito.

---

## 1. Conceitos Fundamentais

Testes unitários verificam o comportamento de uma **única unidade** de código — uma função, método ou classe — de forma isolada. Eles garantem que o código continua funcionando corretamente à medida que novas funcionalidades são adicionadas ou funcionalidades existentes são alteradas.

### Por que testar?

- **Confiança em refatorações:** altere código sem medo de quebrar comportamentos existentes.
- **Documentação viva:** testes descrevem o comportamento esperado do sistema.
- **Feedback rápido:** erros são detectados antes de chegarem à produção.
- **Design melhor:** código testável tende a ser mais modular e desacoplado.

---

## 2. Configuração do Projeto

### 2.1 Dependências

Adicione o pacote `test` (para Dart puro) ou `flutter_test` (para projetos Flutter) como dependência de desenvolvimento:

```bash
# Para projetos Flutter
flutter pub add dev:test

# Para mocking com Mockito (quando necessário)
flutter pub add http dev:mockito dev:build_runner
```

### 2.2 Estrutura de Diretórios

Mantenha sempre esta convenção de pastas:

```
meu_projeto/
├── lib/
│   ├── models/
│   │   └── counter.dart
│   └── services/
│       └── album_service.dart
└── test/
    ├── models/
    │   └── counter_test.dart
    └── services/
        └── album_service_test.dart
```

**Regras obrigatórias:**

- Os arquivos de teste ficam na pasta `test/` na raiz do projeto.
- Todo arquivo de teste **deve** terminar com `_test.dart`.
- A estrutura de pastas dentro de `test/` deve espelhar a estrutura de `lib/`.

---

## 3. Escrevendo o Primeiro Teste

### 3.1 Classe a ser testada

```dart
// lib/models/counter.dart
class Counter {
  int value = 0;

  void increment() => value++;
  void decrement() => value--;
}
```

### 3.2 Arquivo de teste

```dart
// test/models/counter_test.dart
import 'package:counter_app/models/counter.dart';
import 'package:test/test.dart';

void main() {
  test('Counter value should be incremented', () {
    final counter = Counter();

    counter.increment();

    expect(counter.value, 1);
  });
}
```

### 3.3 Anatomia de um teste

| Elemento | Descrição |
|---|---|
| `test()` | Define um caso de teste individual com uma descrição e um corpo. |
| `expect()` | Afirma que um valor real corresponde ao valor esperado. |
| `group()` | Agrupa testes relacionados sob um mesmo rótulo. |
| `setUp()` | Executa código **antes de cada** teste do grupo. |
| `tearDown()` | Executa código **depois de cada** teste do grupo. |
| `setUpAll()` | Executa código **uma vez** antes de todos os testes do grupo. |
| `tearDownAll()` | Executa código **uma vez** depois de todos os testes do grupo. |

---

## 4. Agrupando Testes com `group`

Use `group` para organizar testes relacionados. Isso melhora a legibilidade e permite executar subconjuntos de testes.

```dart
import 'package:counter_app/models/counter.dart';
import 'package:test/test.dart';

void main() {
  group('Counter', () {
    late Counter counter;

    setUp(() {
      counter = Counter();
    });

    test('valor inicial deve ser 0', () {
      expect(counter.value, 0);
    });

    test('valor deve ser incrementado', () {
      counter.increment();
      expect(counter.value, 1);
    });

    test('valor deve ser decrementado', () {
      counter.decrement();
      expect(counter.value, -1);
    });

    test('múltiplos incrementos', () {
      counter.increment();
      counter.increment();
      counter.increment();
      expect(counter.value, 3);
    });
  });
}
```

---

## 5. Matchers — Asserções Poderosas

O pacote `test` fornece diversos matchers além da igualdade simples:

### 5.1 Matchers de igualdade e comparação

```dart
expect(valor, equals(42));           // igualdade
expect(valor, isNot(equals(0)));     // negação
expect(valor, greaterThan(10));      // maior que
expect(valor, lessThanOrEqualTo(5)); // menor ou igual
expect(valor, inInclusiveRange(1, 10)); // dentro de um intervalo
```

### 5.2 Matchers de tipo

```dart
expect(objeto, isA<String>());       // verifica tipo
expect(valor, isNull);               // é nulo
expect(valor, isNotNull);            // não é nulo
expect(valor, isTrue);               // é verdadeiro
expect(valor, isFalse);              // é falso
```

### 5.3 Matchers de coleções

```dart
expect(lista, isEmpty);              // lista vazia
expect(lista, isNotEmpty);           // lista não vazia
expect(lista, contains('item'));     // contém item
expect(lista, hasLength(3));         // tamanho específico
expect(lista, containsAll([1, 2])); // contém todos
expect(lista, everyElement(greaterThan(0))); // todo elemento satisfaz
```

### 5.4 Matchers de String

```dart
expect(texto, startsWith('Hello'));
expect(texto, endsWith('world'));
expect(texto, contains('middle'));
expect(texto, matches(RegExp(r'\d+')));
```

### 5.5 Matchers de exceção

```dart
expect(() => funcaoQueFalha(), throwsException);
expect(() => funcaoQueFalha(), throwsA(isA<ArgumentError>()));
expect(
  () => funcaoQueFalha(),
  throwsA(predicate((e) => e.toString().contains('mensagem'))),
);
```

### 5.6 Matchers assíncronos

```dart
expect(futureQueCompleta, completes);
expect(futureQueCompleta, completion(equals(42)));
expect(futureQueFalha, throwsA(isA<Exception>()));
```

---

## 6. Testes Assíncronos

Para testar código assíncrono, marque o corpo do teste como `async`:

```dart
test('busca dados com sucesso', () async {
  final resultado = await servico.buscarDados();

  expect(resultado, isNotNull);
  expect(resultado.nome, equals('Teste'));
});
```

Para testar Streams:

```dart
test('emite valores corretos', () {
  final stream = meuController.stream;

  expect(stream, emitsInOrder([1, 2, 3]));
});

test('emite erro e fecha', () {
  expect(
    stream,
    emitsInOrder([
      emits(1),
      emitsError(isA<Exception>()),
      emitsDone,
    ]),
  );
});
```

---

## 7. Mocking com Mockito

### 7.1 Quando usar mocks

Use mocks quando a unidade sob teste depende de:

- **Serviços web / APIs HTTP:** chamadas de rede são lentas e instáveis.
- **Bancos de dados:** resultados podem variar e tornar testes flaky.
- **Serviços externos:** qualquer dependência fora do seu controle.
- **Classes complexas:** que possuem efeitos colaterais ou estados difíceis de reproduzir.

### 7.2 Configuração do Mockito

O Mockito em Dart usa geração de código. Adicione as dependências:

```bash
flutter pub add http dev:mockito dev:build_runner
```

### 7.3 Padrão de Injeção de Dependência

**Antes (difícil de testar):**

```dart
// ❌ Dependência estática — impossível de mockar
Future<Album> fetchAlbum() async {
  final response = await http.get(Uri.parse('https://api.example.com/albums/1'));
  // ...
}
```

**Depois (testável):**

```dart
// ✅ Dependência injetada — fácil de mockar
Future<Album> fetchAlbum(http.Client client) async {
  final response = await client.get(
    Uri.parse('https://api.example.com/albums/1'),
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Falha ao carregar álbum');
  }
}
```

### 7.4 Criando o Mock

```dart
// test/fetch_album_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocking/main.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'fetch_album_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<http.Client>(as: #MockHttpClient),
])
void main() {
  // testes aqui
}
```

Gere os mocks com:

```bash
dart run build_runner build
```

### 7.5 Escrevendo testes com mocks

```dart
void main() {
  group('fetchAlbum', () {
    late MockHttpClient client;

    setUp(() {
      client = MockHttpClient();
    });

    test('retorna Album quando a chamada HTTP é bem-sucedida', () async {
      // Arrange — configurar o comportamento do mock
      when(
        client.get(Uri.parse('https://api.example.com/albums/1')),
      ).thenAnswer(
        (_) async => http.Response(
          '{"userId": 1, "id": 2, "title": "mock"}',
          200,
        ),
      );

      // Act — executar a função
      final album = await fetchAlbum(client);

      // Assert — verificar o resultado
      expect(album, isA<Album>());
      expect(album.title, equals('mock'));
    });

    test('lança exceção quando a chamada HTTP falha', () {
      // Arrange
      when(
        client.get(Uri.parse('https://api.example.com/albums/1')),
      ).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      // Act & Assert
      expect(fetchAlbum(client), throwsException);
    });
  });
}
```

### 7.6 Principais funções do Mockito

| Função | Descrição |
|---|---|
| `when(mock.metodo()).thenReturn(valor)` | Retorna um valor síncrono. |
| `when(mock.metodo()).thenAnswer((_) async => valor)` | Retorna um valor assíncrono (Future). |
| `when(mock.metodo()).thenThrow(excecao)` | Lança uma exceção. |
| `verify(mock.metodo())` | Verifica que o método foi chamado. |
| `verify(mock.metodo()).called(n)` | Verifica que foi chamado `n` vezes. |
| `verifyNever(mock.metodo())` | Verifica que **nunca** foi chamado. |
| `verifyNoMoreInteractions(mock)` | Verifica que não houve mais interações. |
| `reset(mock)` | Reseta o estado do mock. |

---

## 8. Padrão AAA (Arrange, Act, Assert)

Sempre estruture testes seguindo o padrão AAA:

```dart
test('descrição clara do comportamento esperado', () {
  // Arrange — preparar dados e dependências
  final calculadora = Calculadora();
  const a = 10;
  const b = 5;

  // Act — executar a ação sendo testada
  final resultado = calculadora.somar(a, b);

  // Assert — verificar o resultado
  expect(resultado, equals(15));
});
```

---

## 9. Boas Práticas

### 9.1 Nomenclatura de testes

Descreva **o que** está sendo testado e **qual** o resultado esperado:

```dart
// ✅ Bom — claro e descritivo
test('somar dois números positivos retorna a soma correta', () { ... });
test('buscarUsuario lança exceção quando o ID é inválido', () { ... });
test('carrinho vazio retorna total zero', () { ... });

// ❌ Ruim — vago e genérico
test('teste 1', () { ... });
test('funciona', () { ... });
test('somar', () { ... });
```

### 9.2 Um assert por conceito

Cada teste deve verificar **um único comportamento**. Múltiplos expects são aceitáveis apenas quando verificam facetas do **mesmo** resultado:

```dart
// ✅ OK — verificando propriedades do mesmo objeto retornado
test('parseia JSON do álbum corretamente', () {
  final album = Album.fromJson({'userId': 1, 'id': 2, 'title': 'Teste'});

  expect(album.userId, 1);
  expect(album.id, 2);
  expect(album.title, 'Teste');
});

// ❌ Ruim — testando comportamentos diferentes no mesmo teste
test('testa tudo do counter', () {
  final c = Counter();
  expect(c.value, 0);
  c.increment();
  expect(c.value, 1);
  c.decrement();
  expect(c.value, 0);  // Isso deveria ser um teste separado
});
```

### 9.3 Testes independentes

Cada teste deve ser **independente** e **não depender** da ordem de execução ou do estado de outros testes. Use `setUp()` para inicializar estado limpo.

### 9.4 Não teste implementação, teste comportamento

```dart
// ✅ Bom — testa o comportamento (o que a função faz)
test('depositar aumenta o saldo', () {
  conta.depositar(100);
  expect(conta.saldo, equals(100));
});

// ❌ Ruim — testa detalhes de implementação (como a função faz)
test('depositar chama o método interno _atualizarRegistro', () {
  // Isso cria acoplamento com a implementação
});
```

### 9.5 Mantenha testes rápidos

Testes unitários devem executar em milissegundos. Se um teste é lento, provavelmente ele depende de I/O e deveria usar mocks.

### 9.6 Cubra edge cases

Sempre teste:

- Valores nulos ou vazios.
- Limites numéricos (zero, negativos, overflow).
- Listas vazias e com um único elemento.
- Strings vazias.
- Condições de erro e exceções.

---

## 10. Executando Testes

### Via terminal

```bash
# Rodar todos os testes
flutter test

# Rodar um arquivo específico
flutter test test/models/counter_test.dart

# Rodar um grupo específico por nome
flutter test --plain-name "Counter"

# Com output detalhado
flutter test --reporter expanded

# Ver opções de ajuda
flutter test --help
```

### Via IDE

- **IntelliJ/Android Studio:** abra o arquivo de teste e vá em `Run > Run 'tests in ...'`.
- **VS Code:** abra o arquivo de teste e vá em `Run > Start Debugging`.

---

## 11. Checklist Rápido

Antes de considerar seus testes prontos, verifique:

- [ ] Cada teste tem uma descrição clara do comportamento esperado.
- [ ] Testes seguem o padrão AAA (Arrange, Act, Assert).
- [ ] Cada teste é independente e pode rodar em qualquer ordem.
- [ ] Dependências externas (HTTP, DB) estão mockadas.
- [ ] Edge cases e cenários de erro estão cobertos.
- [ ] Arquivos de teste terminam com `_test.dart`.
- [ ] Testes estão organizados em `group()` por funcionalidade.
- [ ] `setUp()` é usado para evitar duplicação de inicialização.
- [ ] Nenhum teste depende de serviços externos reais.
- [ ] Todos os testes passam com `flutter test`.

---

## 12. Referência Rápida de Imports

```dart
// Testes básicos em Dart
import 'package:test/test.dart';

// Testes em Flutter (inclui tudo do test + utilidades para widgets)
import 'package:flutter_test/flutter_test.dart';

// Mockito — anotações para geração de código
import 'package:mockito/annotations.dart';

// Mockito — funções when(), verify(), etc.
import 'package:mockito/mockito.dart';

// HTTP client para mocking
import 'package:http/http.dart' as http;

// Mocks gerados (ajustar o caminho conforme seu projeto)
import 'nome_do_arquivo_test.mocks.dart';
```

---

*Guia baseado na documentação oficial do Flutter sobre testes unitários e mocking com Mockito.*
