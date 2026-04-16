# Recomendações e Recursos de Arquitetura

**Recomendações para construir aplicações Flutter escaláveis.**

Esta página apresenta melhores práticas de arquitetura, por que elas importam, e se as recomendamos para sua aplicação Flutter. Você deve tratar essas recomendações como recomendações, e não como regras rígidas, e deve adaptá-las aos requisitos únicos do seu app.

As melhores práticas nesta página possuem uma prioridade, que reflete o quão fortemente o time Flutter as recomenda.

- **Fortemente recomendado:** Você deve sempre implementar esta recomendação se está começando a construir uma nova aplicação. Você deve considerar fortemente refatorar um app existente para implementar esta prática, a menos que isso entre em conflito fundamental com sua abordagem atual.
- **Recomendado:** Esta prática provavelmente melhorará seu app.
- **Condicional:** Esta prática pode melhorar seu app em certas circunstâncias.

---

## Separação de Responsabilidades

Você deve separar seu app em uma camada de UI e uma camada de dados. Dentro dessas camadas, você deve separar ainda mais a lógica em classes por responsabilidade.

### Use camadas de dados e UI claramente definidas

**Fortemente recomendado**

Separação de responsabilidades é o princípio arquitetural mais importante. A camada de dados expõe dados da aplicação para o resto do app, e contém a maior parte da lógica de negócio na sua aplicação. A camada de UI exibe dados da aplicação e ouve eventos de usuários. A camada de UI contém classes separadas para lógica de UI e widgets.

### Use o padrão repository na camada de dados

**Fortemente recomendado**

O padrão repository é um padrão de design de software que isola a lógica de acesso a dados do resto da aplicação. Ele cria uma camada de abstração entre a lógica de negócio da aplicação e os mecanismos de armazenamento de dados subjacentes (bancos de dados, APIs, sistemas de arquivos, etc.). Na prática, isso significa criar classes Repository e classes Service.

### Use ViewModels e Views na camada de UI (MVVM)

**Fortemente recomendado**

Separação de responsabilidades é o princípio arquitetural mais importante. Esta separação em particular torna seu código muito menos propenso a erros porque seus widgets permanecem "burros".

### Use ChangeNotifiers e Listenables para lidar com atualizações de widget

**Condicional**

A API do `ChangeNotifier` faz parte do SDK do Flutter, e é uma forma conveniente de fazer seus widgets observarem mudanças nos seus ViewModels.

Existem muitas opções para lidar com gerenciamento de estado, e em última análise a decisão se resume a preferência pessoal. Leia sobre nossa recomendação de ChangeNotifier ou outras opções populares.

### Não coloque lógica em widgets

**Fortemente recomendado**

Lógica deve ser encapsulada em métodos no ViewModel. A única lógica que uma view deve conter é:

- Instruções if simples para mostrar e ocultar widgets baseados em uma flag ou campo nullable no ViewModel
- Lógica de animação que depende do widget para calcular
- Lógica de layout baseada em informações do dispositivo, como tamanho de tela ou orientação
- Lógica de roteamento simples

### Use uma camada de domínio

**Condicional**

Uma camada de domínio só é necessária se sua aplicação tem lógica excessivamente complexa que sobrecarrega seus ViewModels, ou se você se encontra repetindo lógica em ViewModels. Em apps muito grandes, use-cases são úteis, mas na maioria dos apps eles adicionam overhead desnecessário.

Use em apps com requisitos de lógica complexa.

---

## Tratando Dados

Tratar dados com cuidado torna seu código mais fácil de entender, menos propenso a erros, e previne que dados malformados ou inesperados sejam criados.

### Use fluxo de dados unidirecional

**Fortemente recomendado**

Atualizações de dados devem fluir apenas da camada de dados para a camada de UI. Interações na camada de UI são enviadas para a camada de dados onde são processadas.

### Use Commands para lidar com eventos de interação do usuário

**Recomendado**

Commands previnem erros de renderização no seu app, e padronizam como a camada de UI envia eventos para a camada de dados. Leia sobre commands no caso de estudo de arquitetura.

### Use modelos de dados imutáveis

**Fortemente recomendado**

Dados imutáveis são cruciais para garantir que quaisquer mudanças necessárias ocorram apenas no lugar adequado, geralmente na camada de dados ou domínio. Como objetos imutáveis não podem ser modificados após a criação, você deve criar uma nova instância para refletir mudanças. Este processo previne atualizações acidentais na camada de UI e suporta um fluxo de dados claro e unidirecional.

### Use freezed ou built_value para gerar modelos de dados imutáveis

**Recomendado**

Você pode usar pacotes para ajudar a gerar funcionalidades úteis nos seus modelos de dados, como `freezed` ou `built_value`. Estes podem gerar métodos comuns de modelo como serialização/deserialização JSON, verificação de igualdade profunda e métodos de cópia. Esses pacotes de geração de código podem adicionar tempo significativo de build às suas aplicações se você tiver muitos modelos.

### Crie modelos de API e modelos de domínio separados

**Condicional**

Usar modelos separados adiciona verbosidade, mas previne complexidade em ViewModels e use-cases.

Use em apps grandes.

---

## Estrutura do App

Código bem organizado beneficia tanto a saúde do app em si, quanto o time trabalhando no código.

### Use injeção de dependência

**Fortemente recomendado**

Injeção de dependência previne que seu app tenha objetos globalmente acessíveis, o que torna seu código menos propenso a erros. Recomendamos que você use o pacote `provider` para lidar com injeção de dependência.

### Use go_router para navegação

**Recomendado**

`go_router` é a forma preferida de escrever 90% das aplicações Flutter. Existem alguns casos de uso específicos que go_router não resolve, caso em que você pode usar a API do Flutter Navigator diretamente ou experimentar outros pacotes encontrados no pub.dev.

### Use convenções de nomenclatura padronizadas para classes, arquivos e diretórios

**Recomendado**

Recomendamos nomear classes pelo componente arquitetural que elas representam. Por exemplo, você pode ter as seguintes classes:

- `HomeViewModel`
- `HomeScreen`
- `UserRepository`
- `ClientApiService`

Para clareza, não recomendamos usar nomes que possam ser confundidos com objetos do SDK do Flutter. Por exemplo, você deve colocar seus widgets compartilhados em um diretório chamado `ui/core/`, ao invés de um diretório chamado `/widgets`.

### Use classes de repositório abstratas

**Fortemente recomendado**

Classes de repositório são as fontes de verdade para todos os dados no seu app, e facilitam a comunicação com APIs externas. Criar classes de repositório abstratas permite criar diferentes implementações, que podem ser usadas para diferentes ambientes do app, como "development" e "staging".

---

## Testes

Boas práticas de teste tornam seu app flexível. Também tornam simples e de baixo risco adicionar nova lógica e nova UI.

### Teste componentes arquiteturais separadamente e juntos

**Fortemente recomendado**

- Escreva testes unitários para cada classe de service, repository e ViewModel. Esses testes devem testar a lógica de cada método individualmente.
- Escreva testes de widget para views. Testar roteamento e injeção de dependência são particularmente importantes.

### Crie fakes para testes (e escreva código que tire vantagem de fakes)

**Fortemente recomendado**

Fakes não se preocupam com o funcionamento interno de qualquer método dado tanto quanto se preocupam com entradas e saídas. Se você tem isso em mente ao escrever código da aplicação, você é forçado a escrever funções e classes modulares e leves com entradas e saídas bem definidas.

---

## Recursos Recomendados

### Código e templates

- **Código-fonte do Compass app** — Código-fonte de uma aplicação Flutter completa e robusta que implementa muitas dessas recomendações.
- **very_good_cli** — Um template de aplicação Flutter feito pelos especialistas Flutter da Very Good Ventures. Este template gera uma estrutura de app similar.

### Documentação

- **Documentação de arquitetura Very Good Engineering** — Very Good Engineering é um site de documentação da VGV que possui artigos técnicos, demos e projetos open-source. Inclui documentação sobre arquitetura de aplicações Flutter.

### Ferramentas

- **Flutter developer tools** — DevTools é um conjunto de ferramentas de performance e depuração para Dart e Flutter.
- **flutter_lints** — Um pacote que contém os lints para apps Flutter recomendados pelo time Flutter. Use este pacote para encorajar boas práticas de codificação em um time.


# Padrões de Design de Arquitetura

**Uma coleção de artigos sobre padrões de design úteis para construir aplicações Flutter.**

Se você já leu a página do guia de arquitetura, ou se está confortável com Flutter e o padrão MVVM, os artigos a seguir são para você.

Estes artigos não são sobre arquitetura de app de alto nível, mas sim sobre resolver problemas de design específicos que melhoram a base de código da sua aplicação, independentemente de como você arquitetou seu app. Dito isso, os artigos assumem o padrão MVVM apresentado nas páginas anteriores nos exemplos de código.

---

## Estado Otimista

# Estado Otimista

**Melhore a percepção de responsividade de uma aplicação implementando estado otimista.**

Ao construir experiências de usuário, a percepção de performance é por vezes tão importante quanto a performance real do código. Em geral, os usuários não gostam de esperar que uma ação termine para ver o resultado, e qualquer coisa que leve mais do que alguns milissegundos pode ser considerada "lenta" ou "sem resposta" na perspectiva do usuário.

Desenvolvedores podem ajudar a mitigar essa percepção negativa apresentando um estado de UI bem-sucedido antes que a tarefa em segundo plano seja totalmente concluída. Um exemplo disso seria tocar em um botão "Inscrever-se" e vê-lo mudar para "Inscrito" instantaneamente, mesmo que a chamada em segundo plano para a API de inscrição ainda esteja executando.

Essa técnica é conhecida como Estado Otimista, UI Otimista ou Experiência de Usuário Otimista. Nesta receita, você implementará uma funcionalidade de aplicação usando Estado Otimista e seguindo as diretrizes de arquitetura Flutter.

---

## Funcionalidade de Exemplo: Um Botão de Inscrição

Este exemplo implementa um botão de inscrição similar ao que você poderia encontrar em uma aplicação de streaming de vídeo ou uma newsletter.

