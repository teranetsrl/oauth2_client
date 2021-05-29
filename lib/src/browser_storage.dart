import 'dart:html' as html;
import 'package:oauth2_client/src/base_storage.dart';

BaseStorage createStorage() => WebStorage();

class WebStorage implements BaseStorage {
  WebStorage();

  @override
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}
