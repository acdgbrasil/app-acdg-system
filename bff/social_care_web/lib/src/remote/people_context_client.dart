import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

/// Client for the People Context service.
///
/// Registers persons and retrieves canonical [PersonId]s.
/// Used by the BFF Web before creating family members in social-care,
/// ensuring every person exists in the people-context registry.
class PeopleContextClient {
  PeopleContextClient({
    required String baseUrl,
    required String accessToken,
    required String actorId,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $accessToken',
                  'X-Actor-Id': actorId,
                },
              ),
            );

  final Dio _dio;

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
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(data['id'] as String);
      }

      return Failure(
        'People Context error (${response.statusCode}): ${response.data}',
      );
    } catch (e) {
      return Failure('People Context unreachable: $e');
    }
  }
}
