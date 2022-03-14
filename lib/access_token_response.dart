import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oauth2_client/oauth2_response.dart';

/// Represents the response to an Access Token Request.
/// see https://tools.ietf.org/html/rfc6749#section-5.2

class AccessTokenResponse extends OAuth2Response {
  AccessTokenResponse() : super();
  AccessTokenResponse.errorResponse() : super.errorResponse();

  AccessTokenResponse.fromMap(Map<String, dynamic> map) : super.fromMap(map);

  @override
  factory AccessTokenResponse.fromHttpResponse(http.Response response,
      {List<String>? requestedScopes}) {
    AccessTokenResponse resp;

    var defMap = {'http_status_code': response.statusCode};
    if (response.body != '') {
      Map<String, dynamic> rMap = jsonDecode(response.body);
      //From Section 4.2.2. (Access Token Response) of OAuth2 rfc, the "scope" parameter in the Access Token Response is
      //"OPTIONAL, if identical to the scope requested by the client; otherwise, REQUIRED."
      if ((!rMap.containsKey('scope') ||
          rMap['scope'] == null ||
          rMap['scope'].isEmpty)) {
        if (requestedScopes != null) {
          rMap['scope'] = requestedScopes;
        }
      }

      if (rMap.containsKey('expires_in')) {
        var expiresIn;

        try {
          expiresIn = rMap['expires_in'] is String
              ? int.parse(rMap['expires_in'])
              : rMap['expires_in'];
        } on FormatException {
          expiresIn = 0;
        }

        rMap['expires_in'] = expiresIn;

        rMap['expiration_date'] = DateTime.now()
            .add(Duration(seconds: expiresIn!))
            .millisecondsSinceEpoch;
      }

      resp = AccessTokenResponse.fromMap({...rMap, ...defMap});
    } else {
      resp = AccessTokenResponse.fromMap({
        ...defMap,
        ...{'scope': requestedScopes}
      });
    }

    return resp;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...respMap,
      ...{'scope': scope}
    };
  }

  ///Checks if the access token is expired
  bool isExpired() {
    var expired = false;

    if (expirationDate != null) {
      var now = DateTime.now();
      expired = expirationDate!.difference(now).inSeconds < 0;
    }

    return expired;
  }

  ///Checks if the access token must be refreeshed
  bool refreshNeeded({secondsToExpiration = 30}) {
    var needsRefresh = false;

    if (expirationDate != null) {
      var now = DateTime.now();
      needsRefresh =
          expirationDate!.difference(now).inSeconds < secondsToExpiration;
    }

    return needsRefresh;
  }

  ///Checks if the refresh token has been returned by the server
  bool hasRefreshToken() {
    return refreshToken != null;
  }

  ///Checks if the token is a "Bearer" token
  bool isBearer() {
    return tokenType?.toLowerCase() == 'bearer';
  }

  String? get accessToken {
    return isValid() ? respMap['access_token'] : null;
  }

  String? get tokenType {
    //Some providers (e.g. Slack) don't return the token_type parameter, even if it's required...
    //In those cases, fallback to "bearer"
    return isValid() ? respMap['token_type'] ?? 'Bearer' : null;
  }

  String? get refreshToken {
    return isValid() ? respMap['refresh_token'] : null;
  }

  set refreshToken(String? _tkn) {
    respMap['refresh_token'] = _tkn;
  }

  List<String>? get scope {
    var scopes;

    if (isValid()) {
      scopes = _splitScopes(respMap['scope']);
    }

    return scopes;
  }

  int? get expiresIn {
    int? expIn;

    if (isValid()) {
      if (respMap.containsKey('expires_in')) {
        try {
          expIn = respMap['expires_in'] is String
              ? int.parse(respMap['expires_in'])
              : respMap['expires_in'];
        } on FormatException {
          //Provide a fallback value if the expires_in parameter is not an integer...
          expIn = 60;
          //...But rethrow the exception!
          rethrow;
        }
      }
    }

    return expIn;
  }

  DateTime? get expirationDate {
    DateTime? expDt;
    if (isValid() && respMap.containsKey('expiration_date')) {
      expDt = DateTime.fromMillisecondsSinceEpoch(respMap['expiration_date']);
    }

    return expDt;
  }

  List<String>? _splitScopes(dynamic scopes) {
    if (scopes is List) {
      return List.from(scopes);
    } else if (scopes is String) {
      //The OAuth 2 standard suggests that the scopes should be a space-separated list,
      //but some providers (i.e. GitHub) return a comma-separated list
      return scopes.split(RegExp(r'[\s,]'));
    } else {
      return null;
    }
  }

  @override
  String toString() {
    if (httpStatusCode == 200) {
      return 'Access Token: ' + (accessToken ?? 'n.a.');
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
