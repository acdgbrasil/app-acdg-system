# Guia Completo: Visão Geral de Testes em Flutter, Plugins e CI/CD

> **Propósito:** Este documento é um guia de referência para IAs e desenvolvedores sobre a visão geral do ecossistema de testes em Flutter, como testar plugins (incluindo código nativo), como lidar com plugins em testes de app, e como integrar testes em pipelines de CI/CD.

---

## 1. Visão Geral — Tipos de Testes em Flutter

Testes automatizados garantem que o app funciona corretamente antes da publicação, mantendo a velocidade de desenvolvimento mesmo com novas funcionalidades e correções de bugs.

### 1.1 Os três tipos de teste

| Tipo | O que testa | Confiança | Custo de manutenção | Dependências | Velocidade |
|---|---|---|---|---|---|
| **Unitário** | Função, método ou classe individual. | Baixa | Baixo | Poucas | Rápido |
| **Widget** | Widget individual (equivalente a "component test" em outros frameworks). | Média | Médio | Mais | Rápido |
| **Integração** | App completo ou grande parte dele. | Alta | Alto | Muitas | Lento |

### 1.2 Distribuição recomendada

A pirâmide de testes ideal para um app Flutter bem testado:

- **Base (70%) — Testes unitários:** muitos testes cobrindo a lógica de negócios, rastreados por code coverage.
- **Meio (20%) — Testes de widget:** testam a UI e interação de cada widget.
- **Topo (10%) — Testes de integração:** poucos testes cobrindo todos os casos de uso importantes, rodando em dispositivos reais ou emuladores.

### 1.3 Resumo de cada tipo

**Testes unitários** verificam a corretude de uma unidade de lógica sob diversas condições. Dependências externas geralmente são mockadas. Testes unitários não devem ler/escrever em disco, renderizar na tela nem receber ações do usuário.

**Testes de widget** verificam que a UI de um widget parece e interage como esperado. O ambiente de teste fornece o contexto de ciclo de vida do widget (layout, widgets filhos, ações do usuário), mas é uma implementação simplificada comparada ao sistema de UI completo.

**Testes de integração** verificam que todos os widgets e serviços funcionam juntos como esperado. Rodam em dispositivos reais ou emuladores (iOS Simulator, Android Emulator). O app sob teste é tipicamente isolado do código do test driver para não distorcer os resultados.

---

## 2. Plugins em Testes de App Flutter

Quase todo plugin Flutter tem duas partes: código Dart (a API que seu código chama) e código nativo em linguagem da plataforma (Kotlin, Swift, etc.) que implementa essas APIs. O código nativo é compilado e registrado durante o build do app, então **não está disponível durante testes unitários ou de widget**.

Se o código testado chama plugins, isso frequentemente resulta em:

```
MissingPluginException(No implementation found for method someMethodName on channel...)
```

> **Nota:** Implementações de plugins que usam apenas Dart funcionam em testes unitários, mas isso é um detalhe de implementação e os testes não devem depender disso.

### 2.1 Estratégias para evitar o erro (em ordem de preferência)

#### Estratégia 1: Encapsular o plugin (Recomendada)

A melhor abordagem é encapsular as chamadas ao plugin em sua própria API e fornecer uma forma de mockear essa API nos testes:

```dart
// lib/services/location_service.dart
abstract class LocationService {
  Future<Position> getCurrentPosition();
}

// Implementação real (usa o plugin)
class GpsLocationService implements LocationService {
  @override
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition();
  }
}

// Mock para testes
class MockLocationService implements LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(latitude: -3.71, longitude: -38.54);
  }
}
```

**Vantagens:**

- Se a API do plugin mudar, os testes não precisam ser atualizados.
- Você testa apenas seu próprio código, sem que bugs do plugin afetem seus testes.
- Funciona independentemente de como o plugin é implementado.
- Mesma abordagem serve para dependências que não são plugins.

#### Estratégia 2: Mockar a API pública do plugin

Se a API do plugin já é baseada em instâncias de classe, é possível mockear diretamente:

```dart
// Usando Mockito para mockar o plugin diretamente
@GenerateMocks([SomePluginClass])
void main() {
  test('usa plugin mockado', () {
    final mockPlugin = MockSomePluginClass();
    when(mockPlugin.someMethod()).thenReturn('resultado');
    // ...
  });
}
```

**Limitações:**

- Não funciona se o plugin usa funções não-classe ou métodos estáticos.
- Testes precisam ser atualizados quando a API do plugin muda.

#### Estratégia 3: Mockar a interface de plataforma do plugin

Para plugins federados, é possível registrar um mock da interface de plataforma interna:

```dart
// Registra uma implementação fake da interface de plataforma
setUp(() {
  FakePluginPlatform.registerWith();
});
```

**Limitações:**

- Funciona apenas com plugins federados.
- Testes incluem parte do código do plugin, então comportamentos internos (como cache em disco) podem afetar os testes.
- Testes podem quebrar quando a interface de plataforma muda.

