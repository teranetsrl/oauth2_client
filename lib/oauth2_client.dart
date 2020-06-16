import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/authorization_response.dart';
import 'package:meta/meta.dart';
import 'package:oauth2_client/oauth2_response.dart';
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:oauth2_client/src/web_auth.dart';
import 'package:random_string/random_string.dart';

/// Base class that implements OAuth2 authorization flows.
///
/// It currently supports the following grants:
/// * Authorization Code
/// * Client Credentials
///
/// For the Authorization Code grant, PKCE is used by default. If you need to disable it, pass the 'enablePKCE' param to false.
///
/// You can use directly this class, but normally you want to extend it and implement your own client.
/// When instantiating the client, pass your custom uri scheme in the [customUriScheme] field.
/// Normally you would use something like <customUriScheme>:/oauth for the [redirectUri] field.
/// For Android only you must add an intent filter in your AndroidManifest.xml file to enable the custom uri handling.
/// <activity android:name="com.linusu.flutter_web_auth.CallbackActivity" >
///   <intent-filter android:label="flutter_web_auth">
///     <action android:name="android.intent.action.VIEW" />
///     <category android:name="android.intent.category.DEFAULT" />
///     <category android:name="android.intent.category.BROWSABLE" />
///     <data android:scheme="com.teranet.app" />
///   </intent-filter>
/// </activity>
class OAuth2Client {
  String redirectUri;
  String customUriScheme;

  String tokenUrl;
  String refreshUrl;
  String revokeUrl;
  String authorizeUrl;

  Map<String, String> _accessTokenRequestHeaders;

  WebAuth webAuthClient;

  OAuth2Client(
      {@required this.authorizeUrl,
      @required this.tokenUrl,
      this.refreshUrl,
      this.revokeUrl,
      @required this.redirectUri,
      @required this.customUriScheme}) {
    webAuthClient = WebAuth();
  }

  /// Requests an Access Token to the OAuth2 endpoint using the Authorization Code Flow.
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow({
    @required String clientId,
    List<String> scopes,
    String clientSecret,
    bool enablePKCE = true,
    String state,
    String codeVerifier,
    Function afterAuthorizationCodeCb,
    Map<String, dynamic> authCodeParams,
    Map<String, dynamic> accessTokenParams,
    httpClient,
    webAuthClient,
  }) async {
    AccessTokenResponse tknResp;

    String codeChallenge;

    if (enablePKCE) {
      codeVerifier ??= randomAlphaNumeric(80);

      codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
    }

    var authResp = await requestAuthorization(
        webAuthClient: webAuthClient,
        clientId: clientId,
        scopes: scopes,
        codeChallenge: codeChallenge,
        state: state,
        customParams: authCodeParams);

    if (authResp.isAccessGranted()) {
      if (afterAuthorizationCodeCb != null) afterAuthorizationCodeCb(authResp);

      tknResp = await requestAccessToken(
          httpClient: httpClient,
          code: authResp.code,
          clientId: clientId,
          scopes: scopes,
          clientSecret: clientSecret,
          codeVerifier: codeVerifier,
          customParams: accessTokenParams);
    }

    return tknResp;
  }

  /// Requests an Access Token to the OAuth2 endpoint using the Client Credentials flow.
  Future<AccessTokenResponse> getTokenWithClientCredentialsFlow(
      {@required String clientId,
      @required String clientSecret,
      List<String> scopes,
      httpClient}) async {
    httpClient ??= http.Client();

    var params = <String, String>{
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret
    };

    if (scopes != null) params['scope'] = scopes.map((s) => s.trim()).join('+');

    http.Response response = await httpClient.post(tokenUrl, body: params);

    return AccessTokenResponse.fromHttpResponse(response,
        requestedScopes: scopes);
  }

  /// Requests an Authorization Code to be used in the Authorization Code grant.
  Future<AuthorizationResponse> requestAuthorization({
    @required String clientId,
    List<String> scopes,
    String codeChallenge,
    String state,
    Map<String, dynamic> customParams,
    webAuthClient,
  }) async {
    webAuthClient ??= this.webAuthClient;

    state ??= randomAlphaNumeric(25);

    final authorizeUrl = getAuthorizeUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
        state: state,
        codeChallenge: codeChallenge,
        customParams: customParams);

    // Present the dialog to the user
    final result = await webAuthClient.authenticate(
        url: authorizeUrl, callbackUrlScheme: customUriScheme);

