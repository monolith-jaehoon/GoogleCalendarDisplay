import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

Future<auth.AuthClient> desktopClientViaUserConsent(
  auth.ClientId clientId,
  List<String> scopes,
  Future<String> Function(String) prompt,
) async {
  throw UnsupportedError('Desktop OAuth is not supported on this platform.');
}

auth.AuthClient desktopAutoRefreshingClient(
  auth.ClientId clientId,
  auth.AccessCredentials credentials,
  http.Client baseClient,
) {
  throw UnsupportedError('Desktop OAuth is not supported on this platform.');
}
