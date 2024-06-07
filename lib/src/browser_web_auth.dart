// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'package:oauth2_client/src/base_web_auth.dart';

BaseWebAuth createWebAuth() => BrowserWebAuth();

class BrowserWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate({
    required String callbackUrlScheme,
    required String url,
    required String redirectUrl,
    Map<String, dynamic>? opts,
  }) async {
    // ignore: unsafe_html
    final popupLogin = html.window.open(
      url,
      'oauth2_client::authenticateWindow',
      'menubar=no, status=no, scrollbars=no, menubar=no, width=1000, height=500',
    );

    final messageEvt = await html.window.onMessage
        .firstWhere((evt) => evt.origin == Uri.parse(redirectUrl).origin);

    popupLogin.close();

    return messageEvt.data;
  }
}
