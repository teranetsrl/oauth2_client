import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/google_oauth2_client.dart';

class Oauth2ClientExample {
  Oauth2ClientExample();

  Future<void> fetchFiles() async {
    var hlp = OAuth2Helper(GoogleOAuth2Client(
        redirectUri: 'com.teranet.app:/oauth2redirect',
        customUriScheme: 'com.teranet.app'));

    hlp.setAuthorizationParams(
        grantType: OAuth2Helper.AUTHORIZATION_CODE,
        clientId: 'XXX-XXX-XXX',
        clientSecret: 'XXX-XXX-XXX',
        scopes: ['https://www.googleapis.com/auth/drive.readonly']);

    var resp =
        await hlp.get('https://www.googleapis.com/drive/v3/files');

    print(resp.body);
  }
}
