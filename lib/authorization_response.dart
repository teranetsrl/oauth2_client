/// Represents the response to an Authorization Request.
/// see https://tools.ietf.org/html/rfc6749#page-26
class AuthorizationResponse {
  AuthorizationResponse.fromRedirectUri(
    String redirectUri,
    String? checkState,
  ) {
    queryParams = Uri.parse(redirectUri).queryParameters;

    error = getQueryParam('error');
    errorDescription = getQueryParam('error_description');

    if (error == null) {
      code = getQueryParam('code');
      if (code == null) {
        throw Exception('Expected "code" parameter not found in response');
      }

      // Only validate the state if the checkState was actually supplied
      if (checkState != null && checkState.isNotEmpty) {
        state = getQueryParam('state');
        if (state == null) {
          throw Exception('Expected "state" parameter not found in response');
        }

        if (state != checkState) {
          throw Exception('"state" parameter in response doesn\'t correspond to the expected value');
        }
      }
    }
  }
  String? code;
  String? state;
  late Map<String, String> queryParams;

  String? error;
  String? errorDescription;

  /// Returns the value of the [paramName] key in the queryParams map
  dynamic getQueryParam(String paramName) {
    return queryParams.containsKey(paramName) && queryParams[paramName]!.isNotEmpty ? queryParams[paramName] : null;
  }

  bool isAccessGranted() {
    return error?.isEmpty ?? true;
  }
}
