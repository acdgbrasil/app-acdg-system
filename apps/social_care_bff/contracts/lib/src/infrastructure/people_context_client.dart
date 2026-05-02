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

  /// Registers a person with a Zitadel login (for team members).
  ///
  /// Sets `createLogin: true` which provisions a Zitadel user.
  /// Returns the canonical PersonId on success.
  Future<Result<String>> registerPersonWithLogin({
    required String fullName,
    required String birthDate,
    required String email,
    String? cpf,
    String? initialPassword,
  }) async {
    try {
      final dateOnly = birthDate.contains('T')
          ? birthDate.split('T')[0]
          : birthDate;
      final body = <String, dynamic>{
        'fullName': fullName,
        'birthDate': dateOnly,
        'email': email,
        'createLogin': true,
      };
      if (cpf != null && cpf.isNotEmpty) body['cpf'] = cpf;
      if (initialPassword != null && initialPassword.isNotEmpty) {
        body['initialPassword'] = initialPassword;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/people',
        data: body,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 ||
          response.statusCode == 200 ||
          response.statusCode == 207) {
        final data = response.data?['data'] as Map<String, dynamic>?;
        final personId = data?['id'] as String?;
        if (personId == null) {
          return Failure(
            'People Context error (${response.statusCode}): Missing "id"',
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

  /// Assigns a role to a person for a specific system.
  Future<Result<void>> assignRole({
    required String personId,
    required String system,
    required String role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/people/$personId/roles',
        data: {'system': system, 'role': role},
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 204) {
        return const Success(null);
      }

      return Failure(
        'Assign role error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Queries roles across all people for a given system.
  ///
  /// Returns a list of `{person: {...}, role: {...}}` objects.
  Future<Result<List<Map<String, dynamic>>>> queryRoles({
    required String system,
    String? role,
    bool active = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'system': system,
        'active': active.toString(),
      };
      if (role != null) queryParams['role'] = role;

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/roles',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data?['data'] as List<dynamic>?;
        if (data == null) {
          return const Success([]);
        }
        return Success(data.cast<Map<String, dynamic>>());
      }

      return Failure(
        'Query roles error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Deactivates a person and their Zitadel user.
  Future<Result<void>> deactivatePerson(String personId) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/people/$personId/deactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204) return const Success(null);

      return Failure(
        'Deactivate error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Reactivates a previously deactivated person.
  Future<Result<void>> reactivatePerson(String personId) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/people/$personId/reactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204) return const Success(null);

      return Failure(
        'Reactivate error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Requests a password reset for a person's Zitadel user.
  Future<Result<void>> requestPasswordReset(String personId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/people/$personId/request-password-reset',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204) return const Success(null);

      return Failure(
        'Password reset error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Lists all roles for a specific person, optionally filtered by active status.
  Future<Result<List<Map<String, dynamic>>>> listPersonRoles(
    String personId, {
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (active != null) queryParams['active'] = active.toString();

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/people/$personId/roles',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data?['data'] as List<dynamic>?;
        if (data == null) return const Success([]);
        return Success(data.cast<Map<String, dynamic>>());
      }

      return Failure(
        'List roles error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Searches people with optional filters and cursor-based pagination.
  ///
  /// Returns `{items: [...], nextCursor: '...'}` on success.
  Future<Result<Map<String, dynamic>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (name != null) queryParams['name'] = name;
      if (cpf != null) queryParams['cpf'] = cpf;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/people',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        if (responseBody == null) {
          return const Failure('People Context: empty response body');
        }
        final rawData = responseBody['data'];
        if (rawData == null) {
          return const Failure('People Context: missing "data" in response');
        }

        // People Context may return data as a List (items directly)
        // or as a Map (with items + nextCursor). Normalize to Map.
        if (rawData is List) {
          return Success(<String, dynamic>{
            'items': rawData,
            'nextCursor': responseBody['nextCursor'],
          });
        }

        return Success(rawData as Map<String, dynamic>);
      }

      return Failure(
        'People Context error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Deactivates a specific role for a person.
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/people/$personId/roles/$roleId/deactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204) return const Success(null);

      return Failure(
        'Deactivate role error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }

  /// Reactivates a previously deactivated role for a person.
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/people/$personId/roles/$roleId/reactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204) return const Success(null);

      return Failure(
        'Reactivate role error (${response.statusCode}): ${response.data}',
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
