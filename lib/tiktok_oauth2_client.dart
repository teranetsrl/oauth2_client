import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';

class TikTokOAuth2Client extends OAuth2Client {
  TikTokOAuth2Client(
      {required String redirectUri, required String customUriScheme})
      : super(
          authorizeUrl: 'https://www.tiktok.com/v2/auth/authorize',
          tokenUrl: 'https://open.tiktokapis.com/v2/oauth/token/',
          revokeUrl: 'https://open.tiktokapis.com/v2/oauth/revoke/',
          scopeSeparator: ',',
          credentialsLocation: CredentialsLocation.body,
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
        );

  @override
  Future<AccessTokenResponse> requestAccessToken({
    required String code,
    required String clientId,
    String? clientSecret,
    String? codeVerifier,
    List<String>? scopes,
    Map<String, dynamic>? customParams,
    Map<String, String>? customHeaders,
    httpClient,
  }) async {
    final params = getTokenUrlParams(
      code: code,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier,
      customParams: customParams,
    );

    final headers = {
      ...?customHeaders,
      ...{'Content-Type': 'application/x-www-form-urlencoded'}
    };

    var response = await _performAuthorizedRequest(
      url: tokenUrl,
      clientId: clientId,
      clientSecret: clientSecret,
      params: params,
      headers: headers,
      httpClient: httpClient,
    );

    return http2TokenResponse(response, requestedScopes: scopes);
  }

  Future<http.Response> _performAuthorizedRequest({
    required String url,
    required String clientId,
    String? clientSecret,
    Map? params,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) async {
    final dio = Dio();

    headers ??= {};
    params ??= {};

    //If a client secret has been specified, it will be sent in the "Authorization" header instead of a body parameter...
    if (clientSecret == null) {
      if (clientId.isNotEmpty) {
        params[clientKey] = clientId;
      }
    } else {
      switch (credentialsLocation) {
        case CredentialsLocation.header:
          headers.addAll(getAuthorizationHeader(
            clientId: clientId,
            clientSecret: clientSecret,
          ));
          break;
        case CredentialsLocation.body:
          params[clientKey] = clientId;
          params['client_secret'] = clientSecret;
          break;
      }
    }

    var response = await dio.post<Map<String, dynamic>>(url,
        data: params,
        options: Options(headers: headers, responseType: ResponseType.json));

    return http.Response(jsonEncode(response.data), response.statusCode ?? 0);
  }
}
