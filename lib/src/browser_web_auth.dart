import 'base_web_auth.dart';
import 'dart:async';
import 'dart:html' as html;

BaseWebAuth createWebAuth() => BrowserWebAuth();

const _oauthRedirect = 'oauth-redirect';

class BrowserWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl,
      Map<String, dynamic>? opts}) async {
    // ignore: unsafe_html
    html.window.open(url, 'html.window.onMessage',
        'menubar=no, status=no, scrollbars=no, menubar=no, width=1000, height=500');

    final completer = Completer<String>();

    html.window.onStorage.listen((event) {
      if (event.key == _oauthRedirect && !completer.isCompleted) {
        html.window.localStorage.remove(_oauthRedirect);
        final newValue = event.newValue;

        if (newValue == null) {
          throw 'oauth-failed';
        }

        completer.complete(newValue);
      }
    });

    return completer.future;
  }
}
