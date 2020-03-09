import 'dart:convert';

import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_exception.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:oauth2_client/src/token_storage.dart';

/// Helper class for simplifying OAuth2 authorization process.
///
/// Tokens are stored in a secure storage.
/// The helper performs automatic token refreshing upon access token expiration.
/// Moreover it provides methods to perform http post/get calls with automatic Access Token injection in the requests header
///
///
class OAuth2Helper {

  static const AUTHORIZATION_CODE = 1;
  static const CLIENT_CREDENTIALS = 2;

  final OAuth2Client client;
  TokenStorage tokenStorage;

  int grantType;
  String clientId;
  String clientSecret;
  List<String> scopes;

  OAuth2Helper(this.client, {this.tokenStorage}) {
    if(tokenStorage == null)
      tokenStorage = TokenStorage(client.tokenUrl);
  }

  /// Sets the proper parameters for requesting an authorization token.
  ///
  /// The parameters are validated depending on the [grantType].
  void setAuthorizationParams({@required int grantType, String clientId, String clientSecret, List<String> scopes}) {
    this.grantType = grantType;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.scopes = scopes;

    _validateAuthorizationParams();
  }

  /// Returns a previously required token, if any, or requires a new one.
  ///
  /// If a token already exists but is expired, a new token is generated through the refresh_token grant.
  Future<AccessTokenResponse> getToken() async {

    _validateAuthorizationParams();

    AccessTokenResponse tknResp = await tokenStorage.getToken(scopes);

    if(tknResp != null) {
      if(tknResp.refreshNeeded()) {
        //The access token is expired
        tknResp = await refreshToken(tknResp.refreshToken);
      }
    }
    else {
      if(grantType == AUTHORIZATION_CODE) {

        tknResp = await client.getTokenWithAuthCodeFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes
        );

      }
      else if(grantType == CLIENT_CREDENTIALS) {
        tknResp = await client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes
        );
      }

      if(tknResp != null && tknResp.isValid())
        tokenStorage.addToken(tknResp);
    }

    if(tknResp != null && !tknResp.isBearer()) {
      throw Exception('Only Bearer tokens are currently supported');
    }

    return tknResp;
  }

  /// Performs a refresh_token request using the [refreshToken].
  Future<AccessTokenResponse> refreshToken(String refreshToken) async {

    AccessTokenResponse tknResp;

    tknResp = await client.refreshToken(refreshToken);

    if(tknResp != null && tknResp.isValid()) {
      tokenStorage.addToken(tknResp);
    }
    else {

      if(tknResp.error == 'invalid_grant') {
        //The refresh token is expired too
        tokenStorage.deleteToken(scopes);
        tknResp = await getToken();
      }
      else {
        throw OAuth2Exception(tknResp.error, errorDescription: tknResp.errorDescription);
      }
    }

    return tknResp;
  }

  /// Performs a post request to the specified [url], adding the authorization token.
  ///
  /// If no token already exists, or if it is exipired, a new one is requested.
  Future<http.Response> post(String url, {Map<String, dynamic> params, httpClient}) async {

    if(httpClient == null)
      httpClient = http.Client();

    http.Response resp;

    AccessTokenResponse tknResp = await getToken();

    try {
      resp = await httpClient.post(url, body: params, headers: {
        'Authorization': 'Bearer ' + tknResp.accessToken
      });

      if(resp.statusCode == 401) {

        Map<String, dynamic> respData = jsonDecode(resp.body);
        if(respData.containsKey('error')) {
          if(respData['error'] == 'invalid_token') {

            tknResp = await refreshToken(tknResp.refreshToken);

            resp = await httpClient.post(url, body: params, headers: {
              'Authorization': 'Bearer ' + tknResp.accessToken
            });
          }
        }
      }

    } catch(e) {
      rethrow;
    }
    return resp;
  }

  /// Performs a get request to the specified [url], adding the authorization token.
  ///
  /// If no token already exists, or if it is exipired, a new one is requested.
  Future<http.Response> get(String url, {httpClient}) async {

    if(httpClient == null)
      httpClient = http.Client();

    http.Response resp;

    AccessTokenResponse tknResp = await getToken();

    try {

      resp = await httpClient.get(url, headers: {
        'Authorization': 'Bearer ' + tknResp.accessToken
      });

      if(resp.statusCode == 401) {
        Map<String, dynamic> respData = jsonDecode(resp.body);
        if(respData.containsKey('error')) {
          if(respData['error'] == 'invalid_token') {

            tknResp = await refreshToken(tknResp.refreshToken);

            resp = await httpClient.get(url, headers: {
              'Authorization': 'Bearer ' + tknResp.accessToken
            });
          }
        }
      }
    } catch(e) {
      rethrow;
    }

    return resp;
  }

  _validateAuthorizationParams() {

    switch(grantType) {

      case AUTHORIZATION_CODE:
        // if(clientSecret == null || clientSecret.isEmpty)
          // throw Exception('Required "clientSecret" parameter not set');
        if(clientId == null || clientId.isEmpty)
          throw Exception('Required "clientId" parameter not set');
        if(scopes == null || scopes.isEmpty)
          throw Exception('Required "scopes" parameter not set');
        break;

      case CLIENT_CREDENTIALS:
        if(clientSecret == null || clientSecret.isEmpty)
          throw Exception('Required "clientSecret" parameter not set');
        if(clientId == null || clientId.isEmpty)
          throw Exception('Required "clientId" parameter not set');
        break;
    }

  }

}