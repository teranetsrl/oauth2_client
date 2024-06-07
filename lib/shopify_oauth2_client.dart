import 'package:oauth2_client/oauth2_client.dart';

/// Implements an OAuth2 client that uses Shopify services to authorize requests.
///
/// You can get the access token for using it with the graphql or rest APIS via
/// ```dart
/// oauth2Helper.getToken()
/// ```
/// Note that shopify only http and https as scheme
class ShopifyOAuth2Client extends OAuth2Client {
  ShopifyOAuth2Client({
    required String shop,
    required super.redirectUri,
    required super.customUriScheme,
  }) : super(
          authorizeUrl: 'https://$shop.myshopify.com/admin/oauth/authorize',
          tokenUrl: 'https://$shop.myshopify.com/admin/oauth/access_token',
          credentialsLocation: CredentialsLocation.body,
        );
}
