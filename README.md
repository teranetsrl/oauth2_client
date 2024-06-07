[![codecov](https://codecov.io/gh/teranetsrl/oauth2_client/branch/master/graph/badge.svg)](https://codecov.io/gh/teranetsrl/oauth2_client)

# oauth2_client
Simple Flutter library for interacting with OAuth2 servers. It provides convenience classes for interacting with the "usual suspects" (Google, Facebook, LinkedIn, GitHub), but it's particularly suited for implementing clients for custom OAuth2 servers.

The library handles **Authorization Code**, **Client Credentials** and **Implicit Grant** flows.

# Prerequisites #

## Android ##
On Android you must first set the *minSdkVersion* in the *build.gradle* file:
```
defaultConfig {
   ...
   minSdkVersion 18
   ...
```

If at all possible, when registering your application on the OAuth provider **try not to use HTTPS** as the scheme part of the redirect uri, because in that case your application won't intercept the server redirection, as it will be automatically handled by the system browser (at least on Android). Just use a custom scheme, such as "my.test.app" or any other scheme you want.

If the OAuth2 server **allows only HTTPS** uri schemes, refer to the [FAQ](#faq) section.

Again on Android, if your application uses the Authorization Code flow, you first need to modify the *AndroidManifest.xml* file adding the activity `com.linusu.flutter_web_auth_2.CallbackActivity` with the intent filter needed to open the browser window for the authorization workflow.
The library relies on the [flutter_web_auth_2](https://pub.dev/packages/flutter_web_auth_2) package to allow the Authorization Code flow.

AndroidManifest.xml

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
	<intent-filter android:label="flutter_web_auth_2">
		<action android:name="android.intent.action.VIEW" />
		<category android:name="android.intent.category.DEFAULT" />
		<category android:name="android.intent.category.BROWSABLE" />
		<data android:scheme="my.test.app" /> <!-- This must correspond to the custom scheme used for instantiating the client... See below -->
	</intent-filter>
</activity>
```

## iOS ##
On iOS you need to set the *platform* in the *ios/Podfile* file:
```
platform :ios, '11.0'
```

## Web ##
Web support has been added in the 2.2.0 version, and should be considered preliminary.

On the web platform you **must** register your application using an **HTTPS** redirect uri.

When the authorization code flow is used, the authorization phase will be carried out by opening a popup window to the provider login page.

After the user grants access to your application, the server will redirect the browser to the redirect uri. This page should contain some javascript code to read the _code_ parameter sent by the authorization server and pass it to the parent window through postMessage.

Something like:

```javascript
window.onload = function() {
	const urlParams = new URLSearchParams(window.location.search);
	const code = urlParams.get('code');
	if(code) {
		window.opener.postMessage(window.location.href, _url_of_the_opener_window_);
	}
}
```

**Please note** that the browser can't *securely* store confidential information! The OAuth2Helper class, when used on the web, stores the tokens in the localStorage, and this means they won't be encrypted!

# Installation #

Add the library to your *pubspec.yaml* file:

```yaml
dependencies:
	oauth2_client: ^3.0.0
```

## Upgrading from previous versions (< 3.0.0)
Version 3.0.0 introduced some breaking changes that need to be addressed if you are upgrading from previous versions.

Please take note of the following:
* From version 3.0.0, `flutter_web_auth` has been replaced by [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2). Please refer to the [upgrade instructions](https://pub.dev/packages/flutter_web_auth_2#upgrading-from-flutter_web_auth).
* The migration to `flutter_web_auth_2` marks the transition to Flutter 3. This means that you *must* upgrade to Flutter 3 (a simple `flutter upgrade` should be enough).
* Version 3.0.0 migrates away from the `pedantic` package (that's now deprecated) to `flutter_lints`. This too entails some breaking changes. In particular, constants names are now in camelCase format for compliance with the style guides enforced by `flutter_lints`.

  These include:
```
# Before 3.0.0
OAuth2Helper.AUTHORIZATION_CODE
OAuth2Helper.CLIENT_CREDENTIALS
OAuth2Helper.IMPLICIT_GRANT

# After 3.0.0 become:
OAuth2Helper.authorizationCode
OAuth2Helper.clientCredentials
OAuth2Helper.implicitGrant
```
  As well as the `CredentialsLocation` enum:
```
# Before 3.0.0
CredentialsLocation.HEADER
CredentialsLocation.BODY

# After 3.0.0 become:
CredentialsLocation.header
CredentialsLocation.body
```
* The `OAuth2Helper.setAuthorizationParams` has been definitively removed, after being deprecated since version 2.0.0. You must use the `OAuth2Helper` constructor parameters instead.

* The `OAuth2Client.accessTokenRequestHeaders` class field has been removed. You can now send custom headers by passing the `accessTokenHeaders` parameter to the `getTokenWithAuthCodeFlow` method, or the `customHeaders` parameter to the `getTokenWithClientCredentialsFlow` method. When using the helper, you can pass the custom parameters in the helper's constructor through the `accessTokenHeaders` parameter.
For example:

```dart
OAuth2Client client = OAuth2Client(
  redirectUri: ...,
  customUriScheme: ...,
  accessTokenRequestHeaders: {
    'Accept': 'application/json'
  });

client.getTokenWithClientCredentialsFlow(clientId: ..., clientSecret: ..., customHeaders: {
    'MyCustomHeaderName': 'MyCustomHeaderValue'
});
//or...
client.getTokenWithAuthCodeFlow(clientId: ..., clientSecret: ..., accessTokenHeaders: {
    'MyCustomHeaderName': 'MyCustomHeaderValue'
});

//...or, if using the OAuth2Helper...
OAuth2Helper hlp = OAuth2Helper(client, {
	...,
	accessTokenHeaders: {
    	'MyCustomHeaderName': 'MyCustomHeaderValue'
	}
});

...

```

# Usage with the helper class #
The simplest way to use the library is through the *OAuth2Helper* class.
This class transparently handles tokens request/refresh, as well as storing and caching them.

Besides, it implements convenience  methods to transparently perform http requests adding the generated access tokens.

First, instantiate and setup the helper:


```dart
import 'package:oauth2_client/oauth2_helper.dart';
//We are going to use the google client for this example...
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:http/http.dart' as http;

//Instantiate an OAuth2Client...
GoogleOAuth2Client client = GoogleOAuth2Client(
	customUriScheme: 'my.test.app' //Must correspond to the AndroidManifest's "android:scheme" attribute
	redirectUri: 'my.test.app:/oauth2redirect', //Can be any URI, but the scheme part must correspond to the customUriScheme
);

//Then, instantiate the helper passing the previously instantiated client
OAuth2Helper oauth2Helper = OAuth2Helper(client,
	grantType: OAuth2Helper.authorizationCode,
	clientId: 'your_client_id',
	clientSecret: 'your_client_secret',
	scopes: ['https://www.googleapis.com/auth/drive.readonly']);

```
In the example we used the Google client, but you can use any other provided client or implement your own (see below).

_Note that the redirect uri has just one slash. This is [required per  Google specs](https://developers.google.com/identity/protocols/oauth2/native-app#step-2:-send-a-request-to-googles-oauth-2.0-server). Other providers could require double slash!_

Now you can use the helper class to perform HTTP requests to the server.

```dart
http.Response resp = helper.get('https://www.googleapis.com/drive/v3/files');
```

The helper will:
 - **check** if a **token** already exists in the **secure storage**
 - if it doesn't exist:
 	- **request the token** using the flow and the parameters specified in the *setAuthorizationParams* call. For example, for the Authorization Code flow this involves opening a web browser for the authorization code and then requesting the actual access token. The token is then **stored in secure storage**.
 - if the token already exists, but is **expired**, a new one is **automatically generated** using the **refresh_token** flow. The token is then stored in secure storage.
 - **Perform** the actual http **request** with the access **token included**.

# Usage without the helper class #
You can use the library without the helper class, using one of the base client classes.

This way tokens won't be automatically stored, nor will be automatically refreshed. Furthermore, you will have to add the access token to http requests by yourself.

```dart
//Import the client you need (see later for available clients)...
import 'myclient.dart'; //Not an actual client!
import 'package:oauth2_client/access_token_response.dart';

...

//Instantiate the client
client = MyClient(...);

//Request a token using the Authorization Code flow...
AccessTokenResponse tknResp = await client.getTokenWithAuthCodeFlow(
	clientId: 'your_client_id',
	scopes: ['scope1', 'scope2', ...]
);

//Request a token using the Client Credentials flow...
AccessTokenResponse tknResp = await client.getTokenWithClientCredentialsFlow(
	clientId: 'XXX', //Your client id
	clientSecret: 'XXX', //Your client secret
	scopes: ['scope1', 'scope2', ...] //Optional
);

//Or, if you already have a token, check if it is expired and in case refresh it...
if(tknResp.isExpired()) {
	tknResp = client.refreshToken(tknResp.refreshToken);
}
```

## Accessing custom/non standard response fields ##
You can access non standard fields in the response by calling the ```getRespField``` method.

For example:
```dart
AccessTokenResponse tknResp = await client.getTokenWithAuthCodeFlow(
	clientId: 'your_client_id',
	scopes: ['scope1', 'scope2', ...]
);

if(tknResp.isExpired()) {
	var myCustomFieldVal = tknResp.getRespField('my_custom_field');
}
```

# Predefined clients #
The library implements clients for the following services/organizations:

 - Google
 - Facebook
 - LinkedIn
 - GitHub
 - Shopify
 - Spotify
 - Twitter
 - Microsoft

## Google client ##

In order to use this client you need to first configure OAuth2 credentials in the Google API console (https://console.developers.google.com/apis/).

First you need to create a new Project if it doesn't already exists, then you need to create the OAuth2 credentials ("OAuth Client ID").

Select **iOS** as *Application Type*, specify a name for the client and a *Bundle ID*.
Now edit the just created Client ID and take note of the "IOS URL scheme". This should look something like ``com.googleusercontent.apps.XXX`` and is the custom scheme you'll need to use.

Then in your code:

```dart
import 'package:oauth2_client/google_oauth2_client.dart';

OAuth2Client googleClient = GoogleOAuth2Client(
	redirectUri: 'com.googleusercontent.apps.XXX:/oauth2redirect', //Just one slash, required by Google specs
	customUriScheme: 'com.googleusercontent.apps.XXX'
);
```

Then you can instantiate an helper class or directly use the client methods to acquire access tokens.

## Facebook client ##

In order to use this client you need to first configure OAuth2 credentials in the Facebook dashboard.

Then in your code:

```dart
import 'package:oauth2_client/facebook_oauth2_client.dart';

OAuth2Client fbClient = FacebookOAuth2Client(
	redirectUri: 'my.test.app://oauth2redirect',
	customUriScheme: 'my.test.app'
);
```

Then you can instantiate an helper class or directly use the client methods to acquire access tokens.

## LinkedIn client ##

In order to use this client you need to first configure OAuth2 credentials. See https://docs.microsoft.com/it-it/linkedin/shared/authentication/authorization-code-flow.

Then in your code:

```dart
import 'package:oauth2_client/linkedin_oauth2_client.dart';

OAuth2Client liClient = LinkedInOAuth2Client(
	redirectUri: 'my.test.app://oauth2redirect',
	customUriScheme: 'my.test.app'
);
```

Then you can instantiate an helper class or directly use the client methods to acquire access tokens.

## GitHub client ##

In order to use this client you need to first create a new OAuth2 App in the GitHub Developer Settings (https://github.com/settings/developers)

Then in your code:

```dart
import 'package:oauth2_client/github_oauth2_client.dart';

OAuth2Client ghClient = GitHubOAuth2Client(
	redirectUri: 'my.test.app://oauth2redirect',
	customUriScheme: 'my.test.app'
);
```

Then you can instantiate an helper class or directly use the client methods to acquire access tokens.

# Implementing your own client #
Implementing your own client is quite simple, and often it requires only few lines of code.

In the majority of cases you only need to extend the base *OAuth2Client* class and configure the proper endpoints for the authorization and token url.

```dart
import 'package:oauth2_client/oauth2_client.dart';

class MyOAuth2Client extends OAuth2Client {
  MyOAuth2Client({required String redirectUri, required String customUriScheme}): super(
    authorizeUrl: 'https://...', //Your service's authorization url
    tokenUrl: 'https://...', //Your service access token url
    redirectUri: redirectUri,
    customUriScheme: customUriScheme
  );
}
```

## Open ID support ##
Open ID Connect is currently in development. Stay tuned for updates!

## <a name="faqe"></a>FAQ ##

### Tokens are not getting stored! ###
If when using the helper class the tokens seem to not getting stored, it could be that the requested scopes differs from those returned by the Authorization server.

OAuth2 specs state that the server could optionally return the granted scopes. The OAuth2Helper, when storing an access token, keeps track of the scopes it has been granted for, so the next time a token is needed for one or more of those scopes, it will be readily available without performing another authorization flow.

If the client requests an authorization grant for scopes "A" and "B", but the server for some reason returns a token valid for scope "A" only, that token will be stored along with scope "A", and not "B".
This means that the next time the client will need a token for scopes "A" and "B", the helper will check its storage looking for a token for both "A" and "B", but will only find a token valid for "A", so it will start a new authorization process.

To verify that the requested scopes are really the ones granted on the server, you can use something like the following:

```dart
var client = OAuth2Client(
  authorizeUrl: <YOUR_AUTHORIZE_URL>,
  tokenUrl: <YOUR_TOKEN_URL>,
  redirectUri: <YOUR_REDIRECT_URI>,
  customUriScheme: <YOUR_CUSTOM_SCHEME>);

var tknResp = await client.getTokenWithAuthCodeFlow(
  clientId: <YOUR_CLIENT_ID>,
  scopes: [
	  <LIST_OF_SCOPES>
  ]);

print(tknResp.httpStatusCode);
print(tknResp.error);
print(tknResp.expirationDate);
print(tknResp.scope);
```

Apart from the order, the printed scopes should correspond **exactly** to the ones you requested.

### I get an error *PlatformException(CANCELED, User canceled login, null, null)* on Android ###
Please make sure you modified the *AndroidManifest.xml* file adding the  ```com.linusu.flutter_web_auth_2.CallbackActivity``` and the intent filter needed to open the browser window for the authorization workflow.

The AndroidManifest.xml file must contain the ```com.linusu.flutter_web_auth_2.CallbackActivity``` activity. Copy and paste the below code and CHANGE the value of `android:scheme` to match the scheme used in the redirect uri:

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
	<intent-filter android:label="flutter_web_auth_2">
		<action android:name="android.intent.action.VIEW" />
		<category android:name="android.intent.category.DEFAULT" />
		<category android:name="android.intent.category.BROWSABLE" />
		<data android:scheme="my.test.app" />
	</intent-filter>
</activity>
```

If you are sure your intent filter is set up correctly, maybe you have another one enabled that clashes with `flutter_web_auth_2`'s (https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/8)?

### Can I use https instead of a custom scheme? ###

If you want to use an HTTPS url as the redirect uri, you must set it up as an [App Link](https://developer.android.com/training/app-links/index.html).
First you need to specify both the ```android:host``` and ```android:pathPrefix``` attributes, as long as the ```android:autoVerify="true"``` attribute in the intent-filter tag inside the _AndroidManifest.xml_:

```xml
<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity">
	<intent-filter android:label="flutter_web_auth_2" android:autoVerify="true">
		<action android:name="android.intent.action.VIEW" />
		<category android:name="android.intent.category.DEFAULT" />
		<category android:name="android.intent.category.BROWSABLE" />

		<data android:scheme="https"
				android:host="www.myapp.com"
				android:pathPrefix="/oauth2redirect" />
	</intent-filter>
</activity>
```

Then you need to [prove ownership](https://developer.android.com/training/app-links/verify-site-associations) of the domain host by publishing a [Digital Asset Links](https://developers.google.com/digital-asset-links/v1/getting-started) JSON file on your website. This involves generating an [App signing key](https://developer.android.com/studio/publish/app-signing) and signing your app with it.
