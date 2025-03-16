import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_exception.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/oauth2_response.dart';
// import 'package:oauth2_client/src/secure_storage.dart';
import 'package:oauth2_client/src/base_storage.dart';
import 'package:oauth2_client/src/token_storage.dart';
import 'package:oauth2_client/src/volatile_storage.dart';

import 'oauth2_helper_test.mocks.dart';

@GenerateMocks([OAuth2Client])
@GenerateMocks([http.Client])
@GenerateMocks([TokenStorage])
@GenerateMocks([BaseStorage])
void main() {
  const clientId = 'test_client';
  const clientSecret = 'test_secret';
  final scopes = ['scope1', 'scope2'];
  const accessToken = 'test_token';
  const renewedAccessToken = 'test_token_renewed';
  const tokenType = 'Bearer';
  const refreshToken = 'test_refresh_token';
  const expiresIn = 3600;

  final oauth2Client = MockOAuth2Client();
  final httpClient = MockClient();

  when(oauth2Client.tokenUrl).thenReturn('http://my.test.app/token');
  when(oauth2Client.revokeUrl).thenReturn('http://my.test.app/revoke');

  void mockGetTokenWithAuthCodeFlow(oauth2Client,
      {Map<String, dynamic>? respMap}) {
    var accessTokenMap = <String, dynamic>{
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scopes,
      'expires_in': expiresIn,
      'http_status_code': 200
    };

    if (respMap != null) {
      respMap.forEach((k, v) => accessTokenMap[k] = v);
    }

    when(oauth2Client.getTokenWithAuthCodeFlow(
            clientId: clientId, clientSecret: clientSecret, scopes: scopes))
        .thenAnswer((_) async => AccessTokenResponse.fromMap(accessTokenMap));
  }

  void mockGetTokenWithClientCredentials(oauth2Client,
      {Map<String, dynamic>? respMap}) {
    var accessTokenMap = <String, dynamic>{
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scopes,
      'expires_in': expiresIn,
      'http_status_code': 200
    };

    if (respMap != null) {
      respMap.forEach((k, v) => accessTokenMap[k] = v);
    }

    accessTokenMap['expiration_date'] = DateTime.now()
        .add(Duration(seconds: accessTokenMap['expires_in']))
        .millisecondsSinceEpoch;

    when(oauth2Client.getTokenWithClientCredentialsFlow(
            clientId: clientId, clientSecret: clientSecret, scopes: scopes))
        .thenAnswer((_) async => AccessTokenResponse.fromMap(accessTokenMap));
  }

  void mockGetTokenWithImplicitFlow(oauth2Client,
      {Map<String, dynamic>? respMap}) {
    var accessTokenMap = <String, dynamic>{
      'access_token': accessToken,
      'token_type': tokenType,
      'scope': scopes,
      // 'expires_in': expiresIn,
      'http_status_code': 200
    };

    if (respMap != null) {
      respMap.forEach((k, v) => accessTokenMap[k] = v);
    }

    when(oauth2Client.getTokenWithImplicitGrantFlow(
            clientId: clientId, scopes: scopes))
        .thenAnswer((_) async => AccessTokenResponse.fromMap(accessTokenMap));
  }

  void mockRefreshToken(oauth2Client) {
    when(oauth2Client.refreshToken(refreshToken,
            clientId: clientId, clientSecret: clientSecret, scopes: scopes))
        .thenAnswer((_) async => AccessTokenResponse.fromMap({
              'access_token': renewedAccessToken,
              'token_type': tokenType,
              'refresh_token': refreshToken,
              'scope': scopes,
              'expires_in': 3600,
              'http_status_code': 200
            }));
  }

  group('Authorization Code Grant.', () {
    test('Authorization Request without errors', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);
    });

    test('Authorization Request with token expiration', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client, respMap: {
        'expires_in': 1,
        'expiration_date': DateTime.now()
            .add(const Duration(seconds: 1))
            .millisecondsSinceEpoch
      });

      mockRefreshToken(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);
      var tknResp = await hlp.getToken();
      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);

      await Future.delayed(const Duration(seconds: 2), () => 'X');

      tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, renewedAccessToken);
    });

    test('Post authorization Request with server side token expiration',
        () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      when(httpClient.post(Uri.parse('https://my.test.url'),
              // headers: {'Authorization': 'Bearer ' + accessToken},
              headers: captureAnyNamed('headers'),
              body: null,
              encoding: null))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);

      await hlp.post('https://my.test.url', httpClient: httpClient);
      tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, renewedAccessToken);
    });

    test('Refresh token expiration', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);

      when(oauth2Client.refreshToken(refreshToken,
              clientId: clientId, clientSecret: clientSecret))
          .thenAnswer((_) async => AccessTokenResponse.fromMap(
              {'error': 'invalid_grant', 'http_status_code': 400}));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.refreshToken(AccessTokenResponse.fromMap({
        'refresh_token': refreshToken,
        'http_status_code': 200,
        'access_token': accessToken
      }));

      expect(tknResp.isValid(), true);
      expect(tknResp.accessToken, accessToken);
    });

    test('GET request with refresh token expiration', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      when(httpClient.get(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);

      await hlp.get('https://my.test.url', httpClient: httpClient);
      tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, renewedAccessToken);
    });

    test('Refresh token generic error', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);

      when(oauth2Client.refreshToken(refreshToken,
              clientId: clientId, clientSecret: clientSecret))
          .thenAnswer((_) async => AccessTokenResponse.fromMap(
              {'error': 'generic_error', 'http_status_code': 400}));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      // expect(() async => await hlp.refreshToken(refreshToken),
      expect(
          () async => await hlp.refreshToken(AccessTokenResponse.fromMap({
                'refresh_token': refreshToken,
                'http_status_code': 200,
                'access_token': accessToken
              })),
          throwsA(isInstanceOf<OAuth2Exception>()));
    });

    test('Test GET method with custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.get(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.get('https://my.test.url',
          httpClient: httpClient, headers: {'TestHeader': 'test'});

      expect(
          verify(httpClient.get(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'TestHeader': 'test', 'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test GET method without custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.get(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.get('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.get(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test POST method with custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.post(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.post('https://my.test.url',
          httpClient: httpClient, headers: {'TestHeader': 'test'});

      expect(
          verify(httpClient.post(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'TestHeader': 'test', 'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test POST method without custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.post(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.post('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.post(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test PUT method', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.put(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.put('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.put(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test PATCH method', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.patch(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.patch('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.patch(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test DELETE method with custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.delete(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.delete('https://my.test.url',
          httpClient: httpClient, headers: {'TestHeader': 'test'});

      expect(
          verify(httpClient.delete(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'TestHeader': 'test', 'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test DELETE method without custom headers', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.delete(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.delete('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.delete(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test HEAD method', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      when(httpClient.head(Uri.parse('https://my.test.url'),
              headers: captureAnyNamed('headers')))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.head('https://my.test.url', httpClient: httpClient);

      expect(
          verify(httpClient.head(Uri.parse('https://my.test.url'),
                  headers: captureAnyNamed('headers')))
              .captured[0],
          {'Authorization': 'Bearer test_token_renewed'});
    });

    test('Test sending requests for StreamedResponses', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithAuthCodeFlow(oauth2Client);
      mockRefreshToken(oauth2Client);

      clearInteractions(httpClient);

      var req = http.Request('GET', Uri.parse('https://my.test.url'));

      when(httpClient.send(req)).thenAnswer((_) async => http.StreamedResponse(
          Stream.value('{"error": "invalid_token"}'.codeUnits), 401));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.send(req, httpClient: httpClient);

      expect(req.headers, {'Authorization': 'Bearer test_token_renewed'});
      verify(httpClient.send(req)).called(greaterThanOrEqualTo(1));
    });

    test('Token revocation', () async {
      final tknResp = AccessTokenResponse.fromMap({
        'access_token': accessToken,
        'token_type': tokenType,
        'refresh_token': refreshToken,
        'scope': scopes,
        'expires_in': expiresIn,
        'http_status_code': 200
      });

      final tokenStorage = MockTokenStorage();
      when(tokenStorage.getToken(scopes)).thenAnswer((_) async => tknResp);
      when(tokenStorage.deleteToken(scopes)).thenAnswer((_) async => true);

      when(oauth2Client.revokeToken(tknResp,
              clientId: clientId,
              clientSecret: clientSecret,
              httpClient: httpClient))
          .thenAnswer(
              (_) async => OAuth2Response.fromMap({'http_status_code': 200}));

      final hlp = OAuth2Helper(oauth2Client,
          tokenStorage: tokenStorage,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes);

      final revokeResp = await hlp.disconnect(httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Token revocation without a previously fetched token (fallback)',
        () async {
      final tokenStorage = MockTokenStorage();
      when(tokenStorage.getToken(scopes)).thenAnswer((_) async => null);

      final hlp = OAuth2Helper(oauth2Client,
          tokenStorage: tokenStorage,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes);

      final revokeResp = await hlp.disconnect(httpClient: httpClient);

      expect(revokeResp.isValid(), true);
    });

    test('Test PKCE param', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      when(oauth2Client.getTokenWithAuthCodeFlow(
        clientId: 'test_client',
        scopes: ['scope1', 'scope2'],
        clientSecret: 'test_secret',
        enablePKCE: false,
        enableState: true,
      )).thenAnswer((_) async => AccessTokenResponse());

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.authorizationCode,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      await hlp.fetchToken();

      expect(
          verify(oauth2Client.getTokenWithAuthCodeFlow(
                  clientId: captureAnyNamed('clientId'),
                  clientSecret: captureAnyNamed('clientSecret'),
                  scopes: captureAnyNamed('scopes'),
                  enablePKCE: captureAnyNamed('enablePKCE'),
                  state: captureAnyNamed('state'),
                  codeVerifier: captureAnyNamed('codeVerifier'),
                  afterAuthorizationCodeCb:
                      captureAnyNamed('afterAuthorizationCodeCb'),
                  authCodeParams: captureAnyNamed('authCodeParams'),
                  accessTokenParams: captureAnyNamed('accessTokenParams'),
                  httpClient: captureAnyNamed('httpClient'),
                  webAuthClient: captureAnyNamed('webAuthClient')))
              .captured[3],
          true);

      hlp.enablePKCE = true;

      await hlp.fetchToken();

      expect(
          verify(oauth2Client.getTokenWithAuthCodeFlow(
                  clientId: captureAnyNamed('clientId'),
                  clientSecret: captureAnyNamed('clientSecret'),
                  scopes: captureAnyNamed('scopes'),
                  enablePKCE: captureAnyNamed('enablePKCE'),
                  state: captureAnyNamed('state'),
                  codeVerifier: captureAnyNamed('codeVerifier'),
                  afterAuthorizationCodeCb:
                      captureAnyNamed('afterAuthorizationCodeCb'),
                  authCodeParams: captureAnyNamed('authCodeParams'),
                  accessTokenParams: captureAnyNamed('accessTokenParams'),
                  httpClient: captureAnyNamed('httpClient'),
                  webAuthClient: captureAnyNamed('webAuthClient')))
              .captured[3],
          true);

      //enablePKCE param passed as false... Must be false in the client instance
      hlp.enablePKCE = false;

      await hlp.fetchToken();

      expect(
          verify(oauth2Client.getTokenWithAuthCodeFlow(
                  clientId: captureAnyNamed('clientId'),
                  clientSecret: captureAnyNamed('clientSecret'),
                  scopes: captureAnyNamed('scopes'),
                  enablePKCE: captureAnyNamed('enablePKCE'),
                  state: captureAnyNamed('state'),
                  codeVerifier: captureAnyNamed('codeVerifier'),
                  afterAuthorizationCodeCb:
                      captureAnyNamed('afterAuthorizationCodeCb'),
                  authCodeParams: captureAnyNamed('authCodeParams'),
                  accessTokenParams: captureAnyNamed('accessTokenParams'),
                  httpClient: captureAnyNamed('httpClient'),
                  webAuthClient: captureAnyNamed('webAuthClient')))
              .captured[3],
          false);
    });
  });

  group('Client Credentials Grant.', () {
    test('Client Credentials Request without errors', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithClientCredentials(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);
    });

    test('Client Credentials with token expiration', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithClientCredentials(oauth2Client,
          respMap: {'expires_in': 1});

      mockRefreshToken(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);

      await Future.delayed(const Duration(seconds: 2), () => 'X');

      tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, renewedAccessToken);
    });

    test('Client Credentials Request with server side token expiration',
        () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithClientCredentials(oauth2Client);
      mockRefreshToken(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      when(httpClient.post(Uri.parse('https://my.test.url'),
              body: null, headers: {'Authorization': 'Bearer $accessToken'}))
          .thenAnswer(
              (_) async => http.Response('{"error": "invalid_token"}', 401));

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);

      await hlp.post('https://my.test.url', httpClient: httpClient);
      tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, renewedAccessToken);
    });

    test('Refresh token expiration', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithClientCredentials(oauth2Client);

      when(oauth2Client.refreshToken(refreshToken,
              clientId: clientId, clientSecret: clientSecret))
          .thenAnswer((_) async => AccessTokenResponse.fromMap(
              {'error': 'invalid_grant', 'http_status_code': 400}));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      // var tknResp = await hlp.refreshToken(refreshToken);
      var tknResp = await hlp.refreshToken(AccessTokenResponse.fromMap({
        'refresh_token': refreshToken,
        'http_status_code': 200,
        'access_token': accessToken
      }));

      expect(tknResp.isValid(), true);
      expect(tknResp.accessToken, accessToken);
    });

    test(
        'Keep using previous refresh token when no newly refresh token returned',
        () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithClientCredentials(oauth2Client);

      when(oauth2Client.refreshToken(refreshToken,
              clientId: clientId, clientSecret: clientSecret))
          .thenAnswer((_) async => AccessTokenResponse.fromMap({
                'access_token': accessToken,
                'token_type': tokenType,
                'expires_in': expiresIn,
                'expiration_date': DateTime.now()
                    .add(const Duration(seconds: expiresIn))
                    .millisecondsSinceEpoch,
                'http_status_code': 200
              }));

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.clientCredentials,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          tokenStorage: tokenStorage);

      // var tknResp = await hlp.refreshToken(refreshToken);
      var tknResp = await hlp.refreshToken(AccessTokenResponse.fromMap({
        'refresh_token': refreshToken,
        'http_status_code': 200,
        'access_token': accessToken
      }));

      expect(tknResp.isValid(), true);
      expect(tknResp.refreshToken, refreshToken);
    });
  });

  group('Implicit Grant.', () {
    test('Implicit flow request', () async {
      final tokenStorage =
          TokenStorage(oauth2Client.tokenUrl, storage: VolatileStorage());

      mockGetTokenWithImplicitFlow(oauth2Client);

      var hlp = OAuth2Helper(oauth2Client,
          grantType: OAuth2Helper.implicitGrant,
          clientId: clientId,
          scopes: scopes,
          tokenStorage: tokenStorage);

      var tknResp = await hlp.getToken();

      expect(tknResp?.isValid(), true);
      expect(tknResp?.accessToken, accessToken);
    });
  });
}
