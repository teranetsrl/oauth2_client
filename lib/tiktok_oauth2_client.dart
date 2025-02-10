import 'package:oauth2_client/oauth2_client.dart';

class TikTokOAuth2Client extends OAuth2Client {
  TikTokOAuth2Client({required String redirectUri, required String customUriScheme})
      : super(
          authorizeUrl: 'https://www.tiktok.com/v2/auth/authorize',
          tokenUrl: 'https://open.tiktokapis.com/v2/oauth/token',
          revokeUrl: 'https://open.tiktokapis.com/v2/oauth/revoke',
          credentialsLocation: CredentialsLocation.body,
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
        );
}
