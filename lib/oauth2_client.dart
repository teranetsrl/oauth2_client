import 'dart:convert';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/invalidgrantexception.dart';
import 'package:oauth2_client/oauth2_token.dart';
import 'package:random_string/random_string.dart';
import 'package:meta/meta.dart';

class OAuth2Client {

  String baseUrl;
  String redirectUri;
  String callbackUrlScheme;

  String tokenEndpoint;
  String refreshEndpoint;
  String authorizeEndpoint;

	OAuth2Client(this.baseUrl, {
    this.authorizeEndpoint = 'authorize',
    this.tokenEndpoint = 'token',
    this.refreshEndpoint = 'refresh',
    this.redirectUri,
    this.callbackUrlScheme});

  Future<OAuth2Token> getTokenWithAuthCodeFlow({@required String clientId, @required String clientSecret, @required List<String> scopes}) async {

    String code = await _getAuthorizationCode(clientId: clientId, scopes: scopes);

    final String url = _getEndpointUrl(tokenEndpoint);

    http.Response response = await http.post(url, body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'client_secret': clientSecret,
    });

    Map tokenInfo = _parseResponse(response);

    return OAuth2Token.fromMap(tokenInfo);
  }

  Future<OAuth2Token> getTokenWithClientCredentialsFlow({@required String clientId, @required String clientSecret, List<String> scopes}) async {

    final String url = _getEndpointUrl(tokenEndpoint);

    http.Response response = await http.post(url, body: {
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
      'scope': scopes.join(' ')
    });

    Map tokenInfo = _parseResponse(response);

    return OAuth2Token.fromMap(tokenInfo);

  }

  Future<OAuth2Token> refreshToken(String refreshToken) async {

    final String url = _getEndpointUrl(refreshEndpoint);

    http.Response response = await http.post(url, body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken
    });

    Map tokenInfo = _parseResponse(response);

    return OAuth2Token.fromMap(tokenInfo);

  }

  Future<String> _getAuthorizationCode({@required String clientId, @required List<String> scopes}) async {

    if(redirectUri.isEmpty)
      throw Exception('No "redirectUri" supplied');

    final String state = randomAlphaNumeric(25);

    final String url = _getEndpointUrl(authorizeEndpoint, params: {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'state': state
    });

    // Present the dialog to the user
    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
    );

    Map<String, List<String>> queryParams = Uri.parse(result).queryParametersAll;

    if(queryParams.containsKey('error') && queryParams['error'].isNotEmpty) {
      throw Exception(queryParams['error'][0] + (queryParams['error_description'].isNotEmpty ? ': ' + queryParams['error_description'][0] : ''));
    }

    if(!queryParams.containsKey('code') || queryParams['code'].isEmpty) {
      throw Exception('Expected "code" parameter not found in response');
    }

    if(!queryParams.containsKey('state') || queryParams['state'].isEmpty) {
      throw Exception('Expected "state" parameter not found in response');
    }

    if(queryParams['state'][0] != state) {
      throw Exception('"state" parameter in response doesn\'t correspond to the expected value');
    }

    return queryParams['code'][0];
  }

  String _getEndpointUrl(String path, {Map<String, dynamic> params}) {
    String url = baseUrl + '/' + path;

    if(params != null) {
      List<String> qsList = [];
      params.forEach((k, v) {
        qsList.add(k + '=' + v);
      });
      if(qsList.isNotEmpty) {
        url = Uri.encodeFull(url + '?' + qsList.join('&'));
      }
    }

    return url;

  }

  Map<String, dynamic> _parseResponse(http.Response response) {

    Map respData = jsonDecode(response.body);

    //@see https://tools.ietf.org/html/rfc6749#section-5.2
    if(response.statusCode == 400) {

      final String error = respData['error'];

      if(error == 'invalid_grant') {
        throw InvalidGrantException();
      }
      else {
        throw Exception(error + (respData['error_description'].isNotEmpty ? ': ' + respData['error_description'] : ''));
      }
    }

    return respData;
  }

}