class AccessTokenRequest {
  final String code;
  final String clientId;
  final String redirectUri;
  final String tokenUrl;
  final String? clientSecret;
  final String? codeVerifier;
  List<String>? scopes;
  Map<String, dynamic>? customParams;
  dynamic httpClient;

  AccessTokenRequest({
    required this.code,
    required this.clientId,
    required this.redirectUri,
    required this.tokenUrl,
    this.clientSecret,
    this.codeVerifier,
    this.scopes,
    this.customParams,
    this.httpClient,
  });
}
