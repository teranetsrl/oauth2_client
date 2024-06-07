import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/src/secure_storage.dart';
import 'package:oauth2_client/src/token_storage.dart';

import 'token_storage_test.mocks.dart';

@GenerateMocks([SecureStorage])
void main() {
  group('Token Storage.', () {
    test('Read non existent token', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1'],
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken(['scope2']);

      expect(tknResp, null);
    });

    test('Read existent token', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken(['scope1']);

      expect(tknResp?.isValid(), true);
    });

    test('Get token with a subset of scopes (1)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken(['scope1']);
      expect(tknResp?.isValid(), true);
    });

    test('Get token with a subset of scopes (2)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp2 = await storage.getToken(['scope2']);
      expect(tknResp2?.isValid(), true);
    });

    test('Get token with a subset of scopes (3)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp3 = await storage.getToken(['scope1', 'scope2']);
      expect(tknResp3?.isValid(), true);
    });

    test('Get token with a subset of scopes (4)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp4 = await storage.getToken(['scope2', 'scope1']);
      expect(tknResp4?.isValid(), true);
    });

    test('Get token with a subset of scopes (5)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp4 = await storage.getToken(['scope2', 'scope1', 'scope3']);
      expect(tknResp4, null);
    });

    test('Get token with a subset of scopes (6)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp4 = await storage.getToken(['scope3']);
      expect(tknResp4, null);
    });

    test('Get token with a subset of scopes (7)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': ['scope1', 'scope2'],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken([]);
      expect(tknResp, null);

      final tknResp2 = await storage.getToken([]);
      expect(tknResp2, null);
    });

    test('Get token with a subset of scopes (8)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': null,
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken([]);
      expect(tknResp?.isValid(), true);
    });

    test('Get token with a subset of scopes (8)', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = <String, Map<String, dynamic>>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'refresh_token': '0987654321',
          'scope': <String>[],
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tokens));

      final tknResp = await storage.getToken([]);
      expect(tknResp?.isValid(), true);
    });

    test('Insert token', () async {
      final scope1Map = <String, dynamic>{
        'access_token': '1234567890',
        'token_type': 'Bearer',
        'refresh_token': '0987654321',
        'scope': ['scope1'],
        'expires_in': 3600,
        'http_status_code': 200,
      };

      final scope2Map = <String, dynamic>{
        'access_token': '1234567890',
        'token_type': 'Bearer',
        'refresh_token': '0987654321',
        'scope': ['scope2'],
        'expires_in': 3600,
        'http_status_code': 200,
      };

      final secStorage = MockSecureStorage();

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode({'scope1': scope1Map}));

      final storage = TokenStorage('my_token_url', storage: secStorage);

      var tokens = await storage.insertToken(AccessTokenResponse.fromMap(scope1Map));

      expect(tokens, contains('scope1'));
      expect(tokens.containsKey('scope2'), false);

      tokens = await storage.insertToken(AccessTokenResponse.fromMap(scope2Map));

      expect(tokens, contains('scope2'));
    });

    test('Add token', () async {
      final scope1Map = <String, dynamic>{
        'access_token': '1234567890',
        'token_type': 'Bearer',
        'refresh_token': '0987654321',
        'scope': ['scope1'],
        'expires_in': 3600,
        'http_status_code': 200,
      };

      final secStorage = MockSecureStorage();

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode({'scope1': scope1Map}));
      final storage = TokenStorage('my_token_url', storage: secStorage);

      await storage.addToken(AccessTokenResponse.fromMap(scope1Map));
    });

    test('Add token without no scope', () async {
      final noScopesMap = <String, dynamic>{
        'access_token': '1234567890',
        'token_type': 'Bearer',
        'refresh_token': '0987654321',
        'expires_in': 3600,
        'http_status_code': 200,
      };

      final secStorage = MockSecureStorage();
      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode({'scope1': noScopesMap}));

      final storage = TokenStorage('my_token_url', storage: secStorage);

      final tokens = await storage.insertToken(AccessTokenResponse.fromMap(noScopesMap));

      expect(tokens, contains('_default_'));
    });

    test('Delete token', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      final scopes = ['scope1'];

      final tknMap = <String, dynamic>{
        'scope1': {
          'access_token': '1234567890',
          'token_type': 'Bearer',
          'refresh_token': '0987654321',
          'scope': scopes,
          'expires_in': 3600,
          'http_status_code': 200,
        },
      };

      when(secStorage.read('my_token_url')).thenAnswer((_) async => jsonEncode(tknMap));

      when(secStorage.write('my_token_url', captureAny)).thenAnswer((_) async => true);

      await storage.deleteToken(scopes);

      expect(verify(secStorage.write('my_token_url', captureAny)).captured, ['{}']);

      clearInteractions(secStorage);
    });

    test('Scope key generation', () async {
      final secStorage = MockSecureStorage();
      final storage = TokenStorage('my_token_url', storage: secStorage);

      expect(storage.getScopeKey(['test']), 'test');

      //The scope key must be invariant on the order in which the scopes are passed
      expect(storage.getScopeKey(['test1', 'test2']), 'test1__test2');
      expect(storage.getScopeKey(['test2', 'test1']), 'test1__test2');

      expect(storage.getScopeKey([]), '_default_');

      expect(storage.getScopeKey([]), '_default_');
    });
  });
}
