import 'dart:convert';

import 'package:crypto/crypto.dart';

class OAuth2Utils {

  /// Generates a code challenge from the [codeVerifier] used for the PKCE extension
  static String generateCodeChallenge(String codeVerifier) {
      List<int> bytes = utf8.encode(codeVerifier);

      Digest digest = sha256.convert(bytes);

      String codeChallenge = base64UrlEncode(digest.bytes);

      if(codeChallenge.endsWith('=')) {
        //Since code challenge must contain only chars in the range ALPHA | DIGIT | "-" | "." | "_" | "~" (see https://tools.ietf.org/html/rfc7636#section-4.2)
        //many OAuth2 servers (read "Google") don't accept the "=" at the end of the base64 encoded string
        codeChallenge = codeChallenge.substring(0, codeChallenge.length - 1);
      }

      return codeChallenge;
  }

  static String params2qs(Map params) {

    List<String> qsList = [];

    params.forEach((k, v) {
      qsList.add(k + '=' + v);
    });

    return qsList.join('&');

  }

  static String addParamsToUrl(String url, Map params) {

    String qs = params2qs(params);

    if(qs != null && qs.isNotEmpty)
      url = url + '?' + qs;

    return url;
  }
}