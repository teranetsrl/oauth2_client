import 'package:oauth2_client/oauth2_client.dart';

class TwitterOAuth2Client extends OAuth2Client {
  TwitterOAuth2Client({required super.redirectUri, required super.customUriScheme})
      : super(
          authorizeUrl: 'https://twitter.com/i/oauth2/authorize',
          tokenUrl: 'https://api.twitter.com/2/oauth2/token',
          revokeUrl: 'https://api.twitter.com/oauth2/invalidate_token',
        );
}