Quando o botão é tocado, a aplicação então chama uma API externa, realizando uma ação de inscrição, por exemplo gravando em um banco de dados que o usuário agora está na lista de inscrição. Para fins de demonstração, você não implementará o código backend real, ao invés disso substituirá essa chamada por uma ação fake que simulará uma requisição de rede.

No caso de a chamada ser bem-sucedida, o texto do botão mudará de "Subscribe" para "Subscribed". A cor de fundo do botão também mudará.

Pelo contrário, se a chamada falhar, o texto do botão deve reverter para "Subscribe", e a UI deve mostrar uma mensagem de erro ao usuário, por exemplo usando um Snackbar.

Seguindo a ideia de Estado Otimista, o botão deve mudar instantaneamente para "Subscribed" assim que for tocado, e só mudar de volta para "Subscribe" se a requisição falhar.

---

## Arquitetura da Funcionalidade

Comece definindo a arquitetura da funcionalidade. Seguindo as diretrizes de arquitetura, crie estas classes Dart em um projeto Flutter:

- Um `StatefulWidget` chamado `SubscribeButton`
- Uma classe chamada `SubscribeButtonViewModel` estendendo `ChangeNotifier`
- Uma classe chamada `SubscriptionRepository`

O widget `SubscribeButton` e o `SubscribeButtonViewModel` representam a camada de apresentação desta solução. O widget vai exibir um botão que mostrará o texto "Subscribe" ou "Subscribed" dependendo do estado da inscrição. O view model conterá o estado da inscrição. Quando o botão for tocado, o widget chamará o view model para realizar a ação.

O `SubscriptionRepository` implementará um método subscribe que lançará uma exceção quando a ação falhar. O view model chamará este método ao realizar a ação de inscrição.

```dart
class SubscribeButton extends StatefulWidget {
  const SubscribeButton({super.key});

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class SubscribeButtonViewModel extends ChangeNotifier {}

class SubscriptionRepository {}
```

Em seguida, conecte-os adicionando o `SubscriptionRepository` ao `SubscribeButtonViewModel`:

```dart
class SubscribeButtonViewModel extends ChangeNotifier {
  SubscribeButtonViewModel({required this.subscriptionRepository});

  final SubscriptionRepository subscriptionRepository;
}
```

E adicione o `SubscribeButtonViewModel` ao widget `SubscribeButton`:

```dart
class SubscribeButton extends StatefulWidget {
  const SubscribeButton({super.key, required this.viewModel});

  /// View model do botão de inscrição.
  final SubscribeButtonViewModel viewModel;

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}
```

Agora que você criou a arquitetura básica da solução, pode criar o widget `SubscribeButton` da seguinte forma:

```dart
SubscribeButton(
  viewModel: SubscribeButtonViewModel(
    subscriptionRepository: SubscriptionRepository(),
  ),
)
```

---

## Implementar o SubscriptionRepository

Adicione um novo método assíncrono chamado `subscribe()` ao `SubscriptionRepository` com o seguinte código:

```dart
class SubscriptionRepository {
  /// Simula uma requisição de rede e então falha.
  Future<void> subscribe() async {
    // Simula uma requisição de rede
    await Future.delayed(const Duration(seconds: 1));
    // Falha após um segundo
    throw Exception('Failed to subscribe');
  }
}
```

A chamada a `await Future.delayed()` com duração de um segundo foi adicionada para simular uma requisição de longa duração. A execução do método pausará por um segundo, e então continuará executando.

Para simular uma requisição falhando, o método subscribe lança uma exceção no final. Isso será usado mais adiante para mostrar como se recuperar de uma requisição falha ao implementar Estado Otimista.

---

## Implementar o SubscribeButtonViewModel

Para representar o estado da inscrição, bem como um possível estado de erro, adicione os seguintes membros públicos ao `SubscribeButtonViewModel`:

```dart
// Se o usuário está inscrito
bool subscribed = false;

// Se a ação de inscrição falhou
bool error = false;
```

Ambos são definidos como `false` no início.

Seguindo as ideias de Estado Otimista, o estado `subscribed` mudará para `true` assim que o usuário tocar no botão de inscrição. E só mudará de volta para `false` se a ação falhar.

O estado `error` mudará para `true` quando a ação falhar, indicando ao widget `SubscribeButton` para mostrar uma mensagem de erro ao usuário. A variável deve voltar para `false` assim que o erro for exibido.

Em seguida, implemente um método assíncrono `subscribe()`:

```dart
// Ação de inscrição
Future<void> subscribe() async {
  // Ignora toques quando inscrito
  if (subscribed) {
    return;
  }

  // Estado otimista.
  // Será revertido se a inscrição falhar.
  subscribed = true;

  // Notifica listeners para atualizar a UI
  notifyListeners();

  try {
    await subscriptionRepository.subscribe();
  } catch (e) {
    print('Failed to subscribe: $e');
    // Reverte para o estado anterior
    subscribed = false;
    // Define o estado de erro
    error = true;
  } finally {
    notifyListeners();
  }
}
```

Conforme descrito anteriormente, primeiro o método define o estado `subscribed` como `true` e então chama `notifyListeners()`. Isso força a UI a atualizar e o botão muda sua aparência, mostrando o texto "Subscribed" ao usuário.

Então o método realiza a chamada real ao repositório. Essa chamada é envolvida por um try-catch para capturar quaisquer exceções que possa lançar. Caso uma exceção seja capturada, o estado `subscribed` é definido de volta para `false`, e o estado `error` é definido como `true`. Uma chamada final a `notifyListeners()` é feita para mudar a UI de volta para 'Subscribe'.

Se não houver exceção, o processo está completo porque a UI já está refletindo o estado de sucesso.

O `SubscribeButtonViewModel` completo deve ficar assim:

```dart
/// View Model do botão de inscrição.
/// Trata a ação de inscrição e expõe o estado da inscrição.
class SubscribeButtonViewModel extends ChangeNotifier {
  SubscribeButtonViewModel({required this.subscriptionRepository});

  final SubscriptionRepository subscriptionRepository;

  // Se o usuário está inscrito
  bool subscribed = false;

  // Se a ação de inscrição falhou
  bool error = false;

  // Ação de inscrição
  Future<void> subscribe() async {
    // Ignora toques quando inscrito
    if (subscribed) {
      return;
    }

    // Estado otimista.
    // Será revertido se a inscrição falhar.
    subscribed = true;

    // Notifica listeners para atualizar a UI
    notifyListeners();

    try {
      await subscriptionRepository.subscribe();
    } catch (e) {
      print('Failed to subscribe: $e');
      // Reverte para o estado anterior
      subscribed = false;
      // Define o estado de erro
      error = true;
    } finally {
      notifyListeners();
    }
  }
}
```

---

## Implementar o SubscribeButton

Neste passo, você primeiro implementará o método build do `SubscribeButton`, e então implementará o tratamento de erros da funcionalidade.

Adicione o seguinte código ao método build:

```dart
@override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      return FilledButton(
        onPressed: widget.viewModel.subscribe,
        style: widget.viewModel.subscribed
            ? SubscribeButtonStyle.subscribed
            : SubscribeButtonStyle.unsubscribed,
        child: widget.viewModel.subscribed
            ? const Text('Subscribed')
            : const Text('Subscribe'),
      );
    },
  );
}
```

Este método build contém um `ListenableBuilder` que ouve mudanças do view model. O builder então cria um `FilledButton` que exibirá o texto "Subscribed" ou "Subscribe" dependendo do estado do view model. O estilo do botão também mudará dependendo deste estado. Além disso, quando o botão é tocado, ele executa o método `subscribe()` do view model.

O `SubscribeButtonStyle` pode ser encontrado aqui. Adicione esta classe junto ao `SubscribeButton`. Sinta-se livre para modificar o `ButtonStyle`.

```dart
class SubscribeButtonStyle {
  static const unsubscribed = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.red),
  );
  static const subscribed = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.green),
  );
}
```

Se você executar a aplicação agora, verá como o botão muda quando você o pressiona, porém ele mudará de volta ao estado original sem mostrar um erro.

---

## Tratando Erros

Para tratar erros, adicione os métodos `initState()` e `dispose()` ao `SubscribeButtonState`, e então adicione o método `_onViewModelChange()`.

```dart
@override
void initState() {
  super.initState();
  widget.viewModel.addListener(_onViewModelChange);
}

@override
void dispose() {
  widget.viewModel.removeListener(_onViewModelChange);
  super.dispose();
}
```

```dart
/// Ouve mudanças no ViewModel.
void _onViewModelChange() {
  // Se a ação de inscrição falhou
  if (widget.viewModel.error) {
    // Reseta o estado de erro
    widget.viewModel.error = false;
    // Mostra uma mensagem de erro
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to subscribe')));
  }
}
```

A chamada `addListener()` registra o método `_onViewModelChange()` para ser chamado quando o view model notifica os listeners. É importante chamar `removeListener()` quando o widget é descartado, para evitar erros.

O método `_onViewModelChange()` verifica o estado `error`, e se for `true`, exibe um Snackbar ao usuário mostrando uma mensagem de erro. Além disso, o estado `error` é definido de volta para `false`, para evitar exibir a mensagem de erro múltiplas vezes se `notifyListeners()` for chamado novamente no view model.

---

## Estado Otimista Avançado

Neste tutorial, você aprendeu como implementar um Estado Otimista com um único estado binário, mas você pode usar essa técnica para criar uma solução mais avançada incorporando um terceiro estado temporal que indica que a ação ainda está executando.

Por exemplo, em uma aplicação de chat quando o usuário envia uma nova mensagem, a aplicação exibirá a nova mensagem de chat na janela de conversa, mas com um ícone indicando que a mensagem ainda está pendente de entrega. Quando a mensagem é entregue, esse ícone seria removido.

No exemplo do botão de inscrição, você poderia adicionar outra flag no view model indicando que o método `subscribe()` ainda está executando, ou usar o estado running do padrão Command, então modificar o estilo do botão levemente para mostrar que a operação está em andamento.

---

## Exemplo Interativo

