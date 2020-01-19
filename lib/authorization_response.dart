/// Represents the response to an Authorization Request.
/// see https://tools.ietf.org/html/rfc6749#page-26
class AuthorizationResponse {

  String code;
  String state;

  String error;
  String errorDescription;

	AuthorizationResponse();

  AuthorizationResponse.fromRedirectUri(String redirectUri, String state) {

    Map<String, List<String>> queryParams = Uri.parse(redirectUri).queryParametersAll;

    if(queryParams.containsKey('error') && queryParams['error'].isNotEmpty) {
      // throw Exception(queryParams['error'][0] + (queryParams['error_description'].isNotEmpty ? ': ' + queryParams['error_description'][0] : ''));
      error = queryParams['error'][0];
      errorDescription = (queryParams['error_description'].isNotEmpty ? ': ' + queryParams['error_description'][0] : '');
    }
    else {

      if(!queryParams.containsKey('code') || queryParams['code'].isEmpty) {
        throw Exception('Expected "code" parameter not found in response');
      }

      if(!queryParams.containsKey('state') || queryParams['state'].isEmpty) {
        throw Exception('Expected "state" parameter not found in response');
      }

      if(queryParams['state'][0] != state) {
        throw Exception('"state" parameter in response doesn\'t correspond to the expected value');
      }

      code = queryParams['code'][0];
      state = queryParams['state'][0];
    }

  }

  bool isAccessGranted() {
    return error != null ? error.isEmpty : true;
  }

}