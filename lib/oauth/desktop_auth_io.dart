import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

Future<auth.AuthClient> desktopClientViaUserConsent(
  auth.ClientId clientId,
  List<String> scopes,
  Future<String> Function(String) prompt,
) {
  return auth_io.clientViaUserConsent(clientId, scopes, prompt);
}

auth.AuthClient desktopAutoRefreshingClient(
  auth.ClientId clientId,
  auth.AccessCredentials credentials,
  http.Client baseClient,
) {
  return auth_io.autoRefreshingClient(clientId, credentials, baseClient);
}
