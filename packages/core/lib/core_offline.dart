/// Offline infrastructure from the core package.
///
/// Imports [persistence] and [drift] — only use in packages that
/// depend on the persistence layer (shell, desktop BFF).
library;

export 'src/offline/drift_database_service.dart';
export 'src/offline/sync_queue_service.dart';
export 'src/offline/sync_status.dart';
