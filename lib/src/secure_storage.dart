import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oauth2_client/src/base_storage.dart';

BaseStorage createStorage() => SecureStorage();

class SecureStorage implements BaseStorage {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  SecureStorage();

  @override
  Future<String?> read(String key) async {
    const options =
        IOSOptions(accessibility: KeychainAccessibility.first_unlock);
    return await storage.read(key: key, iOptions: options);
  }

  @override
  Future<void> write(String key, String value) async {
    const options =
        IOSOptions(accessibility: KeychainAccessibility.first_unlock);
    return await storage.write(key: key, value: value, iOptions: options);
  }
}
