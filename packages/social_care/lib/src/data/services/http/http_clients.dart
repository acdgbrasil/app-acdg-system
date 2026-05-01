/// Barrel for the split HttpSocialCareClient.
///
/// Organizational split only — original `http_social_care_client.dart`
/// remains intact and in use. These specialized clients are here to
/// be adopted incrementally by the data layer.
library;

export 'assessment_http_client.dart';
export 'care_http_client.dart';
export 'health_http_client.dart';
export 'lookup_http_client.dart';
export 'people_http_client.dart';
export 'protection_http_client.dart';
export 'registry_http_client.dart';
