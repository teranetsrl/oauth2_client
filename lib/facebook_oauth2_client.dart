import 'package:oauth2_client/oauth2_client.dart';
import 'package:meta/meta.dart';

/// Implements an OAuth2 client that uses Facebook services to authorize requests.
///
/// In order to use this client you need to first configure OAuth2 credentials in the Facebook dashboard.
///
class FacebookOAuth2Client extends OAuth2Client {
  FacebookOAuth2Client(
      {@required String redirectUri, @required String customUriScheme})
      : super(
            authorizeUrl: 'https://www.facebook.com/v5.0/dialog/oauth',
            tokenUrl: 'https://graph.facebook.com/oauth/access_token',
            redirectUri: redirectUri,
            customUriScheme: customUriScheme);
}