Este exemplo mostra o widget `SubscribeButton` junto com o `SubscribeButtonViewModel` e o `SubscriptionRepository`, que implementam uma ação de toque de inscrição com Estado Otimista.

Quando você toca no botão, o texto do botão muda de "Subscribe" para "Subscribed". Após um segundo, o repositório lança uma exceção, que é capturada pelo view model, e o botão reverte para mostrar "Subscribe", enquanto também exibe um Snackbar com uma mensagem de erro.

## Arquitetura de Armazenamento Persistente: Dados Chave-Valor

**Tags:** dados | shared-preferences | modo escuro

**Salve dados da aplicação no armazenamento chave-valor no dispositivo do usuário.**
# Arquitetura de Armazenamento Persistente: Dados Chave-Valor

**Salve dados da aplicação no armazenamento chave-valor no dispositivo do usuário.**

A maioria das aplicações Flutter, não importa quão pequenas ou grandes sejam, requerem armazenar dados no dispositivo do usuário em algum momento, como chaves de API, preferências do usuário ou dados que devem estar disponíveis offline.

Nesta receita, você aprenderá como integrar armazenamento persistente para dados chave-valor em uma aplicação Flutter que usa o design de arquitetura Flutter recomendado. Se você não está familiarizado com armazenamento de dados em disco, pode ler a receita "Armazenar dados chave-valor em disco".

Armazenamentos chave-valor são frequentemente usados para salvar dados simples, como configuração do app, e nesta receita você o usará para salvar preferências de Modo Escuro. Se você quiser aprender como armazenar dados complexos em um dispositivo, provavelmente vai querer usar SQL. Nesse caso, veja a receita do cookbook que segue esta chamada Persistent storage architecture: SQL.

---

## Aplicação de Exemplo: App com Seleção de Tema

A aplicação de exemplo consiste em uma única tela com uma app bar no topo, uma lista de itens e um campo de texto de entrada na parte inferior.

Na `AppBar`, um `Switch` permite que os usuários alternem entre os modos de tema escuro e claro. Essa configuração é aplicada imediatamente e armazenada no dispositivo usando um serviço de armazenamento de dados chave-valor. A configuração é restaurada quando o usuário inicia a aplicação novamente.

> **Nota:** O código-fonte completo e executável para este exemplo está disponível em `/examples/app-architecture/todo_data_service/`.

---

## Armazenando Dados Chave-Valor da Seleção de Tema

Esta funcionalidade segue o padrão de design de arquitetura Flutter recomendado, com uma camada de apresentação e uma camada de dados.

- A camada de apresentação contém o widget `ThemeSwitch` e o `ThemeSwitchViewModel`.
- A camada de dados contém o `ThemeRepository` e o `SharedPreferencesService`.

---

## Camada de Apresentação da Seleção de Tema

O `ThemeSwitch` é um `StatelessWidget` que contém um widget `Switch`. O estado do switch é representado pelo campo público `isDarkMode` no `ThemeSwitchViewModel`. Quando o usuário toca no switch, o código executa o comando toggle no view model.

```dart
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key, required this.viewmodel});

  final ThemeSwitchViewModel viewmodel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Dark Mode'),
          ListenableBuilder(
            listenable: viewmodel,
            builder: (context, _) {
              return Switch(
                value: viewmodel.isDarkMode,
                onChanged: (_) {
                  viewmodel.toggle.execute();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
```

O `ThemeSwitchViewModel` implementa um view model conforme descrito no padrão MVVM. Este view model contém o estado do widget `ThemeSwitch`, representado pela variável booleana `_isDarkMode`. O view model usa o `ThemeRepository` para armazenar e carregar a configuração de modo escuro.

Ele contém duas ações de comando diferentes: `load`, que carrega a configuração de modo escuro do repositório, e `toggle`, que alterna o estado entre modo escuro e modo claro. Ele expõe o estado através do getter `isDarkMode`.

```dart
class ThemeSwitchViewModel extends ChangeNotifier {
  ThemeSwitchViewModel(this._themeRepository) {
    load = Command0(_load)..execute();
    toggle = Command0(_toggle);
  }

  final ThemeRepository _themeRepository;

  bool _isDarkMode = false;

  /// Se true, mostra modo escuro
  bool get isDarkMode => _isDarkMode;

  late final Command0<void> load;
  late final Command0<void> toggle;

  /// Carrega a configuração de tema atual do repositório
  Future<Result<void>> _load() async {
    final result = await _themeRepository.isDarkMode();
    if (result is Ok<bool>) {
      _isDarkMode = result.value;
    }
    notifyListeners();
    return result;
  }

  /// Alterna a configuração de tema
  Future<Result<void>> _toggle() async {
    _isDarkMode = !_isDarkMode;
    final result = await _themeRepository.setDarkMode(_isDarkMode);
    notifyListeners();
    return result;
  }
}
```

O método `_load` implementa o comando load. Este método chama `ThemeRepository.isDarkMode` para obter a configuração armazenada e chama `notifyListeners()` para atualizar a UI.

O método `_toggle` implementa o comando toggle. Este método chama `ThemeRepository.setDarkMode` para armazenar a nova configuração de modo escuro. Além disso, ele muda o estado local de `_isDarkMode` e então chama `notifyListeners()` para atualizar a UI.

---

## Camada de Dados da Seleção de Tema

Seguindo as diretrizes de arquitetura, a camada de dados é dividida em duas partes: o `ThemeRepository` e o `SharedPreferencesService`.

O `ThemeRepository` é a fonte única de verdade para todas as configurações de tema, e trata quaisquer erros possíveis vindos da camada de serviço.

Neste exemplo, o `ThemeRepository` também expõe a configuração de modo escuro através de um `Stream` observável. Isso permite que outras partes da aplicação se inscrevam em mudanças na configuração de modo escuro.

O `ThemeRepository` depende do `SharedPreferencesService`. O repositório obtém o valor armazenado do serviço, e o armazena quando ele muda.

```dart
class ThemeRepository {
  ThemeRepository(this._service);

  final _darkModeController = StreamController<bool>.broadcast();
  final SharedPreferencesService _service;

  /// Obtém se o modo escuro está habilitado
  Future<Result<bool>> isDarkMode() async {
    try {
      final value = await _service.isDarkMode();
      return Result.ok(value);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Define o modo escuro
  Future<Result<void>> setDarkMode(bool value) async {
    try {
      await _service.setDarkMode(value);
      _darkModeController.add(value);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Stream que emite mudanças na configuração de tema.
  /// ViewModels devem chamar [isDarkMode] para obter a configuração de tema atual.
  Stream<bool> observeDarkMode() => _darkModeController.stream;
}
```

O método `setDarkMode()` passa o novo valor para o `StreamController`, para que qualquer componente ouvindo o stream `observeDarkMode` seja notificado.

O `SharedPreferencesService` encapsula a funcionalidade do plugin SharedPreferences, e chama os métodos `setBool()` e `getBool()` para armazenar a configuração de modo escuro, escondendo essa dependência de terceiros do resto da aplicação.

```dart
class SharedPreferencesService {
  static const String _kDarkMode = 'darkMode';

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDarkMode) ?? false;
  }
}
```

> **Nota:** Uma dependência de terceiros é uma forma de se referir a pacotes e plugins desenvolvidos por outros programadores fora da sua organização.

---

## Juntando Tudo

No método `main()` da sua aplicação, primeiro inicialize o `ThemeRepository` e o `SharedPreferencesService`, e passe-os para o `MainApp` como argumento de construtor.

```dart
void main() {
  // ···
  runApp(
    MainApp(
      themeRepository: ThemeRepository(SharedPreferencesService()),
      // ···
    ),
  );
}
```

Então, quando o `ThemeSwitch` for criado, também crie o `ThemeSwitchViewModel` e passe o `ThemeRepository` como dependência.

```dart
ThemeSwitch(
  viewmodel: ThemeSwitchViewModel(widget.themeRepository),
),
```

A aplicação de exemplo também inclui a classe `MainAppViewModel`, que ouve mudanças no `ThemeRepository` e expõe a configuração de modo escuro para o widget `MaterialApp`.

