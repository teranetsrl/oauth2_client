import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';

void main() {
  const accessToken = 'test_access_token';
  const refreshToken = 'test_refresh_token';
  final scopes = ['scope1', 'scope2'];
  const expiresIn = 3600;
  const tokenType = 'Bearer';

  group('Access Token Response.', () {
    test('Valid response', () async {
      final respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': expiresIn,
        'http_status_code': 200,
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      expect(resp.accessToken, accessToken);
      expect(resp.refreshToken, refreshToken);
      expect(resp.expiresIn, expiresIn);
      expect(resp.isValid(), true);
      expect(resp.isExpired(), false);
      expect(resp.isBearer(), true);
    });

    test('Token expiration', () async {
      final respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 1,
        'http_status_code': 200,
        'expiration_date': DateTime.now()
            .add(const Duration(seconds: 1))
            .millisecondsSinceEpoch,
      };

      final resp = AccessTokenResponse.fromMap(respMap);
      await Future.delayed(const Duration(seconds: 2), () => 'X');

      expect(resp.isExpired(), true);
      expect(resp.refreshNeeded(), true);
    });

    test('Error response', () async {
      final resp = AccessTokenResponse.errorResponse();
      expect(resp.isValid(), false);
    });

    test('Convert to map', () async {
      final respMap = {
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': expiresIn,
        'http_status_code': 200,
      };

      final resp = AccessTokenResponse.fromMap(respMap);

      expect(
        resp.toMap(),
        allOf(
          containsPair('http_status_code', 200),
          containsPair('access_token', accessToken),
          containsPair('token_type', tokenType),
          containsPair('refresh_token', refreshToken),
          containsPair('scope', scopes),
          containsPair('expires_in', expiresIn),
        ),
      );
    });
  });

  test('Conversion from HTTP response', () async {
    //The OAuth 2 standard suggests that the scopes should be a space-separated list,
    //but some providers (i.e. GitHub) return a comma-separated list
    var response = http.Response(
      '{"access_token": "TKN12345", "token_type": "Bearer", "scope": "scope1 scope2"}',
      200,
    );

    var resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, ['scope1', 'scope2']);

    response = http.Response(
      '{"access_token": "TKN12345", "token_type": "Bearer", "scope": "scope1,scope2"}',
      200,
    );

    resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, ['scope1', 'scope2']);
  });

  test('Conversion from HTTP response with no "scope" parameter', () async {
    //If no scope parameter is sent by the server in the Access Token Response
    //it means that it is identical to the one(s) requested by the client
    final response = http.Response(
      '{"access_token": "TKN12345", "token_type": "Bearer"}',
      200,
    );

    var resp = AccessTokenResponse.fromHttpResponse(
      response,
      requestedScopes: ['scope1', 'scope2'],
    );

    expect(resp.scope, ['scope1', 'scope2']);

    //If the server returned no "scope" parameter AND the client didn't request one, the scope in the AccessTokenResponse should be null
    http.Response('{"access_token": "TKN12345", "token_type": "Bearer"}', 200);

    resp = AccessTokenResponse.fromHttpResponse(response);

    expect(resp.scope, null);
  });

  test('toString(1)', () async {
    final respMap = <String, dynamic>{
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scopes,
      'expires_in': expiresIn,
      'http_status_code': 200,
    };

    final resp = AccessTokenResponse.fromMap(respMap);

    expect(resp.toString(), 'Access Token: $accessToken');
  });

  test('toString(2)', () async {
    final respMap = <String, dynamic>{
      'error': 'generic_error',
      'error_description': 'error_desc',
      'http_status_code': 400,
    };

    final resp = AccessTokenResponse.fromMap(respMap);

    expect(resp.toString(), 'HTTP 400 - generic_error error_desc');
  });

  test('Valid response but expires_in param as string', () async {
    final respMap = {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scopes,
      'expires_in': '3600',
      'http_status_code': 200,
    };

    final resp = AccessTokenResponse.fromMap(respMap);

    expect(resp.isValid(), true);
    expect(resp.expiresIn, 3600);
  });

  test('Fetch non standard response field', () async {
    final respMap = {
      'token_type': tokenType,
      'http_status_code': 200,
      'custom_param': 'custom_val',
    };

    final resp = AccessTokenResponse.fromMap(respMap);

    expect(resp.getRespField('custom_param'), 'custom_val');
  });
}
