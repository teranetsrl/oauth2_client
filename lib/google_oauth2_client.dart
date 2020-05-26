import 'package:oauth2_client/oauth2_client.dart';
import 'package:meta/meta.dart';

/// Implements an OAuth2 client that uses Google services to authorize requests.
///
/// In order to use this client you need to first configure OAuth2 credentials in the Google API console (https://console.developers.google.com/apis/)
/// First you need to create a new Project if it doesn't already exists, then you need to create the OAuth2 credentials ("OAuth Client ID").
/// Select iOS as Application Type, specify a name for the client and in the "Bundle ID" field insert your custom uri scheme
/// (for example 'com.example.app', but you can use whatever uri scheme you want).
///
class GoogleOAuth2Client extends OAuth2Client {
  GoogleOAuth2Client(
      {@required String redirectUri, @required String customUriScheme})
      : super(
            authorizeUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
            tokenUrl: 'https://oauth2.googleapis.com/token',
            revokeUrl: 'https://oauth2.googleapis.com/revoke',
            redirectUri: redirectUri,
            customUriScheme: customUriScheme);
}
