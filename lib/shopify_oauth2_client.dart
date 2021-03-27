import 'package:meta/meta.dart';

import 'oauth2_client.dart';

/// Implements an OAuth2 client that uses Shopify services to authorize requests.
///
/// You can get the access token for using it with the graphql or rest APIS via
/// ```dart
/// oauth2Helper.getToken()
/// ```
class ShopifyOAuth2Client extends OAuth2Client {
  ShopifyOAuth2Client({
    @required String shop,
    @required String redirectUri,
    @required String customUriScheme,
  }) : super(
          authorizeUrl: 'https://$shop.myshopify.com/admin/oauth/authorize',
          tokenUrl: 'https://$shop.myshopify.com/admin/oauth/access_token',
          redirectUri: redirectUri,
          customUriScheme: customUriScheme,
          credentialsLocation: CredentialsLocation.BODY,
        );
}
