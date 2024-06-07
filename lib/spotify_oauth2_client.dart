import 'package:oauth2_client/oauth2_client.dart';

class SpotifyOAuth2Client extends OAuth2Client {
  SpotifyOAuth2Client({required super.redirectUri, required super.customUriScheme})
      : super(
          authorizeUrl: 'https://accounts.spotify.com/authorize',
          tokenUrl: 'https://accounts.spotify.com/api/token',
        );
}
