import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oauth2_client/oauth2_response.dart';

/// Represents the response to an Access Token Request.
/// see https://tools.ietf.org/html/rfc6749#section-5.2
class AccessTokenResponse extends OAuth2Response {
  String accessToken;
  String tokenType;
  int expiresIn;
  String refreshToken;
  List<String> scope;

  DateTime expirationDate;

  AccessTokenResponse();

  AccessTokenResponse.fromMap(Map<String, dynamic> map): super.fromMap(map) {

    if(isValid()) {
      accessToken = map['access_token'];
      tokenType = map['token_type'];
      refreshToken = map['refresh_token'];

      List scopesJson = map['scope'];
      scope = scopesJson != null ? List.from(scopesJson) : null;

      expiresIn = map['expires_in'];

      if(map.containsKey('expiration_date')) {
        expirationDate = DateTime.fromMillisecondsSinceEpoch(map['expiration_date']);
      }
      else {
        DateTime now = DateTime.now();
        expirationDate = now.add(Duration(seconds: expiresIn));
      }
    }

  }

  factory AccessTokenResponse.fromHttpResponse(http.Response response) {

    AccessTokenResponse resp;

    if(response.statusCode != 404) {
      resp = AccessTokenResponse.fromMap(jsonDecode(response.body));
    }
    else {
      resp = AccessTokenResponse();
    }

    resp.httpStatusCode = response.statusCode;


    return resp;
/*
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
    else {
      AccessTokenResponse.fromMap(respData);
    }

    return tknResp;
*/
    // return respData;
  }

  Map<String, dynamic> toMap() {

    DateTime now = DateTime.now();

    return {
      'http_status_code': httpStatusCode,
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scope,
      'expires_in': expirationDate.difference(now).inSeconds,
      'expiration_date': expirationDate.millisecondsSinceEpoch,
      'error': error,
      'errorDescriprion': errorDescription,
      'errorUri': errorUri
    };
  }

  bool isExpired() {
    DateTime now = DateTime.now();
    return expirationDate.difference(now).inSeconds < 0;
  }

  bool refreshNeeded({secondsToExpiration: 30}) {
    DateTime now = DateTime.now();
    return expirationDate.difference(now).inSeconds < secondsToExpiration;
  }

  bool isBearer() {
    return tokenType.toLowerCase() == 'bearer';
  }

  @override
  String toString() {
    if(httpStatusCode == 200) {
      return 'Access Token: ' + accessToken;
    }
    else {
      return 'HTTP ' + httpStatusCode.toString() + ' - ' + (error ?? '') + ' ' + (errorDescription ?? '');
    }
  }
}