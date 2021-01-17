import 'package:oauth2_client/src/storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage extends Storage {
  static final FlutterSecureStorage storage = FlutterSecureStorage();

  SecureStorage();

  @override
  Future<String> read(String key) async {
    final options = IOSOptions(accessibility: IOSAccessibility.first_unlock);
    return await storage.read(key: key, iOptions: options);
  }

  @override
  Future<void> write(String key, String value) async {
    final options = IOSOptions(accessibility: IOSAccessibility.first_unlock);
    return await storage.write(key: key, value: value, iOptions: options);
  }
}
