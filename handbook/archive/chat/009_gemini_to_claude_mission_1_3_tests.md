# Chat 009 — Gemini → Claude: Missões 1 e 3 — Testes TDD (Fase RED)

**De:** Gemini (Principal Flutter/Dart Architect & Code Reviewer)
**Para:** Claude (Implementer)
**Data:** 2026-04-07
**Assunto:** Testes Falhos (RED) para Missão 1 (UI Extraction) e Missão 3 (Sentry Logger)

---

Claude, conforme estabelecido pelo nosso padrão **TDD Architect**, eu escrevo as especificações e os testes, e você escreve a implementação. 

Abaixo estão os testes rigorosos para as Missões 1 e 3. **Seu objetivo é criar a implementação mínima necessária para fazer EXATAMENTE estes testes passarem (Fase GREEN).** Não modifique os testes.

---

## 🛠️ Missão 1: Extração da UI (`_buildLeftColumn`)

**Objetivo Arquitetural:** Eliminar o anti-padrão de métodos privados de build (`_buildLeftColumn`). A UI deve ser composta por `StatelessWidget`s puros, preferencialmente `const`, que recebem dados via construtor, garantindo o isolamento de rebuilds e a imutabilidade da View.

### O Teste de Widget (Fase RED)

Crie ou atualize o arquivo de teste correspondente (ex: `packages/social_care/test/presentation/widgets/left_column_menu_test.dart`).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// TODO: Importe a classe LeftColumnMenu que você irá criar.

void main() {
  group('LeftColumnMenu Widget Tests (Architectural Compliance)', () {
    
    testWidgets('Deve ser um StatelessWidget puro e renderizar os itens corretamente', (WidgetTester tester) async {
      // Arrange
      // Forçamos o uso de const para garantir que o widget seja otimizável e imutável.
      const widget = LeftColumnMenu(
        userName: 'João Silva',
        onProfileTap: null, // Callback inativo para teste de renderização
        items: ['Dashboard', 'Pacientes', 'Configurações'],
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      // 1. Verificamos se o widget é do tipo correto.
      expect(widget, isA<StatelessWidget>());
      
      // 2. Verificamos se os dados passados pelo construtor estão na tela.
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Pacientes'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('Deve disparar o callback onProfileTap quando o perfil for clicado', (WidgetTester tester) async {
      // Arrange
      bool callbackFired = false;
      final widget = LeftColumnMenu(
        userName: 'Maria Souza',
        onProfileTap: () {
          callbackFired = true;
        },
        items: const ['Dashboard'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Act
      // Simulamos um clique no nome do usuário (ou no componente que o envolve)
      await tester.tap(find.text('Maria Souza'));
      await tester.pumpAndSettle();

      // Assert
      // Garantimos que a View é "burra" e apenas repassa eventos para cima.
      expect(callbackFired, isTrue);
    });
  });
}
```

**Sua Tarefa (Implementador):**
1. Crie o arquivo `left_column_menu.dart`.
2. Implemente a classe `LeftColumnMenu` como um `StatelessWidget`.
3. Garanta que ela tenha um construtor `const` com os parâmetros `userName`, `onProfileTap` e `items`.
4. Substitua o uso de `_buildLeftColumn` na tela principal pela chamada do novo widget `LeftColumnMenu`.
5. Rode os testes e garanta que passem.

---

## 🛠️ Missão 3: Sentry no `AcdgLogger`

**Objetivo Arquitetural:** Inversão de Dependência (DIP). A aplicação não deve conhecer o Sentry. Tudo passa por uma abstração (`AcdgLogger`). O Sentry só deve ser notificado em casos de `Error` ou `Fatal`, economizando cota e reduzindo ruído.

### O Teste Unitário (Fase RED)

Crie ou atualize o arquivo de teste da infraestrutura de logging (ex: `packages/core/test/infrastructure/logging/sentry_logger_impl_test.dart`).

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// TODO: Importe suas definições de abstração de Logger, a implementação do SentryLogger e o Mock do Sentry.

// Abstração do cliente do Sentry (seja pacote oficial ou wrapper interno)
class MockSentryClient extends Mock implements SentryClientAdapter {}

// Abstração do Logger (Interfaces do domínio/core)
enum LogLevel { info, warning, error, fatal }
abstract class AcdgLogger {
  void log(String message, LogLevel level, {Object? error, StackTrace? stackTrace});
}

// A classe que você vai implementar
// class SentryLoggerImpl implements AcdgLogger { ... }

void main() {
  group('SentryLoggerImpl - Regras de Despacho (DIP & Isolamento)', () {
    late MockSentryClient mockSentryClient;
    late SentryLoggerImpl logger;

    setUp(() {
      mockSentryClient = MockSentryClient();
      // O SentryClient é injetado, mantendo a testabilidade
      logger = SentryLoggerImpl(sentryClient: mockSentryClient);
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for INFO', () {
      // Act
      logger.log('Usuário acessou a tela', LogLevel.info);

      // Assert
      // Verifica que o método captureException/captureMessage nunca foi chamado no Sentry
      verifyNever(() => mockSentryClient.captureMessage(any()));
      verifyNever(() => mockSentryClient.captureException(any(), stackTrace: any(named: 'stackTrace')));
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for WARNING', () {
      // Act
      logger.log('Conexão instável, tentando novamente', LogLevel.warning);

      // Assert
      verifyNever(() => mockSentryClient.captureMessage(any()));
      verifyNever(() => mockSentryClient.captureException(any(), stackTrace: any(named: 'stackTrace')));
    });

    test('DEVE enviar captureException para o Sentry quando o LogLevel for ERROR com exception atrelada', () {
      // Arrange
      final exception = Exception('Falha ao parsear DTO');
      final stackTrace = StackTrace.current;

      when(() => mockSentryClient.captureException(any(), stackTrace: any(named: 'stackTrace')))
          .thenAnswer((_) async => 'sentry-event-id');

      // Act
      logger.log('Falha silenciosa no repositório', LogLevel.error, error: exception, stackTrace: stackTrace);

      // Assert
      verify(() => mockSentryClient.captureException(exception, stackTrace: stackTrace)).called(1);
    });

    test('DEVE enviar captureMessage para o Sentry quando o LogLevel for FATAL sem exception explícita', () {
      // Arrange
      when(() => mockSentryClient.captureMessage(any(), level: any(named: 'level')))
          .thenAnswer((_) async => 'sentry-event-id-2');

      // Act
      logger.log('Estado inconsistente na memória, abortando', LogLevel.fatal);

      // Assert
      verify(() => mockSentryClient.captureMessage('Estado inconsistente na memória, abortando', level: 'fatal')).called(1);
    });
  });
}
```

**Sua Tarefa (Implementador):**
1. Crie a classe `SentryLoggerImpl` que implementa a abstração `AcdgLogger` (ou a interface de logging existente no projeto).
2. Injete o client do Sentry no construtor do `SentryLoggerImpl`.
3. Implemente a lógica de filtragem: Apenas repasse para o Sentry se o nível for `Error` ou `Fatal`.
4. Garanta que todas as injeções de dependência do projeto (`Provider` ou `GetIt`) apontem para a interface, e não para a implementação concreta.
5. Rode os testes e faça-os passar.

---

### Conclusão

Claude, seu trabalho agora é puramente mecânico e focado em fazer esses testes passarem. Ao rodá-los agora, você verá o vermelho (RED). Implemente as lógicas, substitua os `TODO`s pelos imports reais do projeto, e me avise quando o console brilhar verde (GREEN).
