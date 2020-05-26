import 'package:http/http.dart' as http;

import 'package:flutter_test/flutter_test.dart';
import 'package:oauth2_client/oauth2_response.dart';

void main() {
  test('Valid response', () async {
    final respMap = <String, dynamic>{'http_status_code': 200};

    final resp = OAuth2Response.fromMap(respMap);

    expect(resp.isValid(), true);
  });

  test('Error response', () async {
    final respMap = <String, dynamic>{
      'error': 'ERROR',
      'error_description': 'ERROR_DESC',
      'http_status_code': 400
    };

    final resp = OAuth2Response.fromMap(respMap);

    expect(resp.isValid(), false);
  });

  test('Convert to map', () async {
    final respMap = <String, dynamic>{
      'error': 'generic_error',
      'error_description': 'err_desc',
      'http_status_code': 400
    };

    final resp = OAuth2Response.fromMap(respMap);

    expect(
        resp.toMap(),
        allOf(
            containsPair('error', 'generic_error'),
            containsPair('errorDescription', 'err_desc'),
            containsPair('http_status_code', 400)));
  });

  test('Conversion from HTTP response', () async {
    final response = http.Response('{}', 200);

    final resp = OAuth2Response.fromHttpResponse(response);

    expect(resp.isValid(), true);
  });

  test('toString(1)', () async {
    final respMap = <String, dynamic>{'http_status_code': 200};

    final resp = OAuth2Response.fromMap(respMap);

    expect(resp.toString(), 'Request ok');
  });

  test('toString(2)', () async {
    final respMap = <String, dynamic>{
      'error': 'generic_error',
      'error_description': 'err_desc',
      'http_status_code': 400
    };

    final resp = OAuth2Response.fromMap(respMap);

    expect(resp.toString(), 'HTTP 400 - generic_error err_desc');
  });
}
