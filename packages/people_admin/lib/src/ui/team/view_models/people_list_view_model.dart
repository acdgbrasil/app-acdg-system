import 'package:core/core.dart';

import '../../../domain/models/person.dart';
import '../../../domain/models/register_worker_intent.dart';
import '../../../logic/use_case/register_worker_use_case.dart';
import '../../../logic/use_case/search_people_use_case.dart';

class PeopleListViewModel extends BaseViewModel {
  PeopleListViewModel({
    required SearchPeopleUseCase searchPeopleUseCase,
    required RegisterWorkerUseCase registerWorkerUseCase,
  })  : _searchPeopleUseCase = searchPeopleUseCase,
        _registerWorkerUseCase = registerWorkerUseCase {
    loadCommand = Command0<void>(_initialLoad);
    searchCommand = Command1<void, String>(_search);
    loadMoreCommand = Command0<void>(_loadMore);
    registerCommand = Command1<void, RegisterWorkerIntent>(_register);
  }

  final SearchPeopleUseCase _searchPeopleUseCase;
  final RegisterWorkerUseCase _registerWorkerUseCase;

  late final Command0<void> loadCommand;
  late final Command1<void, String> searchCommand;
  late final Command0<void> loadMoreCommand;
  late final Command1<void, RegisterWorkerIntent> registerCommand;

  List<Person> _people = [];
  String? _nextCursor;
  String _lastQuery = '';

  List<Person> get people => List.unmodifiable(_people);
  bool get hasMore => _nextCursor != null;

  Future<Result<void>> _initialLoad() => _search('');

  Future<Result<void>> _search(String query) async {
    _lastQuery = query;

    final bool isCpf = RegExp(r'^\d+$').hasMatch(query);
    final params = (
      limit: null as int?,
      name: isCpf ? null : query,
      cpf: isCpf ? query : null,
      cursor: null as String?,
    );

    final result = await _searchPeopleUseCase.execute(params);

    switch (result) {
      case Success(:final value):
        _people = List.of(value.items);
        _nextCursor = value.nextCursor;
      case Failure(:final error):
        _people = [];
        _nextCursor = null;
        notifyListeners();
        return Failure(error);
    }

    notifyListeners();
    return const Success(null);
  }

  Future<Result<void>> _loadMore() async {
    if (_nextCursor == null) {
      return const Success(null);
    }

    final bool isCpf = RegExp(r'^\d+$').hasMatch(_lastQuery);
    final params = (
      limit: null as int?,
      name: isCpf ? null : _lastQuery,
      cpf: isCpf ? _lastQuery : null,
      cursor: _nextCursor,
    );

    final result = await _searchPeopleUseCase.execute(params);

    switch (result) {
      case Success(:final value):
        _people = [..._people, ...value.items];
        _nextCursor = value.nextCursor;
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }

    notifyListeners();
    return const Success(null);
  }

  Future<Result<void>> _register(RegisterWorkerIntent intent) async {
    final result = await _registerWorkerUseCase.execute(intent);

    switch (result) {
      case Success():
        // Refresh the list after registration
        await _search(_lastQuery);
      case Failure(:final error):
        return Failure(error);
    }

    return const Success(null);
  }

  @override
  void onDispose() {
    loadCommand.dispose();
    searchCommand.dispose();
    loadMoreCommand.dispose();
    registerCommand.dispose();
  }
}
