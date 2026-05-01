import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Lookup tables.
///
/// Organizational split: no logic changes.
class LookupHttpClient {
  LookupHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/lookups/$tableName',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!;
        return Success(
          data
              .cast<Map<String, dynamic>>()
              .map(
                (item) => LookupItem(
                  id: item['id'] as String,
                  codigo: item['codigo'] as String,
                  descricao: item['descricao'] as String,
                ),
              )
              .toList(),
        );
      }
      return failureFromResponse(
        response,
        'Lookup table $tableName not found',
      );
    } catch (e) {
      return failureFromException(e);
    }
  }
}
