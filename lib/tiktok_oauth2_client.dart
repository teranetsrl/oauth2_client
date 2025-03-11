import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/src/base_web_auth.dart';

class TikTokOAuth2Client extends OAuth2Client {
  TikTokOAuth2Client(
      {required super.redirectUri, required super.customUriScheme})
      : super(
          authorizeUrl: 'https://www.tiktok.com/v2/auth/authorize',
          tokenUrl: 'https://open.tiktokapis.com/v2/oauth/token/',
          revokeUrl: 'https://open.tiktokapis.com/v2/oauth/revoke/',
          scopeSeparator: ',',
          credentialsLocation: CredentialsLocation.body,
          clientIdKey: 'client_key',
        );

  @override
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow({
    required String clientId,
    List<String>? scopes,
    String? clientSecret,
    bool enablePKCE = true,
    bool enableState = true,
    String? state,
    String? codeVerifier,
    Function? afterAuthorizationCodeCb,
    Map<String, dynamic>? authCodeParams,
    Map<String, dynamic>? accessTokenParams,
    Map<String, String>? accessTokenHeaders,
    httpClient,
    BaseWebAuth? webAuthClient,
    Map<String, dynamic>? webAuthOpts,
  }) async {
    return super.getTokenWithAuthCodeFlow(
      clientId: clientId,
      scopes: scopes,
      clientSecret: clientSecret,
      enablePKCE: enablePKCE,
      enableState: enableState,
      state: state,
      codeVerifier: codeVerifier,
      afterAuthorizationCodeCb: afterAuthorizationCodeCb,
      authCodeParams: authCodeParams,
      accessTokenParams: accessTokenParams,
      accessTokenHeaders: {
        ...?accessTokenHeaders,
        ...{
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
        }
      },
      httpClient: httpClient,
      webAuthClient: webAuthClient,
      webAuthOpts: webAuthOpts,
    );
  }
}
