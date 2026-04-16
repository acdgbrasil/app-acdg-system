# Comunicação entre camadas

Como implementar injeção de dependência para comunicação entre camadas MVVM.

---

Além de definir responsabilidades claras para cada componente da arquitetura, é importante considerar como os componentes se comunicam. Isso se refere tanto às regras que ditam a comunicação quanto à implementação técnica de como os componentes se comunicam. A arquitetura de um app deve responder às seguintes perguntas:

- Quais componentes podem se comunicar com quais outros componentes (incluindo componentes do mesmo tipo)?
- O que esses componentes expõem como saída uns para os outros?
- Como uma determinada camada é "conectada" a outra camada?

Usando o diagrama de arquitetura como guia, as regras de engajamento são as seguintes:

| Componente | Regras de engajamento |
|---|---|
| **View** | 1. Uma view conhece exatamente um view model, e nunca conhece nenhuma outra camada ou componente. Quando criada, o Flutter passa o view model para a view como argumento, expondo os dados e callbacks de comando do view model para a view. |
| **ViewModel** | 1. Um ViewModel pertence a exatamente uma view, que pode ver seus dados, mas o model nunca precisa saber que uma view existe. 2. Um view model conhece um ou mais repositories, que são passados no construtor do view model. |
| **Repository** | 1. Um repository pode conhecer muitos services, que são passados como argumentos no construtor do repository. 2. Um repository pode ser usado por muitos view models, mas nunca precisa conhecê-los. |
| **Service** | 1. Um service pode ser usado por muitos repositories, mas nunca precisa conhecer um repository (ou qualquer outro objeto). |

---

## Injeção de dependência

Até agora foi mostrado como esses diferentes componentes se comunicam usando entradas e saídas. Em todos os casos, a comunicação entre duas camadas é facilitada pela passagem de um componente nos métodos construtores (dos componentes que consomem seus dados), como um Service em um Repository.

O que falta, no entanto, é a criação de objetos. Onde, em uma aplicação, a instância de `MyService` é criada para que possa ser passada para `MyRepository`? A resposta a essa pergunta envolve um padrão conhecido como **injeção de dependência**.

No app Compass, a injeção de dependência é tratada usando `package:provider`. Com base em sua experiência construindo apps Flutter, equipes no Google recomendam usar `package:provider` para implementar injeção de dependência.

Services e repositories são expostos no nível mais alto da árvore de widgets da aplicação Flutter como objetos `Provider`.

### Exemplo: dependencies.dart

```dart
class MyRepository {
  MyRepository({required MyService myService})
    : _myService = myService;

  late final MyService _myService;
}
```

```dart
runApp(
  MultiProvider(
    providers: [
      Provider(create: (context) => AuthApiClient()),
      Provider(create: (context) => ApiClient()),
      Provider(create: (context) => SharedPreferencesService()),
      ChangeNotifierProvider(
        create: (context) => AuthRepositoryRemote(
          authApiClient: context.read(),
          apiClient: context.read(),
          sharedPreferencesService: context.read(),
        ) as AuthRepository,
      ),
      Provider(create: (context) =>
        DestinationRepositoryRemote(
          apiClient: context.read(),
        ) as DestinationRepository,
      ),
      Provider(create: (context) =>
        ContinentRepositoryRemote(
          apiClient: context.read(),
        ) as ContinentRepository,
      ),
      // No app Compass, providers adicionais de service e repository existem aqui
    ],
    child: const MainApp(),
  ),
);
// Este código foi modificado para fins de demonstração.
```

Services são expostos apenas para que possam ser imediatamente injetados nos repositories via o método `BuildContext.read` do provider, como mostrado no trecho anterior. Repositories são então expostos para que possam ser injetados nos view models conforme necessário.

Um pouco mais abaixo na árvore de widgets, view models que correspondem a uma tela completa são criados na configuração do `package:go_router`, onde o provider é novamente usado para injetar os repositories necessários.

### Exemplo: router.dart

```dart
GoRouter router(
  AuthRepository authRepository,
) =>
  GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: _redirect,
    refreshListenable: authRepository,
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) {
          return LoginScreen(
            viewModel: LoginViewModel(
              authRepository: context.read(),
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) {
          final viewModel = HomeViewModel(
            bookingRepository: context.read(),
          );
          return HomeScreen(viewModel: viewModel);
        },
        routes: [
          // ...
        ],
      ),
    ],
  );
```

Dentro do view model ou repository, o componente injetado deve ser **privado**. Por exemplo, a classe `HomeViewModel` fica assim:

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

  // ...
}
```

Métodos privados impedem que a view, que tem acesso ao view model, chame métodos no repository diretamente.

---

Isso conclui o walkthrough de código do app Compass. Esta página abordou apenas o código relacionado à arquitetura, mas não conta a história completa. A maior parte do código utilitário, código de widgets e estilização de UI foi ignorada. Navegue pelo código no repositório do app Compass para um exemplo completo de uma aplicação Flutter robusta construída seguindo esses princípios.