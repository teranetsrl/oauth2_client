import 'package:meta/meta.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/authorization_response.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/src/oauth2_utils.dart';
import 'package:random_string/random_string.dart';

class OAuth2ClientImpl {

  String redirectUri;
  String customUriScheme;

  String tokenUrl;
  String refreshUrl;
  String authorizeUrl;

	OAuth2ClientImpl({
    @required this.authorizeUrl,
    @required this.tokenUrl,
    this.refreshUrl,
    @required this.redirectUri,
    @required this.customUriScheme});

  /// Requests an Access Token to the OAuth2 endpoint using the Authorization Code Flow.
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow({
    @required httpClient,
    @required webAuthClient,
    @required String clientId,
    @required List<String> scopes,
    String clientSecret,
    bool enablePKCE = true,
    String codeVerifier
  }) async {

    AccessTokenResponse tknResp;

    String codeChallenge;

    if(enablePKCE) {
      if(codeVerifier == null)
        codeVerifier = randomAlphaNumeric(80);

      codeChallenge = OAuth2Utils.generateCodeChallenge(codeVerifier);
    }

    AuthorizationResponse authResp = await requestAuthorization(webAuthClient: webAuthClient, clientId: clientId, scopes: scopes, codeChallenge: codeChallenge);

    if(authResp.isAccessGranted())
      tknResp = await requestAccessToken(httpClient: httpClient, code: authResp.code, clientId: clientId, clientSecret: clientSecret, codeVerifier: codeVerifier);

    return tknResp;
  }

/// Requests an Authorization Code to be used in the Authorization Code grant.
  Future<AuthorizationResponse> requestAuthorization({
    @required webAuthClient,
    @required String clientId,
    List<String> scopes,
    String codeChallenge,
    String state
  }) async {

    if(redirectUri.isEmpty)
      throw Exception('No "redirectUri" supplied');

    if(state == null)
      state = randomAlphaNumeric(25);

    final String authorizeUrl = getAuthorizeUrl(
      clientId: clientId,
      redirectUri: redirectUri,
      scopes: scopes,
      state: state,
      codeChallenge: codeChallenge
    );

    // Present the dialog to the user
    final result = await webAuthClient.authenticate(
      url: authorizeUrl,
      callbackUrlScheme: customUriScheme
    );

    return AuthorizationResponse.fromRedirectUri(result, state);

  }

  /// Requests and Access Token using the provided Authorization [code].
  Future<AccessTokenResponse> requestAccessToken({
    @required httpClient,
    @required String code,
    @required String clientId,
    String clientSecret,
    String codeVerifier
  }) async {

    final Map body = getTokenUrlParams(
      code: code,
      redirectUri: redirectUri,
      clientId: clientId,
      clientSecret: clientSecret,
      codeVerifier: codeVerifier
    );

    http.Response response = await httpClient.post(tokenUrl, body: body);

    return AccessTokenResponse.fromHttpResponse(response);
  }

  /// Requests an Access Token to the OAuth2 endpoint using the Client Credentials flow.
  Future<AccessTokenResponse> getTokenWithClientCredentialsFlow({@required httpClient, @required String clientId, @required String clientSecret, List<String> scopes}) async {

    http.Response response = await httpClient.post(tokenUrl, body: {
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
      'scope': scopes.join(' ')
    });

    return AccessTokenResponse.fromHttpResponse(response);

  }

  /// Refreshes an Access Token issuing a refresh_token grant to the OAuth2 server.
  Future<AccessTokenResponse> refreshToken({@required httpClient, @required String refreshToken}) async {

    http.Response response = await httpClient.post(refreshUrl, body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken
    });

    return AccessTokenResponse.fromHttpResponse(response);

  }

  /// Generates the url to be used for fetching the authorization code.
  String getAuthorizeUrl({
    @required String clientId,
    String redirectUri,
    List<String> scopes,
    String state,
    String codeChallenge
  }) {

    final Map<String, String> params = {
      'response_type': 'code',
      'client_id': clientId
    };

    if(redirectUri != null && redirectUri.isNotEmpty)
      params['redirect_uri'] = redirectUri;

    if(scopes != null && scopes.isNotEmpty)
      params['scope'] = scopes.join(' ');

    if(state != null && state.isNotEmpty)
      params['state'] = state;

    if(codeChallenge != null && codeChallenge.isNotEmpty) {
      params['code_challenge'] = codeChallenge;
      params['code_challenge_method'] = 'S256';
    }

    return OAuth2Utils.addParamsToUrl(authorizeUrl, params);
  }

  /// Returns the parameters needed for the authorization code request
  Map<String, String> getTokenUrlParams({
    @required String code,
    String redirectUri,
    String clientId,
    String clientSecret,
    String codeVerifier
  }) {

    Map<String, String> params = {
      'grant_type': 'authorization_code',
      'code': code,
    };

    if(redirectUri != null && redirectUri.isNotEmpty)
      params['redirect_uri'] = redirectUri;

    if(clientId != null && clientId.isNotEmpty)
      params['client_id'] = clientId;

    if(clientSecret != null && clientSecret.isNotEmpty)
      params['client_secret'] = clientSecret;

    if(codeVerifier != null && codeVerifier.isNotEmpty)
      params['code_verifier'] = codeVerifier;

    return params;
  }

}