```dart
class MainAppViewModel extends ChangeNotifier {
  MainAppViewModel(this._themeRepository) {
    _subscription = _themeRepository.observeDarkMode().listen((isDarkMode) {
      _isDarkMode = isDarkMode;
      notifyListeners();
    });
    _load();
  }

  final ThemeRepository _themeRepository;
  StreamSubscription<bool>? _subscription;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> _load() async {
    final result = await _themeRepository.isDarkMode();
    if (result is Ok<bool>) {
      _isDarkMode = result.value;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

```dart
ListenableBuilder(
  listenable: _viewModel,
  builder: (context, child) {
    return MaterialApp(
      theme: _viewModel.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: child,
    );
  },
  child: //...
)
```

## Arquitetura de Armazenamento Persistente: SQL

# Arquitetura de Armazenamento Persistente: SQL

**Salve dados complexos da aplicação no dispositivo do usuário com SQL.**

A maioria das aplicações Flutter, não importa quão pequenas ou grandes sejam, pode precisar armazenar dados no dispositivo do usuário em algum momento. Por exemplo, chaves de API, preferências do usuário ou dados que devem estar disponíveis offline.

Nesta receita, você aprenderá como integrar armazenamento persistente para dados complexos usando SQL em uma aplicação Flutter seguindo o padrão de design de Arquitetura Flutter.

Para aprender como armazenar dados mais simples do tipo chave-valor, veja a receita do Cookbook: Persistent storage architecture: Key-value data.

Para ler esta receita, você deve estar familiarizado com SQL e SQLite. Se precisar de ajuda, pode ler a receita "Persist data with SQLite" antes de ler esta.

Este exemplo usa sqflite com o plugin `sqflite_common_ffi`, que combinados suportam mobile e desktop. O suporte para web é fornecido no plugin experimental `sqflite_common_ffi_web`, mas não está incluído neste exemplo.

---

## Aplicação de Exemplo: Aplicação ToDo List

A aplicação de exemplo consiste em uma única tela com uma app bar no topo, uma lista de itens e um campo de texto de entrada na parte inferior.

O corpo da aplicação contém o `TodoListScreen`. Esta tela contém uma `ListView` de itens `ListTile`, cada um representando um item ToDo. Na parte inferior, um `TextField` permite que os usuários criem novos itens ToDo escrevendo a descrição da tarefa e então tocando no `FilledButton` "Add".

Os usuários podem tocar no `IconButton` de deletar para excluir o item ToDo.

A lista de itens ToDo é armazenada localmente usando um serviço de banco de dados, e restaurada quando o usuário inicia a aplicação.

> **Nota:** O código-fonte completo e executável para este exemplo está disponível em `/examples/app-architecture/todo_data_service/`.

---

## Armazenando Dados Complexos com SQL

Esta funcionalidade segue o design de Arquitetura Flutter recomendado, contendo uma camada de UI e uma camada de dados. Adicionalmente, na camada de domínio você encontrará o modelo de dados utilizado.

- Camada de UI com `TodoListScreen` e `TodoListViewModel`
- Camada de domínio com classe de dados `Todo`
- Camada de dados com `TodoRepository` e `DatabaseService`

---

## Camada de Apresentação do ToDo List

O `TodoListScreen` é um Widget que contém a UI responsável por exibir e criar os itens ToDo. Ele segue o padrão MVVM e é acompanhado pelo `TodoListViewModel`, que contém a lista de itens ToDo e três comandos para carregar, adicionar e deletar itens ToDo.

Esta tela é dividida em duas partes, uma contendo a lista de itens ToDo, implementada usando uma `ListView`, e a outra é um `TextField` e um `Button`, usados para criar novos itens ToDo.

A `ListView` é envolvida por um `ListenableBuilder`, que ouve mudanças no `TodoListViewModel`, e mostra um `ListTile` para cada item ToDo.

```dart
ListenableBuilder(
  listenable: widget.viewModel,
  builder: (context, child) {
    return ListView.builder(
      itemCount: widget.viewModel.todos.length,
      itemBuilder: (context, index) {
        final todo = widget.viewModel.todos[index];
        return ListTile(
          title: Text(todo.task),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => widget.viewModel.delete.execute(todo.id),
          ),
        );
      },
    );
  },
)
```

A lista de itens ToDo é definida no `TodoListViewModel`, e carregada pelo comando `load`. Este método chama o `TodoRepository` e busca a lista de itens ToDo.

```dart
List<Todo> _todos = [];
List<Todo> get todos => _todos;

Future<Result<void>> _load() async {
  try {
    final result = await _todoRepository.fetchTodos();
    switch (result) {
      case Ok<List<Todo>>():
        _todos = result.value;
        return Result.ok(null);
      case Error():
        return Result.error(result.error);
    }
  } on Exception catch (e) {
    return Result.error(e);
  } finally {
    notifyListeners();
  }
}
```

Pressionar o `FilledButton` executa o comando add e passa o valor do text controller.

```dart
FilledButton.icon(
  onPressed: () =>
      widget.viewModel.add.execute(_controller.text),
  label: const Text('Add'),
  icon: const Icon(Icons.add),
)
```

O comando add então chama o método `TodoRepository.createTodo()` com o texto de descrição da tarefa e cria um novo item ToDo. O método `createTodo()` retorna o ToDo recém-criado, que é então adicionado à lista `_todos` no view model.

Itens ToDo contêm um identificador único gerado pelo banco de dados. É por isso que o view model não cria o item ToDo, mas sim o `TodoRepository`.

```dart
Future<Result<void>> _add(String task) async {
  try {
    final result = await _todoRepository.createTodo(task);
    switch (result) {
      case Ok<Todo>():
        _todos.add(result.value);
        return Result.ok(null);
      case Error():
        return Result.error(result.error);
    }
  } on Exception catch (e) {
    return Result.error(e);
  } finally {
    notifyListeners();
  }
}
```

Finalmente, o `TodoListScreen` também ouve o resultado no comando add. Quando a ação completa, o `TextEditingController` é limpo.

```dart
void _onAdd() {
  // Limpa o campo de texto quando o comando add completa.
  if (widget.viewModel.add.completed) {
    widget.viewModel.add.clearResult();
    _controller.clear();
  }
}
```

Quando um usuário toca no `IconButton` no `ListTile`, o comando delete é executado.

```dart
IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () => widget.viewModel.delete.execute(todo.id),
)
```

Então, o view model chama o método `TodoRepository.deleteTodo()`, passando o identificador único do item ToDo. Um resultado correto remove o item ToDo do view model e da tela.

```dart
Future<Result<void>> _delete(int id) async {
  try {
    final result = await _todoRepository.deleteTodo(id);
    switch (result) {
      case Ok<void>():
        _todos.removeWhere((todo) => todo.id == id);
        return Result.ok(null);
      case Error():
        return Result.error(result.error);
    }
  } on Exception catch (e) {
    return Result.error(e);
  } finally {
    notifyListeners();
  }
}
```

---

## Camada de Domínio do Todo List

A camada de domínio desta aplicação de exemplo contém o modelo de dados do item Todo.

Itens são representados por uma classe de dados imutável. Neste caso, a aplicação usa o pacote freezed para gerar o código.

A classe tem duas propriedades, um ID representado por um `int`, e uma descrição de tarefa, representada por uma `String`.

```dart
@freezed
abstract class Todo with _$Todo {
  const factory Todo({
    /// O identificador único do item Todo.
    required int id,

    /// A descrição da tarefa do item Todo.
    required String task,
  }) = _Todo;
}
```

---

## Camada de Dados do Todo List

A camada de dados desta funcionalidade é composta por duas classes, o `TodoRepository` e o `DatabaseService`.

O `TodoRepository` atua como a fonte de verdade para todos os itens ToDo. View models devem usar este repositório para acessar a lista de ToDo, e ele não deve expor nenhum detalhe de implementação sobre como eles são armazenados.

Internamente, o `TodoRepository` usa o `DatabaseService`, que implementa o acesso ao banco de dados SQL usando o pacote sqflite. Você pode implementar o mesmo `DatabaseService` usando outros pacotes de armazenamento como `sqlite3`, `drift` ou até soluções de armazenamento em nuvem como `firebase_database`.

O `TodoRepository` verifica se o banco de dados está aberto antes de cada requisição e o abre se necessário.

Ele implementa os métodos `fetchTodos()`, `createTodo()` e `deleteTodo()`.

```dart
class TodoRepository {
  TodoRepository({required DatabaseService database}) : _database = database;

  final DatabaseService _database;

  Future<Result<List<Todo>>> fetchTodos() async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.getAll();
  }

  Future<Result<Todo>> createTodo(String task) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.insert(task);
  }

  Future<Result<void>> deleteTodo(int id) async {
    if (!_database.isOpen()) {
      await _database.open();
    }
    return _database.delete(id);
  }
}
```

O `DatabaseService` implementa o acesso ao banco de dados SQLite usando o pacote sqflite.

É uma boa ideia definir os nomes de tabelas e colunas como constantes para evitar erros de digitação ao escrever código SQL.

```dart
static const String _todoTableName = 'todo';
static const String _idColumnName = '_id';
static const String _taskColumnName = 'task';
```

O método `open()` abre o banco de dados existente, ou cria um novo se não existir.

```dart
Future<void> open() async {
  _database = await databaseFactory.openDatabase(
    join(await databaseFactory.getDatabasesPath(), 'app_database.db'),
    options: OpenDatabaseOptions(
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $_todoTableName($_idColumnName INTEGER PRIMARY KEY AUTOINCREMENT, $_taskColumnName TEXT)',
        );
      },
      version: 1,
    ),
  );
}
```

Note que a coluna id é definida como primary key e autoincrement; isso significa que cada item recém-inserido recebe um novo valor para a coluna id.

O método `insert()` cria um novo item ToDo no banco de dados, e retorna uma instância de Todo recém-criada. O id é gerado conforme mencionado antes.

Todas as operações do `DatabaseService` usam a classe `Result` para retornar um valor, conforme recomendado pelas recomendações de arquitetura Flutter. Isso facilita o tratamento de erros em passos posteriores no código da aplicação.

```dart
Future<Result<Todo>> insert(String task) async {
  try {
    final id = await _database!.insert(_todoTableName, {
      _taskColumnName: task,
    });
    return Result.ok(Todo(id: id, task: task));
  } on Exception catch (e) {
    return Result.error(e);
  }
}
```

O método `getAll()` realiza uma consulta ao banco de dados, obtendo todos os valores nas colunas id e task. Para cada entrada, ele cria uma instância da classe `Todo`.

```dart
Future<Result<List<Todo>>> getAll() async {
  try {
    final entries = await _database!.query(
      _todoTableName,
      columns: [_idColumnName, _taskColumnName],
    );
    final list = entries
        .map(
          (element) => Todo(
            id: element[_idColumnName] as int,
            task: element[_taskColumnName] as String,
          ),
        )
        .toList();
    return Result.ok(list);
  } on Exception catch (e) {
    return Result.error(e);
  }
}
```

O método `delete()` realiza uma operação de delete no banco de dados baseado no id do item ToDo.

Neste caso, se nenhum item foi deletado, um erro é retornado, indicando que algo deu errado.

```dart
Future<Result<void>> delete(int id) async {
  try {
    final rowsDeleted = await _database!.delete(
      _todoTableName,
      where: '$_idColumnName = ?',
      whereArgs: [id],
    );
    if (rowsDeleted == 0) {
      return Result.error(Exception('No todo found with id $id'));
    }
    return Result.ok(null);
  } on Exception catch (e) {
    return Result.error(e);
  }
}
```

> **Nota:** Em alguns casos, você pode querer fechar o banco de dados quando terminar de usá-lo. Por exemplo, quando o usuário sai da tela, ou após um certo tempo. Isso depende da implementação do banco de dados, bem como dos requisitos da sua aplicação. É recomendado verificar com os autores do pacote de banco de dados por recomendações.

---

## Juntando Tudo

No método `main()` da sua aplicação, primeiro inicialize o `DatabaseService`, que requer código de inicialização diferente em diferentes plataformas. Então, passe o `DatabaseService` recém-criado para o `TodoRepository`, que é ele mesmo passado para o `MainApp` como argumento de construtor.

```dart
void main() {
  late DatabaseService databaseService;

  if (kIsWeb) {
    throw UnsupportedError('Platform not supported');
  } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    // Inicializa FFI SQLite
    sqfliteFfiInit();
    databaseService = DatabaseService(databaseFactory: databaseFactoryFfi);
  } else {
    // Usa SQLite nativo padrão
    databaseService = DatabaseService(databaseFactory: databaseFactory);
  }

  runApp(
    MainApp(
      // ···
      todoRepository: TodoRepository(database: databaseService),
    ),
  );
}
```

Então, quando o `TodoListScreen` for criado, também crie o `TodoListViewModel` e passe o `TodoRepository` como dependência.

```dart
TodoListScreen(
  viewModel: TodoListViewModel(todoRepository: widget.todoRepository),
)
```

## Suporte Offline-First

**Tags:** dados | experiência do usuário | padrão repository

**Implemente suporte offline-first para uma funcionalidade em uma aplicação.**

# Suporte Offline-First

**Implemente suporte offline-first para uma funcionalidade em uma aplicação.**

Uma aplicação offline-first é um app capaz de oferecer a maioria ou todas as suas funcionalidades enquanto está desconectado da internet. Aplicações offline-first geralmente dependem de dados armazenados para oferecer aos usuários acesso temporário a dados que, de outra forma, só estariam disponíveis online.

Algumas aplicações offline-first combinam dados locais e remotos de forma integrada, enquanto outras informam o usuário quando a aplicação está usando dados em cache. Da mesma forma, algumas aplicações sincronizam dados em segundo plano enquanto outras exigem que o usuário sincronize explicitamente. Tudo depende dos requisitos da aplicação e da funcionalidade que ela oferece, e cabe ao desenvolvedor decidir qual implementação atende às suas necessidades.

Neste guia, você aprenderá como implementar diferentes abordagens para aplicações offline-first no Flutter, seguindo as diretrizes de Arquitetura Flutter.

---

## Arquitetura Offline-First

Conforme explicado no guia de conceitos comuns de arquitetura, repositórios atuam como a fonte única de verdade. Eles são responsáveis por apresentar dados locais ou remotos, e devem ser o único lugar onde os dados podem ser modificados. Em aplicações offline-first, repositórios combinam diferentes fontes de dados locais e remotas para apresentar dados em um único ponto de acesso, independentemente do estado de conectividade do dispositivo.

Este exemplo usa o `UserProfileRepository`, um repositório que permite obter e armazenar objetos `UserProfile` com suporte offline-first.

O `UserProfileRepository` usa dois serviços de dados diferentes: um trabalha com dados remotos, e o outro trabalha com um banco de dados local.

O cliente de API, `ApiClientService`, conecta-se a um serviço remoto usando chamadas HTTP REST.

O serviço de banco de dados, `DatabaseService`, armazena dados usando SQL, similar ao encontrado na receita Persistent Storage Architecture: SQL.

```dart
class ApiClientService {
  /// realiza requisição GET de rede para obter um UserProfile
  Future<UserProfile> getUserProfile() async {
    // ···
  }