    return AuthorizationResponse.fromRedirectUri(result, state);
  }

  /// Requests and Access Token using the provided Authorization [code].
  Future<AccessTokenResponse> requestAccessToken(
      {@required String code,
      @required String clientId,
      String clientSecret,
      String codeVerifier,
      List<String> scopes,
      Map<String, dynamic> customParams,
      httpClient}) async {
    httpClient ??= http.Client();

    final body = getTokenUrlParams(
        code: code,
        redirectUri: redirectUri,
        clientId: clientId,
        clientSecret: clientSecret,
        codeVerifier: codeVerifier,
        customParams: customParams);

    var response = await httpClient.post(tokenUrl,
        body: body, headers: _accessTokenRequestHeaders);
    return AccessTokenResponse.fromHttpResponse(response,
        requestedScopes: scopes);
  }

  /// Refreshes an Access Token issuing a refresh_token grant to the OAuth2 server.
  Future<AccessTokenResponse> refreshToken(String refreshToken,
      {httpClient, String clientId, String clientSecret}) async {
    httpClient ??= http.Client();

    final Map body = getRefreshUrlParams(
        refreshToken: refreshToken,
        clientId: clientId,
        clientSecret: clientSecret);

    http.Response response =
        await httpClient.post(_getRefreshUrl(), body: body);

    return AccessTokenResponse.fromHttpResponse(response);
  }

  /// Revokes both the Access and the Refresh tokens in the provided [tknResp]
  Future<OAuth2Response> revokeToken(AccessTokenResponse tknResp,
      {httpClient}) async {
    var tokenRevocationResp =
        await revokeAccessToken(tknResp, httpClient: httpClient);
    if (tokenRevocationResp.isValid()) {
      tokenRevocationResp =
          await revokeRefreshToken(tknResp, httpClient: httpClient);
    }

    return tokenRevocationResp;
  }

  /// Revokes the Access Token in the provided [tknResp]
  Future<OAuth2Response> revokeAccessToken(AccessTokenResponse tknResp,
      {httpClient}) async {
    return await _revokeTokenByType(tknResp, 'access_token',
        httpClient: httpClient);
  }

  /// Revokes the Refresh Token in the provided [tknResp]
  Future<OAuth2Response> revokeRefreshToken(AccessTokenResponse tknResp,
      {httpClient}) async {
    return await _revokeTokenByType(tknResp, 'refresh_token',
        httpClient: httpClient);
  }

  /// Generates the url to be used for fetching the authorization code.
  String getAuthorizeUrl(
      {@required String clientId,
      String redirectUri,
      List<String> scopes,
      String state,
      String codeChallenge,
      Map<String, String> customParams}) {
    final params = <String, dynamic>{
      'response_type': 'code',
      'client_id': clientId
    };

    if (redirectUri != null && redirectUri.isNotEmpty) {
      params['redirect_uri'] = redirectUri;
    }

    if (scopes != null && scopes.isNotEmpty) params['scope'] = scopes;

    if (state != null && state.isNotEmpty) params['state'] = state;

    if (codeChallenge != null && codeChallenge.isNotEmpty) {
      params['code_challenge'] = codeChallenge;
      params['code_challenge_method'] = 'S256';
    }

    if (customParams != null && customParams is Map) {
      params.addAll(customParams);
    }

    return OAuth2Utils.addParamsToUrl(authorizeUrl, params);
  }

  /// Returns the parameters needed for the authorization code request
  Map<String, String> getTokenUrlParams(
      {@required String code,
      String redirectUri,
      String clientId,
      String clientSecret,
      String codeVerifier,
      Map<String, String> customParams}) {
    final params = <String, String>{
      'grant_type': 'authorization_code',
      'code': code
    };

    if (redirectUri != null && redirectUri.isNotEmpty) {
      params['redirect_uri'] = redirectUri;
    }

    if (clientId != null && clientId.isNotEmpty) {
      params['client_id'] = clientId;
    }

    if (clientSecret != null && clientSecret.isNotEmpty) {
      params['client_secret'] = clientSecret;
    }

    if (codeVerifier != null && codeVerifier.isNotEmpty) {
      params['code_verifier'] = codeVerifier;
    }

    if (customParams != null && customParams is Map) {
      params.addAll(customParams);
    }

    return params;
  }

  /// Returns the parameters needed for the refresh token request
  Map<String, String> getRefreshUrlParams(
      {@required String refreshToken, String clientId, String clientSecret}) {
    final params = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken
    };

    if (clientId != null && clientId.isNotEmpty) {
      params['client_id'] = clientId;
    }

    if (clientSecret != null && clientSecret.isNotEmpty) {
      params['client_secret'] = clientSecret;
    }

    return params;
  }

  /// Revokes the specified token [type] in the [tknResp]
  Future<OAuth2Response> _revokeTokenByType(
      AccessTokenResponse tknResp, String tokenType,
      {httpClient}) async {
    var resp = OAuth2Response();

    if (revokeUrl == null) return resp;

    httpClient ??= http.Client();

    var token = tokenType == 'access_token'
        ? tknResp.accessToken
        : tknResp.refreshToken;

    if (token != null) {
      http.Response response = await httpClient.post(revokeUrl,
          body: {'token': token, 'token_type_hint': tokenType},
          headers: {'Authorization': 'Bearer ' + tknResp.accessToken});

      resp = OAuth2Response.fromHttpResponse(response);
    }

    return resp;
  }

  String _getRefreshUrl() {
    return refreshUrl ?? tokenUrl;
  }

  set accessTokenRequestHeaders(Map<String, String> headers) {
    _accessTokenRequestHeaders = headers;
  }
}
