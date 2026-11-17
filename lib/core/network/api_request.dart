/// How one request authenticates.
///
/// The default attaches the signed-in session. [public] sends no credentials,
/// and [withToken] sends a one-off bearer such as the signup setup token.
class ApiRequest {
  const ApiRequest({this.authenticated = true, this.bearer});

  const ApiRequest.withToken(String token)
    : authenticated = false,
      bearer = token;

  static const public = ApiRequest(authenticated: false);

  static const authenticatedKey = 'paysplit.authenticated';
  static const bearerKey = 'paysplit.bearer';

  final bool authenticated;
  final String? bearer;
}
