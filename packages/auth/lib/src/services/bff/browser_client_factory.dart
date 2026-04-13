import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

/// Creates an [http.Client] with `withCredentials = true`
/// so session cookies are sent on cross-origin requests.
http.Client createBrowserClient() =>
    BrowserClient()..withCredentials = true;
