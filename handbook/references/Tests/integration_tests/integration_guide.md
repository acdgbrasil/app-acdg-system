# Guia Completo: Testes de Integração em Flutter

> **Propósito:** Este documento é um guia de referência para IAs e desenvolvedores sobre como escrever testes de integração de alta qualidade em Flutter, cobrindo desde conceitos fundamentais até profiling de performance e execução em Firebase Test Lab.

---

## 1. Conceitos Fundamentais

Testes unitários e de widget validam classes, funções ou widgets individuais de forma isolada. Porém, eles **não verificam** como as peças funcionam juntas nem capturam a performance do app em um dispositivo real. Para isso, existem os **testes de integração** (também chamados de testes end-to-end ou testes de GUI).

Testes de integração verificam o comportamento do **app completo**, simulando interações reais do usuário — toques, scrolls, navegação — e validando o resultado visual na tela.

### Quando usar testes de integração?

- **Fluxos completos do usuário:** login → navegação → ação → resultado.
- **Interação entre múltiplas telas e widgets.**
- **Validação de performance:** scroll suave, animações sem jank.
- **Testes em dispositivos reais:** Android, iOS, web e desktop.
- **Testes automatizados em CI/CD** com Firebase Test Lab.

### Terminologia

| Termo | Descrição |
|---|---|
| **Host machine** | O computador onde você desenvolve o app (desktop). |
| **Target device** | O dispositivo móvel, navegador ou app desktop onde o Flutter app roda. |
| **integration_test** | Pacote oficial do Flutter SDK para testes de integração. |
| **WidgetTester** | Classe que permite interagir com widgets durante o teste. |
| **IntegrationTestWidgetsFlutterBinding** | Singleton que executa testes em dispositivos reais. |

> **Nota:** Em apps web ou desktop, o host machine e o target device são o mesmo.

---

## 2. Configuração do Projeto

### 2.1 Dependências

Adicione o pacote `integration_test` (do próprio Flutter SDK) como dependência de desenvolvimento:

```bash
flutter pub add "dev:integration_test:{sdk: flutter}"
```

Isso adiciona ao `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### 2.2 Estrutura de Diretórios

Testes de integração ficam em uma pasta separada chamada `integration_test/` na raiz do projeto:

```
meu_projeto/
├── lib/
│   └── main.dart
├── test/                      # testes unitários e de widget
│   └── widget_test.dart
├── integration_test/          # testes de integração
│   └── app_test.dart
└── test_driver/               # drivers (necessário para web e performance)
    └── integration_test.dart
```

**Regras obrigatórias:**

- Testes de integração ficam na pasta `integration_test/` (não na pasta `test/`).
- Arquivos de teste devem terminar com `_test.dart`.
- O driver file (quando necessário) fica em `test_driver/`.

---

## 3. Preparando o App para Teste

Para que os testes consigam encontrar e interagir com widgets específicos, adicione **Keys** aos widgets importantes:

```dart
// lib/main.dart
floatingActionButton: FloatingActionButton(
  key: const ValueKey('increment'),  // ← Key para o teste encontrar
  onPressed: _incrementCounter,
  tooltip: 'Increment',
  child: const Icon(Icons.add),
),
```

### Boas práticas para Keys em testes

- Use `ValueKey` com strings descritivas para botões de ação.
- Use `Key('item_$index')` para itens de listas dinâmicas.
- Mantenha as Keys consistentes — elas são o "contrato" entre o app e os testes.
- Prefira Keys a buscas por texto quando o texto pode mudar (i18n).

---

## 4. Escrevendo o Primeiro Teste de Integração

### 4.1 Estrutura básica

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meu_app/main.dart';

void main() {
  // OBRIGATÓRIO: inicializar o binding de integração
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('toca no FAB e verifica o counter', (tester) async {
      // 1. Carrega o app
      await tester.pumpWidget(const MyApp());

      // 2. Verifica estado inicial
      expect(find.text('0'), findsOneWidget);

      // 3. Encontra o widget pelo Key
      final fab = find.byKey(const ValueKey('increment'));

      // 4. Simula o toque
      await tester.tap(fab);

      // 5. Aguarda a UI atualizar
      await tester.pumpAndSettle();

      // 6. Verifica o resultado
      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

### 4.2 Anatomia do teste

| Passo | Método | Descrição |
|---|---|---|
| Inicialização | `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` | Configura o binding para rodar em dispositivos reais. **Obrigatório.** |
| Carregar app | `tester.pumpWidget(const MyApp())` | Renderiza o widget raiz do app. |
| Encontrar widgets | `find.text()`, `find.byKey()`, `find.byType()` | Localiza widgets na árvore. |
| Interagir | `tester.tap()`, `tester.drag()`, `tester.enterText()` | Simula ações do usuário. |
| Aguardar | `tester.pumpAndSettle()` | Espera todas as animações e rebuilds terminarem. |
| Verificar | `expect(finder, matcher)` | Valida o estado da UI. |

---

## 5. Finders — Localizando Widgets

Os finders são usados para localizar widgets na árvore de widgets:

### 5.1 Por texto

```dart
find.text('Hello World');          // texto exato
find.textContaining('Hello');      // contém texto
```

### 5.2 Por Key

```dart
find.byKey(const ValueKey('increment'));
find.byKey(const Key('item_42'));
```

### 5.3 Por tipo

```dart
find.byType(FloatingActionButton);
find.byType(ListView);
find.byType(TextField);
```

### 5.4 Por ícone

```dart
find.byIcon(Icons.add);
find.byIcon(Icons.delete);
```

### 5.5 Por widget específico

```dart
find.byWidget(myWidgetInstance);
find.widgetWithText(ElevatedButton, 'Salvar');
find.widgetWithIcon(IconButton, Icons.search);
```

### 5.6 Combinando finders

```dart
find.descendant(
  of: find.byType(AppBar),
  matching: find.text('Título'),
);

