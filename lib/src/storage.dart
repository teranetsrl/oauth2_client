import 'base_storage.dart';

/// Implemented in `browser_client.dart` and `io_client.dart`.
BaseStorage createStorage() => throw UnsupportedError(
    'Cannot create a storage without dart:html or dart:io.');
