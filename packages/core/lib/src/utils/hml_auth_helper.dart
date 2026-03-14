import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';

/// Helper to authenticate with Zitadel using a Service Account key (JWT Profile).
class HmlAuthHelper {
  HmlAuthHelper({
    required this.userId,
    required this.keyId,
    required this.privateKey,
    this.tokenEndpoint = 'https://auth.acdgbrasil.com.br/oauth/v2/token',
    this.issuer = 'https://auth.acdgbrasil.com.br',
  });

  final String userId;
  final String keyId;
  final String privateKey;
  final String tokenEndpoint;
  final String issuer;

  /// Gets an access token using the JWT Profile grant.
  Future<String> getAccessToken() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final jti = DateTime.now().microsecondsSinceEpoch.toString(); // Unique ID for this request

    // Create JWT assertion
    final jwt = JWT(
      {
        'iss': userId,
        'sub': userId,
        'aud': [issuer, '363109883022671995'], // Issuer URL + Project ID as audience
        'iat': now,
        'exp': now + 300, 
        'jti': jti,      
      },
      header: {
        'kid': keyId,
        'typ': 'JWT',
      },
    );
    final signedJwt = jwt.sign(
      RSAPrivateKey(privateKey.trim()), 
      algorithm: JWTAlgorithm.RS256,
    );

    final dio = Dio();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        tokenEndpoint,
        data: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': signedJwt,
          'scope': 'openid profile urn:zitadel:iam:org:project:id:363109883022671995:aud',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true, // Handle error response manually
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data!;
        return data['access_token'] as String;
      } else {
        print('HmlAuthHelper: Error from Zitadel (${response.statusCode}): ${response.data}');
        throw Exception('Failed to get access token: ${response.data}');
      }
    } on DioException catch (e) {
      print('HmlAuthHelper: Dio Error: ${e.message}');
      rethrow;
    }
  }

  /// Factory from the JSON file content.
  factory HmlAuthHelper.fromJson(String jsonContent) {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    return HmlAuthHelper(
      userId: data['userId'] as String,
      keyId: data['keyId'] as String,
      privateKey: data['key'] as String,
    );
  }

  /// Factory from environment variables (useful for CI/Tests).
  factory HmlAuthHelper.fromEnv() {
    var key = const String.fromEnvironment('key');
    if (key.isNotEmpty && !key.startsWith('-----BEGIN')) {
      try {
        key = utf8.decode(base64.decode(key));
      } catch (_) {
        // Not base64, use as is
      }
    }
    return HmlAuthHelper(
      userId: const String.fromEnvironment('userId'),
      keyId: const String.fromEnvironment('keyId'),
      privateKey: key,
    );
  }
}
