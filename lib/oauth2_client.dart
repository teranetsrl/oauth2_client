import 'package:http/http.dart' as http;
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/authorization_response.dart';
import 'package:oauth2_client/src/oauth2_client_impl.dart';
import 'package:meta/meta.dart';
import 'package:oauth2_client/src/web_auth.dart';

/// Base class that implements OAuth2 authorization flows.
///
/// It currently supports the following grants:
/// * Authorization Code
/// * Client Credentials
///
/// For the Authorization Code grant, PKCE is used by default. If you need to disable it, pass the 'enablePKCE' param to false.
///
/// You can use directly this class, but normally you want to extend it and implement your own client.
/// When instantiating the client, pass your custom uri scheme in the [customUriScheme] field.
/// Normally you would use something like <customUriScheme>:/oauth for the [redirectUri] field.
/// For Android only you must add an intent filter in your AndroidManifest.xml file to enable the custom uri handling.
/// <activity android:name="com.linusu.flutter_web_auth.CallbackActivity" >
///   <intent-filter android:label="flutter_web_auth">
///     <action android:name="android.intent.action.VIEW" />
///     <category android:name="android.intent.category.DEFAULT" />
///     <category android:name="android.intent.category.BROWSABLE" />
///     <data android:scheme="com.teranet.app" />
///   </intent-filter>
/// </activity>
class OAuth2Client {

  OAuth2ClientImpl clientImpl;
  WebAuth webAuthClient;

	OAuth2Client({
    @required authorizeUrl,
    @required tokenUrl,
    refreshUrl,
    @required redirectUri,
    @required customUriScheme}) {

    clientImpl = OAuth2ClientImpl(
      authorizeUrl: authorizeUrl,
      tokenUrl: tokenUrl,
      refreshUrl: refreshUrl,
      redirectUri: redirectUri,
      customUriScheme: customUriScheme
    );

    webAuthClient = WebAuth();

  }

  /// Requests an Access Token to the OAuth2 endpoint using the Authorization Code Flow.
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow({
    @required String clientId,
    @required List<String> scopes,
    String clientSecret,
    bool enablePKCE = true
  }) async {

    return await clientImpl.getTokenWithAuthCodeFlow(
      httpClient: http.Client,
      webAuthClient: webAuthClient,
      clientId: clientId,
      scopes: scopes,
      clientSecret: clientSecret,
      enablePKCE: enablePKCE
    );

  }

  /// Requests an Authorization Code to be used in the Authorization Code grant.
  Future<AuthorizationResponse> requestAuthorization({
    @required String clientId,
    List<String> scopes,
    String codeChallenge,
    String state
  }) async {

    return await clientImpl.requestAuthorization(
      webAuthClient: webAuthClient,
      clientId: clientId,
      scopes: scopes,
      codeChallenge: codeChallenge,
      state: state
    );

  }

  /// Requests and Access Token using the provided Authorization [code].
  Future<AccessTokenResponse> requestAccessToken({
    @required String code,
    @required String clientId,
    String clientSecret,
    String codeVerifier
  }) async {

    return await clientImpl.requestAccessToken(
      httpClient: http.Client,
      code: code,
      clientId: clientId,
      clientSecret: clientSecret,
      codeVerifier: codeVerifier
    );

  }

  /// Requests an Access Token to the OAuth2 endpoint using the Client Credentials flow.
  Future<AccessTokenResponse> getTokenWithClientCredentialsFlow({
    @required String clientId,
    @required String clientSecret,
    List<String> scopes
  }) async {
    return await clientImpl.getTokenWithClientCredentialsFlow(
      httpClient: http.Client,
      clientId: clientId,
      clientSecret: clientSecret,
      scopes: scopes
    );
  }

  /// Refreshes an Access Token issuing a refresh_token grant to the OAuth2 server.
  Future<AccessTokenResponse> refreshToken(String refreshToken) async {

    return await clientImpl.refreshToken(
      httpClient: http.Client,
      refreshToken: refreshToken
    );
  }

  get customUriScheme => clientImpl.customUriScheme;

}