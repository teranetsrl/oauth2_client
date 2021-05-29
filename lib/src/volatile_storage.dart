import 'package:oauth2_client/src/base_storage.dart';

BaseStorage createStorage() => VolatileStorage();

class VolatileStorage implements BaseStorage {
  final Map<String, String> storage = {};

  VolatileStorage();

  @override
  Future<String?> read(String key) async {
    return Future.value(storage.containsKey(key) ? storage[key] : null);
  }

  @override
  Future<void> write(String key, String value) async {
    storage[key] = value;
  }
}
