import 'package:oauth2_client/oauth2_client.dart';

/// Implements an OAuth2 client against Microsoft
///
///
class MicrosoftOauth2Client extends OAuth2Client {
  MicrosoftOauth2Client({
    required String tenant,
    required super.redirectUri,
    required super.customUriScheme,
  }) : super(
          authorizeUrl: '$_myAuthority$tenant/oauth2/v2.0/authorize',
          tokenUrl: '$_myAuthority$tenant/oauth2/v2.0/token',
        );
  static const String _myAuthority = 'https://login.microsoftonline.com/';
}
