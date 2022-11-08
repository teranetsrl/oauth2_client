import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'base_web_auth.dart';
import 'wear_auth.dart';
import 'package:wear_bridge/wear_bridge.dart';

BaseWebAuth createWebAuth() => IoWebAuth();

class IoWebAuth implements BaseWebAuth {
  @override
  Future<String> authenticate(
      {required String callbackUrlScheme,
      required String url,
      required String redirectUrl,
      Map<String, dynamic>? opts}) async {
    if (await WearBridge.isWatch()) {
      return await WearAuth.authenticate(
        url: url,
        redirectUrl: redirectUrl,
      );
    }
    return await FlutterWebAuth2.authenticate(
      callbackUrlScheme: callbackUrlScheme,
      url: url,
      preferEphemeral: (opts?['preferEphemeral'] == true),
    );
  }
}
