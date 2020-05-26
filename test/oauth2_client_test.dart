import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/authorization_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:oauth2_client/src/web_auth.dart';

class WebAuthMockClient extends Mock implements WebAuth {}

class HttpClientMock extends Mock implements http.Client {}

void main() {
  final webAuthClient = WebAuthMockClient();

  final String customUriScheme = 'myurlscheme:/';
  final String codeVerifier = '12345';
  final String codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
  final String authCode = '12345';
  final String redirectUri = 'myurlscheme:/oauth2';
  final String clientId = 'myclientid';
  final String clientSecret = 'test_secret';

  final String authorizeUrl = 'http://my.test.app/authorize';
  final String tokenUrl = 'http://my.test.app/token';
  final String revokeUrl = 'http://my.test.app/revoke';

  final String state = 'test_state';
  final List<String> scopes = ['scope1', 'scope2'];

  final String refreshToken = 'test_refresh_token';
  final String accessToken = 'test_access_token';

  final String authorizationCode = 'test_code';

  group('Authorization Code Grant.', () {
    final oauth2Client = OAuth2Client(
        authorizeUrl: authorizeUrl,
        tokenUrl: tokenUrl,
        redirectUri: redirectUri,
        customUriScheme: customUriScheme);

    test('Authorization Request', () async {
      Map authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      };

      when(webAuthClient.authenticate(
              url: OAuth2Utils.addParamsToUrl(authorizeUrl, authParams),
              callbackUrlScheme: customUriScheme))
          .thenAnswer((_) async =>
              redirectUri + '?code=' + authCode + '&state=' + state);

      final AuthorizationResponse authResponse =
          await oauth2Client.requestAuthorization(
              webAuthClient: webAuthClient,
              clientId: clientId,
              scopes: scopes,
              codeChallenge: codeChallenge,
              state: state);

      expect(authResponse.code, authCode);
    });

    test('Fetch Access Token', () async {
      final httpClient = HttpClientMock();

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
          // body: captureAnyNamed('body'))) //tokenParams))
          .thenAnswer((_) async => http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      final AccessTokenResponse tknResponse =
          await oauth2Client.requestAccessToken(
              httpClient: httpClient,
              code: authCode,
              clientId: clientId,
              // clientSecret: clientSecret,
              codeVerifier: codeVerifier);

      expect(tknResponse.accessToken, accessToken);
    });

    test('Error fetching Access Token', () async {
      final httpClient = HttpClientMock();

      Map tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
        // 'client_secret': clientSecret
      };

      when(httpClient.post(tokenUrl, body: tokenParams))
          .thenAnswer((_) async => http.Response('', 404));

      final AccessTokenResponse tknResponse =
          await oauth2Client.requestAccessToken(
              httpClient: httpClient,
              code: authCode,
              clientId: clientId,
              // clientSecret: clientSecret,
              codeVerifier: codeVerifier);

      expect(tknResponse.isValid(), false);
    });

    test('Token request with authorization code flow', () async {
      Map authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      };

      final httpClient = HttpClientMock();

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

      when(httpClient.post(tokenUrl, body: tokenParams)).thenAnswer((_) async =>
          http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      when(webAuthClient.authenticate(
              url: OAuth2Utils.addParamsToUrl(authorizeUrl, authParams),
              callbackUrlScheme: customUriScheme))
          .thenAnswer((_) async =>
              redirectUri + '?code=' + authCode + '&state=' + state);

      final AccessTokenResponse tknResponse =
          await oauth2Client.getTokenWithAuthCodeFlow(
              webAuthClient: webAuthClient,
              httpClient: httpClient,
              clientId: clientId,
              scopes: scopes,
              state: state,
              codeVerifier: codeVerifier);

      expect(tknResponse.accessToken, accessToken);
    });

    test('Refresh token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl, body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret
      })).thenAnswer((_) async => http.Response(
          '{"access_token": "' +
              accessToken +
              '", "token_type": "Bearer", "refresh_token": "' +
              refreshToken +
              '", "expires_in": 3600}',
          200));

      AccessTokenResponse resp = await oauth2Client.refreshToken(refreshToken,
          clientId: clientId,
          clientSecret: clientSecret,
          httpClient: httpClient);

      expect(resp.isValid(), true);
      expect(resp.accessToken, accessToken);
    });

    test('Error in refreshing token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl, body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret
      })).thenAnswer((_) async => http.Response('', 404));

      AccessTokenResponse resp = await oauth2Client.refreshToken(refreshToken,
          clientId: clientId,
          clientSecret: clientSecret,
          httpClient: httpClient);

      expect(resp.isValid(), false);
    });

    test('Authorization url params (1/5)', () {
      final String authorizeUrl =
          oauth2Client.getAuthorizeUrl(clientId: clientId);

      Map<String, String> urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(containsPair('response_type', 'code'),
              containsPair('client_id', clientId)));
    });

    test('Authorization url params (2/5)', () {
      final String authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId, redirectUri: redirectUri);

      Map<String, String> urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
              containsPair('response_type', 'code'),
              containsPair('client_id', clientId),
              containsPair('redirect_uri', redirectUri)));
    });

    test('Authorization url params (3/5)', () {
      final String authorizeUrl = oauth2Client.getAuthorizeUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
      );

      Map<String, String> urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
            containsPair('response_type', 'code'),
            containsPair('client_id', clientId),
            containsPair('redirect_uri', redirectUri),
            containsPair('scope', scopes.join(' ')),
          ));
    });

    test('Authorization url params (4/5)', () {
      final String authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          scopes: scopes,
          state: state);

      Map<String, String> urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
            containsPair('response_type', 'code'),
            containsPair('client_id', clientId),
            containsPair('redirect_uri', redirectUri),
            containsPair('scope', scopes.join(' ')),
            containsPair('state', state),
          ));
    });

    test('Authorization url params (5/5)', () {
      final String authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          scopes: scopes,
          state: state,
          codeChallenge: codeChallenge);

      Map<String, String> urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
            containsPair('response_type', 'code'),
            containsPair('client_id', clientId),
            containsPair('redirect_uri', redirectUri),
            containsPair('scope', scopes.join(' ')),
            containsPair('state', state),
            containsPair('code_challenge', codeChallenge),
            containsPair('code_challenge_method', 'S256'),
          ));
    });

    test('Token url params (1/5)', () {
      final Map<String, String> params =
          oauth2Client.getTokenUrlParams(code: authorizationCode);

      expect(
          params,
          allOf(containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode)));
    });

    test('Token url params (2/5)', () {
      final Map<String, String> params = oauth2Client.getTokenUrlParams(
          code: authorizationCode, redirectUri: redirectUri);

      expect(
          params,
          allOf(
              containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode),
              containsPair('redirect_uri', redirectUri)));
    });

    test('Token url params (3/5)', () {
      final Map<String, String> params = oauth2Client.getTokenUrlParams(
          code: authorizationCode,
          redirectUri: redirectUri,
          clientId: clientId);

      expect(
          params,
          allOf(
              containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode),
              containsPair('redirect_uri', redirectUri),
              containsPair('client_id', clientId)));
    });

    test('Token url params (4/5)', () {
      final Map<String, String> params = oauth2Client.getTokenUrlParams(
          code: authorizationCode,
          redirectUri: redirectUri,
          clientId: clientId,
          clientSecret: clientSecret);

      expect(
          params,
          allOf(
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
            containsPair('redirect_uri', redirectUri),
            containsPair('client_id', clientId),
            containsPair('client_secret', clientSecret),
          ));
    });

    test('Token url params (5/5)', () {
      final String verifier = 'test_verifier';

      final Map<String, String> params = oauth2Client.getTokenUrlParams(
          code: authorizationCode,
          redirectUri: redirectUri,
          clientId: clientId,
          clientSecret: clientSecret,
          codeVerifier: verifier);

      expect(
          params,
          allOf(
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
            containsPair('redirect_uri', redirectUri),
            containsPair('client_id', clientId),
            containsPair('client_secret', clientSecret),
            containsPair('code_verifier', verifier),
          ));
    });
  });

  group('Client Credentials Grant.', () {
    final oauth2Client = OAuth2Client(
        authorizeUrl: authorizeUrl,
        tokenUrl: tokenUrl,
        redirectUri: redirectUri,
        customUriScheme: customUriScheme);

    test('Get new token', () async {
      final httpClient = HttpClientMock();

      final String accessToken = '12345';
      final String refreshToken = '54321';

      Map authParams = {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
        // 'scope': scopes
      };

      when(httpClient.post(tokenUrl, body: authParams)).thenAnswer((_) async =>
          http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      final AccessTokenResponse tknResponse =
          await oauth2Client.getTokenWithClientCredentialsFlow(
              clientId: clientId,
              clientSecret: clientSecret,
              // List<String> scopes,
              httpClient: httpClient);

      expect(tknResponse.accessToken, accessToken);
    });

    test('Error in getting new token', () async {
      final httpClient = HttpClientMock();

      Map authParams = {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
        // 'scope': scopes
      };

      when(httpClient.post(tokenUrl, body: authParams))
          .thenAnswer((_) async => http.Response('', 404));

      final AccessTokenResponse tknResponse =
          await oauth2Client.getTokenWithClientCredentialsFlow(
              clientId: clientId,
              clientSecret: clientSecret,
              // List<String> scopes,
              httpClient: httpClient);

      expect(tknResponse.isValid(), false);
    });
  });

  group('Token revocation.', () {
    final oauth2Client = OAuth2Client(
        authorizeUrl: authorizeUrl,
        tokenUrl: tokenUrl,
        revokeUrl: revokeUrl,
        redirectUri: redirectUri,
        customUriScheme: customUriScheme);

    test('Access token revocation', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {'token': accessToken, 'token_type_hint': 'access_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp =
          await oauth2Client.revokeAccessToken(tknResp, httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Refresh token revocation', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {'token': refreshToken, 'token_type_hint': 'refresh_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeRefreshToken(tknResp,
          httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Revoke both Access and Refresh token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {'token': accessToken, 'token_type_hint': 'access_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      when(httpClient.post(revokeUrl,
              body: {'token': refreshToken, 'token_type_hint': 'refresh_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp =
          await oauth2Client.revokeToken(tknResp, httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Error in token revocation(1)', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {'token': accessToken, 'token_type_hint': 'access_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async =>
              http.Response('{"error": "access token revocation error"}', 404));

      when(httpClient.post(revokeUrl,
              body: {'token': refreshToken, 'token_type_hint': 'refresh_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp =
          await oauth2Client.revokeToken(tknResp, httpClient: httpClient);

      expect(revokeResp.isValid(), false);
    });

    test('Error in token revocation(2)', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {'token': accessToken, 'token_type_hint': 'access_token'},
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      when(httpClient.post(revokeUrl,
              body: {'token': refreshToken, 'token_type_hint': 'refresh_token'},
              headers: anyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "generic error"}', 400));

      final Map<String, dynamic> respMap = {
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp =
          await oauth2Client.revokeToken(tknResp, httpClient: httpClient);

      expect(revokeResp.isValid(), false);
    });
  });
}
