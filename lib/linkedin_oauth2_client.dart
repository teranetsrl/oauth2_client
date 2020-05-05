import 'package:oauth2_client/oauth2_client.dart';
import 'package:meta/meta.dart';

/// Implements an OAuth2 client to access the Linkedin API.
///
/// In order to use this client you need to first configure OAuth2 credentials (see https://docs.microsoft.com/it-it/linkedin/shared/authentication/authorization-code-flow)
///
class LinkedInOAuth2Client extends OAuth2Client {
  LinkedInOAuth2Client(
      {@required String redirectUri, @required String customUriScheme})
      : super(
            authorizeUrl: 'https://www.linkedin.com/oauth/v2/authorization',
            tokenUrl: 'https://www.linkedin.com/oauth/v2/accessToken',
            redirectUri: redirectUri,
            customUriScheme: customUriScheme);
}
