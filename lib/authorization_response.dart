/// Represents the response to an Authorization Request.
/// see https://tools.ietf.org/html/rfc6749#page-26
class AuthorizationResponse {
  String code;
  String state;

  String error;
  String errorDescription;

  AuthorizationResponse();

  AuthorizationResponse.fromRedirectUri(String redirectUri, String checkState) {
    Map<String, String> queryParams = Uri.parse(redirectUri).queryParameters;

    if (queryParams.containsKey('error') && queryParams['error'].isNotEmpty) {
      error = queryParams['error'];
      if (queryParams.containsKey('error_description'))
        errorDescription = (queryParams['error_description'].isNotEmpty
            ? ': ' + queryParams['error_description']
            : '');
    } else {
      if (!queryParams.containsKey('code') || queryParams['code'].isEmpty) {
        throw Exception('Expected "code" parameter not found in response');
      }

      if (!queryParams.containsKey('state') || queryParams['state'].isEmpty) {
        throw Exception('Expected "state" parameter not found in response');
      }

      if (queryParams['state'] != checkState) {
        throw Exception(
            '"state" parameter in response doesn\'t correspond to the expected value');
      }

      code = queryParams['code'];
      state = queryParams['state'];
    }
  }

  bool isAccessGranted() {
    return error != null ? error.isEmpty : true;
  }
}
