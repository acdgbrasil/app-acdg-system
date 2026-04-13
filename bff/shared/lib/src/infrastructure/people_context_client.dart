import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

/// Client for the People Context service.
///
/// Registers persons and retrieves canonical [PersonId]s.
/// Used by both the BFF Web (RegistryHandler) and the Desktop BFF
/// (SyncEngine) to ensure every person exists in people-context
/// before registering with the social-care backend.
class PeopleContextClient {
  PeopleContextClient({
    required String baseUrl,
    required String actorId,
    String? accessToken,
    String Function()? tokenProvider,
    Dio? dio,
  }) : _tokenProvider = tokenProvider,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               headers: {
                 'Content-Type': 'application/json',
                 if (accessToken != null)
                   'Authorization': 'Bearer $accessToken',
                 'X-Actor-Id': actorId,
               },
             ),
           ) {
    if (_tokenProvider != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = _tokenProvider();
            if (token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _dio;
  final String Function()? _tokenProvider;

  /// Registers a person in people-context and returns the canonical PersonId.
  ///
  /// If a person with the same CPF already exists, returns the existing ID
  /// (people-context is idempotent on CPF).
  Future<Result<String>> registerPerson({
    required String fullName,
    required String birthDate,
    String? cpf,
  }) async {
    try {
      final dateOnly = birthDate.contains('T')
          ? birthDate.split('T')[0]
          : birthDate;
      final body = <String, dynamic>{
        'fullName': fullName,
        'birthDate': dateOnly,
      };
      if (cpf != null && cpf.isNotEmpty) {
        body['cpf'] = cpf;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/people',
        data: body,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody == null) {
          return Failure(
            'People Context error (${response.statusCode}): Empty response body',
          );
        }
        final data = responseBody['data'] as Map<String, dynamic>?;
        final personId = data?['id'] as String?;
        if (personId == null) {
          return Failure(
            'People Context error (${response.statusCode}): Missing "id" in response',
          );
        }
        return Success(personId);
      }

      return Failure(
        'People Context error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Finds a person by CPF in people-context.
  ///
  /// Returns `{id, fullName, birthDate, cpf}` on success, or a Failure
  /// if the person is not found (404) or the service is unavailable.
  Future<Result<Map<String, dynamic>>> findPersonByCpf(String cpf) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/people/by-cpf/$cpf',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody == null) {
          return const Failure('People Context: empty response body');
        }
        final data = responseBody['data'] as Map<String, dynamic>?;
        if (data == null) {
          return const Failure('People Context: missing "data" in response');
        }
        return Success(data);
      }

      if (response.statusCode == 404) {
        return const Failure('not_found');
      }

      return Failure(
        'People Context error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Retrieves a person by [personId] from people-context.
  ///
  /// Returns `{id, fullName, birthDate}` on success.
  Future<Result<Map<String, dynamic>>> getPerson(String personId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/people/$personId',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody == null) {
          return Failure(
            'People Context error (${response.statusCode}): Empty response body',
          );
        }
        final data = responseBody['data'] as Map<String, dynamic>?;
        if (data == null) {
          return Failure(
            'People Context error (${response.statusCode}): Missing "data" in response',
          );
        }
        return Success(data);
      }

      return Failure(
        'People Context error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }
}