  /// realiza requisição PUT de rede para atualizar um UserProfile
  Future<void> putUserProfile(UserProfile userProfile) async {
    // ···
  }
}
```

```dart
class DatabaseService {
  /// Busca o UserProfile do banco de dados.
  /// Retorna null se o perfil do usuário não for encontrado.
  Future<UserProfile?> fetchUserProfile() async {
    // ···
  }

  /// Atualiza o UserProfile no banco de dados.
  Future<void> updateUserProfile(UserProfile userProfile) async {
    // ···
  }
}
```

Este exemplo também usa a classe de dados `UserProfile` que foi criada usando o pacote freezed.

```dart
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String photoUrl,
  }) = _UserProfile;
}
```

Em apps que possuem dados complexos, como quando os dados remotos contêm mais campos do que o necessário pela UI, você pode querer ter uma classe de dados para os serviços de API e banco de dados, e outra para a UI. Por exemplo, `UserProfileLocal` para a entidade do banco de dados, `UserProfileRemote` para o objeto de resposta da API, e então `UserProfile` para a classe de modelo de dados da UI. O `UserProfileRepository` se encarregaria de converter de um para o outro quando necessário.

Este exemplo também inclui o `UserProfileViewModel`, um view model que usa o `UserProfileRepository` para exibir o `UserProfile` em um widget.

```dart
class UserProfileViewModel extends ChangeNotifier {
  // ···
  final UserProfileRepository _userProfileRepository;

  UserProfile? get userProfile => _userProfile;
  // ···

  /// Carrega o perfil do usuário do banco de dados ou da rede
  Future<void> load() async {
    // ···
  }

  /// Salva o perfil do usuário com o novo nome
  Future<void> save(String newName) async {
    // ···
  }
}
```

---

## Lendo Dados

Ler dados é uma parte fundamental de qualquer aplicação que depende de serviços de API remotos.

Em aplicações offline-first, você quer garantir que o acesso a esses dados seja o mais rápido possível, e que não dependa do dispositivo estar online para fornecer dados ao usuário. Isso é similar ao padrão de design Optimistic State.

Nesta seção, você aprenderá duas abordagens diferentes, uma que usa o banco de dados como fallback, e outra que combina dados locais e remotos usando um `Stream`.

### Usando dados locais como fallback

Como primeira abordagem, você pode implementar suporte offline tendo um mecanismo de fallback para quando o usuário estiver offline ou uma chamada de rede falhar.

Neste caso, o `UserProfileRepository` tenta obter o `UserProfile` do servidor de API remoto usando o `ApiClientService`. Se essa requisição falhar, então retorna o `UserProfile` armazenado localmente do `DatabaseService`.

```dart
Future<UserProfile> getUserProfile() async {
  try {
    // Busca o perfil do usuário da API
    final apiUserProfile = await _apiClientService.getUserProfile();
    // Atualiza o banco de dados com o resultado da API
    await _databaseService.updateUserProfile(apiUserProfile);
    return apiUserProfile;
  } catch (e) {
    // Se a chamada de rede falhou,
    // busca o perfil do usuário do banco de dados
    final databaseUserProfile = await _databaseService.fetchUserProfile();
    // Se o perfil do usuário nunca foi buscado da API
    // será null, então lança um erro
    if (databaseUserProfile != null) {
      return databaseUserProfile;
    } else {
      // Trata o erro
      throw Exception('User profile not found');
    }
  }
}
```

### Usando um Stream

Uma alternativa melhor apresenta os dados usando um `Stream`. No melhor cenário, o Stream emite dois valores, os dados armazenados localmente e os dados do servidor.

Primeiro, o stream emite os dados armazenados localmente usando o `DatabaseService`. Essa chamada é geralmente mais rápida e menos propensa a erros do que uma chamada de rede, e ao fazê-la primeiro, o view model já pode exibir dados para o usuário.

Se o banco de dados não contiver nenhum dado em cache, então o Stream depende completamente da chamada de rede, emitindo apenas um valor.

Em seguida, o método realiza a chamada de rede usando o `ApiClientService` para obter dados atualizados. Se a requisição foi bem-sucedida, ele atualiza o banco de dados com os dados recém-obtidos, e então faz yield do valor para o view model, para que possa ser exibido ao usuário.

```dart
Stream<UserProfile> getUserProfile() async* {
  // Busca o perfil do usuário do banco de dados
  final userProfile = await _databaseService.fetchUserProfile();
  // Retorna o resultado do banco de dados se existir
  if (userProfile != null) {
    yield userProfile;
  }
  // Busca o perfil do usuário da API
  try {
    final apiUserProfile = await _apiClientService.getUserProfile();
    // Atualiza o banco de dados com o resultado da API
    await _databaseService.updateUserProfile(apiUserProfile);
    // Retorna o resultado da API
    yield apiUserProfile;
  } catch (e) {
    // Trata o erro
  }
}
```

O view model deve se inscrever neste Stream e esperar até que ele tenha completado. Para isso, chame `asFuture()` com o objeto Subscription e aguarde o resultado. Para cada valor obtido, atualize os dados do view model e chame `notifyListeners()` para que a UI mostre os dados mais recentes.

```dart
Future<void> load() async {
  await _userProfileRepository
      .getUserProfile()
      .listen(
        (userProfile) {
          _userProfile = userProfile;
          notifyListeners();
        },
        onError: (error) {
          // tratar erro
        },
      )
      .asFuture<void>();
}
```

### Usando apenas dados locais

Outra abordagem possível usa dados armazenados localmente para operações de leitura. Essa abordagem requer que os dados tenham sido pré-carregados em algum momento no banco de dados, e requer um mecanismo de sincronização que possa manter os dados atualizados.

```dart
Future<UserProfile> getUserProfile() async {
  // Busca o perfil do usuário do banco de dados
  final userProfile = await _databaseService.fetchUserProfile();
  // Retorna o resultado do banco de dados se existir
  if (userProfile == null) {
    throw Exception('Data not found');
  }
  return userProfile;
}

