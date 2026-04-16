# Estudo de caso da camada de UI

Um walkthrough da camada de UI de um app que implementa a arquitetura MVVM.

---

A camada de UI de cada feature na sua aplicação Flutter deve ser composta por dois componentes: uma **View** e um **ViewModel**.

No sentido mais geral, view models gerenciam o estado da UI e views exibem o estado da UI. Views e view models possuem um relacionamento um-para-um; para cada view, existe exatamente um view model correspondente que gerencia o estado daquela view. Cada par de view e view model compõe a UI para uma única feature. Por exemplo, um app pode ter classes chamadas `LogOutView` e `LogOutViewModel`.

---

## Definindo um view model

Um view model é uma classe Dart responsável por lidar com a lógica de UI. View models recebem modelos de dados de domínio como entrada e expõem esses dados como estado de UI para suas views correspondentes. Eles encapsulam lógica que a view pode anexar a manipuladores de eventos, como pressionamentos de botão, e gerenciam o envio desses eventos para a camada de dados do app, onde as mudanças de dados acontecem.

O trecho de código a seguir é uma declaração de classe para um view model chamado `HomeViewModel`. Suas entradas são os repositories que fornecem seus dados. Neste caso, o view model depende de `BookingRepository` e `UserRepository` como argumentos.

### Exemplo: home_viewmodel.dart

```dart
class HomeViewModel {
  HomeViewModel({
    required BookingRepository bookingRepository,
    required UserRepository userRepository,
  }) :
    // Repositories são atribuídos manualmente porque são membros privados.
    _bookingRepository = bookingRepository,
    _userRepository = userRepository;

  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  // ...
}
```

View models são sempre dependentes de repositories de dados, que são fornecidos como argumentos para o construtor do view model. View models e repositories possuem um relacionamento muitos-para-muitos, e a maioria dos view models dependerá de múltiplos repositories.

Como no exemplo anterior de declaração do `HomeViewModel`, repositories devem ser membros privados no view model, caso contrário as views teriam acesso direto à camada de dados da aplicação.

---

### Estado da UI

A saída de um view model são dados que uma view precisa para renderizar, geralmente referidos como **Estado da UI**, ou simplesmente estado. O estado da UI é um snapshot imutável de dados necessários para renderizar completamente uma view.

O view model expõe estado como membros públicos. No view model do exemplo de código a seguir, os dados expostos são um objeto `User`, bem como os itinerários salvos do usuário que são expostos como um objeto do tipo `List<BookingSummary>`.

### Exemplo: home_viewmodel.dart

```dart
class HomeViewModel {
  HomeViewModel({
    required BookingRepository bookingRepository,
    required UserRepository userRepository,
  }) : _bookingRepository = bookingRepository,
       _userRepository = userRepository;

  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  User? _user;
  User? get user => _user;

  List<BookingSummary> _bookings = [];

  /// Itens em um [UnmodifiableListView] não podem ser modificados diretamente,
  /// mas mudanças na lista fonte podem ser modificadas. Como _bookings
  /// é privado e bookings não é, a view não tem como modificar a
  /// lista diretamente.
  UnmodifiableListView<BookingSummary> get bookings => UnmodifiableListView(_bookings);

  // ...
}
```

Como mencionado, o estado da UI deve ser **imutável**. Esta é uma parte crucial de software livre de bugs.

O app Compass usa o `package:freezed` para garantir imutabilidade nas classes de dados. Por exemplo, o código a seguir mostra a definição da classe `User`. O freezed fornece imutabilidade profunda e gera a implementação de métodos úteis como `copyWith` e `toJson`.

### Exemplo: user.dart

```dart
@freezed
class User with _$User {
  const factory User({
    /// O nome do usuário.
    required String name,

    /// A URL da foto do usuário.
    required String picture,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
```

> **Nota:** No exemplo do view model, dois objetos são necessários para renderizar a view. À medida que o estado da UI de um dado model cresce em complexidade, um view model pode ter muitos mais dados de muitos mais repositories expostos à view. Em alguns casos, você pode querer criar objetos que representem especificamente o estado da UI. Por exemplo, você poderia criar uma classe chamada `HomeUiState`.

---

### Atualizando o estado da UI

Além de armazenar estado, view models precisam dizer ao Flutter para re-renderizar views quando a camada de dados fornece um novo estado. No app Compass, view models estendem `ChangeNotifier` para alcançar isso.