#### Estratégia 4: Mockar o platform channel (Último recurso)

Use `TestDefaultBinaryMessenger` para mockar platform channels apenas se nenhuma das opções acima estiver disponível:

**Problemas graves desta abordagem:**

- Apenas implementações que usam platform channels podem ser mockadas.
- Platform channels são detalhes internos de implementação e podem mudar drasticamente mesmo em updates de bugfix.
- Platform channels podem diferir entre implementações de um plugin federado (Windows vs macOS vs Linux).
- Platform channels não são fortemente tipados — usam dicionários com chaves string, e você precisa ler a implementação do plugin para conhecer as chaves e tipos.

> **Resumo:** `TestDefaultBinaryMessenger` é útil principalmente para testes internos de implementações de plugins, não para testes de código que usa plugins.

---

## 3. Testando Plugins Flutter

Plugins possuem código Dart e código nativo, e ambos precisam de testes. Cada tipo de teste cobre uma parte diferente do plugin.

### 3.1 Tipos de testes para plugins

| Tipo | O que testa | Onde fica | Linguagem |
|---|---|---|---|
| **Dart unitário/widget** | Parte Dart do plugin (com platform channels mockados). | `test/` | Dart |
| **Dart integração** | Dart + nativo juntos, no contexto do example app. | `example/integration_test/` | Dart |
| **Nativo unitário** | Parte nativa isolada, com mocks de APIs nativas. | Varia por plataforma | Kotlin/Swift/C++ |
| **Nativo UI** | Interação com UI nativa e Flutter juntas. | Via Espresso/XCUITest | Kotlin/Swift |

### 3.2 Testes Dart unitários e de widget

Testam a porção Dart do plugin assim como qualquer pacote Dart. O código nativo não é carregado, então chamadas a platform channels precisam ser mockadas.

```dart
// test/my_plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_plugin/my_plugin.dart';
import 'package:my_plugin/my_plugin_platform_interface.dart';

class MockMyPluginPlatform extends MyPluginPlatform {
  @override
  Future<String> getPlatformVersion() async => '42';
}

void main() {
  setUp(() {
    MyPluginPlatform.instance = MockMyPluginPlatform();
  });

  test('getPlatformVersion retorna versão mockada', () async {
    expect(await MyPlugin().getPlatformVersion(), '42');
  });
}
```

### 3.3 Testes de integração Dart

São frequentemente **os testes mais importantes para um plugin**, pois testam código Dart e nativo juntos, incluindo a comunicação entre eles. Rodam no contexto do example app:

```dart
// example/integration_test/plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_plugin/my_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion retorna valor real', (tester) async {
    final version = await MyPlugin().getPlatformVersion();
    expect(version, isNotNull);
    expect(version!.isNotEmpty, isTrue);
  });
}
```

**Limitação:** testes de integração Dart não conseguem interagir com UI nativa (diálogos nativos, conteúdo de platform views).

### 3.4 Testes nativos unitários

Testam a parte nativa do plugin em isolamento, permitindo mockar APIs nativas que o plugin encapsula.

#### Android (JUnit)

Localização: `android/src/test/`

```bash
# No diretório example/android
./gradlew testDebugUnitTest
```

Também é possível rodar pela UI de testes do Android Studio.

#### iOS e macOS (XCTest)

Localização: `example/ios/RunnerTests/` e `example/macos/RunnerTests/`

```bash
# Para iOS (no diretório example/ios)
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug

# Para macOS (no diretório example/macos)
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug
```

> **Nota para iOS:** pode ser necessário abrir `Runner.xcworkspace` no Xcode primeiro para configurar code signing.

Também é possível rodar pela UI de testes do Xcode.

#### Linux (GoogleTest)

Localização: `linux/test/`

```bash
# No diretório example (substitua "my_plugin" pelo nome do plugin)
build/linux/plugins/x64/debug/my_plugin/my_plugin_test
```

#### Windows (GoogleTest)

Localização: `windows/test/`

```bash
# No diretório example (substitua "my_plugin" pelo nome do plugin)
build/windows/plugins/my_plugin/Debug/my_plugin_test.exe
```

Também é possível rodar pela UI de testes do Visual Studio.

> **Importante para todos os testes nativos:** é necessário compilar o example app pelo menos uma vez antes de rodar os testes nativos, para garantir que todos os arquivos de build específicos da plataforma foram criados.

### 3.5 Recomendações para testes de plugins

- Tenha pelo menos **um teste de integração para cada chamada de platform channel**, pois apenas testes de integração testam a comunicação real entre Dart e nativo.
- Para fluxos que não podem ser testados via integração (UI nativa, estado do device mockado), use a abordagem "end-to-end em duas metades":
  - **Testes nativos unitários:** configuram mocks, chamam o ponto de entrada do method channel com uma chamada sintetizada e validam a resposta.
  - **Testes Dart unitários:** mockam o platform channel, chamam a API pública do plugin e validam os resultados.