Future<void> sync() async {
  try {
    // Busca o perfil do usuário da API
    final userProfile = await _apiClientService.getUserProfile();
    // Atualiza o banco de dados com o resultado da API
    await _databaseService.updateUserProfile(userProfile);
  } catch (e) {
    // Tenta novamente mais tarde
  }
}
```

Essa abordagem pode ser útil para aplicações que não requerem que os dados estejam sincronizados com o servidor o tempo todo. Por exemplo, uma aplicação de clima onde os dados do clima são atualizados apenas uma vez por dia.

A sincronização pode ser feita manualmente pelo usuário, por exemplo, uma ação de pull-to-refresh que então chama o método `sync()`, ou feita periodicamente por um Timer ou processo em background. Você pode aprender como implementar uma tarefa de sincronização na seção sobre sincronização de estado.

---

## Escrevendo Dados

Escrever dados em aplicações offline-first depende fundamentalmente do caso de uso da aplicação.

Algumas aplicações podem requerer que os dados de entrada do usuário estejam imediatamente disponíveis no lado do servidor, enquanto outras aplicações podem ser mais flexíveis e permitir que os dados fiquem temporariamente fora de sincronização.

Esta seção explica duas abordagens diferentes para implementar a escrita de dados em aplicações offline-first.

### Escrita apenas online

Uma abordagem para escrever dados em aplicações offline-first é obrigar estar online para escrever dados. Embora isso possa parecer contra-intuitivo, isso garante que os dados que o usuário modificou estejam totalmente sincronizados com o servidor, e que a aplicação não tenha um estado diferente do servidor.

Neste caso, você primeiro tenta enviar os dados para o serviço de API, e se a requisição for bem-sucedida, então armazena os dados no banco de dados.

```dart
Future<void> updateUserProfile(UserProfile userProfile) async {
  try {
    // Atualiza a API com o perfil do usuário
    await _apiClientService.putUserProfile(userProfile);
    // Somente se a chamada da API foi bem-sucedida
    // atualiza o banco de dados com o perfil do usuário
    await _databaseService.updateUserProfile(userProfile);
  } catch (e) {
    // Trata o erro
  }
}
```

A desvantagem neste caso é que a funcionalidade offline-first está disponível apenas para operações de leitura, mas não para operações de escrita, já que essas requerem que o usuário esteja online.

### Escrita offline-first

A segunda abordagem funciona ao contrário. Ao invés de realizar a chamada de rede primeiro, a aplicação primeiro armazena os novos dados no banco de dados, e então tenta enviá-los ao serviço de API depois de armazená-los localmente.

```dart
Future<void> updateUserProfile(UserProfile userProfile) async {
  // Atualiza o banco de dados com o perfil do usuário
  await _databaseService.updateUserProfile(userProfile);
  try {
    // Atualiza a API com o perfil do usuário
    await _apiClientService.putUserProfile(userProfile);
  } catch (e) {
    // Trata o erro
  }
}
```

Essa abordagem permite que usuários armazenem dados localmente mesmo quando a aplicação está offline, porém, se a chamada de rede falhar, o banco de dados local e o serviço de API não estão mais sincronizados. Na próxima seção, você aprenderá diferentes abordagens para lidar com a sincronização entre dados locais e remotos.

---

## Sincronizando Estado

Manter os dados locais e remotos sincronizados é uma parte importante de aplicações offline-first, já que as mudanças que foram feitas localmente precisam ser copiadas para o serviço remoto. O app também deve garantir que, quando o usuário voltar à aplicação, os dados armazenados localmente sejam os mesmos que no serviço remoto.

### Escrevendo uma tarefa de sincronização

Existem diferentes abordagens para implementar sincronização em uma tarefa em background.

Uma solução simples é criar um Timer no `UserProfileRepository` que executa periodicamente, por exemplo a cada cinco minutos.

```dart
Timer.periodic(const Duration(minutes: 5), (timer) => sync());
```

O método `sync()` então busca o `UserProfile` do banco de dados, e se ele requer sincronização, é então enviado ao serviço de API.

```dart
Future<void> sync() async {
  try {
    // Busca o perfil do usuário do banco de dados
    final userProfile = await _databaseService.fetchUserProfile();
    // Verifica se o perfil do usuário requer sincronização
    if (userProfile == null || userProfile.synchronized) {
      return;
    }
    // Atualiza a API com o perfil do usuário
    await _apiClientService.putUserProfile(userProfile);
    // Define o perfil do usuário como sincronizado
    await _databaseService.updateUserProfile(
      userProfile.copyWith(synchronized: true),
    );
  } catch (e) {
    // Tenta novamente mais tarde
  }
}
```

Uma solução mais complexa usa processos em background como o plugin workmanager. Isso permite que sua aplicação execute o processo de sincronização em background mesmo quando a aplicação não está em execução.

> **Nota:** Executar operações em background continuamente pode drenar a bateria do dispositivo drasticamente, e alguns dispositivos limitam as capacidades de processamento em background, então essa abordagem precisa ser ajustada aos requisitos da aplicação e uma solução pode não servir para todos os casos.

Também é recomendado realizar a tarefa de sincronização apenas quando a rede está disponível. Por exemplo, você pode usar o plugin `connectivity_plus` para verificar se o dispositivo está conectado ao WiFi. Você também pode usar `battery_plus` para verificar se o dispositivo não está com bateria baixa.

No exemplo anterior, a tarefa de sincronização executa a cada 5 minutos. Em alguns casos, isso pode ser excessivo, enquanto em outros pode não ser frequente o suficiente. O período real de sincronização para sua aplicação depende das necessidades da sua aplicação e é algo que você terá que decidir.

### Armazenando uma flag de sincronização

Para saber se os dados requerem sincronização, adicione uma flag à classe de dados indicando se as mudanças precisam ser sincronizadas.

Por exemplo, `bool synchronized`:

```dart
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String photoUrl,
    @Default(false) bool synchronized,
  }) = _UserProfile;
}
```

Sua lógica de sincronização deve tentar enviá-lo ao serviço de API apenas quando a flag `synchronized` for `false`. Se a requisição for bem-sucedida, então mude para `true`.

### Enviando dados do servidor (push)

Uma abordagem diferente para sincronização é usar um serviço de push para fornecer dados atualizados à aplicação. Neste caso, o servidor notifica a aplicação quando os dados mudaram, ao invés de ser a aplicação pedindo por atualizações.

Por exemplo, você pode usar Firebase messaging para enviar pequenas cargas de dados ao dispositivo, bem como disparar tarefas de sincronização remotamente usando mensagens em background.

Ao invés de ter uma tarefa de sincronização executando em background, o servidor notifica a aplicação quando os dados armazenados precisam ser atualizados com uma notificação push.

Você pode combinar ambas as abordagens juntas, tendo uma tarefa de sincronização em background e usando mensagens push em background, para manter o banco de dados da aplicação sincronizado com o servidor.

---

## Juntando Tudo

Escrever uma aplicação offline-first requer tomar decisões sobre a forma como operações de leitura, escrita e sincronização são implementadas, que dependem dos requisitos da aplicação que você está desenvolvendo.

Os pontos-chave são:

- Ao ler dados, você pode usar um `Stream` para combinar dados armazenados localmente com dados remotos.
- Ao escrever dados, decida se você precisa estar online ou offline, e se precisa sincronizar dados depois ou não.
- Ao implementar uma tarefa de sincronização em background, leve em conta o status do dispositivo e as necessidades da sua aplicação, já que diferentes aplicações podem ter diferentes requisitos.

## O Padrão Command

**Tags:** mvvm | dart assíncrono | estado

**Simplifique a lógica do view model implementando uma classe Command.**

# O Padrão Command

**Simplifique a lógica do view model implementando uma classe Command.**

Model-View-ViewModel (MVVM) é um padrão de design que separa uma funcionalidade de uma aplicação em três partes: o model, o view model e a view. Views e view models compõem a camada de UI de uma aplicação. Repositórios e serviços representam a camada de dados de uma aplicação, ou a camada model do MVVM.

Um command é uma classe que encapsula um método e ajuda a lidar com os diferentes estados desse método, como executando, completo e erro.

View models podem usar commands para lidar com interação e executar ações. Você também pode usá-los para exibir diferentes estados de UI, como indicadores de carregamento quando uma ação está executando, ou exibir um diálogo de erro quando uma ação falhou.

View models podem se tornar muito complexos conforme uma aplicação cresce e funcionalidades ficam maiores. Commands podem ajudar a simplificar view models e reusar código.

Neste guia, você aprenderá como usar o padrão command para melhorar seus view models.

---

## Desafios ao Implementar View Models

Classes de view model no Flutter são tipicamente implementadas estendendo a classe `ChangeNotifier`. Isso permite que view models chamem `notifyListeners()` para atualizar views quando dados são atualizados.

View models contêm uma representação do estado da UI, incluindo os dados sendo exibidos. Por exemplo, este `HomeViewModel` expõe a instância `User` para a view.

```dart
class HomeViewModel extends ChangeNotifier {
  // ···
}
```

```dart
class HomeViewModel extends ChangeNotifier {
  User? get user => // ...
  // ···
}
```

View models também contêm ações tipicamente acionadas pela view, como uma ação load responsável por carregar o `user`.

```dart
class HomeViewModel extends ChangeNotifier {
  User? get user => // ...
  // ···

  void load() {
    // carregar user
  }

  // ···
}
```

### Estado da UI em view models

Um view model também contém estado de UI além de dados, como se a view está executando ou se encontrou um erro. Isso permite que o app informe ao usuário se a ação foi completada com sucesso.

```dart
class HomeViewModel extends ChangeNotifier {
  User? get user => // ...
  bool get running => // ...
  Exception? get error => // ...

  void load() {
    // carregar user
  }

  // ···
}
```

Você pode usar o estado running para exibir um indicador de progresso na view:

```dart
ListenableBuilder(
  listenable: widget.viewModel,
  builder: (context, _) {
    if (widget.viewModel.running) {
      return const Center(child: CircularProgressIndicator());
    }
    // ···
  },
)
```

Ou usar o estado running para evitar executar a ação múltiplas vezes:

```dart
void load() {
  if (running) {
    return;
  }
  // carregar user
}
```

Gerenciar o estado de uma ação pode ficar complicado se o view model contiver múltiplas ações. Por exemplo, adicionar uma ação `edit()` ao `HomeViewModel` pode levar ao seguinte resultado:

```dart
class HomeViewModel extends ChangeNotifier {
  User? get user => // ...

  bool get runningLoad => // ...
  Exception? get errorLoad => // ...

  bool get runningEdit => // ...
  Exception? get errorEdit => // ...

  void load() {
    // carregar user
  }

  void edit(String name) {
    // editar user
  }
}
```

Compartilhar o estado running entre as ações `load()` e `edit()` pode nem sempre funcionar, porque você pode querer mostrar um componente de UI diferente quando a ação `load()` executa do que quando a ação `edit()` executa; você terá o mesmo problema com o estado de erro.

### Acionando ações de UI a partir de view models

Classes de view model podem encontrar problemas ao executar ações de UI e o estado do view model muda.

Por exemplo, você pode querer mostrar um `SnackBar` quando um erro ocorre, ou navegar para uma tela diferente quando uma ação completa. Para implementar isso, ouça mudanças no view model e realize a ação dependendo do estado.

Na view:

```dart
@override
void initState() {
  super.initState();
  widget.viewModel.addListener(_onViewModelChanged);
}

