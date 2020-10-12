import 'dart:convert';

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

  /// Requests an Access Token to the OAuth2 endpoint using the Implicit grant flow (https://tools.ietf.org/html/rfc6749#page-31)
  Future<AccessTokenResponse> getTokenWithImplicitGrantFlow({
    @required String clientId,
    List<String> scopes,
    bool enableState = true,
    String state,
    httpClient,
    webAuthClient,
  }) async {
    httpClient ??= http.Client();
    webAuthClient ??= this.webAuthClient;

    if (enableState) state ??= randomAlphaNumeric(25);

    final authorizeUrl = getAuthorizeUrl(
        clientId: clientId,
        responseType: 'token',
        scopes: scopes,
        enableState: enableState,
        state: state,
        redirectUri: redirectUri);

    // Present the dialog to the user
    final result = await webAuthClient.authenticate(
        url: authorizeUrl, callbackUrlScheme: customUriScheme);

    final fragment = Uri.splitQueryString(Uri.parse(result).fragment);

    if (enableState) {
      final checkState = fragment['state'];
      if (state != checkState) {
        throw Exception(
            '"state" parameter in response doesn\'t correspond to the expected value');
      }
    }

    return AccessTokenResponse.fromMap({
      'access_token': fragment['access_token'],
      'token_type': fragment['token_type'],
      'scope': fragment['scope'] ?? scopes,
      'expires_in': fragment['expires_in'],
      'http_status_code': 200
    });
  }

  /// Requests an Access Token to the OAuth2 endpoint using the Authorization Code Flow.
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow({
    @required String clientId,
    List<String> scopes,
    String clientSecret,
    bool enablePKCE = true,
    bool enableState = true,
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
        enableState: enableState,
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
    var params = <String, String>{'grant_type': 'client_credentials'};

    if (scopes != null) params['scope'] = scopes.map((s) => s.trim()).join('+');

    var response = await _performAuthorizedRequest(
        url: tokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        params: params,
        httpClient: httpClient);

    return AccessTokenResponse.fromHttpResponse(response,
        requestedScopes: scopes);
  }

  /// Requests an Authorization Code to be used in the Authorization Code grant.
  Future<AuthorizationResponse> requestAuthorization({
    @required String clientId,
    List<String> scopes,
    String codeChallenge,
    bool enableState = true,
    String state,
    Map<String, dynamic> customParams,
    webAuthClient,
  }) async {
    webAuthClient ??= this.webAuthClient;

    if (enableState) {
      state ??= randomAlphaNumeric(25);
    }

    final authorizeUrl = getAuthorizeUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        scopes: scopes,
        enableState: enableState,
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
    final params = getTokenUrlParams(
        code: code,
        redirectUri: redirectUri,
        codeVerifier: codeVerifier,
        customParams: customParams);

    var response = await _performAuthorizedRequest(
        url: tokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        params: params,
        headers: _accessTokenRequestHeaders,
        httpClient: httpClient);

    return AccessTokenResponse.fromHttpResponse(response,
        requestedScopes: scopes);
  }

  /// Refreshes an Access Token issuing a refresh_token grant to the OAuth2 server.
  Future<AccessTokenResponse> refreshToken(String refreshToken,
      {httpClient, String clientId, String clientSecret}) async {
    final Map params = getRefreshUrlParams(refreshToken: refreshToken);

    var response = await _performAuthorizedRequest(
        url: _getRefreshUrl(),
        clientId: clientId,
        clientSecret: clientSecret,
        params: params,
        httpClient: httpClient);

    return AccessTokenResponse.fromHttpResponse(response);
  }

  /// Revokes both the Access and the Refresh tokens in the provided [tknResp]
  Future<OAuth2Response> revokeToken(AccessTokenResponse tknResp,
      {String clientId, String clientSecret, httpClient}) async {
    var tokenRevocationResp = await revokeAccessToken(tknResp,
        clientId: clientId, clientSecret: clientSecret, httpClient: httpClient);
    if (tokenRevocationResp.isValid()) {
      tokenRevocationResp = await revokeRefreshToken(tknResp,
          clientId: clientId,
          clientSecret: clientSecret,
          httpClient: httpClient);
    }

    return tokenRevocationResp;
  }

  /// Revokes the Access Token in the provided [tknResp]
  Future<OAuth2Response> revokeAccessToken(AccessTokenResponse tknResp,
      {String clientId, String clientSecret, httpClient}) async {
    return await _revokeTokenByType(tknResp, 'access_token',
        clientId: clientId, clientSecret: clientSecret, httpClient: httpClient);
  }

  /// Revokes the Refresh Token in the provided [tknResp]
  Future<OAuth2Response> revokeRefreshToken(AccessTokenResponse tknResp,
      {String clientId, String clientSecret, httpClient}) async {
    return await _revokeTokenByType(tknResp, 'refresh_token',
        clientId: clientId, clientSecret: clientSecret, httpClient: httpClient);
  }

  /// Generates the url to be used for fetching the authorization code.
  String getAuthorizeUrl(
      {@required String clientId,
      String responseType = 'code',
      String redirectUri,
      List<String> scopes,
      bool enableState = true,
      String state,
      String codeChallenge,
      Map<String, dynamic> customParams}) {
    final params = <String, dynamic>{
      'response_type': responseType,
      'client_id': clientId
    };

    if (redirectUri != null && redirectUri.isNotEmpty) {
      params['redirect_uri'] = redirectUri;
    }

    if (scopes != null && scopes.isNotEmpty) params['scope'] = scopes;

    if (enableState && state != null && state.isNotEmpty) {
      params['state'] = state;
    }

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
  Map<String, dynamic> getTokenUrlParams(
      {@required String code,
      String redirectUri,
      String codeVerifier,
      Map<String, dynamic> customParams}) {
    final params = <String, dynamic>{
      'grant_type': 'authorization_code',
      'code': code
    };

    if (redirectUri != null && redirectUri.isNotEmpty) {
      params['redirect_uri'] = redirectUri;
    }

/*
    //If a client secret has been specified, it will be sent in the "Authorization" header instead of a body parameter...
    if (clientSecret == null || clientSecret.isEmpty) {
      if (clientId != null && clientId.isNotEmpty) {
        params['client_id'] = clientId;
      }
    }
*/

    if (codeVerifier != null && codeVerifier.isNotEmpty) {
      params['code_verifier'] = codeVerifier;
    }

    if (customParams != null && customParams is Map) {
      params.addAll(customParams);
    }

    return params;
  }

  /// Performs a post request to the specified [url],
  /// adding authentication credentials as described here: https://tools.ietf.org/html/rfc6749#section-2.3
  Future<http.Response> _performAuthorizedRequest(
      {@required String url,
      @required String clientId,
      String clientSecret,
      Map params,
      Map<String, String> headers,
      httpClient}) async {
    httpClient ??= http.Client();

    headers ??= {};

    //If a client secret has been specified, it will be sent in the "Authorization" header instead of a body parameter...
    if (clientSecret == null || clientSecret.isEmpty) {
      if (clientId != null && clientId.isNotEmpty) {
        params['client_id'] = clientId;
      }
    } else {
      var authHeaders = getAuthorizationHeader(
          clientId: clientId, clientSecret: clientSecret);
      headers.addAll(authHeaders);
    }

    var response = await httpClient.post(url, body: params, headers: headers);

    return response;
  }

  Map<String, String> getAuthorizationHeader(
      {String clientId, String clientSecret}) {
    var headers = <String, String>{};

    if ((clientId != null && clientId.isNotEmpty) &&
        (clientSecret != null && clientSecret.isNotEmpty)) {
      var credentials =
          base64.encode(utf8.encode(clientId + ':' + clientSecret));

      headers['Authorization'] = 'Basic ' + credentials;
    }

    return headers;
  }

  /// Returns the parameters needed for the refresh token request
  Map<String, String> getRefreshUrlParams(
      {@required String refreshToken, String clientId, String clientSecret}) {
    final params = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken
    };

/*
    if (clientSecret == null || clientSecret.isEmpty) {
      if (clientId != null && clientId.isNotEmpty) {
        params['client_id'] = clientId;
      }
    }
    if (clientId != null && clientId.isNotEmpty) {
      params['client_id'] = clientId;
    }

    if (clientSecret != null && clientSecret.isNotEmpty) {
      params['client_secret'] = clientSecret;
    }
*/

    return params;
  }

  /// Revokes the specified token [type] in the [tknResp]
  Future<OAuth2Response> _revokeTokenByType(
      AccessTokenResponse tknResp, String tokenType,
      {String clientId, String clientSecret, httpClient}) async {
    var resp = OAuth2Response();

    if (revokeUrl == null) return resp;

    httpClient ??= http.Client();

    var token = tokenType == 'access_token'
        ? tknResp.accessToken
        : tknResp.refreshToken;

    if (token != null) {
      var params = {'token': token, 'token_type_hint': tokenType};

      if (clientId != null) params['client_id'] = clientId;
      if (clientSecret != null) params['client_secret'] = clientSecret;

      http.Response response = await httpClient.post(revokeUrl, body: params);

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
