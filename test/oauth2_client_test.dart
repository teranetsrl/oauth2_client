import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:oauth2_client/src/web_auth.dart';

class WebAuthMockClient extends Mock implements WebAuth {}

class HttpClientMock extends Mock implements http.Client {}

void main() {
  final webAuthClient = WebAuthMockClient();

  final customUriScheme = 'myurlscheme:/';
  final codeVerifier = '12345';
  final codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
  final authCode = '12345';
  final redirectUri = 'myurlscheme:/oauth2';
  final clientId = 'myclientid';
  final clientSecret = 'test_secret';

  final authorizeUrl = 'http://my.test.app/authorize';
  final tokenUrl = 'http://my.test.app/token';

  final state = 'test_state';
  final scopes = ['scope1', 'scope2'];

  final refreshToken = 'test_refresh_token';
  final accessToken = 'test_access_token';

  final authorizationCode = 'test_code';

  group('Authorization Code Grant.', () {
    final oauth2Client = OAuth2Client(
      authorizeUrl: authorizeUrl,
      tokenUrl: tokenUrl,
      redirectUri: redirectUri,
      customUriScheme: customUriScheme,
    );

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
        state: state,
      );

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

      final tknResponse = await oauth2Client.requestAccessToken(
        httpClient: httpClient,
        code: authCode,
        clientId: clientId,
        // clientSecret: clientSecret,
        codeVerifier: codeVerifier,
      );

      expect(tknResponse.accessToken, accessToken);
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

      when(httpClient.post(tokenUrl, body: tokenParams))
          .thenAnswer((_) async => http.Response('', 404));

      final tknResponse = await oauth2Client.requestAccessToken(
        httpClient: httpClient,
        code: authCode,
        clientId: clientId,
        // clientSecret: clientSecret,
        codeVerifier: codeVerifier,
      );

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

      final tknResponse = await oauth2Client.getTokenWithAuthCodeFlow(
        webAuthClient: webAuthClient,
        httpClient: httpClient,
        clientId: clientId,
        scopes: scopes,
        state: state,
        codeVerifier: codeVerifier,
      );

      expect(tknResponse.accessToken, accessToken);
    });

    test('Refresh token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl, body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken
      })).thenAnswer((_) async => http.Response(
          '{"access_token": "' +
              accessToken +
              '", "token_type": "Bearer", "refresh_token": "' +
              refreshToken +
              '", "expires_in": 3600}',
          200));

      var resp =
          await oauth2Client.refreshToken(refreshToken, httpClient: httpClient);

      expect(resp.isValid(), true);
      expect(resp.accessToken, accessToken);
    });

    test('Error in refreshing token', () async {
      final httpClient = HttpClientMock();

      when(httpClient.post(tokenUrl, body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken
      })).thenAnswer((_) async => http.Response('', 404));

      var resp =
          await oauth2Client.refreshToken(refreshToken, httpClient: httpClient);

      expect(resp.isValid(), false);
    });

    test('Authorization url params (1/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(clientId: clientId);

      var urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(containsPair('response_type', 'code'),
              containsPair('client_id', clientId)));
    });

    test('Authorization url params (2/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
          clientId: clientId, redirectUri: redirectUri);

      var urlParams = Uri.parse(authorizeUrl).queryParameters;

      expect(
          urlParams,
          allOf(
            containsPair('response_type', 'code'),
            containsPair('client_id', clientId),
            containsPair('redirect_uri', redirectUri),
          ));
    });

    test('Authorization url params (3/5)', () {
      final authorizeUrl = oauth2Client.getAuthorizeUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
      );

      var urlParams = Uri.parse(authorizeUrl).queryParameters;

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

      var urlParams = Uri.parse(authorizeUrl).queryParameters;

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
      );

      var urlParams = Uri.parse(authorizeUrl).queryParameters;

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
      final params = oauth2Client.getTokenUrlParams(code: authorizationCode);

      expect(
          params,
          allOf(
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
          ));
    });

    test('Token url params (2/5)', () {
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

    test('Token url params (3/5)', () {
      final params = oauth2Client.getTokenUrlParams(
          code: authorizationCode,
          redirectUri: redirectUri,
          clientId: clientId);

      expect(
          params,
          allOf(
            containsPair('grant_type', 'authorization_code'),
            containsPair('code', authorizationCode),
            containsPair('redirect_uri', redirectUri),
            containsPair('client_id', clientId),
          ));
    });

    test('Token url params (4/5)', () {
      final params = oauth2Client.getTokenUrlParams(
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
      final verifier = 'test_verifier';

      final params = oauth2Client.getTokenUrlParams(
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

      final accessToken = '12345';
      final refreshToken = '54321';

      var authParams = {
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

      final tknResponse = await oauth2Client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          // List<String> scopes,
          httpClient: httpClient);

      expect(tknResponse.accessToken, accessToken);
    });

    test('Error in getting new token', () async {
      final httpClient = HttpClientMock();

      var authParams = {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
        // 'scope': scopes
      };

      when(httpClient.post(tokenUrl, body: authParams))
          .thenAnswer((_) async => http.Response('', 404));

      final tknResponse = await oauth2Client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          // List<String> scopes,
          httpClient: httpClient);

      expect(tknResponse.isValid(), false);
    });
  });
}