### Exemplo: home_viewmodel.dart

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required BookingRepository bookingRepository,
    required UserRepository userRepository,
  }) : _bookingRepository = bookingRepository,
       _userRepository = userRepository;

  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  User? _user;
  User? get user => _user;

  List<BookingSummary> _bookings = [];
  List<BookingSummary> get bookings => _bookings;

  // ...
}
```

`HomeViewModel.user` é um membro público do qual a view depende. Quando novos dados fluem da camada de dados e um novo estado precisa ser emitido, `notifyListeners` é chamado.

O fluxo de alto nível de como novos dados no repository se propagam até a camada de UI e acionam um re-build dos seus widgets Flutter é:

1. Novo estado é fornecido ao view model a partir de um Repository.
2. O view model atualiza seu estado de UI para refletir os novos dados.
3. `ViewModel.notifyListeners` é chamado, alertando a View sobre o novo estado de UI.
4. A view (widget) re-renderiza.

Por exemplo, quando o usuário navega para a tela Home e o view model é criado, o método `_load` é chamado. Até que este método complete, o estado da UI está vazio e a view exibe um indicador de carregamento. Quando o método `_load` completa, se for bem-sucedido, há novos dados no view model e ele deve notificar a view que novos dados estão disponíveis.

### Exemplo: home_viewmodel.dart

```dart
class HomeViewModel extends ChangeNotifier {
  // ...

  Future<Result> _load() async {
    try {
      final userResult = await _userRepository.getUser();
      switch (userResult) {
        case Ok<User>():
          _user = userResult.value;
          _log.fine('Loaded user');
        case Error<User>():
          _log.warning('Failed to load user', userResult.error);
      }
      // ...
      return userResult;
    } finally {
      notifyListeners();
    }
  }
}
```

> **Nota:** `ChangeNotifier` e `ListenableBuilder` (discutido mais adiante nesta página) fazem parte do SDK do Flutter e fornecem uma boa solução para atualizar a UI quando o estado muda. Você também pode usar uma solução robusta de gerenciamento de estado de terceiros, como `package:riverpod`, `package:flutter_bloc` ou `package:signals`. Essas bibliotecas oferecem ferramentas diferentes para lidar com atualizações de UI. Leia mais sobre o uso de ChangeNotifier na documentação de gerenciamento de estado.

---

## Definindo uma view

Uma view é um widget dentro do seu app. Frequentemente, uma view representa uma tela no seu app que possui sua própria rota e inclui um `Scaffold` no topo da subárvore de widgets, como a `HomeScreen`, mas nem sempre é o caso.

Às vezes, uma view é um único elemento de UI que encapsula funcionalidade que precisa ser reutilizada em todo o app. Por exemplo, o app Compass tem uma view chamada `LogoutButton`, que pode ser colocada em qualquer lugar na árvore de widgets onde um usuário espera encontrar um botão de logout. A view `LogoutButton` tem seu próprio view model chamado `LogoutViewModel`. E em telas maiores, pode haver múltiplas views na tela que ocupariam a tela inteira em dispositivos móveis.

> **Nota:** "View" é um termo abstrato, e uma view não é igual a um widget. Widgets são composáveis, e vários podem ser combinados para criar uma view. Portanto, view models não possuem um relacionamento um-para-um com widgets, mas sim um relacionamento um-para-um com uma *coleção* de widgets.

Os widgets dentro de uma view possuem três responsabilidades:

- Exibem as propriedades de dados do view model.
- Escutam atualizações do view model e re-renderizam quando novos dados estão disponíveis.
- Anexam callbacks do view model a manipuladores de eventos, se aplicável.

Continuando o exemplo da feature Home, o código a seguir mostra a definição da view `HomeScreen`.

### Exemplo: home_screen.dart

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
    );
  }
}
```

Na maioria das vezes, as únicas entradas de uma view devem ser uma `key`, que todos os widgets Flutter recebem como argumento opcional, e o view model correspondente da view.

---

### Exibindo dados da UI em uma view

Uma view depende de um view model para seu estado. No app Compass, o view model é passado como argumento no construtor da view.

### Exemplo: home_screen.dart

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

