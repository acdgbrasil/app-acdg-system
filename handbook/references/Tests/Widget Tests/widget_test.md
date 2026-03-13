# Guia Completo: Testes de Widget em Flutter

> **Propósito:** Este documento é um guia de referência para IAs e desenvolvedores sobre como escrever testes de widget de alta qualidade em Flutter, cobrindo finders, interações (tap, drag, texto), scroll em listas e matchers específicos de widget.

---

## 1. Conceitos Fundamentais

Testes de widget ficam entre os testes unitários e os testes de integração na pirâmide de testes. Eles verificam o comportamento de **widgets individuais ou composições de widgets** em um ambiente de teste controlado, sem precisar de um dispositivo real ou emulador.

### O que o `flutter_test` oferece?

| Ferramenta | Descrição |
|---|---|
| `WidgetTester` | Permite construir e interagir com widgets no ambiente de teste. |
| `testWidgets()` | Substitui `test()` para testes de widget. Cria automaticamente um `WidgetTester`. |
| **Finders** (`find.*`) | Classes para localizar widgets na árvore de widgets. |
| **Matchers** | Constantes como `findsOneWidget` para verificar se widgets existem na tela. |

### Por que testes de widget?

- **Mais rápidos que testes de integração:** não precisam de dispositivo real.
- **Mais realistas que testes unitários:** verificam renderização e interação de UI.
- **Testam composição:** validam como widgets pai e filho interagem.
- **Feedback visual:** verificam se textos, ícones e layouts aparecem corretamente.

---

## 2. Configuração

### 2.1 Dependência

O `flutter_test` já vem incluído em projetos Flutter. Verifique que está no `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 2.2 Estrutura de Diretórios

Testes de widget ficam na pasta `test/`, assim como os testes unitários:

```
meu_projeto/
├── lib/
│   ├── widgets/
│   │   └── my_widget.dart
│   └── main.dart
└── test/
    ├── widgets/
    │   └── my_widget_test.dart
    └── widget_test.dart
```

**Regras:**

- Arquivos de teste terminam com `_test.dart`.
- A estrutura de `test/` espelha a de `lib/`.
- Testes de widget e unitários convivem na mesma pasta `test/`.

---

## 3. Escrevendo o Primeiro Teste de Widget

### 3.1 Widget a ser testado

```dart
// lib/widgets/my_widget.dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(message)),
      ),
    );
  }
}
```

### 3.2 Teste completo

```dart
// test/widgets/my_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importe o widget (ajuste o caminho conforme seu projeto)
import 'package:meu_app/widgets/my_widget.dart';

void main() {
  testWidgets('MyWidget exibe título e mensagem', (tester) async {
    // 1. Constrói o widget no ambiente de teste
    await tester.pumpWidget(const MyWidget(title: 'T', message: 'M'));

    // 2. Cria finders para localizar os textos
    final titleFinder = find.text('T');
    final messageFinder = find.text('M');

    // 3. Verifica que aparecem exatamente uma vez
    expect(titleFinder, findsOneWidget);
    expect(messageFinder, findsOneWidget);
  });
}
```

### 3.3 Anatomia de um teste de widget

| Passo | O que faz |
|---|---|
| `testWidgets('descrição', (tester) async { })` | Define o teste e fornece um `WidgetTester`. |
| `tester.pumpWidget(widget)` | Constrói e renderiza o widget no ambiente de teste. |
| `find.*()` | Localiza widgets na árvore. |
| `expect(finder, matcher)` | Verifica se o widget encontrado atende à expectativa. |

---

## 4. Métodos de Pump — Controlando o Ciclo de Build

Após a chamada inicial de `pumpWidget()`, o Flutter **não reconstrói automaticamente** widgets quando o estado muda no ambiente de teste. É necessário solicitar reconstruções manualmente.

### 4.1 `pump()`

Agenda um frame e dispara um rebuild. Aceita uma `Duration` opcional para avançar o relógio:

```dart
// Rebuild simples (1 frame)
await tester.pump();

