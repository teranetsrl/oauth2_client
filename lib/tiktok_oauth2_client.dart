import 'package:oauth2_client/oauth2_client.dart';

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
}
