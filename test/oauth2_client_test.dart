import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:oauth2_client/src/web_auth.dart';

class WebAuthMockClient extends Mock implements WebAuth {}

class HttpClientMock extends Mock implements http.Client {}

void main() {
  final webAuthClient = WebAuthMockClient();

  // final customUriScheme = 'myurlscheme:/';
  final customUriScheme = 'myurlscheme';
  final codeVerifier = '12345';
  final codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
  final authCode = '12345';
  final redirectUri = 'myurlscheme://oauth2';
  final clientId = 'myclientid';
  final clientSecret = 'test_secret';

  final authorizeUrl = 'http://my.test.app/authorize';
  final tokenUrl = 'http://my.test.app/token';
  final revokeUrl = 'http://my.test.app/revoke';

  final state = 'test_state';
  final scopes = <String>['scope1', 'scope2'];

  final refreshToken = 'test_refresh_token';
  final accessToken = 'test_access_token';

  final authorizationCode = 'test_code';

  group('Authorization Code Grant.', () {
    final oauth2Client = OAuth2Client(
        authorizeUrl: authorizeUrl,
        tokenUrl: tokenUrl,
        redirectUri: redirectUri,
        customUriScheme: customUriScheme);

    test('Authorization Request', () async {
      var authParams = {
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

      final authResponse = await oauth2Client.requestAuthorization(
          webAuthClient: webAuthClient,
          clientId: clientId,
          scopes: scopes,
          codeChallenge: codeChallenge,
          state: state);

      expect(authResponse.code, authCode);
    });

    test('Fetch Access Token', () async {
      final httpClient = HttpClientMock();

      final accessToken = '12345';
      final refreshToken = '54321';

      var tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      };

      when(httpClient.post(tokenUrl,
              body: tokenParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      final tknResponse = await oauth2Client.requestAccessToken(
          httpClient: httpClient,
          code: authCode,
          clientId: clientId,
          codeVerifier: codeVerifier);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: tokenParams, headers: captureAnyNamed('headers')))
              .captured[0],
          {});

      expect(tknResponse.accessToken, accessToken);
    });

    test('Fetch Access Token with custom headers', () async {
      final httpClient = HttpClientMock();

      oauth2Client.accessTokenRequestHeaders = {'test': '42'};

      final accessToken = '12345';
      final refreshToken = '54321';

      var tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      };

      when(httpClient.post(tokenUrl,
              body: tokenParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      final tknResponse = await oauth2Client.requestAccessToken(
          httpClient: httpClient,
          code: authCode,
          clientId: clientId,
          codeVerifier: codeVerifier);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: tokenParams, headers: captureAnyNamed('headers')))
              .captured[0],
          {'test': '42'});

      expect(tknResponse.accessToken, accessToken);

      oauth2Client.accessTokenRequestHeaders = {};
    });

    test('Error fetching Access Token', () async {
      final httpClient = HttpClientMock();

      var tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
        // 'client_secret': clientSecret
      };

      when(httpClient.post(tokenUrl,
              body: tokenParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 404));

      final tknResponse = await oauth2Client.requestAccessToken(
          httpClient: httpClient,
          code: authCode,
          clientId: clientId,
          // clientSecret: clientSecret,
          codeVerifier: codeVerifier);

      expect(tknResponse.isValid(), false);
    });

    test('Token request with authorization code flow', () async {
      var authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'testParam': 'testVal'
      };

      final httpClient = HttpClientMock();

      final accessToken = '12345';
      final refreshToken = '54321';

      var tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
        // 'client_secret': clientSecret
      };

      when(httpClient.post(tokenUrl,
              body: tokenParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
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

      final tknResponse = await oauth2Client.getTokenWithAuthCodeFlow(
          webAuthClient: webAuthClient,
          httpClient: httpClient,
          clientId: clientId,
          scopes: scopes,
          state: state,
          codeVerifier: codeVerifier,
          authCodeParams: {'testParam': 'testVal'});

      expect(tknResponse.accessToken, accessToken);
    });

    test('Authorization code flow with callback', () async {
      var authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      };

      final httpClient = HttpClientMock();

      final accessToken = '12345';
      final refreshToken = '54321';

      var tokenParams = {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
        // 'client_secret': clientSecret
      };

      when(httpClient.post('https://test.token.url',
              body: tokenParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
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

      await oauth2Client.getTokenWithAuthCodeFlow(
          webAuthClient: webAuthClient,
          httpClient: httpClient,
          clientId: clientId,
          scopes: scopes,
          state: state,
          codeVerifier: codeVerifier,
          afterAuthorizationCodeCb: (authResp) {
            oauth2Client.tokenUrl = 'https://test.token.url';
          });

      expect(oauth2Client.tokenUrl, 'https://test.token.url');

      oauth2Client.tokenUrl = tokenUrl;
    });

    test('Refresh token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl,
              body: {
                'grant_type': 'refresh_token',
                'refresh_token': refreshToken,
              },
              headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      var resp = await oauth2Client.refreshToken(refreshToken,
          clientId: clientId,
          clientSecret: clientSecret,
          httpClient: httpClient);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: captureAnyNamed('body'),
                  headers: captureAnyNamed('headers')))
              .captured[1],
          {'Authorization': 'Basic bXljbGllbnRpZDp0ZXN0X3NlY3JldA=='});

      expect(resp.isValid(), true);
      expect(resp.accessToken, accessToken);
    });

    test('Error in refreshing token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl,
              body: {
                'grant_type': 'refresh_token',
                'refresh_token': refreshToken,
              },
              headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 404));

      var resp = await oauth2Client.refreshToken(refreshToken,
          clientId: clientId,
          clientSecret: clientSecret,
          httpClient: httpClient);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: captureAnyNamed('body'),
                  headers: captureAnyNamed('headers')))
              .captured[1],
          {'Authorization': 'Basic bXljbGllbnRpZDp0ZXN0X3NlY3JldA=='});

      expect(resp.isValid(), false);
    });

    test('Authorization url params (1/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(clientId: clientId);

      final urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(containsPair('response_type', 'code'),
              containsPair('client_id', clientId)));
    });

    test('Authorization url params (2/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId, redirectUri: redirectUri);

      final urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
              containsPair('response_type', 'code'),
              containsPair('client_id', clientId),
              containsPair('redirect_uri', redirectUri)));
    });

    test('Authorization url params (3/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
      );

      final urlParams = Uri.parse(authorizeUrl).queryParameters;

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
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          scopes: scopes,
          state: state);

      final urlParams = Uri.parse(authorizeUrl).queryParameters;

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
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          scopes: scopes,
          state: state,
          codeChallenge: codeChallenge,
          customParams: {'authparm1': 'test1', 'authparm2': '5'});

      final urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf([
            containsPair('response_type', 'code'),
            containsPair('client_id', clientId),
            containsPair('redirect_uri', redirectUri),
            containsPair('scope', scopes.join(' ')),
            containsPair('state', state),
            containsPair('code_challenge', codeChallenge),
            containsPair('code_challenge_method', 'S256'),
            containsPair('authparm1', 'test1'),
            containsPair('authparm2', '5')
          ]));
    });

    test('Token url params (1/5)', () {
      final params = oauth2Client.getTokenUrlParams(code: authorizationCode);

      expect(
          params,
          allOf(containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode)));
    });

    test('Token url params (2/5)', () {
      final params = oauth2Client.getTokenUrlParams(
          code: authorizationCode, redirectUri: redirectUri);

      expect(
          params,
          allOf(
              containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode),
              containsPair('redirect_uri', redirectUri)));
    });

    test('Token url params (3/5)', () {
      final params = oauth2Client.getTokenUrlParams(
          code: authorizationCode, redirectUri: redirectUri);

      expect(
          params,
          allOf(
              containsPair('grant_type', 'authorization_code'),
              containsPair('code', authorizationCode),
              containsPair('redirect_uri', redirectUri)));
    });

    test('Token url params (4/5)', () {
      final params = oauth2Client.getTokenUrlParams(
          code: authorizationCode, redirectUri: redirectUri);

      expect(
          params,
          allOf(
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
            containsPair('redirect_uri', redirectUri),
          ));
    });

    test('Token url params (5/5)', () {
      final verifier = 'test_verifier';

      final params = oauth2Client.getTokenUrlParams(
          code: authorizationCode,
          redirectUri: redirectUri,
          codeVerifier: verifier,
          customParams: {'accTknparm1': 'test1', 'accTknparm2': '5'});

      expect(
          params,
          allOf([
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
            containsPair('redirect_uri', redirectUri),
            // containsPair('client_id', clientId),
            // containsPair('client_secret', clientSecret),
            containsPair('code_verifier', verifier),
            containsPair('accTknparm1', 'test1'),
            containsPair('accTknparm2', '5'),
          ]));
    });

    test('Disabled state parameter', () async {
      var authParams = {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256'
      };

      when(webAuthClient.authenticate(
              url: OAuth2Utils.addParamsToUrl(authorizeUrl, authParams),
              callbackUrlScheme: customUriScheme))
          .thenAnswer((_) async => redirectUri + '?code=' + authCode);

      final authResponse = await oauth2Client.requestAuthorization(
          webAuthClient: webAuthClient,
          clientId: clientId,
          scopes: scopes,
          codeChallenge: codeChallenge,
          enableState: false);

      expect(authResponse.code, authCode);
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

      final accessToken = '12345';
      final refreshToken = '54321';

      final authParams = {
        'grant_type': 'client_credentials',
        // 'scope': scopes
      };

      when(httpClient.post(tokenUrl,
              body: authParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response(
              '{"access_token": "' +
                  accessToken +
                  '", "token_type": "Bearer", "refresh_token": "' +
                  refreshToken +
                  '", "expires_in": 3600}',
              200));

      final tknResponse = await oauth2Client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          // List<String> scopes,
          httpClient: httpClient);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: captureAnyNamed('body'),
                  headers: captureAnyNamed('headers')))
              .captured[1],
          {'Authorization': 'Basic bXljbGllbnRpZDp0ZXN0X3NlY3JldA=='});

      expect(tknResponse.accessToken, accessToken);
    });

    test('Error in getting new token', () async {
      final httpClient = HttpClientMock();

      final authParams = {
        'grant_type': 'client_credentials',
        // 'scope': scopes
      };

      when(httpClient.post(tokenUrl,
              body: authParams, headers: captureAnyNamed('headers')))
          .thenAnswer((_) async => http.Response('', 404));

      final tknResponse = await oauth2Client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          // List<String> scopes,
          httpClient: httpClient);

      expect(
          verify(httpClient.post(tokenUrl,
                  body: captureAnyNamed('body'),
                  headers: captureAnyNamed('headers')))
              .captured[1],
          {'Authorization': 'Basic bXljbGllbnRpZDp0ZXN0X3NlY3JldA=='});

      expect(tknResponse.isValid(), false);
    });
  });

  group('Implicit flow Grant.', () {
    final oauth2Client = OAuth2Client(
        authorizeUrl: authorizeUrl,
        tokenUrl: tokenUrl,
        redirectUri: redirectUri,
        customUriScheme: customUriScheme);

    test('Get new token', () async {
      final httpClient = HttpClientMock();

      final accessToken = '12345';

      final authParams = {
        'response_type': 'token',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'state': state,
        // 'scope': scopes
      };

      when(webAuthClient.authenticate(
              url: OAuth2Utils.addParamsToUrl(authorizeUrl, authParams),
              callbackUrlScheme: customUriScheme))
          .thenAnswer((_) async =>
              redirectUri +
              '#access_token=' +
              accessToken +
              '&token_type=bearer&state=' +
              state);

      final tknResponse = await oauth2Client.getTokenWithImplicitGrantFlow(
          clientId: clientId,
          state: state,
          // List<String> scopes,
          httpClient: httpClient,
          webAuthClient: webAuthClient);

      expect(tknResponse.accessToken, accessToken);
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

      when(httpClient.post(revokeUrl, body: {
        'token': accessToken,
        'token_type_hint': 'access_token',
        'client_id': clientId
      })).thenAnswer((_) async => http.Response('{}', 200));

      final respMap = <String, dynamic>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeAccessToken(tknResp,
          clientId: clientId, httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Refresh token revocation', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {
                'token': refreshToken,
                'token_type_hint': 'refresh_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final respMap = <String, dynamic>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeRefreshToken(tknResp,
          clientId: clientId, httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Revoke both Access and Refresh token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {
                'token': accessToken,
                'token_type_hint': 'access_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      when(httpClient.post(revokeUrl,
              body: {
                'token': refreshToken,
                'token_type_hint': 'refresh_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final respMap = <String, dynamic>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeToken(tknResp,
          clientId: clientId, httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Error in token revocation(1)', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {
                'token': accessToken,
                'token_type_hint': 'access_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async =>
              http.Response('{"error": "access token revocation error"}', 404));

      when(httpClient.post(revokeUrl,
              body: {
                'token': refreshToken,
                'token_type_hint': 'refresh_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final respMap = <String, dynamic>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeToken(tknResp,
          clientId: clientId, httpClient: httpClient);

      expect(revokeResp.isValid(), false);
    });

    test('Error in token revocation(2)', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(revokeUrl,
              body: {
                'token': accessToken,
                'token_type_hint': 'access_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      when(httpClient.post(revokeUrl,
              body: {
                'token': refreshToken,
                'token_type_hint': 'refresh_token',
                'client_id': clientId
              },
              headers: anyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "generic error"}', 400));

      final respMap = <String, dynamic>{
        'access_token': accessToken,
        'token_type': 'Bearer',
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': 3600,
        'http_status_code': 200
      };

      final tknResp = AccessTokenResponse.fromMap(respMap);

      final revokeResp = await oauth2Client.revokeToken(tknResp,
          clientId: clientId, httpClient: httpClient);

      expect(revokeResp.isValid(), false);
    });
  });
}