// Avança 1 segundo e faz rebuild (1 frame apenas, mesmo com duração longa)
await tester.pump(const Duration(seconds: 1));
```

> **Nota:** Para iniciar uma animação, é necessário chamar `pump()` uma vez sem duração para ativar o ticker. Sem isso, a animação não começa.

### 4.2 `pumpAndSettle()`

Chama `pump()` repetidamente até que não haja mais frames agendados. Essencialmente, **espera todas as animações terminarem**:

```dart
// Aguarda todas as animações e transições completarem
await tester.pumpAndSettle();
```

### 4.3 Quando usar cada um?

| Método | Quando usar |
|---|---|
| `pump()` | Após `tap()`, `enterText()` ou qualquer mudança de estado simples. |
| `pump(duration)` | Quando precisa avançar o tempo (ex: debounce, timers). |
| `pumpAndSettle()` | Quando há animações (navegação, dismiss, transições) que precisam completar. |

> **Cuidado:** `pumpAndSettle()` dá timeout se houver animações infinitas (ex: `CircularProgressIndicator`). Nesses casos, use `pump(duration)`.

---

## 5. Finders — Localizando Widgets

O objeto `find` fornecido pelo `flutter_test` oferece diversas formas de localizar widgets.

### 5.1 Por texto

```dart
// Texto exato
find.text('Hello World');

// Widget que contém o texto (busca parcial)
find.textContaining('Hello');
```

**Quando usar:** quando o texto exibido é único e estável (não sujeito a i18n).

### 5.2 Por Key

```dart
find.byKey(const Key('meu_botao'));
find.byKey(const ValueKey('item_42'));
```

**Quando usar:** quando há múltiplos widgets do mesmo tipo, ou quando o texto pode mudar (internacionalização). É a forma **mais robusta** de encontrar widgets.

### 5.3 Por tipo

```dart
find.byType(FloatingActionButton);
find.byType(TextField);
find.byType(ListView);
```

**Quando usar:** quando existe apenas um widget daquele tipo na tela, ou quando o tipo é suficiente para identificar o widget.

### 5.4 Por instância específica

```dart
const childWidget = Padding(padding: EdgeInsets.zero);
await tester.pumpWidget(Container(child: childWidget));

expect(find.byWidget(childWidget), findsOneWidget);
```

**Quando usar:** quando você tem uma referência direta ao widget (útil para testar se um widget-filho está sendo renderizado corretamente).

### 5.5 Por ícone

```dart
find.byIcon(Icons.add);
find.byIcon(Icons.delete);
```

### 5.6 Combinando com tipo e texto

```dart
// Botão que contém texto específico
find.widgetWithText(ElevatedButton, 'Salvar');

// Botão que contém ícone específico
find.widgetWithIcon(IconButton, Icons.search);
```

### 5.7 Descendentes e ancestrais

```dart
// Encontra um Text dentro do AppBar
find.descendant(
  of: find.byType(AppBar),
  matching: find.text('Título'),
);

