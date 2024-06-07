import 'package:oauth2_client/src/base_web_auth.dart';

/// Implemented in `browser_client.dart` and `io_client.dart`.
BaseWebAuth createWebAuth() => throw UnsupportedError('Cannot create a web auth without dart:html or dart:io.');
