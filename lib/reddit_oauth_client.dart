import 'package:oauth2_client/oauth2_client.dart';

/// Implements an OAuth2 client against Reddit
///
/// In order to use this client you need to first create a new OAuth2 App in Reddit autorized apps settings (https://www.reddit.com/prefs/apps)
///
class RedditOauth2Client extends OAuth2Client {
  RedditOauth2Client(
      {required String redirectUri, required String customUriScheme})
      : super(
          authorizeUrl:
              'https://www.reddit.com/api/v1/authorize.compact', //Your service's authorization url
          tokenUrl:
              'https://www.reddit.com/api/v1/access_token', //Your service access token url
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
          scopeSeparator: ',',
          credentialsLocation: CredentialsLocation.HEADER,
        );
}
