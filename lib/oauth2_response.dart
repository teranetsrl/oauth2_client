import 'dart:convert';

import 'package:http/http.dart' as http;

/// Represents the base response for the OAuth 2 requests.
/// see https://tools.ietf.org/html/rfc6749#section-5.2
class OAuth2Response {
  String error;
  String errorDescription;
  String errorUri;
  int httpStatusCode;

  OAuth2Response() {
    httpStatusCode = 200;
  }

  OAuth2Response.fromMap(Map<String, dynamic> map) {
    httpStatusCode = map['http_status_code'];

    if (map.containsKey('error') && map['error'] != null) {
      error = map['error'];
      errorDescription = map.containsKey('error_description')
          ? map['error_description']
          : null;
      errorUri = map.containsKey('errorUri') ? map['errorUri'] : null;
    }
  }

  factory OAuth2Response.fromHttpResponse(http.Response response) {
    OAuth2Response resp;

    if (response.statusCode != 404) {
      if (response.body != '') {
        resp = OAuth2Response.fromMap(jsonDecode(response.body));
      } else {
        resp = OAuth2Response();
      }
    } else {
      resp = OAuth2Response();
    }

    resp.httpStatusCode = response.statusCode;

    return resp;
  }

  Map<String, dynamic> toMap() {
    return {
      'http_status_code': httpStatusCode,
      'error': error,
      'errorDescription': errorDescription,
      'errorUri': errorUri
    };
  }

  ///Checks if the access token request returned a valid status code
  bool isValid() {
    return httpStatusCode == 200 && (error == null || error.isEmpty);
  }

  @override
  String toString() {
    if (httpStatusCode == 200) {
      return 'Request ok';
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
