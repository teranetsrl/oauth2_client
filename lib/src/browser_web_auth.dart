import 'base_web_auth.dart';
import 'dart:html' as html;

BaseWebAuth createWebAuth() => BrowserWebAuth();

class BrowserWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl}) async {
    // ignore: unsafe_html
    final popupLogin = html.window.open(
        url,
        'oauth2_client::authenticateWindow',
        'menubar=no, status=no, scrollbars=no, menubar=no, width=1000, height=500');

    var messageEvt = await html.window.onMessage
        .firstWhere((evt) => evt.origin == Uri.parse(redirectUrl).origin);

    popupLogin.close();

    return messageEvt.data;
  }
}
