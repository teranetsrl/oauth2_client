class OAuth2Exception implements Exception {
  OAuth2Exception(this.error, {this.errorDescription});
  String error;
  String? errorDescription;
}
