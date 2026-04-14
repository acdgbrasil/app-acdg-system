import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../../domain/errors/team_errors.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/models/person.dart';
import '../../domain/models/register_worker_intent.dart';
import '../../domain/models/system_role.dart';
import '../models/person_dto.dart';
import '../models/system_role_dto.dart';

class PeopleAdminClient {
  PeopleAdminClient({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? '/api',
              contentType: 'application/json',
              extra: {'withCredentials': true},
            ),
          );

  final Dio _dio;

  Future<Result<PaginatedResult<Person>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (name != null) queryParams['name'] = name;
      if (cpf != null) queryParams['cpf'] = cpf;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dio.get<Map<String, dynamic>>(
        '/team/people',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null && data['items'] is List) {
          final itemsList = data['items'] as List<dynamic>;
          final items = itemsList
              .cast<Map<String, dynamic>>()
              .map((json) => PersonDto.fromJson(json).toDomain())
              .toList();

          final nextCursor = data['nextCursor'] as String?;

          return Success(PaginatedResult(items: items, nextCursor: nextCursor));
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to fetch people');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<Person>> getPersonById(String personId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/team/people/$personId',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null) {
          return Success(PersonDto.fromJson(data).toDomain());
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to fetch person');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<Person>> getPersonByCpf(String cpf) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/team/people/by-cpf/$cpf',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null) {
          return Success(PersonDto.fromJson(data).toDomain());
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to fetch person by CPF');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<String>> registerPerson(RegisterWorkerIntent intent) async {
    try {
      final payload = {
        'fullName': intent.fullName,
        'birthDate': intent.birthDate,
        'email': intent.email,
        if (intent.cpf != null) 'cpf': intent.cpf,
        if (intent.initialPassword != null)
          'initialPassword': intent.initialPassword,
        'createLogin': intent.initialPassword != null,
      };

      final response = await _dio.post<Map<String, dynamic>>(
        '/team',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null) {
          final id = data['personId'] as String? ?? data['id'] as String? ?? '';
          return Success(id);
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to register person');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> deactivatePerson(String personId) async {
    try {
      final response = await _dio.put<dynamic>(
        '/team/$personId/deactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to deactivate person');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> reactivatePerson(String personId) async {
    try {
      final response = await _dio.put<dynamic>(
        '/team/$personId/reactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to reactivate person');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> requestPasswordReset(String personId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/team/$personId/reset-password',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to reset password');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> assignRole({
    required String personId,
    required String system,
    required String role,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/team/people/$personId/roles',
        data: {'system': system, 'role': role},
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to assign role');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<List<SystemRole>>> fetchRolesForPerson(
    String personId, {
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (active != null) queryParams['active'] = active;

      final response = await _dio.get<List<dynamic>>(
        '/team/people/$personId/roles',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null) {
          final roles = data
              .cast<Map<String, dynamic>>()
              .map((json) => SystemRoleDto.fromJson(json).toDomain())
              .toList();
          return Success(roles);
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to fetch roles');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/team/people/$personId/roles/$roleId/deactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to deactivate role');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/team/people/$personId/roles/$roleId/reactivate',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to reactivate role');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  Future<Result<List<SystemRole>>> queryRolesBySystem({
    required String system,
    String? role,
    bool? active,
  }) async {
    try {
      final queryParams = <String, dynamic>{'system': system};
      if (role != null) queryParams['role'] = role;
      if (active != null) queryParams['active'] = active;

      final response = await _dio.get<List<dynamic>>(
        '/team/roles',
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data = response.data;
        if (data != null) {
          final roles = data
              .cast<Map<String, dynamic>>()
              .map((json) => SystemRoleDto.fromJson(json).toDomain())
              .toList();
          return Success(roles);
        }
        return const Failure(UnexpectedTeamError('Invalid response payload'));
      }
      return _failureFromResponse(response, 'Failed to query roles');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  bool _isSuccessStatus(int? statusCode) =>
      statusCode == 200 || statusCode == 201 || statusCode == 204;

  Failure<T> _failureFromResponse<T>(
    Response<dynamic> response,
    String fallback,
  ) {
    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = fallback;
    String code = 'SRV-$statusCode';

    if (data is Map<String, dynamic>) {
      final errorStr = data['error'] as String?;
      final messageStr = data['message'] as String?;

      if (errorStr != null) {
        final match = RegExp(r'^([A-Z]+-\d+):\s*(.*)$').firstMatch(errorStr);
        if (match != null) {
          code = match.group(1)!;
          final parsedMessage = match.group(2);
          message = (parsedMessage != null && parsedMessage.trim().isNotEmpty)
              ? parsedMessage
              : (messageStr ?? fallback);
        } else {
          message = messageStr ?? errorStr;
        }
      } else if (messageStr != null) {
        message = messageStr;
      }
    }

    return Failure(_mapToTeamError(code, message, statusCode));
  }

  TeamError _mapToTeamError(String code, String message, int httpStatus) {
    return switch (code) {
      'SRV-409' => const TeamConflictError(),
      'SRV-404' => TeamNotFoundError(message),
      _ => TeamServerError(
        httpStatus: httpStatus,
        backendCode: code,
        backendMessage: message,
      ),
    };
  }

  Failure<T> _failureFromException<T>(Object e) {
    if (e is DioException) {
      final isNetwork = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => true,
        _ => false,
      };
      if (isNetwork) {
        return Failure(TeamNetworkError(e.message ?? e.type.name));
      }
    }
    return Failure(UnexpectedTeamError(e));
  }
}