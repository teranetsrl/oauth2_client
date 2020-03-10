import 'package:oauth2_client/oauth2_helper.dart';
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:http/http.dart' as http;

class Oauth2ClientExample {
  Oauth2ClientExample();

  Future<void> fetchFiles() async {
    OAuth2Helper hlp = OAuth2Helper(GoogleOAuth2Client(
        redirectUri: 'com.teranet.app:/oauth2redirect',
        customUriScheme: 'com.teranet.app'));

    hlp.setAuthorizationParams(
        grantType: OAuth2Helper.AUTHORIZATION_CODE,
        clientId: 'XXX-XXX-XXX',
        scopes: ['https://www.googleapis.com/auth/drive.readonly']);

    http.Response resp =
        await hlp.get('https://www.googleapis.com/drive/v3/files');

    print(resp.body);
  }
}
