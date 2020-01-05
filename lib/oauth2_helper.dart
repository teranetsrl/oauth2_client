import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/exceptions.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/access_token.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Helper class for simplifying OAuth2 authorization process.
///
/// Tokens are stored in a secure storage
/// Automatic token refreshing
/// Automatic injection of the Access Token in requests through the various post/get/... methods
///
///
class OAuth2Helper {

  static const AUTHORIZATION_CODE = 1;
  static const CLIENT_CREDENTIALS = 2;

  final OAuth2Client client;
  final FlutterSecureStorage storage = new FlutterSecureStorage();

  int grantType;
  String clientId;
  String clientSecret;
  List<String> scopes;

  OAuth2Helper(this.client);

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
  Future<AccessToken> getToken() async {

    _validateAuthorizationParams();

    AccessToken token;

    final String key = _getStorageKey(scopes);

    String serToken = await storage.read(key: key);

    if(serToken != null) {
      token = AccessToken.fromMap(jsonDecode(serToken));
      if(token.refreshNeeded()) {
        //The access token is expired
        token = await refreshToken(token.refreshToken);
      }
    }
    else {
      if(grantType == AUTHORIZATION_CODE) {
        token = await client.getTokenWithAuthCodeFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes
        );
      }
      else if(grantType == CLIENT_CREDENTIALS) {
        token = await client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes
        );
      }

      if(token != null)
        storage.write(key: key, value: jsonEncode(token.toMap()));
    }

    if(token != null && !token.isBearer()) {
      throw Exception('Only Bearer tokens are currently supported');
    }

    return token;
  }

  /// Performs a refresh_token request using the [refreshToken].
  Future<AccessToken> refreshToken(String refreshToken) async {

    AccessToken token;

    final String key = _getStorageKey(scopes);

    try {
      token = await client.refreshToken(refreshToken);
      storage.write(key: key, value: jsonEncode(token.toMap()));
    } catch(err) {
      //The refresh token is expired too
      if(err is InvalidGrantException) {
        storage.delete(key: key);
        token = await getToken();
      }
      else {
        rethrow;
      }
    }

    return token;
  }

  /// Performs a post request to the specified [url], adding the authorization token.
  ///
  /// If no token already exists, or if it is exipired, a new one is requested.
  Future<http.Response> post(String url, {Map<String, dynamic> params}) async {

    AccessToken tkn = await getToken();

    http.Response resp = await http.post(url, body: params, headers: {
      'Authorization': 'Bearer ' + tkn.accessToken
    });

    if(resp.statusCode == 401) {
      Map<String, dynamic> respData = jsonDecode(resp.body);
      if(respData.containsKey('error')) {
        if(respData['error'] == 'invalid_token') {

          tkn = await refreshToken(tkn.refreshToken);

          resp = await http.post(url, body: params, headers: {
            'Authorization': 'Bearer ' + tkn.accessToken
          });
        }
      }
    }

    return resp;
  }

  /// Performs a get request to the specified [url], adding the authorization token.
  ///
  /// If no token already exists, or if it is exipired, a new one is requested.
  Future<http.Response> get(String url) async {

    AccessToken tkn = await getToken();

    http.Response resp = await http.get(url, headers: {
      'Authorization': 'Bearer ' + tkn.accessToken
    });

    if(resp.statusCode == 401) {
      Map<String, dynamic> respData = jsonDecode(resp.body);
      if(respData.containsKey('error')) {
        if(respData['error'] == 'invalid_token') {
          tkn = await refreshToken(tkn.refreshToken);
          resp = await http.get(url, headers: {
            'Authorization': 'Bearer ' + tkn.accessToken
          });
        }
      }
    }

    return resp;
  }

  String _getStorageKey(List<String> scopes) {
    return client.customUriScheme + '.' + scopes.join('_') + '.tkn';
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