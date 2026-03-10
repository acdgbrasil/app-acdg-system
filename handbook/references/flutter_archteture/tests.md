# Testando cada camada

Como testar um app que implementa a arquitetura MVVM.

---

## Testando a camada de UI

Uma forma de determinar se sua arquitetura é sólida é considerar o quão fácil (ou difícil) a aplicação é de testar. Como view models e views possuem entradas bem definidas, suas dependências podem ser facilmente mockadas ou fakeadas, e testes unitários são facilmente escritos.

### Testes unitários de ViewModel

Para testar a lógica de UI do view model, você deve escrever testes unitários que não dependam de bibliotecas ou frameworks de teste do Flutter.

Repositories são as únicas dependências de um view model (a menos que você esteja implementando use-cases), e escrever mocks ou fakes do repository é a única configuração que você precisa fazer. Neste exemplo de teste, um fake chamado `FakeBookingRepository` é usado.

#### Exemplo: home_screen_test.dart

```dart
void main() {
  group('HomeViewModel tests', () {
    test('Load bookings', () {
      // HomeViewModel._load é chamado no construtor do HomeViewModel.
      final viewModel = HomeViewModel(
        bookingRepository: FakeBookingRepository()
          ..createBooking(kBooking),
        userRepository: FakeUserRepository(),
      );

      expect(viewModel.bookings.isNotEmpty, true);
    });
  });
}
```

A classe `FakeBookingRepository` implementa `BookingRepository`. Na seção de camada de dados deste estudo de caso, a classe `BookingRepository` é explicada em detalhes.

#### Exemplo: fake_booking_repository.dart

```dart
class FakeBookingRepository implements BookingRepository {
  List<Booking> bookings = List.empty(growable: true);

  @override
  Future<Result<void>> createBooking(Booking booking) async {
    bookings.add(booking);
    return Result.ok(null);
  }

  // ...
}
```

> **Nota:** Se você estiver usando esta arquitetura com use-cases, estes também precisariam ser fakeados.

---

### Testes de widget para Views

Uma vez que você escreveu testes para seu view model, você já criou os fakes necessários para escrever testes de widget também. O exemplo a seguir mostra como os testes de widget do `HomeScreen` são configurados usando o `HomeViewModel` e os repositories necessários:

#### Exemplo: home_screen_test.dart

```dart
void main() {
  group('HomeScreen tests', () {
    late HomeViewModel viewModel;
    late MockGoRouter goRouter;
    late FakeBookingRepository bookingRepository;

    setUp(() {
      bookingRepository = FakeBookingRepository()
        ..createBooking(kBooking);
      viewModel = HomeViewModel(
        bookingRepository: bookingRepository,
        userRepository: FakeUserRepository(),
      );
      goRouter = MockGoRouter();
      when(() => goRouter.push(any())).thenAnswer((_) => Future.value(null));
    });

    // ...
  });
}
```

Essa configuração cria os dois fake repositories necessários e os passa para um objeto `HomeViewModel`. Essa classe não precisa ser fakeada.

> **Nota:** O código também define um `MockGoRouter`. O router é mockado usando `package:mocktail` e está fora do escopo deste estudo de caso. Você pode encontrar orientações gerais de teste na documentação de testes do Flutter.

Após o view model e suas dependências serem definidos, a árvore de widgets que será testada precisa ser criada. Nos testes do `HomeScreen`, um método `loadWidget` é definido.

#### Exemplo: home_screen_test.dart

```dart
void main() {
  group('HomeScreen tests', () {
    late HomeViewModel viewModel;
    late MockGoRouter goRouter;
    late FakeBookingRepository bookingRepository;

    setUp(
      // ...
    );

    void loadWidget(WidgetTester tester) async {
      await testApp(
        tester,
        ChangeNotifierProvider.value(
          value: FakeAuthRepository() as AuthRepository,
          child: Provider.value(
            value: FakeItineraryConfigRepository() as ItineraryConfigRepository,
            child: HomeScreen(viewModel: viewModel),
          ),
        ),
        goRouter: goRouter,
      );
    }

    // ...
  });
}
```

Esse método chama `testApp`, um método generalizado usado para todos os testes de widget no app Compass. Ele tem esta aparência:

#### Exemplo: testing/app.dart

```dart
void testApp(
  WidgetTester tester,
  Widget body, {
  GoRouter? goRouter,
}) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  await mockNetworkImages(() async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          AppLocalizationDelegate(),
        ],
        theme: AppTheme.lightTheme,
        home: InheritedGoRouter(
          goRouter: goRouter ?? MockGoRouter(),
          child: Scaffold(
            body: body,
          ),
        ),
      ),
    );
  });
}
```

A única função desse método é criar uma árvore de widgets que possa ser testada.

O método `loadWidget` passa as partes únicas de uma árvore de widgets para teste. Neste caso, isso inclui o `HomeScreen` e seu view model, bem como alguns repositories fakeados adicionais que estão mais acima na árvore de widgets.

O ponto mais importante a se levar é que testes de view e view model **requerem apenas mockar repositories** se sua arquitetura for sólida.

---

## Testando a camada de dados

Similar à camada de UI, os componentes da camada de dados possuem entradas e saídas bem definidas, tornando ambos os lados fakeáveis. Para escrever testes unitários para um dado repository, mocke os services dos quais ele depende. O exemplo a seguir mostra um teste unitário para o `BookingRepository`.

#### Exemplo: booking_repository_remote_test.dart

```dart
void main() {
  group('BookingRepositoryRemote tests', () {
    late BookingRepository bookingRepository;
    late FakeApiClient fakeApiClient;

    setUp(() {
      fakeApiClient = FakeApiClient();
      bookingRepository = BookingRepositoryRemote(
        apiClient: fakeApiClient,
      );
    });

    test('should get booking', () async {
      final result = await bookingRepository.getBooking(0);
      final booking = result.asOk.value;
      expect(booking, kBooking);
    });
  });
}
```

Para aprender mais sobre escrever mocks e fakes, confira os exemplos no diretório de testes do app Compass ou leia a documentação de testes do Flutter.