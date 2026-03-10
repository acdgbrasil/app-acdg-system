# Camada de dados

Um walkthrough da camada de dados de um app que implementa a arquitetura MVVM.

---

A camada de dados de uma aplicação, conhecida como o *model* na terminologia MVVM, é a fonte de verdade para todos os dados da aplicação. Como fonte de verdade, é o único lugar onde os dados da aplicação devem ser atualizados.

Ela é responsável por consumir dados de diversas APIs externas, expor esses dados para a UI, lidar com eventos da UI que requerem atualização de dados e enviar requisições de atualização para essas APIs externas conforme necessário.

A camada de dados neste guia tem dois componentes principais: **repositories** e **services**.

- **Repositories** são a fonte de verdade para os dados da aplicação e contêm lógica relacionada a esses dados, como atualizar os dados em resposta a novos eventos do usuário ou buscar dados dos services. Repositories são responsáveis por sincronizar dados quando recursos offline são suportados, gerenciar lógica de retry e cache de dados.
- **Services** são classes Dart sem estado que interagem com APIs, como servidores HTTP e plugins de plataforma. Qualquer dado que sua aplicação precisa e que não é criado dentro do código da aplicação em si deve ser buscado a partir de classes service.

---

## Definindo um service

Uma classe service é o menos ambíguo de todos os componentes da arquitetura. É sem estado e suas funções não possuem efeitos colaterais. Seu único trabalho é encapsular uma API externa. Geralmente existe uma classe service por fonte de dados, como um servidor HTTP do cliente ou um plugin de plataforma.

No app Compass, por exemplo, existe um service `APIClient` que lida com as chamadas CRUD para o servidor voltado ao cliente.

### Exemplo: api_client.dart

```dart
class ApiClient {
  // Código omitido para fins de demonstração.

  Future<Result<List<ContinentApiModel>>> getContinents() async { /* ... */ }
  Future<Result<List<DestinationApiModel>>> getDestinations() async { /* ... */ }
  Future<Result<List<ActivityApiModel>>> getActivityByDestination(String ref) async { /* ... */ }
  Future<Result<List<BookingApiModel>>> getBookings() async { /* ... */ }
  Future<Result<BookingApiModel>> getBooking(int id) async { /* ... */ }
  Future<Result<BookingApiModel>> postBooking(BookingApiModel booking) async { /* ... */ }
  Future<Result<void>> deleteBooking(int id) async { /* ... */ }
  Future<Result<UserApiModel>> getUser() async { /* ... */ }
}
```

O service em si é uma classe, onde cada método encapsula um endpoint de API diferente e expõe objetos de resposta assíncronos. Continuando o exemplo anterior de deletar uma reserva salva, o método `deleteBooking` retorna um `Future<Result<void>>`.

> **Nota:** Alguns métodos retornam classes de dados que são especificamente para dados brutos da API, como a classe `BookingApiModel`. Como você verá em breve, repositories extraem os dados e os expõem em um formato diferente.

---

## Definindo um repository

A única responsabilidade de um repository é gerenciar dados da aplicação. Um repository é a fonte de verdade para um único tipo de dado da aplicação, e deve ser o único lugar onde esse tipo de dado é mutado. O repository é responsável por buscar novos dados de fontes externas, lidar com lógica de retry, gerenciar dados em cache e transformar dados brutos em modelos de domínio.

Você deve ter um repository separado para cada tipo diferente de dado na sua aplicação. Por exemplo, o app Compass possui repositories chamados `UserRepository`, `BookingRepository`, `AuthRepository`, `DestinationRepository` e mais.

O exemplo a seguir é o `BookingRepository` do app Compass e mostra a estrutura básica de um repository.

### Exemplo: booking_repository_remote.dart

```dart
class BookingRepositoryRemote implements BookingRepository {
  BookingRepositoryRemote({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  List<Destination>? _cachedDestinations;

  Future<Result<void>> createBooking(Booking booking) async {...}
  Future<Result<Booking>> getBooking(int id) async {...}
  Future<Result<List<BookingSummary>>> getBookingsList() async {...}
  Future<Result<void>> delete(int id) async {...}
}
```

