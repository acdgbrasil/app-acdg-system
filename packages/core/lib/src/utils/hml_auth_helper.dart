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
    
    // Create JWT assertion
    final jwt = JWT(
      {
        'iss': userId,
        'sub': userId,
        'aud': issuer,
        'iat': now,
        'exp': now + 3600,
      },
      header: {
        'kid': keyId,
      },
    );

    final signedJwt = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);

    final dio = Dio();
    final response = await dio.post<Map<String, dynamic>>(
      tokenEndpoint,
      data: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signedJwt,
        'scope': 'openid profile email urn:zitadel:iam:org:project:roles',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data!;
      return data['access_token'] as String;
    } else {
      throw Exception('Failed to get access token: ${response.data}');
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