@override
void dispose() {
  widget.viewModel.removeListener(_onViewModelChanged);
  super.dispose();
}

void _onViewModelChanged() {
  if (widget.viewModel.error != null) {
    // Mostrar Snackbar
  }
}
```

Você precisa limpar o estado de erro cada vez que executar esta ação, caso contrário esta ação acontece cada vez que `notifyListeners()` é chamado.

```dart
void _onViewModelChanged() {
  if (widget.viewModel.error != null) {
    widget.viewModel.clearError();
    // Mostrar Snackbar
  }
}
```

---

## Padrão Command

Você pode se encontrar repetindo o código acima inúmeras vezes, implementando um estado running diferente para cada ação em cada view model. Nesse ponto, faz sentido extrair esse código em um padrão reutilizável chamado command.

Um command é uma classe que encapsula uma ação de view model, e expõe os diferentes estados que uma ação pode ter.

```dart
class Command extends ChangeNotifier {
  Command(this._action);

  bool get running => // ...
  Exception? get error => // ...
  bool get completed => // ...

  void Function() _action;

  void execute() {
    // executar _action
  }

  void clear() {
    // limpar estado
  }
}
```

No view model, ao invés de definir uma ação diretamente com um método, você cria um objeto command:

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    load = Command(_load)..execute();
  }

  User? get user => // ...

  late final Command load;

  void _load() {
    // carregar user
  }
}
```

O método `load()` anterior se torna `_load()`, e ao invés disso o command `load` é exposto à View. Os estados running e error anteriores podem ser removidos, pois agora fazem parte do command.

### Executando um command

Ao invés de chamar `viewModel.load()` para executar a ação load, agora você chama `viewModel.load.execute()`.

O método `execute()` também pode ser chamado de dentro do view model. A seguinte linha de código executa o command load quando o view model é criado.

```dart
HomeViewModel() {
  load = Command(_load)..execute();
}
```

O método `execute()` define o estado running como `true` e reseta os estados de error e completed. Quando a ação termina, o estado running muda para `false` e o estado completed para `true`.

Se o estado running for `true`, o command não pode começar a executar novamente. Isso previne que usuários acionem um command múltiplas vezes pressionando um botão rapidamente.

O método `execute()` do command captura quaisquer Exceptions lançadas automaticamente e as expõe no estado error.

O código a seguir mostra uma classe Command de exemplo que foi simplificada para fins de demonstração. Você pode ver uma implementação completa no final desta página.

```dart
class Command extends ChangeNotifier {
  Command(this._action);

  bool _running = false;
  bool get running => _running;

  Exception? _error;
  Exception? get error => _error;

  bool _completed = false;
  bool get completed => _completed;

  final Future<void> Function() _action;

  Future<void> execute() async {
    if (_running) {
      return;
    }

    _running = true;
    _completed = false;
    _error = null;
    notifyListeners();

    try {
      await _action();
      _completed = true;
    } on Exception catch (error) {
      _error = error;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clear() {
    _running = false;
    _error = null;
    _completed = false;
  }
}
```

### Ouvindo o estado do command

A classe `Command` estende `ChangeNotifier`, permitindo que Views ouçam seus estados.

No `ListenableBuilder`, ao invés de passar o view model para `ListenableBuilder.listenable`, passe o command:

```dart
ListenableBuilder(
  listenable: widget.viewModel.load,
  builder: (context, child) {
    if (widget.viewModel.load.running) {
      return const Center(child: CircularProgressIndicator());
    }
    // ···
  },
)
```

E ouça mudanças no estado do command para executar ações de UI:

```dart
@override
void initState() {
  super.initState();
  widget.viewModel.addListener(_onViewModelChanged);
}

@override
void dispose() {
  widget.viewModel.removeListener(_onViewModelChanged);
  super.dispose();
}

void _onViewModelChanged() {
  if (widget.viewModel.load.error != null) {
    widget.viewModel.load.clear();
    // Mostrar Snackbar
  }
}
```

---

## Combinando Command e ViewModel

Você pode empilhar múltiplos widgets `ListenableBuilder` para ouvir estados de running e error antes de mostrar os dados do view model.

```dart
body: ListenableBuilder(
  listenable: widget.viewModel.load,
  builder: (context, child) {
    if (widget.viewModel.load.running) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.viewModel.load.error != null) {
      return Center(
        child: Text('Error: ${widget.viewModel.load.error}'),
      );
    }
    return child!;
  },
  child: ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      // ···
    },
  ),
),
```

Você pode definir múltiplas classes de commands em um único view model, simplificando sua implementação e minimizando a quantidade de código repetido.

```dart
class HomeViewModel2 extends ChangeNotifier {
  HomeViewModel2() {
    load = Command(_load)..execute();
    delete = Command(_delete);
  }

  User? get user => // ...

  late final Command load;
  late final Command delete;

  Future<void> _load() async {
    // carregar user
  }

  Future<void> _delete() async {
    // deletar user
  }
}
```

---

## Estendendo o Padrão Command

O padrão command pode ser estendido de múltiplas formas. Por exemplo, para suportar um número diferente de argumentos.

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    load = Command0(_load)..execute();
    edit = Command1<String>(_edit);
  }

  User? get user => // ...

  // Command0 aceita 0 argumentos
  late final Command0 load;

  // Command1 aceita 1 argumento
  late final Command1<String> edit;

  Future<void> _load() async {
    // carregar user
  }

  Future<void> _edit(String name) async {
    // editar user
  }
}
```

---

## Juntando Tudo

Neste guia, você aprendeu como usar o padrão de design command para melhorar a implementação de view models ao usar o padrão de design MVVM.

Abaixo, você encontra a classe Command completa conforme implementada no exemplo do Compass App para as diretrizes de arquitetura Flutter. Ela também usa a classe `Result` para determinar se a ação completou com sucesso ou com erro.

Esta implementação também inclui dois tipos de commands, um `Command0`, para ações sem parâmetros, e um `Command1`, para ações que recebem um parâmetro.

> **Nota:** Confira pub.dev para outras implementações prontas para uso do padrão command, como o pacote `command_it`.

```dart
// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'result.dart';

/// Define uma ação de command que retorna um [Result] do tipo [T].
/// Usada por [Command0] para ações sem argumentos.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// Define uma ação de command que retorna um [Result] do tipo [T].
/// Recebe um argumento do tipo [A].
/// Usada por [Command1] para ações com um argumento.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A);

/// Facilita a interação com um view model.
///
/// Encapsula uma ação,
/// expõe seus estados de execução e erro,
/// e garante que não pode ser lançada novamente até terminar.
///
/// Use [Command0] para ações sem argumentos.
/// Use [Command1] para ações com um argumento.
///
/// Ações devem retornar um [Result] do tipo [T].
///
/// Consuma o resultado da ação ouvindo mudanças,
/// então chame [clearResult] quando o estado for consumido.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;

  /// Se a ação está executando.
  bool get running => _running;

  Result<T>? _result;

  /// Se a ação completou com um erro.
  bool get error => _result is Error;

  /// Se a ação completou com sucesso.
  bool get completed => _result is Ok;

  /// O resultado da ação mais recente.
  ///
  /// Retorna `null` se a ação está executando ou completou com erro.
  Result<T>? get result => _result;

  /// Limpa o resultado da ação mais recente.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Executa a [action] fornecida, notificando listeners e
  /// definindo os estados de execução e resultado conforme necessário.
  Future<void> _execute(CommandAction0<T> action) async {
    // Garante que a ação não pode ser lançada múltiplas vezes.
    // ex: evita múltiplos toques em botão
    if (_running) return;

    // Notifica listeners.
    // ex: botão mostra estado de carregamento
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// Um [Command] que não aceita argumentos.
final class Command0<T> extends Command<T> {
  /// Cria um [Command0] com a [CommandAction0] fornecida.
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Executa a ação.
  Future<void> execute() async {
    await _execute(_action);
  }
}

/// Um [Command] que aceita um argumento.
final class Command1<T, A> extends Command<T> {
  /// Cria um [Command1] com a [CommandAction1] fornecida.
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Executa a ação com o [argument] especificado.
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}
```

## Tratamento de Erros com Objetos Result

**Tags:** tratamento de erros | serviços

**Melhore o tratamento de erros entre classes com objetos Result.**

# Tratamento de Erros com Objetos Result

**Melhore o tratamento de erros entre classes com objetos Result.**

Dart fornece um mecanismo de tratamento de erros integrado com a capacidade de lançar e capturar exceções.

Conforme mencionado na documentação de tratamento de erros, as exceções do Dart são exceções não verificadas. Isso significa que métodos que lançam exceções não precisam declará-las, e métodos que os chamam não são obrigados a capturá-las.

Isso pode levar a situações onde exceções não são tratadas adequadamente. Em projetos grandes, desenvolvedores podem esquecer de capturar exceções, e as diferentes camadas e componentes da aplicação podem lançar exceções que não estão documentadas. Isso pode levar a erros e crashes.

Neste guia, você aprenderá sobre essa limitação e como mitigá-la usando o padrão result.

---

## Fluxo de Erros em Aplicações Flutter

Aplicações que seguem as diretrizes de arquitetura do Flutter são normalmente compostas por view models, repositórios e serviços, entre outras partes. Quando uma função em um desses componentes falha, ela deve comunicar o erro ao componente chamador.

Tipicamente, isso é feito com exceções. Por exemplo, um serviço de cliente API que falha ao se comunicar com o servidor remoto pode lançar uma HTTP Error Exception. O componente chamador, por exemplo um Repository, teria que capturar essa exceção ou ignorá-la e deixar o view model chamador tratá-la.

Isso pode ser observado no seguinte exemplo. Considere estas classes:

- Um serviço, `ApiClientService`, realiza chamadas de API para um serviço remoto.
- Um repositório, `UserProfileRepository`, fornece o `UserProfile` disponibilizado pelo `ApiClientService`.
- Um view model, `UserProfileViewModel`, usa o `UserProfileRepository`.

O `ApiClientService` contém um método, `getUserProfile`, que lança exceções em certas situações:

- O método lança uma `HttpException` se o código de resposta não for 200.
- O método de parsing JSON lança uma exceção se a resposta não estiver formatada corretamente.
- O cliente HTTP pode lançar uma exceção devido a problemas de rede.

O código a seguir testa uma variedade de exceções possíveis:

```dart
class ApiClientService {
  // ···
  Future<UserProfile> getUserProfile() async {
    try {
      final request = await client.get(_host, _port, '/user');
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return UserProfile.fromJson(jsonDecode(stringData));
      } else {
        throw const HttpException('Invalid response');
      }
    } finally {
      client.close();
    }
  }
}
```

O `UserProfileRepository` não precisa tratar as exceções do `ApiClientService`. Neste exemplo, ele apenas retorna o valor do API Client.

```dart
class UserProfileRepository {
  // ···
  Future<UserProfile> getUserProfile() async {
    return await _apiClientService.getUserProfile();
  }
}
```

Finalmente, o `UserProfileViewModel` deve capturar todas as exceções e tratar os erros.

Isso pode ser feito envolvendo a chamada ao `UserProfileRepository` com um try-catch:

```dart
class UserProfileViewModel extends ChangeNotifier {
  // ···
  Future<void> load() async {
    try {
      _userProfile = await userProfileRepository.getUserProfile();
      notifyListeners();
    } on Exception catch (exception) {
      // tratar exceção
    }
  }
}
```

Na realidade, um desenvolvedor pode esquecer de capturar exceções adequadamente e acabar com o seguinte código. Ele compila e executa, mas crasha se uma das exceções mencionadas anteriormente ocorrer:

```dart
class UserProfileViewModel extends ChangeNotifier {
  // ···
  Future<void> load() async {
    _userProfile = await userProfileRepository.getUserProfile();
    notifyListeners();
  }
}
```

Você pode tentar resolver isso documentando o `ApiClientService`, alertando sobre as possíveis exceções que ele pode lançar. No entanto, como o view model não usa o serviço diretamente, outros desenvolvedores trabalhando no codebase podem perder essa informação.

---

## Usando o Padrão Result

Uma alternativa a lançar exceções é envolver a saída da função em um objeto Result.

Quando a função executa com sucesso, o Result contém o valor retornado. No entanto, se a função não completar com sucesso, o objeto Result contém o erro.

Um `Result` é uma sealed class que pode ser subclasse de `Ok` ou da classe `Error`. Retorne o valor bem-sucedido com a subclasse `Ok`, e o erro capturado com a subclasse `Error`.

O código a seguir mostra uma classe Result de exemplo que foi simplificada para fins de demonstração. Uma implementação completa está no final desta página.

```dart
/// Classe utilitária que simplifica o tratamento de erros.
///
/// Retorne um [Result] de uma função para indicar sucesso ou falha.
///
/// Um [Result] é ou um [Ok] com um valor do tipo [T]
/// ou um [Error] com uma [Exception].
///
/// Use [Result.ok] para criar um resultado bem-sucedido com um valor do tipo [T].
/// Use [Result.error] para criar um resultado de erro com uma [Exception].
sealed class Result<T> {
  const Result();