> **Ambientes de desenvolvimento vs. staging:** A classe no exemplo anterior é `BookingRepositoryRemote`, que estende uma classe abstrata chamada `BookingRepository`. Essa classe base é usada para criar repositories para diferentes ambientes. Por exemplo, o app Compass também possui uma classe chamada `BookingRepositoryLocal`, que é usada para desenvolvimento local. Você pode ver as diferenças entre as classes `BookingRepository` no GitHub.

O `BookingRepository` recebe o service `ApiClient` como entrada, que ele usa para buscar e atualizar os dados brutos do servidor. É importante que o service seja um membro privado, para que a camada de UI não consiga contornar o repository e chamar um service diretamente.

Com o service `ApiClient`, o repository pode buscar atualizações nas reservas salvas de um usuário que podem acontecer no servidor e fazer requisições POST para deletar reservas salvas.

Os dados brutos que um repository transforma em modelos de aplicação podem vir de múltiplas fontes e múltiplos services, e portanto repositories e services possuem um relacionamento muitos-para-muitos. Um service pode ser usado por qualquer número de repositories, e um repository pode usar mais de um service.

---

## Modelos de domínio

O `BookingRepository` produz objetos `Booking` e `BookingSummary`, que são **modelos de domínio**. Todos os repositories produzem modelos de domínio correspondentes. Esses modelos de dados diferem dos modelos de API pois contêm apenas os dados necessários pelo restante do app. Modelos de API contêm dados brutos que frequentemente precisam ser filtrados, combinados ou removidos para serem úteis aos view models do app. O repository refina os dados brutos e os produz como modelos de domínio.

No app de exemplo, modelos de domínio são expostos através de valores de retorno em métodos como `BookingRepository.getBooking`. O método `getBooking` é responsável por buscar os dados brutos do service `ApiClient` e transformá-los em um objeto `Booking`. Ele faz isso combinando dados de múltiplos endpoints do service.

### Exemplo: booking_repository_remote.dart

```dart
// Este método foi editado para brevidade.
Future<Result<Booking>> getBooking(int id) async {
  try {
    // Busca a reserva por ID do servidor.
    final resultBooking = await _apiClient.getBooking(id);
    if (resultBooking is Error<BookingApiModel>) {
      return Result.error(resultBooking.error);
    }

    final booking = resultBooking.asOk.value;

    final destination = _apiClient.getDestination(booking.destinationRef);
    final activities = _apiClient.getActivitiesForBooking(
      booking.activitiesRef);

    return Result.ok(
      Booking(
        startDate: booking.startDate,
        endDate: booking.endDate,
        destination: destination,
        activity: activities,
      ),
    );
  } on Exception catch (e) {
    return Result.error(e);
  }
}
```

> **Nota:** No app Compass, classes service retornam objetos `Result`. `Result` é uma classe utilitária que encapsula chamadas assíncronas e facilita o tratamento de erros e o gerenciamento de estado da UI que depende de chamadas assíncronas. Esse padrão é uma recomendação, mas não um requisito. A arquitetura recomendada neste guia pode ser implementada sem ele. Você pode aprender sobre essa classe na receita do cookbook de Result.

---

## Completando o ciclo de eventos

Ao longo desta página, você viu como um usuário pode deletar uma reserva salva, começando com um evento — o usuário deslizando em um widget `Dismissible`. O view model lida com esse evento delegando a mutação real dos dados para o `BookingRepository`. O trecho a seguir mostra o método `BookingRepository.deleteBooking`.

### Exemplo: booking_repository_remote.dart

```dart
Future<Result<void>> delete(int id) async {
  try {
    return _apiClient.deleteBooking(id);
  } on Exception catch (e) {
    return Result.error(e);
  }
}
```

O repository envia uma requisição POST para o API client com o método `_apiClient.deleteBooking` e retorna um `Result`. O `HomeViewModel` consome o `Result` e os dados que ele contém, então finalmente chama `notifyListeners`, completando o ciclo.