// Encontra o ListTile que contém 'Item 1'
find.ancestor(
  of: find.text('Item 1'),
  matching: find.byType(ListTile),
);
```

### 5.8 Dica interativa

Durante uma sessão de `flutter run` em um teste de widget, é possível tocar interativamente em partes da tela e o Flutter imprime o `Finder` sugerido para aquele widget.

---

## 6. Matchers — Verificando Widgets

### 6.1 Matchers de presença

```dart
expect(find.text('Hello'), findsOneWidget);          // exatamente 1
expect(find.text('Inexistente'), findsNothing);       // nenhum
expect(find.byType(ListTile), findsNWidgets(5));      // exatamente N
expect(find.byType(Card), findsAtLeastNWidgets(3));   // pelo menos N
expect(find.byType(Text), findsWidgets);              // 1 ou mais
```

### 6.2 Golden file testing

Verifica se a renderização de um widget corresponde a uma imagem bitmap de referência:

```dart
expect(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget.png'));
```

> **Nota:** Na primeira execução, o golden file é gerado. Nas execuções seguintes, o teste compara a renderização atual com o arquivo salvo. Execute `flutter test --update-goldens` para atualizar as imagens de referência.

### 6.3 Verificando propriedades de widgets

```dart
// Extrair o widget e verificar propriedades
final text = tester.widget<Text>(find.text('Título'));
expect(text.style?.fontSize, equals(24.0));
expect(text.style?.fontWeight, equals(FontWeight.bold));

// Verificar se botão está habilitado
final button = tester.widget<ElevatedButton>(find.byKey(const Key('submit')));
expect(button.onPressed, isNotNull);  // habilitado
expect(button.onPressed, isNull);     // desabilitado
```

---

## 7. Interações — Tap, Drag e Texto

### 7.1 Entrada de texto

Use `enterText()` para digitar em um `TextField`:

```dart
testWidgets('digita texto no campo', (tester) async {
  await tester.pumpWidget(const TodoList());

  // Digita 'hi' no TextField
  await tester.enterText(find.byType(TextField), 'hi');

  // Verifica que o texto aparece
  expect(find.text('hi'), findsOneWidget);
});
```

Para múltiplos campos, use Keys para distingui-los:

```dart
await tester.enterText(find.byKey(const Key('campo_email')), 'user@test.com');
await tester.enterText(find.byKey(const Key('campo_senha')), '123456');
```

### 7.2 Tap (toque)

Use `tap()` para simular toques em botões e outros widgets:

```dart
testWidgets('adicionar item ao tocar no botão', (tester) async {
  await tester.pumpWidget(const TodoList());

  // Digita o texto
  await tester.enterText(find.byType(TextField), 'hi');

  // Toca no FloatingActionButton
  await tester.tap(find.byType(FloatingActionButton));

  // Reconstrói o widget após a mudança de estado
  await tester.pump();

  // Verifica que o item aparece na lista
  expect(find.text('hi'), findsOneWidget);
});
```

> **Importante:** Sempre chame `pump()` ou `pumpAndSettle()` após `tap()`, pois o Flutter não reconstrói automaticamente no ambiente de teste.

### 7.3 Drag (arrastar)

Use `drag()` para simular gestos de arrastar, como swipe-to-dismiss:

```dart
testWidgets('swipe remove o item', (tester) async {
  await tester.pumpWidget(const TodoList());

  // Adiciona um item
  await tester.enterText(find.byType(TextField), 'hi');
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();

  // Arrasta para a direita para dispensar
  await tester.drag(find.byType(Dismissible), const Offset(500, 0));

  // Aguarda a animação de dismiss completar
  await tester.pumpAndSettle();

  // Verifica que o item foi removido
  expect(find.text('hi'), findsNothing);
});
```

> **Nota:** Use `pumpAndSettle()` (não apenas `pump()`) após drag com animações, para esperar a animação de dismiss completar.

---

## 8. Scroll em Listas

### 8.1 Preparando o app para scroll

Adicione `Key` aos widgets da lista para que os testes consigam localizá-los:

```dart
ListView.builder(
  key: const Key('long_list'),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(
        items[index],
        key: Key('item_${index}_text'),
      ),
    );
  },
),
```

### 8.2 `scrollUntilVisible()`

O método mais robusto para encontrar itens em listas longas. Rola a lista repetidamente até o widget alvo ficar visível:

```dart
testWidgets('encontra item profundo em lista longa', (tester) async {
  await tester.pumpWidget(
    MyApp(items: List<String>.generate(10000, (i) => 'Item $i')),
  );

  final listFinder = find.byType(Scrollable);
  final itemFinder = find.byKey(const ValueKey('item_50_text'));

  // Rola 500 pixels por vez até encontrar o item
  await tester.scrollUntilVisible(
    itemFinder,
    500.0,
    scrollable: listFinder,
  );

  // Verifica que o item está na tela
  expect(itemFinder, findsOneWidget);
});
```

### 8.3 Por que `scrollUntilVisible`?

- **Não assume a altura dos itens:** funciona com itens de tamanhos variáveis.
- **Independente de dispositivo:** não depende do tamanho da tela.
- **Mais resiliente:** continua rolando até encontrar, em vez de calcular offsets manualmente.

### 8.4 Scroll manual com `drag()`

Para casos simples ou quando se precisa de controle fino:

```dart
// Rola 300 pixels para cima
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();
```

---

## 9. Exemplo Completo — App Todo List

### 9.1 Widget

```dart
class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  static const _appTitle = 'Todo List';
  final todos = <String>[];
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(_appTitle)),
        body: Column(
          children: [
            TextField(controller: controller),
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Dismissible(
                    key: Key('$todo$index'),
                    onDismissed: (direction) => todos.removeAt(index),
                    background: Container(color: Colors.red),
                    child: ListTile(title: Text(todo)),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              todos.add(controller.text);
              controller.clear();
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

### 9.2 Teste completo

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Adicionar e remover todo', (tester) async {
    // Constrói o widget
    await tester.pumpWidget(const TodoList());

    // Digita 'hi' no TextField
    await tester.enterText(find.byType(TextField), 'hi');

    // Toca no botão adicionar
    await tester.tap(find.byType(FloatingActionButton));

    // Reconstrói após mudança de estado
    await tester.pump();

    // Verifica que o item aparece
    expect(find.text('hi'), findsOneWidget);

    // Arrasta para dispensar
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));

    // Aguarda animação completar
    await tester.pumpAndSettle();

    // Verifica que o item foi removido
    expect(find.text('hi'), findsNothing);
  });
}
```

---

## 10. Padrões Comuns

### 10.1 Testando widgets com dependências

Widgets que dependem de `Theme`, `MediaQuery`, `Navigator` ou `InheritedWidget` precisam ser envolvidos em um `MaterialApp` ou equivalente:

```dart
testWidgets('widget com dependências', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MeuWidgetComDependencias(),
      ),
    ),
  );
  // ...
});
```

### 10.2 Helper para pumpWidget

Para evitar repetição, crie um helper:

```dart
Future<void> pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