find.ancestor(
  of: find.text('Item 1'),
  matching: find.byType(ListTile),
);
```

---

## 6. Interações — Simulando o Usuário

### 6.1 Toques

```dart
await tester.tap(find.byKey(const Key('botao')));
await tester.pumpAndSettle();

// Toque longo
await tester.longPress(find.byKey(const Key('item')));
await tester.pumpAndSettle();

// Toque duplo
await tester.tap(find.byKey(const Key('item')));
await tester.tap(find.byKey(const Key('item')));
await tester.pumpAndSettle();
```

### 6.2 Entrada de texto

```dart
// Digitar texto em um TextField
await tester.enterText(find.byType(TextField), 'meu texto');
await tester.pumpAndSettle();

// Digitar em campo específico
await tester.enterText(find.byKey(const Key('email_field')), 'user@test.com');
await tester.enterText(find.byKey(const Key('senha_field')), '123456');
await tester.pumpAndSettle();
```

### 6.3 Scroll

```dart
// Scroll até encontrar um widget
await tester.scrollUntilVisible(
  find.byKey(const ValueKey('item_50_text')),
  500.0,  // distância de cada scroll
  scrollable: find.byType(Scrollable),
);

// Drag manual
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();
```

### 6.4 Swipe / Dismiss

```dart
// Swipe para a esquerda (dismiss)
await tester.drag(
  find.byKey(const Key('item_dismissible')),
  const Offset(-500, 0),
);
await tester.pumpAndSettle();
```

---

## 7. Matchers para Testes de Integração

### 7.1 Matchers de presença de widgets

```dart
expect(find.text('0'), findsOneWidget);       // encontra exatamente 1
expect(find.text('Hello'), findsNothing);      // não encontra nenhum
expect(find.byType(ListTile), findsNWidgets(5)); // encontra exatamente N
expect(find.byType(Card), findsAtLeastNWidgets(3)); // encontra pelo menos N
expect(find.text('Item'), findsWidgets);       // encontra 1 ou mais
```

### 7.2 Verificando propriedades de widgets

```dart
// Verificar se um widget está habilitado
final button = tester.widget<ElevatedButton>(find.byKey(const Key('submit')));
expect(button.onPressed, isNotNull);  // botão habilitado

