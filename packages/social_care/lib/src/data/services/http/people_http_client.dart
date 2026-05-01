import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — People Context (proxied via BFF).
///
/// Organizational split: no logic changes.
class PeopleHttpClient {
  PeopleHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Looks up a person by CPF via the BFF's people-context proxy.
  ///
  /// Returns `{id, fullName, birthDate, cpf}` on success.
  /// Returns a Failure with 'not_found' if no person matches.
  Future<Result<Map<String, dynamic>>> lookupPersonByCpf(String cpf) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/people/by-cpf/$cpf',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Success(response.data!);
      }
      if (response.statusCode == 404) {
        return const Failure('not_found');
      }
      return failureFromResponse(response, 'Failed to lookup person');
    } catch (e) {
      return failureFromException(e);
    }
  }
}
