class OAuth2Exception implements Exception {
  String error;
  String errorDescription;

  OAuth2Exception(this.error, {this.errorDescription});
}
