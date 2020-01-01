class OAuth2Token {

	String accessToken;
  String tokenType;
  String refreshToken;
  List<String> scope;
  DateTime expirationDate;

	OAuth2Token();

  OAuth2Token.fromMap(Map<String, dynamic> map) {
    accessToken = map['access_token'];
    tokenType = map['token_type'];
    refreshToken = map['refresh_token'];

    List scopesJson = map['scope'];
    scope = scopesJson != null ? List.from(scopesJson) : null;

    int expiresIn = map['expires_in'];

    DateTime now = DateTime.now();
    expirationDate = now.add(Duration(seconds: expiresIn));
  }

  Map<String, dynamic> toMap() {

    DateTime now = DateTime.now();

    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'refresh_token': refreshToken,
      'scope': scope,
      'expires_in': expirationDate.difference(now).inSeconds
    };
  }

  bool isExpired() {
    DateTime now = DateTime.now();
    return expirationDate.difference(now).inSeconds < 0;
  }

  bool refreshNeeded({secondsToExpiration: 30}) {
    DateTime now = DateTime.now();
    return expirationDate.difference(now).inSeconds < secondsToExpiration;
  }
}