  /// Cria uma instância de Result contendo um valor
  factory Result.ok(T value) => Ok(value);

  /// Cria uma instância de Result contendo um erro
  factory Result.error(Exception error) => Error(error);
}

/// Subclasse de Result para valores
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// Valor retornado no resultado
  final T value;
}

/// Subclasse de Result para erros
final class Error<T> extends Result<T> {
  const Error(this.error);

  /// Erro retornado no resultado
  final Exception error;
}
```

Neste exemplo, a classe `Result` usa um tipo genérico `T` para representar qualquer valor de retorno, que pode ser um tipo primitivo do Dart como `String` ou `int`, ou uma classe customizada como `UserProfile`.

---

## Criando um Objeto Result

Para funções que usam a classe `Result` para retornar valores, ao invés de um valor, a função retorna um objeto `Result` contendo o valor.

Por exemplo, no `ApiClientService`, `getUserProfile` é alterado para retornar um `Result`:

```dart
class ApiClientService {
  // ···
  Future<Result<UserProfile>> getUserProfile() async {
    // ···
  }
}
```

Ao invés de retornar o `UserProfile` diretamente, ele retorna um objeto `Result` contendo um `UserProfile`.

Para facilitar o uso da classe `Result`, ela contém dois construtores nomeados, `Result.ok` e `Result.error`. Use-os para construir o `Result` dependendo da saída desejada. Além disso, capture quaisquer exceções lançadas pelo código e envolva-as no objeto `Result`.

Por exemplo, aqui o método `getUserProfile()` foi alterado para usar a classe `Result`:

```dart
class ApiClientService {
  // ···
  Future<Result<UserProfile>> getUserProfile() async {
    try {
      final request = await client.get(_host, _port, '/user');
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(UserProfile.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException('Invalid response'));
      }
    } on Exception catch (exception) {
      return Result.error(exception);
    } finally {
      client.close();
    }
  }
}
```

A instrução de retorno original foi substituída por uma instrução que retorna o valor usando `Result.ok`. O `throw HttpException()` foi substituído por uma instrução que retorna `Result.error(HttpException())`, envolvendo o erro em um `Result`. Além disso, o método é envolvido com um bloco try-catch para capturar quaisquer exceções lançadas pelo cliente HTTP ou pelo parser JSON em um `Result.error`.

A classe de repositório também precisa ser modificada, e ao invés de retornar um `UserProfile` diretamente, agora retorna um `Result<UserProfile>`.

```dart
Future<Result<UserProfile>> getUserProfile() async {
  return await _apiClientService.getUserProfile();
}
```

---

## Desempacotando o Objeto Result

Agora o view model não recebe o `UserProfile` diretamente, mas sim recebe um `Result` contendo um `UserProfile`.

Isso força o desenvolvedor que implementa o view model a desempacotar o `Result` para obter o `UserProfile`, e evita ter exceções não capturadas.

A classe `Result` é implementada usando uma sealed class, o que significa que só pode ser do tipo `Ok` ou `Error`. Isso permite que o código avalie o resultado com um switch.

No caso `Ok<UserProfile>`, obtenha o valor usando a propriedade `value`.

No caso `Error<UserProfile>`, obtenha o objeto de erro usando a propriedade `error`.

```dart
class UserProfileViewModel extends ChangeNotifier {
  // ···
  UserProfile? userProfile;
  Exception? error;

  Future<void> load() async {
    final result = await userProfileRepository.getUserProfile();
    switch (result) {
      case Ok<UserProfile>():
        userProfile = result.value;
      case Error<UserProfile>():
        error = result.error;
    }
    notifyListeners();
  }
}
```

---

## Melhorando o Fluxo de Controle

Envolver código em um bloco try-catch garante que exceções lançadas sejam capturadas e não propagadas para outras partes do código.

Considere o seguinte código.

```dart
class UserProfileRepository {
  // ···
  Future<UserProfile> getUserProfile() async {
    try {
      return await _apiClientService.getUserProfile();
    } catch (e) {
      try {
        return await _databaseService.createTemporaryUser();
      } catch (e) {
        throw Exception('Failed to get user profile');
      }
    }
  }
}
```

Neste método, o `UserProfileRepository` tenta obter o `UserProfile` usando o `ApiClientService`. Se falhar, tenta criar um usuário temporário em um `DatabaseService`.

Como qualquer método de serviço pode falhar, o código deve capturar as exceções em ambos os casos.

Isso pode ser melhorado usando o padrão Result:

```dart
Future<Result<UserProfile>> getUserProfile() async {
  final apiResult = await _apiClientService.getUserProfile();
  if (apiResult is Ok) {
    return apiResult;
  }

  final databaseResult = await _databaseService.createTemporaryUser();
  if (databaseResult is Ok) {
    return databaseResult;
  }

  return Result.error(Exception('Failed to get user profile'));
}
```

Neste código, se o objeto `Result` é uma instância de `Ok`, então a função retorna esse objeto; caso contrário, retorna `Result.Error`.

---

## Juntando Tudo

Neste guia, você aprendeu como usar uma classe `Result` para retornar valores de resultado.

Os pontos-chave são:

- Classes Result forçam o método chamador a verificar erros, reduzindo a quantidade de bugs causados por exceções não capturadas.
- Classes Result ajudam a melhorar o fluxo de controle comparado a blocos try-catch.
- Classes Result são sealed e só podem retornar instâncias `Ok` ou `Error`, permitindo que o código as desempacote com uma instrução switch.

> **Nota:** Confira pub.dev para diferentes implementações prontas para uso da classe Result, como os pacotes `result_dart`, `result_type` e `multiple_result`.

Abaixo você encontra a classe Result completa conforme implementada no exemplo do Compass App para as diretrizes de arquitetura Flutter.

```dart
/// Classe utilitária que simplifica o tratamento de erros.
///
/// Retorne um [Result] de uma função para indicar sucesso ou falha.
///
/// Um [Result] é ou um [Ok] com um valor do tipo [T]
/// ou um [Error] com uma [Exception].
///
/// Use [Result.ok] para criar um resultado bem-sucedido com um valor do tipo [T].
/// Use [Result.error] para criar um resultado de erro com uma [Exception].
///
/// Avalie o resultado usando uma instrução switch:
/// ```dart
/// switch (result) {
///   case Ok(): {
///     print(result.value);
///   }
///   case Error(): {
///     print(result.error);
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Cria um [Result] bem-sucedido, completado com o [value] especificado.
  const factory Result.ok(T value) = Ok._;

  /// Cria um [Result] de erro, completado com o [error] especificado.
  const factory Result.error(Exception error) = Error._;
}

/// Um [Result] bem-sucedido com um [value] retornado.
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// O valor retornado deste resultado.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// Um [Result] de erro com um [error] resultante.
final class Error<T> extends Result<T> {
  const Error._(this.error);

  /// O erro resultante deste resultado.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
```