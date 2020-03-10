import 'dart:convert';

import 'package:http/http.dart' as http;

/// Represents the response to an Access Token Request.
/// see https://tools.ietf.org/html/rfc6749#section-5.2
class AccessTokenResponse {
  String accessToken;
  String tokenType;
  int expiresIn;
  String refreshToken;
  List<String> scope;

  DateTime expirationDate;

  String error;
  String errorDescription;
  String errorUri;
  int httpStatusCode;

  AccessTokenResponse();

  AccessTokenResponse.fromMap(Map<String, dynamic> map) {
    httpStatusCode = map['http_status_code'];

    if (!map.containsKey('error') || map['error'] == null) {
      accessToken = map['access_token'];
      tokenType = map['token_type'];
      refreshToken = map['refresh_token'];

      if (map.containsKey('scope')) {
        if (map['scope'] is List) {
          List scopesJson = map['scope'];
          scope = scopesJson != null ? List.from(scopesJson) : null;
        } else {
          scope = [map['scope']];
        }
      }

      expiresIn = map['expires_in'];

      if (map.containsKey('expiration_date')) {
        expirationDate =
            DateTime.fromMillisecondsSinceEpoch(map['expiration_date']);
      } else {
        DateTime now = DateTime.now();
        expirationDate = now.add(Duration(seconds: expiresIn));
      }
    } else {
      error = map['error'];
      errorDescription = map.containsKey('error_description')
          ? map['error_description']
          : null;
      errorUri = map.containsKey('errorUri') ? map['errorUri'] : null;
    }
  }

  factory AccessTokenResponse.fromHttpResponse(http.Response response) {
    AccessTokenResponse resp;

    if (response.statusCode != 404) {
      resp = AccessTokenResponse.fromMap(jsonDecode(response.body));
    } else {
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

  bool isValid() {
    return httpStatusCode == 200 && (error == null || error.isEmpty);
  }

  @override
  String toString() {
    if (httpStatusCode == 200) {
      return 'Access Token: ' + accessToken;
    } else {
      return 'HTTP ' +
          httpStatusCode.toString() +
          ' - ' +
          (error ?? '') +
          ' ' +
          (errorDescription ?? '');
    }
  }
}