- Use frameworks de teste nativos de UI (Espresso, XCUITest) quando o plugin requer interação com elementos de UI tanto nativos quanto Flutter.

---

## 4. Integração Contínua (CI/CD)

Serviços de CI permitem rodar testes automaticamente quando novas mudanças de código são enviadas, fornecendo feedback rápido sobre se as mudanças funcionam como esperado e não introduzem bugs.

### 4.1 Serviços compatíveis com Flutter

| Serviço | Observações |
|---|---|
| **Codemagic** | CI/CD dedicado para Flutter, configuração simplificada. |
| **GitHub Actions** | Ampla adoção, boa integração com repositórios GitHub. |
| **Bitrise** | Suporte nativo a Flutter com workflows visuais. |
| **Appcircle** | Focado em mobile, suporte a Flutter. |
| **Travis CI** | Opção tradicional para open source. |
| **Cirrus CI** | Boa opção para projetos open source. |
| **fastlane** | Ferramenta de automação que pode ser integrada com qualquer CI. |
| **Firebase Test Lab** | Para rodar testes de integração em múltiplos dispositivos reais. |

### 4.2 Pipeline básico recomendado

```yaml
# Exemplo conceitual de pipeline CI para Flutter
steps:
  # 1. Análise estática
  - flutter analyze

  # 2. Testes unitários e de widget
  - flutter test

  # 3. Testes de integração (em emulador ou Firebase Test Lab)
  - flutter test integration_test

  # 4. Build para validação
  - flutter build apk --release
  - flutter build ios --release
```

### 4.3 Boas práticas de CI/CD para Flutter

- **Rode `flutter analyze` antes dos testes** para capturar erros estáticos cedo.
- **Separe os estágios:** análise → testes unitários/widget → testes de integração → build.
- **Use caching** para dependências (`pub cache`, Gradle, CocoaPods) para acelerar builds.
- **Rode testes de integração em paralelo** em múltiplos dispositivos via Firebase Test Lab.
- **Gere relatórios de code coverage** com `flutter test --coverage` e monitore a tendência.
- **Falhe rápido:** configure o pipeline para parar na primeira falha.

---

## 5. Comandos de Referência

### 5.1 Executando testes

```bash
# Todos os testes unitários e de widget
flutter test

# Arquivo específico
flutter test test/my_test.dart

# Com coverage
flutter test --coverage

# Testes de integração
flutter test integration_test

# Teste de integração específico
flutter test integration_test/app_test.dart

# Teste de integração para web
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome

# Teste de performance (profile mode)
flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/scrolling_test.dart \
  --profile

# Ajuda sobre opções de teste
flutter test --help
```

### 5.2 Testes nativos de plugin

```bash
# Android (JUnit) — no diretório example/android
./gradlew testDebugUnitTest

# iOS (XCTest) — no diretório example/ios
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug

# macOS (XCTest) — no diretório example/macos
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug

# Linux (GoogleTest) — no diretório example
build/linux/plugins/x64/debug/my_plugin/my_plugin_test

# Windows (GoogleTest) — no diretório example
build/windows/plugins/my_plugin/Debug/my_plugin_test.exe
```

---

## 6. Checklist Geral de Testes

### Para apps Flutter

- [ ] Testes unitários cobrem toda a lógica de negócios.
- [ ] Testes de widget cobrem todos os widgets com interação.
- [ ] Testes de integração cobrem os fluxos críticos do usuário.
- [ ] Dependências externas (plugins, HTTP, DB) são mockadas em testes unitários/widget.
- [ ] Plugins são encapsulados em abstrações próprias para facilitar mocking.
- [ ] CI/CD roda todos os testes automaticamente em cada push.
- [ ] Code coverage é rastreado e mantido acima do threshold definido.

### Para plugins Flutter

- [ ] Testes Dart unitários cobrem a porção Dart com platform channels mockados.
- [ ] Pelo menos um teste de integração para cada chamada de platform channel.
- [ ] Testes nativos unitários cobrem o código nativo com APIs mockadas.
- [ ] Example app compila antes de rodar testes nativos.
- [ ] Testes rodam em todas as plataformas suportadas pelo plugin.
- [ ] Fluxos que requerem UI nativa usam frameworks como Espresso ou XCUITest.

---

## 7. Referência Rápida de Imports

```dart
// Testes unitários em Dart
import 'package:test/test.dart';

// Testes de widget e integração em Flutter
import 'package:flutter_test/flutter_test.dart';

// Binding para testes de integração
import 'package:integration_test/integration_test.dart';

// Driver para testes de integração (web e performance)
import 'package:integration_test/integration_test_driver.dart';

// Timeline para profiling de performance
import 'package:flutter_driver/flutter_driver.dart' as driver;

// Mockito para mocking
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// HTTP client (quando testando chamadas HTTP)
import 'package:http/http.dart' as http;
```

---

*Guia baseado na documentação oficial do Flutter sobre visão geral de testes, plugins em testes e testes de plugins.*
