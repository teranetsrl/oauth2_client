import 'package:flutter_test/flutter_test.dart';
import 'package:oauth2_client/authorization_response.dart';

void main() {
  final authCode = 'test_code';
  final state = 'test_state';

  group('Authorization Response.', () {
    test('Valid response', () {
      final url = 'myurlscheme:/oauth2?code=' + authCode + '&state=' + state;
      final resp = AuthorizationResponse.fromRedirectUri(url, state);

      expect(resp.code, authCode);
      expect(resp.state, state);
      expect(resp.isAccessGranted(), true);
    });

    test('Error response', () {
      final url = 'myurlscheme:/oauth2?error=ERR&error_description=ERR_DESC';
      final resp = AuthorizationResponse.fromRedirectUri(url, state);

      expect(resp.error, 'ERR');
      expect(resp.isAccessGranted(), false);
    });

    test('Bad response (no code param)', () {
      final url = 'myurlscheme:/oauth2?state=' + state;

      expect(() => AuthorizationResponse.fromRedirectUri(url, state),
          throwsException);
    });

    test('Bad response (no state param)', () {
      final url = 'myurlscheme:/oauth2?code=' + authCode;

      expect(() => AuthorizationResponse.fromRedirectUri(url, state),
          throwsException);
    });

    test('Bad response (wrong state param)', () {
      final url = 'myurlscheme:/oauth2?code=' + authCode + '&state=WRONGSTATE';

      expect(() => AuthorizationResponse.fromRedirectUri(url, state),
          throwsException);
    });

    test('Fetch query parameters', () {
      final testParamVal = 'testValue';
      final url = 'myurlscheme:/oauth2?code=' +
          authCode +
          '&state=' +
          state +
          '&testParam=' +
          testParamVal;
      final resp = AuthorizationResponse.fromRedirectUri(url, state);

      expect(resp.getQueryParam('code'), authCode);
      expect(resp.getQueryParam('state'), state);
      expect(resp.getQueryParam('testParam'), testParamVal);
      expect(resp.getQueryParam('testParam2'), null);
    });
  });
}
