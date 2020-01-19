// import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/authorization_response.dart';
import 'package:oauth2_client/src/oauth2_client_impl.dart';
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:oauth2_client/src/web_auth.dart';

class WebAuthMockClient extends Mock implements WebAuth {}
class HttpMockClient extends Mock implements http.Client {}

void main() {

  final webAuthClient = WebAuthMockClient();

  final String customUriScheme = 'myurlscheme:/';
  final String codeVerifier = '12345';
  final String codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
  final String authCode = '12345';
  final String redirectUri = 'myurlscheme:/oauth2';
  final String clientId = 'myclientid';

  final String authorizeUrl = 'http://my.test.app/authorize';
  final String tokenUrl = 'http://my.test.app/token';

  group('Authorization Code Grant.', () {

    final oauth2Client = OAuth2ClientImpl(
      authorizeUrl: authorizeUrl,
      tokenUrl: tokenUrl,
      redirectUri: redirectUri,
      customUriScheme: customUriScheme
    );

    test('Authorization Request', () async {

      Map authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'scope1',
        'state': '12345',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      };

      when(webAuthClient.authenticate(
        url: OAuth2Utils.addParamsToUrl(authorizeUrl, authParams),
        callbackUrlScheme: customUriScheme
      )).thenAnswer((_) async => authParams['redirect_uri'] + '?code=' + authCode + '&state=' + authParams['state']);

      final AuthorizationResponse authResponse = await oauth2Client.requestAuthorization(
        webAuthClient: webAuthClient,
        clientId: authParams['client_id'],
        scopes: [authParams['scope']],
        codeChallenge: authParams['code_challenge'],
        state: authParams['state']
      );

      expect(authResponse.code, authCode);
    });

    test('Fetch Access Token', () async {

      final httpClient = HttpMockClient();

      final String accessToken = '12345';
      final String refreshToken = '54321';

      Map tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
        // 'client_secret': clientSecret
      };

      when(httpClient.post(tokenUrl, body: tokenParams))
        .thenAnswer((_) async => http.Response('{"access_token": "' + accessToken + '", "token_type": "Bearer", "refresh_token": "' + refreshToken + '", "expires_in": 3600}', 200));

      final AccessTokenResponse tknResponse = await oauth2Client.requestAccessToken(
        httpClient: httpClient,
        code: authCode,
        clientId: clientId,
        // clientSecret: clientSecret,
        codeVerifier: codeVerifier
      );

      expect(tknResponse.accessToken, accessToken);

    });

  });

}
