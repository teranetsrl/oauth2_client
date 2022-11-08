import 'package:flutter/services.dart';

class WearAuth {
  static const MethodChannel _channel = MethodChannel('oauth2_client');

  static Future<String> authenticate({
      required String redirectUrl,
      required String url,
  }) async {
    final oldUri = Uri.parse(url);
    final query = Map<String, dynamic>.from(oldUri.queryParameters);
    query.remove('redirect_uri');
    final newUri = oldUri.replace(
      queryParameters: query,
    );
    final resultUrl = await _channel.invokeMethod<String>('authenticate', {
      'redirectUrl': redirectUrl,
      'url': newUri.toString(),
    });
    return resultUrl!;
  }

  static Future<String> authUrl({
      required String url,
  }) async {
    final oldUri = Uri.parse(url);
    final query = Map<String, dynamic>.from(oldUri.queryParameters);
    query.remove('redirect_uri');
    final newUri = oldUri.replace(
      queryParameters: query,
    );
    try {
      final String authUrl = await _channel.invokeMethod('authUrl', {
          'url': newUri.toString(),
      });
      return authUrl;
    } on PlatformException {
      return url;
    }
  }
}
