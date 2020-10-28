import 'dart:convert';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/src/secure_storage.dart';
import 'package:oauth2_client/src/storage.dart';

class TokenStorage {
  String key;

  Storage storage;

  TokenStorage(this.key, {this.storage}) {
    storage ??= SecureStorage();
  }

  /// Looks for a token in the storage that matches the required [scopes].
  /// If a token in the storage has been generated for a superset of the requested scopes, it is considered valid.
  Future<AccessTokenResponse> getToken(List<String> scopes) async {
    AccessTokenResponse tknResp;

    final serializedStoredTokens = await storage.read(key);

    if (serializedStoredTokens != null) {
      final Map<String, dynamic> storedTokens =
          jsonDecode(serializedStoredTokens);

      final cleanScopes = clearScopes(scopes);

      var tknMap = storedTokens.values.firstWhere((tkn) {
        var found = false;

        if (cleanScopes == null || cleanScopes.isEmpty) {
          //If the scopes are empty, onlty tokens granted to empty scopes are considered valid...
          found = (tkn['scope'] == null || tkn['scope'].isEmpty);
        } else {
          //...Otherwise look for a token granted to a superset of the requested scopes
          final tknCleanScopes = clearScopes(tkn['scope'].cast<String>());

          if (tknCleanScopes != null) {
            var s1 = Set.from(tknCleanScopes);
            var s2 = Set.from(cleanScopes);
            found = s1.intersection(s2).length == cleanScopes.length;
          }
        }

        return found;
      }, orElse: () => null);

      if (tknMap != null) tknResp = AccessTokenResponse.fromMap(tknMap);
    }

    return tknResp;
  }

  Future<void> addToken(AccessTokenResponse tknResp) async {
    var tokens = await insertToken(tknResp);
    await storage.write(key, jsonEncode(tokens));
  }

  Future<Map<String, Map>> insertToken(AccessTokenResponse tknResp) async {
    final serTokens = await storage.read(key);
    final scopeKey = getScopeKey(tknResp.scope);
    var tokens = <String, Map>{};

    if (serTokens != null) {
      tokens = Map.from(jsonDecode(serTokens));
    }

    tokens[scopeKey] = tknResp.toMap();

    return tokens;
  }

  Future<bool> deleteToken(List<String> scopes) async {
    final serTokens = await storage.read(key);

    if (serTokens != null) {
      final scopeKey = getScopeKey(scopes);
      final tokens = Map.from(jsonDecode(serTokens));

      if (tokens.containsKey(scopeKey)) {
        tokens.remove(scopeKey);
        await storage.write(key, jsonEncode(tokens));
      }
    }

    return true;
  }

  List clearScopes(List<String> scopes) {
    return scopes?.where((element) => element.trim().isNotEmpty)?.toList();
  }

  List getSortedScopes(List<String> scopes) {
    var sortedScopes = [];

    var cleanScopes = clearScopes(scopes);

    if (cleanScopes != null) {
      sortedScopes = cleanScopes.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    return sortedScopes;
  }

  String getScopeKey(List<String> scope) {
    var key = '_default_';

    var sortedScopes = getSortedScopes(scope);
    if (sortedScopes.isNotEmpty) {
      key = sortedScopes.join('__');
    }

    return key;
  }
}
