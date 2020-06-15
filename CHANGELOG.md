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
