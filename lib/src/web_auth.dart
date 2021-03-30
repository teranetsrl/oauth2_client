import 'package:flutter_web_auth/flutter_web_auth.dart'; // ignore: import_of_legacy_library_into_null_safe

class WebAuth {
  Future<String> authenticate(
      {required String callbackUrlScheme, required String url}) async {
    return await FlutterWebAuth.authenticate(
        callbackUrlScheme: callbackUrlScheme, url: url);
  }
}
