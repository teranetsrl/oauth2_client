## [3.2.2] - 2023/08/27
* Updated dependencies (thanks [Jason Held](https://github.com/jheld))
* Fix for LinkedInOAuth2Client client (thanks [Abhishek-Khanal](https://github.com/Abhishek-Khanal))

## [3.2.1] - 2023/03/12
* Updated dependencies

## [3.2.0] - 2023/03/12
* Added Twitter client
* Added Microsoft client (thanks [Eradparvar](https://github.com/Eradparvar)).

## [3.1.0] - 2023/01/26
* Updated dependencies
* Small fixes

## [3.0.0] - 2022/09/19
* Migrated to [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2) (thanks [ThexXTURBOXx](https://github.com/ThexXTURBOXx) & [Piotr Mitkowski](https://github.com/PiotrMitkowski)).
* Migrated to [`flutter_lints`](https://pub.dev/packages/flutter_lints) (thanks [ThexXTURBOXx](https://github.com/ThexXTURBOXx)).
* Updated [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage)
* Constants are now in lowerCamelCase
* Removed the `OAuth2Client.accessTokenRequestHeaders` class field. Use the proper `getTokenWithAuthCodeFlow`/`getTokenWithClientCredentialsFlow` parameters instead (see upgrading notes in the README).

## [2.4.2] - 2022/08/16
* Fix for breaking change in flutter_secure_storage (thanks [asmith26](https://github.com/asmith26))

## [2.4.1] - 2022/07/17
* Fix accessing secure token storage on newer Android versions (thanks [Piotr Mitkowski](https://github.com/PiotrMitkowski)).
* Added custom params handling for Implicit grant flow (thanks [qasim90](https://github.com/qasim90))

## [2.4.0] - 2022/05/03
* Fix for token renewal process through the refresh token flow
* Expose the TokenStorage class
## [2.3.3] - 2022/03/14
* Expose the BaseStorage object (thanks [Jon Salmon](https://github.com/Jon-Salmon))
* Improved documentation for android Manifest modification (thanks [supermar1010](https://github.com/supermar1010))
* Update flutter_web_auth dependency
## [2.3.2] - 2022/01/17
* Fix: support fetching a new token when expired without a refresh token (thanks [Tiernan](https://github.com/nvx))
* Updated dependencies (thanks [Menelphor](https://github.com/Menelphor))
* Fix linter warnings

## [2.3.1] - 2021/12/13
* Small fix
## [2.3.0] - 2021/11/03
* Add Spotify client (thanks [mauriciocartagena](https://github.com/mauriciocartagena))
* Allow passing custom WebAuth class to OAuth2Helper (thanks [Jon Salmon](https://github.com/Jon-Salmon))

## [2.2.7] - 2021/10/07
* Fix: null check operator in WebAuth class (thanks [jakub-bacic](https://github.com/jakub-bacic))

## [2.2.6] - 2021/10/03
* Allow passing optional parameters to web_auth "authenticate" method

## [2.2.5] - 2021/09/29
* Fix for authorization url params encoding

## [2.2.4] - 2021/09/28
* Support ephemeral sessions (thanks [ThexXTURBOXx](https://github.com/ThexXTURBOXx))
* Fixes (URI components encoding)

## [2.2.2] - 2021/06/27
* Fixes (scope handling)

## [2.2.1] - 2021/06/23
* Fixes (incorrect scope handling with implicit grant, send empty client secret if specified)
* Added Reddit client (thanks [lavalleeale](https://github.com/lavalleeale))
## [2.2.0] - 2021/05/29
* Web platform support!
## [2.1.0] - 2021/04/15
* AccessTokenResponse refactorization. It is now possible to retrieve custom response fields through the ```getRespField``` method
* Scopes separator can be configured with the OAuth2Client's ```scopeSeparator``` param
## [2.0.1] - 2021/04/06
* Complete migration to sound null safety
* Updated dependencies
## [2.0.0-nullsafety] - 2021/03/30
* Migration to null safety
* Deprecated OAuth2Helper.setAuthorizationParams method
## [1.8.0] - 2021/03/28
* Add compatibility with http 0.13 (thanks [bangfalse](https://github.com/bangfalse))
* Allow passing credentials location in request body or header (thanks [sbu-WBT](https://github.com/wbt-solutions))
* Added Shopify client (thanks [sbu-WBT](https://github.com/wbt-solutions))
## [1.7.1] - 2021/02/25
* Fixes (make httpClient optional again in OAuth2Helper)

## [1.7.0] - 2021/02/24
* Added PUT, PATCH and HEAD methods to the OAuth2Helper class

## [1.6.2] - 2021/01/31
* Allows iOS token reading from storage when invoked in background task
* Small fixes

## [1.6.1] - 2020/10/29
* Changed helper's token retrieval method

## [1.6.0] - 2020/10/13
* Added "delete" request method to helper class
* OAuth requests refactorization
* Fixes (fallback token_type parameter value)

## [1.5.1] - 2020/09/15
* Made "state" parameter optional
* Fixes (refreshToken)

## [1.5.0] - 2020/09/12
* Add implicit grant flow

## [1.4.6] - 2020/09/03
* Allow disabling PKCE when using OAuth2Helper

## [1.4.5] - 2020/08/23
* Bugfixes (check "expires_in" parameter type)

## [1.4.4] - 2020/08/10
* Bugfixes (add null-aware operators)

## [1.4.3] - 2020/07/09
* Token storage fix when scopes are empty

## [1.4.2] - 2020/06/27
* Revocation token fixes

## [1.4.1] - 2020/06/19
* Small fixes

## [1.4.0] - 2020/06/15
* scopes parameter become ooptional (as per the OAuth2 specs)
* custom query parameters sent back from the authorization code response can now be retrieved throught the AuthorizationCode.getQueryParam method
* added _afterAuthorizationCodeCb_ callback to handle use cases for access token requests
* added custom params handling to the Authorization Code and the Access Token Requests

## [1.3.2] - 2020/06/08
* Minor bugfixes.

## [1.3.1] - 2020/06/05
* Handled situations in which no new refresh token is returned upon a refresh flow.

## [1.3.0] - 2020/05/27
* Added revocation token ("logout") process
* Refresh token flow is more spec compliant
* Updated dependencies

## [1.2.4] - 2020/05/10
* Bugfixes (optional scopes handling in the Access Token Response)

## [1.2.3] - 2020/05/06
* Bugfixes (multiple scopes handling)

## [1.2.2] - 2020/05/03
* Added trim for "scope" parameter

## [1.2.1] - 2020/04/29
* Bugfixes

## [1.2.0] - 2020/04/22
* Added the _headers_ parameter to the _oauth2_helper_'s _get_ and _post_ methods.

## [1.1.2] - 2020/04/13
* Updated dependencies

## [1.1.1] - 2020/04/06
* Simplified helper set up

## [1.1.0] - 2020/04/02
* Implemented GitHub client. Added the possibility to specify custom headers to the Access Token request. Partial OAuth2Helper refactorization.

## [1.0.2] - 2020/03/10
* Added example, minor bugfixes.

## [1.0.1] - 2020/03/09
* Bugfixes, added test cases.

## [1.0.0] - 2020/01/05
* First public release.
