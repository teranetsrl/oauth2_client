import 'package:oauth2_client/oauth2_client.dart';
import 'package:meta/meta.dart';

/// Implements an OAuth2 client against GitHub
///
/// In order to use this client you need to first create a new OAuth2 App in the GittHub Developer Settings (https://github.com/settings/developers)
///
class GitHubOAuth2Client extends OAuth2Client {
  GitHubOAuth2Client(
      {@required String redirectUri, @required String customUriScheme})
      : super(
            authorizeUrl: 'https://github.com/login/oauth/authorize',
            tokenUrl: 'https://github.com/login/oauth/access_token',
            redirectUri: redirectUri,
            customUriScheme: customUriScheme) {
    accessTokenRequestHeaders = {'Accept': 'application/json'};
  }
}
