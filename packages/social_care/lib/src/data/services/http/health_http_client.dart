import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Health endpoints only.
///
/// Organizational split: no logic changes.
class HealthHttpClient {
  HealthHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Result<void>> checkHealth() async {
    try {
      await _dio.get<dynamic>('/health/live');
      return const Success(null);
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<void>> checkReady() async {
    try {
      await _dio.get<dynamic>('/health/ready');
      return const Success(null);
    } catch (e) {
      return failureFromException(e);
    }
  }
}
