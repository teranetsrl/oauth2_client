# oauth2_client
Simple Flutter library for interacting with OAuth2 servers.

Currently only **Authorization Code** and **Client Credentials** flows are implemented.

# Usage with the helper class #
The simplest way to use the library is through the *OAuth2Helper* class.
This class transparently handles tokens request/refreshing, as well as storing and caching them.

It finally implements commodity methods to transparently perform http requests adding the generated bearer tokens.

First you need to add the library to your *pubspec.yaml* file:

```dart
dependencies:
	oauth2_client: ^0.1.0
```

Then instantiate and setup the helper:


```dart
import 'package:oauth2_client/oauth2_helper.dart';
//We are going to use the google client for this example...
import 'package:oauth2_client/google_oauth2_client.dart';

//Instantiate an OAuth2Client...
//For the Google client, the first parameter is the redirect uri, the second is the custom url scheme
GoogleOAuth2Client client = GoogleOAuth2Client('com.teranet.app:/oauth2redirect', 'com.teranet.app');

//Then, instantiate the helper passing the client
OAuth2Helper oauth2Helper = OAuth2Helper(client);

//Set up the authorization params...
oauth2Helper.setAuthorizationParams(
	grantType: OAuth2Helper.AUTHORIZATION_CODE,
	clientId: 'your_client_id',
	scopes: ['https://www.googleapis.com/auth/documents.readonly']
);

```
In the example we used the Google client, but you can use any other provided client or implement your own.

Now you can use the helper class to perform HTTP requests to the server.

```dart
Response resp = helper.post('TODO');
```

The helper will:
 - **check** if a **token** already exists in the **secure storage**
 - if it doesn't exist:
 	- **request the token** using the flow and the parameters specified in the *setAuthorizationParams* call. For example, for the Authorization Code flow this involves opening a web browser for the authorization code and then requesting the actual authorization token. The token is then **stored in secure storage**.
 - if the token already exists, but is **expired**, a new one is **automatically generated** using the **refresh_token** flow. The token is then stored in secure storage.
 - **Perform** the actual http **request** with the authorization **token included**.

# Usage without the helper class #
You can use the library without the helper class, using one of the base client classes.

This way tokens won't be automatically stored, and won't be automatically refreshed. Furthermore, you will have to add the authorization token to http requests by yourself.

## Using Google client ##
```dart
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:oauth2_client/authorization_token.dart';

...

//Instantiate the client as before...
GoogleOAuth2Client client = GoogleOAuth2Client('com.teranet.app:/oauth2redirect', 'com.teranet.app');

//Request a token using the Authorization Code flow...
AuthorizationToken token = client.getTokenWithAuthCodeFlow(
	clientId: 'your_client_id',
	scopes: ['scope1', 'scope2', ...]
);

//Request a token using the Client Credentials flow...
AuthorizationToken token = client.getTokenWithClientCredentialsFlow(
	clientId: 'XXX', //Your client id
	clientSecret: 'XXX', //Your client secret
	scopes: ['scope1', 'scope2', ...] //Optional
);

//Or, if you already have a token, check if it is expired and in case refresh it...
if(token.isExpired()) {
	token = client.refreshToken(token.refreshToken);
}
```

## Using base client class ##

## Implementing your own client class ##