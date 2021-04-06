import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oauth2_client/oauth2_response.dart';

/// Represents the response to an Access Token Request.
/// see https://tools.ietf.org/html/rfc6749#section-5.2

class AccessTokenResponse extends OAuth2Response {
  // String? accessToken;
  // String? tokenType;
  // int? expiresIn;
  // String? refreshToken;
  // List<String>? scope;

  // DateTime? expirationDate;

  AccessTokenResponse() : super();
  AccessTokenResponse.errorResponse() : super.errorResponse();

  AccessTokenResponse.fromMap(Map<String, dynamic> map) : super.fromMap(map);

  @override
  factory AccessTokenResponse.fromHttpResponse(http.Response response,
      {List<String>? requestedScopes}) {
    AccessTokenResponse resp;

    var defMap = {
      'http_status_code': response.statusCode,
      // 'resp_ts': DateTime.now()
    };
    // print('SON QUAAAAAAAAAAAAAAAA');
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
      } else {
        //The OAuth 2 standard suggests that the scopes should be a space-separated list,
        //but some providers (i.e. GitHub) return a comma-separated list
        rMap['scope'] = rMap['scope'].split(RegExp(r'[\s,]'));
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

        rMap['expiration_date'] =
            DateTime.now().add(Duration(seconds: expiresIn!));
      }

      resp = AccessTokenResponse.fromMap({...rMap, ...defMap});
    } else {
      resp = AccessTokenResponse.fromMap({
        ...defMap,
        ...{'scope': requestedScopes}
      });
    }

    return resp;
/*
    AccessTokenResponse resp;

    if (response.statusCode != 404) {
      Map<String, dynamic> respMap = jsonDecode(response.body);
      //From Section 4.2.2. (Access Token Response) of OAuth2 rfc, the "scope" parameter in the Access Token Response is
      //"OPTIONAL, if identical to the scope requested by the client; otherwise, REQUIRED."
      if ((!respMap.containsKey('scope') ||
              respMap['scope'] == null ||
              respMap['scope'].isEmpty) &&
          requestedScopes != null) {
        respMap['scope'] = requestedScopes;
      }
      respMap['http_status_code'] = response.statusCode;

      resp = AccessTokenResponse.fromMap(respMap);
    } else {
      resp = AccessTokenResponse();
    }

    return resp;
*/
  }

/*
   {

    if (isValid()) {
      accessToken = map['access_token'];
      //Some providers (e.g. Slack) don't return the token_type parameter, even if it's required...
      //In those cases, fallback to "bearer"
      tokenType = map['token_type'] ?? 'Bearer';
      if (map.containsKey('refresh_token')) refreshToken = map['refresh_token'];

      if (map.containsKey('scope')) {
        if (map['scope'] is List) {
          List scopesJson = map['scope'];
          scope = List.from(scopesJson);
        } else {
          //The OAuth 2 standard suggests that the scopes should be a space-separated list,
          //but some providers (i.e. GitHub) return a comma-separated list
          scope = map['scope']?.split(RegExp(r'[\s,]'));
        }

        scope = scope?.map((s) => s.trim()).toList();
      }

      if (map.containsKey('expires_in')) {
        try {
          expiresIn = map['expires_in'] is String
              ? int.parse(map['expires_in'])
              : map['expires_in'];
        } on FormatException {
          //Provide a fallback value if the expires_in parameter is not an integer...
          expiresIn = 60;
          //...But rethrow the exception!
          rethrow;
        }
      }

      expirationDate = null;

      if (map.containsKey('expiration_date') &&
          map['expiration_date'] != null) {
        expirationDate =
            DateTime.fromMillisecondsSinceEpoch(map['expiration_date']);
      } else {
        if (expiresIn != null) {
          var now = DateTime.now();
          expirationDate = now.add(Duration(seconds: expiresIn!));
        }
      }
    }
  }
*/
/*
  factory AccessTokenResponse.fromHttpResponse(http.Response response,
      {requestedScopes}) {
    AccessTokenResponse resp;

    if (response.statusCode != 404) {
      Map<String, dynamic> respMap = jsonDecode(response.body);
      //From Section 4.2.2. (Access Token Response) of OAuth2 rfc, the "scope" parameter in the Access Token Response is
      //"OPTIONAL, if identical to the scope requested by the client; otherwise, REQUIRED."
      if ((!respMap.containsKey('scope') ||
              respMap['scope'] == null ||
              respMap['scope'].isEmpty) &&
          requestedScopes != null) {
        respMap['scope'] = requestedScopes;
      }
      respMap['http_status_code'] = response.statusCode;

      resp = AccessTokenResponse.fromMap(respMap);
    } else {
      resp = AccessTokenResponse();
      resp.httpStatusCode = response.statusCode;
    }

    return resp;
  }
*/
  @override
  Map<String, dynamic> toMap() {
    return respMap;
/*
    var now = DateTime.now();

    return {
      ...respMap,
      ...{
        'expires_in': expirationDate?.difference(now).inSeconds,
        'expiration_date': expirationDate?.millisecondsSinceEpoch,
      }
    };
*/
/*
    return {
      'http_status_code': httpStatusCode,
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scope,
      'expires_in': expirationDate?.difference(now).inSeconds,
      'expiration_date': expirationDate?.millisecondsSinceEpoch,
      'error': error,
      'errorDescription': errorDescription,
      'errorUri': errorUri
    };
*/
  }

  ///Checks if the access token is expired
  bool isExpired() {
    var expired = false;

    if (expirationDate != null) {
      var now = DateTime.now();
      // print('${expirationDate!.minute}:${expirationDate!.second}');
      // print('${now.minute}:${now.second}');
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

  List<String>? get scope {
    var scopes;

    if (isValid()) {
      scopes = respMap['scope'];
/*
      if (respMap.containsKey('scope')) {
        if (respMap['scope'] is List) {
          List scopesJson = respMap['scope'];
          scopes = List.from(scopesJson);
        } else {
          //The OAuth 2 standard suggests that the scopes should be a space-separated list,
          //but some providers (i.e. GitHub) return a comma-separated list
          scopes = respMap['scope']?.split(RegExp(r'[\s,]'));
        }

        scopes = scopes?.map((s) => s.trim()).toList();
      }
*/
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
      expDt = respMap['expiration_date'];
      // expDt = respMap['resp_ts'].add(Duration(seconds: expiresIn!));
    }

    return expDt;
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