Dentro do widget, você pode acessar os bookings passados a partir do `viewModel`. No código a seguir, a propriedade booking está sendo fornecida a um sub-widget.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // Código removido para brevidade.
    body: SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(...),
              SliverList.builder(
                itemCount: viewModel.bookings.length,
                itemBuilder: (_, index) => _Booking(
                  key: ValueKey(viewModel.bookings[index].id),
                  booking: viewModel.bookings[index],
                  onTap: () => context.push(Routes.bookingWithId(
                    viewModel.bookings[index].id)),
                  onDismissed: (_) => viewModel.deleteBooking.execute(
                    viewModel.bookings[index].id,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
```

---

### Atualizando a UI

O widget `HomeScreen` escuta atualizações do view model com o widget `ListenableBuilder`. Tudo na subárvore de widgets sob o `ListenableBuilder` re-renderiza quando o `Listenable` fornecido muda. Neste caso, o `Listenable` fornecido é o view model. Lembre-se de que o view model é do tipo `ChangeNotifier`, que é um subtipo do tipo `Listenable`.

---

### Lidando com eventos do usuário

Finalmente, uma view precisa escutar eventos dos usuários para que o view model possa lidar com esses eventos. Isso é alcançado expondo um método de callback na classe do view model que encapsula toda a lógica.

Na `HomeScreen`, usuários podem deletar eventos previamente reservados deslizando um widget `Dismissible`. Quando um `_Booking` é dispensado, o método `viewModel.deleteBooking` é executado.

Uma reserva salva é estado de aplicação que persiste além de uma sessão ou do tempo de vida de uma view, e apenas repositories devem modificar tal estado de aplicação. Portanto, o método `HomeViewModel.deleteBooking` delega a chamada para um método exposto por um repository na camada de dados.

### Exemplo: home_viewmodel.dart

```dart
Future<Result<void>> _deleteBooking(int id) async {
  try {
    final resultDelete = await _bookingRepository.delete(id);
    switch (resultDelete) {
      case Ok<void>():
        _log.fine('Deleted booking $id');
      case Error<void>():
        _log.warning('Failed to delete booking $id', resultDelete.error);
        return resultDelete;
    }
    // Código omitido para brevidade.
    // final resultLoadBookings = ...;
    return resultLoadBookings;
  } finally {
    notifyListeners();
  }
}
```

No app Compass, esses métodos que lidam com eventos do usuário são chamados de **commands**.

---

## Objetos Command

Commands são responsáveis pela interação que começa na camada de UI e flui de volta para a camada de dados. Neste app especificamente, um `Command` também é um tipo que ajuda a atualizar a UI de forma segura, independentemente do tempo de resposta ou conteúdo.

A classe `Command` encapsula um método e ajuda a lidar com os diferentes estados desse método, como `running`, `complete` e `error`. Esses estados facilitam a exibição de UI diferente, como indicadores de carregamento quando `Command.running` é `true`.

### Exemplo: command.dart

```dart
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool running = false;
  Result<T>? _result;

  /// true se a ação completou com erro
  bool get error => _result is Error;

  /// true se a ação completou com sucesso
  bool get completed => _result is Ok;

  /// Implementação interna de execute
  Future<void> _execute(action) async {
    if (_running) return;

    // Emite estado de execução - ex.: botão mostra estado de carregamento
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
```

A classe `Command` em si estende `ChangeNotifier`, e dentro do método `Command.execute`, `notifyListeners` é chamado múltiplas vezes. Isso permite que a view lide com diferentes estados com muito pouca lógica.

Você também deve ter notado que `Command` é uma classe abstrata. Ela é implementada por classes concretas como `Command0` e `Command1`. O inteiro no nome da classe se refere ao número de argumentos que o método subjacente espera. Você pode ver exemplos dessas classes de implementação no diretório utils do app Compass.

> **Recomendação de pacote:** Em vez de escrever sua própria classe Command, considere usar o pacote `flutter_command`, que é uma biblioteca robusta que implementa classes como essas.

---

## Garantindo que views possam renderizar antes dos dados existirem

Nas classes de view model, commands são criados no construtor.

### Exemplo: home_viewmodel.dart

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required BookingRepository bookingRepository,
    required UserRepository userRepository,
  }) : _bookingRepository = bookingRepository,
       _userRepository = userRepository {
    // Carrega dados necessários quando esta tela é construída.
    load = Command0(_load)..execute();
    deleteBooking = Command1(_deleteBooking);
  }

  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  late Command0 load;
  late Command1<void, int> deleteBooking;

  User? _user;
  User? get user => _user;

  List<BookingSummary> _bookings = [];
  List<BookingSummary> get bookings => _bookings;

  Future<Result> _load() async {
    // ...
  }

  Future<Result<void>> _deleteBooking(int id) async {
    // ...
  }

  // ...
}
```

O método `Command.execute` é assíncrono, então não pode garantir que os dados estarão disponíveis quando a view quiser renderizar. É por isso que o app Compass usa Commands. No método `Widget.build` da view, o command é usado para renderizar condicionalmente diferentes widgets.

### Exemplo: home_screen.dart

```dart
// ...
child: ListenableBuilder(
  listenable: viewModel.load,
  builder: (context, child) {
    if (viewModel.load.running) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.load.error) {
      return ErrorIndicator(
        title: AppLocalization.of(context).errorWhileLoadingHome,
        label: AppLocalization.of(context).tryAgain,
        onPressed: viewModel.load.execute,
      );
    }

    // O command completou sem erro.
    // Retorna o widget principal da view.
    return child!;
  },
),
// ...
```

Como o command `load` é uma propriedade que existe no view model em vez de algo efêmero, não importa quando o método load é chamado ou quando ele resolve. Por exemplo, se o command load resolver antes mesmo do widget `HomeScreen` ser criado, isso não é um problema porque o objeto `Command` ainda existe e expõe o estado correto.

Esse padrão padroniza como problemas comuns de UI são resolvidos no app, tornando sua base de código menos propensa a erros e mais escalável, mas não é um padrão que todo app vai querer implementar. Se você quer usá-lo depende muito de outras escolhas arquiteturais que você fizer. Muitas bibliotecas que ajudam a gerenciar estado possuem suas próprias ferramentas para resolver esses problemas. Por exemplo, se você usar streams e `StreamBuilders` no seu app, as classes `AsyncSnapshot` fornecidas pelo Flutter possuem essa funcionalidade incorporada.

> **Exemplo do mundo real:** Ao construir o app Compass, encontramos um bug que foi resolvido usando o padrão Command. Leia sobre isso no GitHub.