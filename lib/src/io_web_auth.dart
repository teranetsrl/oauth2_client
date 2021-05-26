import 'base_web_auth.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

BaseWebAuth createWebAuth() => IoWebAuth();

class IoWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl}) async {
    return await FlutterWebAuth.authenticate(
        callbackUrlScheme: callbackUrlScheme, url: url);
  }
}