// Uso:
testWidgets('teste limpo', (tester) async {
  await pumpApp(tester, const MeuWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

### 10.3 Testando StatefulWidget com mudanças de estado

```dart
testWidgets('botão alterna estado', (tester) async {
  await tester.pumpWidget(const MeuToggle());

  // Estado inicial: desligado
  expect(find.text('OFF'), findsOneWidget);

  // Toca para alternar
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Estado alterado: ligado
  expect(find.text('ON'), findsOneWidget);
  expect(find.text('OFF'), findsNothing);
});
```

### 10.4 Testando navegação

```dart
testWidgets('navega para segunda tela', (tester) async {
  await tester.pumpWidget(const MeuApp());

  // Toca no botão de navegação
  await tester.tap(find.byKey(const Key('btn_proxima')));
  await tester.pumpAndSettle();  // espera animação de transição

  // Verifica que está na segunda tela
  expect(find.text('Segunda Tela'), findsOneWidget);
});
```

### 10.5 Testando diálogos e bottom sheets

```dart
testWidgets('exibe diálogo de confirmação', (tester) async {
  await tester.pumpWidget(const MeuApp());

  // Abre o diálogo
  await tester.tap(find.byKey(const Key('btn_deletar')));
  await tester.pumpAndSettle();

  // Verifica que o diálogo apareceu
  expect(find.text('Tem certeza?'), findsOneWidget);

  // Confirma
  await tester.tap(find.text('Sim'));
  await tester.pumpAndSettle();

  // Verifica que o diálogo fechou
  expect(find.text('Tem certeza?'), findsNothing);
});
```

---

## 11. Boas Práticas

### 11.1 Prefira `find.byKey` a `find.text`

Keys tornam os testes resilientes a mudanças de texto (i18n, redesign). Use `find.text` apenas para verificar o conteúdo exibido, não para localizar o widget a interagir.

### 11.2 Um fluxo por teste

Cada `testWidgets` deve testar **um cenário específico**. Evite testes monolíticos que testam tudo de uma vez.

### 11.3 Sempre chame pump após interações

O Flutter não reconstrói automaticamente no ambiente de teste. Esquecer `pump()` ou `pumpAndSettle()` é a causa mais comum de testes falhando inesperadamente.

### 11.4 Envolva widgets em MaterialApp

Widgets que usam `Theme`, `Navigator`, `MediaQuery` ou outros `InheritedWidget` falham se não estiverem envolvidos em `MaterialApp` ou `CupertinoApp`.

### 11.5 Cuidado com pumpAndSettle em animações infinitas

`pumpAndSettle()` espera até não haver mais frames agendados. Se o widget tem uma animação infinita (spinner, shimmer), use `pump(duration)` em vez disso.

### 11.6 Use setUp para inicialização comum

```dart
group('TodoList', () {
  late Widget app;

  setUp(() {
    app = const MaterialApp(home: TodoList());
  });

  testWidgets('exibe título', (tester) async {
    await tester.pumpWidget(app);
    expect(find.text('Todo List'), findsOneWidget);
  });

  testWidgets('campo de texto vazio inicialmente', (tester) async {
    await tester.pumpWidget(app);
    expect(find.byType(TextField), findsOneWidget);
  });
});
```

---

## 12. Executando Testes de Widget

```bash
# Rodar todos os testes da pasta test/
flutter test

# Rodar um arquivo específico
flutter test test/widgets/my_widget_test.dart

# Rodar com output detalhado
flutter test --reporter expanded

# Atualizar golden files
flutter test --update-goldens
```

---

## 13. Checklist Rápido

Antes de considerar seus testes de widget prontos, verifique:

- [ ] Widgets sob teste estão envolvidos em `MaterialApp` (ou equivalente).
- [ ] `pump()` ou `pumpAndSettle()` é chamado após toda interação.
- [ ] Widgets interativos possuem `Key` para localização robusta.
- [ ] Cada teste verifica um cenário ou fluxo específico.
- [ ] Animações infinitas usam `pump(duration)` em vez de `pumpAndSettle()`.
- [ ] Golden files estão atualizados (se usados).
- [ ] Testes estão agrupados com `group()` por widget ou funcionalidade.
- [ ] Helpers de pump reduzem duplicação.
- [ ] Todos os testes passam com `flutter test`.

---

## 14. Referência Rápida de Imports

```dart
// Pacote principal de testes de widget
import 'package:flutter_test/flutter_test.dart';

// Material widgets (para MaterialApp, Scaffold, Keys, etc.)
import 'package:flutter/material.dart';

// Seu widget (ajustar conforme o projeto)
import 'package:meu_app/widgets/my_widget.dart';
```

### Resumo dos métodos do WidgetTester

| Método | Descrição |
|---|---|
| `pumpWidget(widget)` | Constrói e renderiza o widget. |
| `pump()` | Agenda 1 frame e reconstrói. |
| `pump(duration)` | Avança o relógio e reconstrói (1 frame). |
| `pumpAndSettle()` | Reconstrói até todas as animações finalizarem. |
| `tap(finder)` | Simula um toque. |
| `longPress(finder)` | Simula toque longo. |
| `drag(finder, offset)` | Simula arrastar. |
| `enterText(finder, text)` | Digita texto em um campo. |
| `scrollUntilVisible(finder, delta)` | Rola lista até o widget ficar visível. |
| `widget<T>(finder)` | Retorna o widget encontrado para inspeção de propriedades. |

---

*Guia baseado na documentação oficial do Flutter sobre testes de widget, finders, interações e scroll handling.*