import 'dart:convert';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/exceptions.dart';
import 'package:oauth2_client/access_token.dart';
import 'package:oauth2_client/id_token.dart';
import 'package:random_string/random_string.dart';
import 'package:meta/meta.dart';
import 'package:crypto/crypto.dart';

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
  String authorizeUrl;

	OAuth2Client({
    @required this.authorizeUrl,
    @required this.tokenUrl,
    this.refreshUrl,
    @required this.redirectUri,
    @required this.customUriScheme});

  /// Requests an Access Token to the OAuth2 endpoint using the Authorization Code Flow.
  Future<AccessToken> getTokenWithAuthCodeFlow({@required String clientId, @required List<String> scopes, String clientSecret, bool enablePKCE = true}) async {

    String codeChallenge;
    String codeVerifier;

    if(enablePKCE) {
      codeVerifier = randomAlphaNumeric(80);
      List<int> bytes = utf8.encode(codeVerifier);

      Digest digest = sha256.convert(bytes);

      codeChallenge = base64UrlEncode(digest.bytes);

      if(codeChallenge.endsWith('=')) {
        codeChallenge = codeChallenge.substring(0, codeChallenge.length - 1);
      }
    }

    String code = await _getAuthorizationCode(clientId: clientId, scopes: scopes, codeChallenge: codeChallenge);

    final String url = _getEndpointUrl(tokenUrl);

    Map<String, String> body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
    };

    if(clientSecret != null)
      body['client_secret'] = clientSecret;

    if(codeVerifier != null)
      body['code_verifier'] = codeVerifier;

    http.Response response = await http.post(url, body: body);

    Map tokenInfo = _parseResponse(response);

    return AccessToken.fromMap(tokenInfo);
  }

  /// Requests an Access Token to the OAuth2 endpoint using the Client Credentials flow.
  Future<AccessToken> getTokenWithClientCredentialsFlow({@required String clientId, @required String clientSecret, List<String> scopes}) async {

    final String url = _getEndpointUrl(tokenUrl);

    http.Response response = await http.post(url, body: {
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
      'scope': scopes.join(' ')
    });

    Map tokenInfo = _parseResponse(response);

    return AccessToken.fromMap(tokenInfo);

  }

  /// Refreshes an Access Token issuing a refresh_token grant to the OAuth2 server.
  Future<AccessToken> refreshToken(String refreshToken) async {

    final String url = _getEndpointUrl(refreshUrl);

    http.Response response = await http.post(url, body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken
    });

    Map tokenInfo = _parseResponse(response);

    return AccessToken.fromMap(tokenInfo);

  }

  Future<String> _getAuthorizationCode({@required String clientId, @required List<String> scopes, String codeChallenge}) async {

    if(redirectUri.isEmpty)
      throw Exception('No "redirectUri" supplied');

    final String state = randomAlphaNumeric(25);

    Map<String, String> params = {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'state': state
    };

    if(codeChallenge != null) {
      params['code_challenge'] = codeChallenge;
      params['code_challenge_method'] = 'S256';
    }

    final String url = _getEndpointUrl(authorizeUrl, params: params);

    // Present the dialog to the user
    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: customUriScheme
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

  String _getEndpointUrl(String url, {Map<String, dynamic> params}) {

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

    if(response.statusCode != 200) {

      final String error = respData['error'];

      //@see https://tools.ietf.org/html/rfc6750#section-3.1
      if(response.statusCode == 401 && response.headers.containsKey('WWW-Authenticate')) {
        if(error == 'invalid_token') {
          throw InvalidTokenException();
        }
      }
      else if(response.statusCode == 400) {
        //@see https://tools.ietf.org/html/rfc6749#section-5.2
        // if(error == 'invalid_grant') {
          throw InvalidGrantException();
        // }
      }

      throw Exception(error + (respData['error_description'].isNotEmpty ? ': ' + respData['error_description'] : ''));
    }

    return respData;
  }

}