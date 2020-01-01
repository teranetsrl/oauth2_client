import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/invalidgrantexception.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_token.dart';
import 'package:meta/meta.dart';

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

  void setAuthorizationParams({@required int grantType, String clientId, String clientSecret, List<String> scopes}) {
    this.grantType = grantType;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.scopes = scopes;

    _validateAuthorizationParams();
  }

  Future<OAuth2Token> getToken() async {

    _validateAuthorizationParams();

    OAuth2Token token;

    final String key = _getStorageKey(scopes);

    String serToken = await storage.read(key: key);

    if(serToken != null) {
      token = OAuth2Token.fromMap(jsonDecode(serToken));
      if(token.refreshNeeded()) {
        //The access token is expired
        try {
          token = await refreshToken(token.refreshToken);
        } catch(err) {
          //The refresh token is expired too
          if(err is InvalidGrantException) {
            storage.delete(key: key);
            token = await getToken();
          }
        }
      }
    }
    else {
      if(grantType == AUTHORIZATION_CODE) {
        token = await client.getTokenWithAuthCodeFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes);
      }
      else if(grantType == CLIENT_CREDENTIALS) {
        token = await client.getTokenWithClientCredentialsFlow(
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes);
      }
      storage.write(key: key, value: jsonEncode(token.toMap()));
    }

    return token;
  }

  Future<OAuth2Token> refreshToken(String refreshToken) async {

    OAuth2Token token;

    final String key = _getStorageKey(scopes);

    try {
      token = await client.refreshToken(refreshToken);
      storage.write(key: key, value: jsonEncode(token.toMap()));
    } catch(err) {
      storage.delete(key: key);
      token = await getToken();
    }

    return token;
  }

  String _getStorageKey(List<String> scopes) {
    return client.baseUrl + '.' + scopes.join('_') + '.tkn';
  }

  _validateAuthorizationParams() {

    switch(grantType) {

      case AUTHORIZATION_CODE:
        if(clientSecret.isEmpty)
          throw Exception('Reuired "clientSecret" parameter not set');
        if(clientId.isEmpty)
          throw Exception('Required "clientId" parameter not set');
        if(scopes.isEmpty)
          throw Exception('Required "scopes" parameter not set');
        break;

      case CLIENT_CREDENTIALS:
        if(clientSecret.isEmpty)
          throw Exception('Reuired "clientSecret" parameter not set');
        if(clientId.isEmpty)
          throw Exception('Required "clientId" parameter not set');
        break;
    }

  }

}