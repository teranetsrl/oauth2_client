import 'package:meta/meta.dart';

import 'oauth2_client.dart';

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
        );
}
