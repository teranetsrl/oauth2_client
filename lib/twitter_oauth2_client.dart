import 'package:oauth2_client/oauth2_client.dart';

class TwitterOAuth2Client extends OAuth2Client {
  TwitterOAuth2Client(
      {required String redirectUri, required String customUriScheme})
      : super(
            authorizeUrl: 'https://twitter.com/i/oauth2/authorize',
            tokenUrl: 'https://api.twitter.com/2/oauth2/token',
            revokeUrl: 'https://api.twitter.com/oauth2/invalidate_token',
            redirectUri: redirectUri,
            customUriScheme: customUriScheme);
}
