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
      if(map.containsKey('refresh_token'))
        refreshToken = map['refresh_token'];

      if (map.containsKey('scope')) {
        if (map['scope'] is List) {
          List scopesJson = map['scope'];
          scope = scopesJson != null ? List.from(scopesJson) : null;
        } else {
          scope = [map['scope']];
        }
      }

      if(map.containsKey('expires_in'))
        expiresIn = map['expires_in'];

      expirationDate = null;

      if (map.containsKey('expiration_date') && map['expiration_date'] != null) {
        expirationDate =
            DateTime.fromMillisecondsSinceEpoch(map['expiration_date']);
      } else {
        if(expiresIn != null) {
          DateTime now = DateTime.now();
          expirationDate = now.add(Duration(seconds: expiresIn));
        }
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
  }

  Map<String, dynamic> toMap() {
    DateTime now = DateTime.now();

    return {
      'http_status_code': httpStatusCode,
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scope,
      'expires_in': expirationDate != null ? expirationDate.difference(now).inSeconds : null,
      'expiration_date': expirationDate != null ? expirationDate.millisecondsSinceEpoch : null,
      'error': error,
      'errorDescriprion': errorDescription,
      'errorUri': errorUri
    };
  }

  ///Checks if the access token is expired
  bool isExpired() {
    bool expired = false;

    if(expirationDate != null) {
      DateTime now = DateTime.now();
      expired = expirationDate.difference(now).inSeconds < 0;
    }

    return expired;
  }

  ///Checks if the access token must be refreeshed
  bool refreshNeeded({secondsToExpiration: 30}) {

    bool needsRefresh = false;

    if(expirationDate != null) {
      DateTime now = DateTime.now();
      needsRefresh = expirationDate.difference(now).inSeconds < secondsToExpiration;
    }

    return needsRefresh;

  }

  ///Checks if the refresh token has been returned by the server
  bool hasRefreshToken() {
    return refreshToken != null;
  }

  ///Checks if the token is a "Bearer" token
  bool isBearer() {
    return tokenType.toLowerCase() == 'bearer';
  }

  ///Checks if the access token request returned a valid status code
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
