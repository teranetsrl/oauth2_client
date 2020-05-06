import 'dart:convert';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/src/secure_storage.dart';
import 'package:oauth2_client/src/storage.dart';

class TokenStorage {
  String key;

  Storage storage;

  TokenStorage(this.key, {this.storage}) {
    if (storage == null) storage = SecureStorage();
  }

  Future<AccessTokenResponse> getToken(List<String> scopes) async {
    AccessTokenResponse tknResp;

    final String serTokens = await storage.read(key);
    final String scopeKey = getScopeKey(scopes);

    if (serTokens != null) {
      final Map<String, dynamic> tokens = jsonDecode(serTokens);

      if (tokens.containsKey(scopeKey)) {
        tknResp = AccessTokenResponse.fromMap(tokens[scopeKey]);
      }
    }

    return tknResp;
  }

  Future<void> addToken(AccessTokenResponse tknResp) async {
    Map<String, Map> tokens = await insertToken(tknResp);
    await storage.write(key, jsonEncode(tokens));
  }

  Future<Map<String, Map>> insertToken(AccessTokenResponse tknResp) async {
    final String serTokens = await storage.read(key);
    final String scopeKey = getScopeKey(tknResp.scope);

    Map<String, Map> tokens = {};

    if (serTokens != null) {
      tokens = Map.from(jsonDecode(serTokens));
    }

    tokens[scopeKey] = tknResp.toMap();

    return tokens;
  }

  Future<bool> deleteToken(List<String> scopes) async {
    final String serTokens = await storage.read(key);
    final String scopeKey = getScopeKey(scopes);

    if (serTokens != null) {
      final Map<String, Map> tokens = Map.from(jsonDecode(serTokens));

      if (tokens.containsKey(scopeKey)) {
        tokens.remove(scopeKey);
        await storage.write(key, jsonEncode(tokens));
      }
    }

    return true;
  }

  String getScopeKey(List<String> scope) {
    String key = '_default_';

    if (scope.isNotEmpty) {
      List<String> sortedScopes = scope.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      key = sortedScopes.join('__');
    }

    return key;
  }
}