// Verificar cor ou estilo
final text = tester.widget<Text>(find.text('Título'));
expect(text.style?.fontSize, equals(24.0));
```

---

## 8. Padrões Comuns de Testes de Integração

### 8.1 Fluxo de login completo

```dart
testWidgets('fluxo de login', (tester) async {
  await tester.pumpWidget(const MyApp());

  // Navegar para tela de login
  await tester.tap(find.byKey(const Key('btn_login')));
  await tester.pumpAndSettle();

  // Preencher credenciais
  await tester.enterText(find.byKey(const Key('email')), 'user@test.com');
  await tester.enterText(find.byKey(const Key('senha')), 'password123');

  // Submeter
  await tester.tap(find.byKey(const Key('btn_submit')));
  await tester.pumpAndSettle();

  // Verificar redirecionamento para home
  expect(find.text('Bem-vindo'), findsOneWidget);
});
```

### 8.2 Teste de lista com scroll

```dart
testWidgets('scroll até o último item', (tester) async {
  await tester.pumpWidget(
    MyApp(items: List<String>.generate(100, (i) => 'Item $i')),
  );

  final listFinder = find.byType(Scrollable);
  final itemFinder = find.byKey(const ValueKey('item_99'));

  await tester.scrollUntilVisible(
    itemFinder,
    500.0,
    scrollable: listFinder,
  );

  expect(itemFinder, findsOneWidget);
});
```

### 8.3 Teste de navegação entre telas

```dart
testWidgets('navega para detalhes e volta', (tester) async {
  await tester.pumpWidget(const MyApp());

  // Toca em um item da lista
  await tester.tap(find.text('Item 1'));
  await tester.pumpAndSettle();

  // Verifica que está na tela de detalhes
  expect(find.text('Detalhes do Item 1'), findsOneWidget);

  // Volta
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();

  // Verifica que voltou para a lista
  expect(find.text('Item 1'), findsOneWidget);
  expect(find.text('Detalhes do Item 1'), findsNothing);
});
```

---

## 9. Medindo Performance

Testes de integração podem capturar timelines de performance para identificar jank (frames perdidos ou lentos).

### 9.1 Gravando timeline de performance

```dart
// integration_test/scrolling_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:meu_app/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('performance de scroll', (tester) async {
    await tester.pumpWidget(
      MyApp(items: List<String>.generate(10000, (i) => 'Item $i')),
    );

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.byKey(const ValueKey('item_50_text'));

    // Grava a timeline durante a ação
    await binding.traceAction(() async {
      await tester.scrollUntilVisible(
        itemFinder,
        500.0,
        scrollable: listFinder,
      );
    }, reportKey: 'scrolling_timeline');
  });
}
```

### 9.2 Salvando resultados no disco

Crie o driver que processa e salva a timeline:

```dart
// test_driver/perf_driver.dart
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data != null) {
        final timeline = driver.Timeline.fromJson(
          data['scrolling_timeline'] as Map<String, dynamic>,
        );

        final summary = driver.TimelineSummary.summarize(timeline);

        // Salva a timeline completa e o resumo como JSON
        await summary.writeTimelineToFile(
          'scrolling_timeline',
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
```

### 9.3 Executando o teste de performance

```bash
flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/scrolling_test.dart \
  --profile
```

> **Importante:** Use `--profile` para compilar em modo profile (mais próximo da experiência real do usuário). Use `--no-dds` ao rodar em dispositivos móveis ou emuladores.

### 9.4 Interpretando os resultados

O arquivo `scrolling_summary.timeline_summary.json` contém métricas como:

```json
{
  "average_frame_build_time_millis": 4.26,
  "worst_frame_build_time_millis": 21.0,
  "missed_frame_build_budget_count": 2,
  "average_frame_rasterizer_time_millis": 5.52,
  "worst_frame_rasterizer_time_millis": 51.0,
  "missed_frame_rasterizer_budget_count": 10,
  "frame_count": 54
}
```

| Métrica | O que significa | Meta ideal |
|---|---|---|
| `average_frame_build_time_millis` | Tempo médio para construir um frame. | < 16ms (60fps) |
| `worst_frame_build_time_millis` | Pior tempo de build de um frame. | < 16ms |
| `missed_frame_build_budget_count` | Frames que excederam o orçamento de 16ms. | 0 |
| `average_frame_rasterizer_time_millis` | Tempo médio de rasterização. | < 16ms |
| `worst_frame_rasterizer_time_millis` | Pior tempo de rasterização. | < 16ms |
| `frame_count` | Total de frames renderizados. | Quanto mais, melhor |

> **Dica:** Abra o arquivo `scrolling_timeline.timeline.json` em `chrome://tracing` para uma visualização detalhada da timeline.

---

## 10. Executando Testes

### 10.1 Desktop (macOS, Windows, Linux)

```bash
# Rodar todos os testes de integração
flutter test integration_test

# Rodar um arquivo específico
flutter test integration_test/app_test.dart
```

### 10.2 Android (dispositivo real ou emulador)

```bash
# Conecte o dispositivo e execute
flutter test integration_test/app_test.dart
```

### 10.3 iOS (dispositivo real ou simulador)

```bash
# Conecte o dispositivo e execute
flutter test integration_test/app_test.dart
```

> **Nota:** Após o teste, verifique se o app foi removido do dispositivo. Caso contrário, testes subsequentes podem falhar.

### 10.4 Web (com ChromeDriver)

```bash
# 1. Instale o ChromeDriver
npx @puppeteer/browsers install chromedriver@stable

# 2. Inicie o ChromeDriver
chromedriver --port=4444

# 3. Execute o teste (em outro terminal)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

O driver file para web:

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

Para rodar headless (sem janela do navegador):

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server
```

### 10.5 Firebase Test Lab (Android)

```bash
# 1. Navegue até a pasta android
pushd android

# 2. Build do APK de debug
flutter build apk --debug

# 3. Build do APK de teste
./gradlew app:assembleAndroidTest

# 4. Build com target do teste de integração
./gradlew app:assembleDebug -Ptarget=integration_test/app_test.dart

# 5. Volte ao diretório raiz
popd
```

Depois, faça upload dos APKs no Firebase Console em **Quality > Test Lab**, selecionando o tipo **Instrumentation**.

### 10.5 Firebase Test Lab (iOS)

Siga as instruções de iOS Device Testing da documentação oficial do Firebase para gerar e enviar os testes via Xcode ou linha de comando.

---

## 11. Diferenças: Testes Unitários vs Widget vs Integração

| Aspecto | Unitário | Widget | Integração |
|---|---|---|---|
| **Escopo** | Função/classe | Widget isolado | App completo |
| **Velocidade** | Muito rápido | Rápido | Lento |
| **Dependências** | Mockadas | Mockadas | Reais ou mockadas |
| **Dispositivo real** | Não | Não | Sim |
| **Pacote** | `test` | `flutter_test` | `integration_test` |
| **Pasta** | `test/` | `test/` | `integration_test/` |
| **Confiança** | Baixa (isolado) | Média | Alta (end-to-end) |
| **Custo de manutenção** | Baixo | Médio | Alto |

### Pirâmide de testes recomendada

- **Base (70%):** Testes unitários — muitos, rápidos, baratos.
- **Meio (20%):** Testes de widget — validam componentes de UI.
- **Topo (10%):** Testes de integração — poucos, focados em fluxos críticos.

---

## 12. Boas Práticas

### 12.1 Adicione Keys estrategicamente

Coloque `Key` em todos os widgets com os quais os testes precisam interagir. Isso torna os testes resilientes a mudanças de texto ou layout.

### 12.2 Use `pumpAndSettle()` após cada interação

Sempre aguarde a UI estabilizar depois de toques, navegações ou animações. Sem isso, os expects podem falhar intermitentemente.

### 12.3 Mantenha testes focados

Cada teste deve cobrir **um fluxo específico**. Evite testes que fazem login, navegam por 5 telas e verificam 20 coisas diferentes.

### 12.4 Lide com estados assíncronos

Se o app faz chamadas HTTP, use mocks ou backends de teste para evitar flakiness. Testes de integração com dependências de rede reais são frágeis.

### 12.5 Isole o estado entre testes

Cada `testWidgets` deve começar com um app limpo. Não dependa do estado deixado por testes anteriores.

### 12.6 Rode em CI/CD

Automatize testes de integração no pipeline de CI. Use Firebase Test Lab para testar em múltiplos dispositivos Android e iOS automaticamente.

### 12.7 Timeout para `pumpAndSettle`

Se uma animação roda infinitamente (como um spinner), `pumpAndSettle()` vai dar timeout. Use `pump(duration)` com duração específica nesses casos:

```dart
// Em vez de pumpAndSettle (que esperaria infinitamente)
await tester.pump(const Duration(seconds: 2));
```

---

## 13. Checklist Rápido

Antes de considerar seus testes de integração prontos, verifique:

- [ ] `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` está no início de `main()`.
- [ ] Testes estão na pasta `integration_test/` (não em `test/`).
- [ ] Widgets interativos possuem `Key` para fácil localização.
- [ ] `pumpAndSettle()` é chamado após cada interação.
- [ ] Cada teste cobre um único fluxo do usuário.
- [ ] Testes não dependem de serviços externos reais (ou usam backend de teste).
- [ ] Testes de performance usam `--profile` ao executar.
- [ ] Driver file está em `test_driver/` (necessário para web e performance).
- [ ] Testes passam em `flutter test integration_test`.
- [ ] Pipeline de CI executa os testes automaticamente.

---

## 14. Referência Rápida de Imports

```dart
// Binding de integração (obrigatório)
import 'package:integration_test/integration_test.dart';

// APIs de teste Flutter (finders, matchers, testWidgets)
import 'package:flutter_test/flutter_test.dart';

// Widgets do Flutter (para Keys, tipos, etc.)
import 'package:flutter/material.dart';

// Seu app (ajustar conforme o projeto)
import 'package:meu_app/main.dart';

// Driver para web e performance (no test_driver/)
import 'package:integration_test/integration_test_driver.dart';

// Timeline para profiling de performance (no test_driver/)
import 'package:flutter_driver/flutter_driver.dart' as driver;
```

---

*Guia baseado na documentação oficial do Flutter sobre testes de integração, profiling de performance e Firebase Test Lab.*