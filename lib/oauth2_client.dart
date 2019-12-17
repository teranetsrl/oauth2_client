import 'dart:convert';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';

class OAuth2Client {

  String scheme;
  String host;
  int port;
  String path;
  String redirectUri;
  String clientId;
  String clientSecret;
  String tokenEndpoint;
  String authorizeEndpoint;
  String callbackUrlScheme;

	OAuth2Client(String host, String path, {
    String clientId,
    String redirectUri,
    String clientSecret,
    String scheme = 'https',
    int port = 443,
    String authorizeEndpoint = 'authorize',
    String tokenEndpoint = 'token',
    String callbackUrlScheme = ''}) {

    this.host = host;
    this.path = path;
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.redirectUri = redirectUri;
    this.scheme = scheme;
    this.port = port;
    this.tokenEndpoint = tokenEndpoint;
    this.callbackUrlScheme = callbackUrlScheme;
  }

  Future<Map<String, dynamic>> getTokenWithAuthCode(List<String> scopes) async {

    String code = await _getAuthorizationCode(scopes);

    Uri uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path + '/' + tokenEndpoint
    );

    http.Response response = await http.post(uri.toString(), body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'client_secret': clientSecret,
    });

    var json = jsonDecode(response.body);

    assert(json is Map);

    // DateTime now = DateTime.now();
    // int expDate = now.add(Duration(seconds: json['expires_in'])).millisecondsSinceEpoch;
/*
    return {
      'access_token': json['access_token'],
      'token_type': json['token_type'],
      'expires_in': json['expires_in'],
      'refresh_token': json['refresh_token'],
      'scope': json['scope']
    };
*/

    return json;

  }

  Future<String> _getAuthorizationCode(List<String> scopes) async {

    if(clientId.isEmpty)
      throw FormatException('No client_id supplied');

    if(redirectUri.isEmpty)
      throw FormatException('No redirect_uri supplied');

    final String state = randomAlphaNumeric(25);

    Uri uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path + '/' + authorizeEndpoint,
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scopes.join(' '),
        'state': state
      }
    );

    // Present the dialog to the user
    final result = await FlutterWebAuth.authenticate(
      url: uri.toString(),
      callbackUrlScheme: callbackUrlScheme,
    );

    Map<String, List<String>> queryParams = Uri.parse(result).queryParametersAll;

    if(!queryParams.containsKey('code') || queryParams['code'].isEmpty) {
      throw FormatException('Expected code parameter not found in response');
    }

    if(!queryParams.containsKey('state') || queryParams['state'].isEmpty) {
      throw FormatException('Expected state parameter not found in response');
    }

    if(queryParams['state'][0] != state) {
      throw FormatException('state parameter in response doesn\'t correspond to the expected value');
    }

    return queryParams['code'][0];
  }

}