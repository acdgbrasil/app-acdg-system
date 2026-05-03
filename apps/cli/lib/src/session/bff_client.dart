/// HTTP client wrapper for BFF calls — Result-returning, never throws.
///
/// C01 contract:
///   * Constructor wires baseUrl + [CredentialStore] + optional [Dio]
///     (injectable for tests).
///   * Bearer interceptor: when [CredentialStore.read] yields credentials,
///     the next request carries `Authorization: Bearer <token>`. When it
///     yields `null`, no Authorization header is added.
///   * `get<T>` returns `Result<T>` — adapter exceptions never escape.
///
/// Real decoding, retries, refresh-on-401, and the rest of the verb surface
/// land in C02+ as actual commands need them.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

import '../errors/cli_error.dart';
import 'credential_store.dart';

/// Thin Dio wrapper that:
///   * injects Bearer tokens from the [CredentialStore],
///   * normalises every failure into a [CliError]-shaped [Failure].
final class BffClient {
  BffClient({
    required this.baseUrl,
    required CredentialStore credentialStore,
    Dio? dio,
  }) : _credentialStore = credentialStore,
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final creds = await _credentialStore.read();
          if (creds != null) {
            options.headers['Authorization'] = 'Bearer ${creds.accessToken}';
          }
          handler.next(options);
        },
      ),
    );
  }

  final String baseUrl;
  final CredentialStore _credentialStore;
  final Dio _dio;

  /// Issues `GET [path]` and returns a [Result].
  ///
  /// * Adapter throws → [Failure] wrapping a translated [CliError]
  ///   (network / auth / server).
  /// * 2xx with a [decode] callback → [Success] wrapping the decoded value.
  /// * 2xx without [decode] → [Success] wrapping the raw response data
  ///   coerced to `T`.
  Future<Result<T>> get<T>(
    String path, {
    T Function(Object? data)? decode,
  }) async {
    try {
      final response = await _dio.get<Object?>(path);
      if (decode != null) {
        return Success(decode(response.data));
      }
      return Success(response.data as T);
    } on DioException catch (e, stack) {
      return Failure(_translate(e), stackTrace: stack);
    }
  }

  /// Maps a [DioException] into the matching [CliError] variant.
  CliError _translate(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkError(e.message ?? 'connection failed');
      case DioExceptionType.badCertificate:
        return NetworkError(e.message ?? 'TLS handshake failed');
      case DioExceptionType.cancel:
        return NetworkError(e.message ?? 'request cancelled');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = e.response?.statusCode;
        if (status == 401) return const AuthRequiredError();
        if (status != null) {
          return ServerError(status, e.message ?? 'server error');
        }
        return NetworkError(e.message ?? 'unknown transport failure');
    }
  }
}
