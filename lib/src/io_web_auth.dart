import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'base_web_auth.dart';

BaseWebAuth createWebAuth() => IoWebAuth();

class IoWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl,
      Map<String, dynamic>? opts}) async {
    final preferEphemeral = (opts?['preferEphemeral'] == true);
    final intentFlags =
        preferEphemeral ? ephemeralIntentFlags : defaultIntentFlags;

    return await FlutterWebAuth2.authenticate(
        callbackUrlScheme: callbackUrlScheme,
        url: url,
        options: FlutterWebAuth2Options(
            preferEphemeral: preferEphemeral, intentFlags: intentFlags));
  }
}
