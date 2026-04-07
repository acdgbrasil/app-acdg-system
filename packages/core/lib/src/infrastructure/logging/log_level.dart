/// Log severity levels used by [AcdgLogger] implementations.
///
/// Only [error] and [fatal] are forwarded to external error tracking
/// services (e.g. Sentry). [info] and [warning] are local-only.
enum LogLevel { info, warning, error, fatal }
