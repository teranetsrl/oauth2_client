import 'package:meta/meta.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class WebAuth {
  Future<String> authenticate(
      {@required String callbackUrlScheme, @required String url}) async {
    return await FlutterWebAuth.authenticate(
        callbackUrlScheme: callbackUrlScheme, url: url);
  }
}
