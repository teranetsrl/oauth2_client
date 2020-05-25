import 'package:http/http.dart' as http;

import 'package:flutter_test/flutter_test.dart';
import 'package:oauth2_client/access_token_response.dart';

void main() {
  final String accessToken = 'test_access_token';
  final String refreshToken = 'test_refresh_token';
  final List<String> scopes = ['scope1', 'scope2'];
  final int expiresIn = 3600;
  final String tokenType = 'Bearer';

  group('Access Token Response.', () {
    test('Valid response', () async {
      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': expiresIn
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      expect(resp.accessToken, accessToken);
      expect(resp.refreshToken, refreshToken);
      expect(resp.expiresIn, expiresIn);
      expect(resp.isValid(), false);
      expect(resp.isExpired(), false);
      expect(resp.isBearer(), true);
    });

    test('Token expiration', () async {
      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 1
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      await Future.delayed(const Duration(seconds: 2), () => "X");

      expect(resp.isExpired(), true);
      expect(resp.refreshNeeded(), true);
    });

    test('Error response', () async {
      final Map<String, dynamic> respMap = {
        'error': 'ERROR',
        'error_description': 'ERROR_DESC',
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      expect(resp.isValid(), false);
    });

    test('Convert to map', () async {
      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': expiresIn
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      DateTime now = DateTime.now();
      DateTime expirationDate = now.add(Duration(seconds: expiresIn));

      expect(
          resp.toMap(),
          allOf(
              containsPair('access_token', accessToken),
              containsPair('token_type', tokenType),
              containsPair('refresh_token', refreshToken),
              containsPair('scope', scopes),
              containsPair(
                  'expiration_date', expirationDate.millisecondsSinceEpoch)));
    });
  });

  test('Conversion from HTTP response', () async {
    //The OAuth 2 standard suggests that the scopes should be a space-separated list,
    //but some providers (i.e. GitHub) return a comma-separated list
    http.Response response = http.Response(
        '{"access_token": "TKN12345", "token_type": "Bearer", "scope": "scope1 scope2"}',
        200);

    AccessTokenResponse resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, ['scope1', 'scope2']);

    response = http.Response(
        '{"access_token": "TKN12345", "token_type": "Bearer", "scope": "scope1,scope2"}',
        200);

    resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, ['scope1', 'scope2']);
  });

  test('Conversion from HTTP response with no "scope" parameter', () async {
    //If no scope parameter is sent by the server in the Access Token Response
    //it means that it is identical to the one(s) requested by the client
    http.Response response = http.Response(
        '{"access_token": "TKN12345", "token_type": "Bearer"}', 200);

    AccessTokenResponse resp = AccessTokenResponse.fromHttpResponse(response,
        requestedScopes: ['scope1', 'scope2']);

    expect(resp.scope, ['scope1', 'scope2']);

    //If the server returned no "scope" parameter AND the client didn't request one, the scope in the AccessTokenResponse should be null
    http.Response('{"access_token": "TKN12345", "token_type": "Bearer"}', 200);

    resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, null);
  });
}
