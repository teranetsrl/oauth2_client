import 'package:oauth2_client/src/base_storage.dart';
import 'package:web/web.dart' as web;

BaseStorage createStorage() => WebStorage();

class WebStorage implements BaseStorage {
  WebStorage();

  @override
  Future<String?> read(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }
}
