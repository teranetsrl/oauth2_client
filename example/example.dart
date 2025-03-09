// ignore_for_file: avoid_print

import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

class Oauth2ClientExample {
  Oauth2ClientExample();

  Future<void> fetchFiles() async {
    var hlp = OAuth2Helper(
      GoogleOAuth2Client(
          redirectUri: 'com.teranet.app://oauth2redirect',
          customUriScheme: 'com.teranet.app'),
      grantType: OAuth2Helper.authorizationCode,
      clientId: 'XXX-XXX-XXX',
      clientSecret: 'XXX-XXX-XXX',
      scopes: ['https://www.googleapis.com/auth/drive.readonly'],
    );

    var resp = await hlp.get('https://www.googleapis.com/drive/v3/files');

    print(resp.body);
  }
}
