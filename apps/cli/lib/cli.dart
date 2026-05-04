/// ACDG CLI public API — exported by the `cli` package.
///
/// The barrel re-exports the surface that external callers (including the
/// `bin/acdg.dart` entrypoint and any future embedding) need:
///   * [CliRunner] — top-level wiring of CommandRunner + global flags.
///   * [CliError] family — sealed error hierarchy used across the CLI.
///   * Formatters — interface + concrete impls + the auto-detect resolver.
///   * Session — credential persistence + BFF HTTP client scaffold.
///   * OIDC subsystem — PKCE, discovery, loopback listener, token client
///     (the auth surface a future embedding may want to drive directly).
library;

export 'src/cli_runner.dart';
export 'src/commands/family_add_command.dart';
export 'src/commands/family_assign_caregiver_command.dart';
export 'src/commands/family_command.dart';
export 'src/commands/family_remove_command.dart';
export 'src/commands/family_update_identity_command.dart';
export 'src/commands/patient_admit_command.dart';
export 'src/commands/patient_audit_command.dart';
export 'src/commands/patient_command.dart';
export 'src/commands/patient_discharge_command.dart';
export 'src/commands/patient_get_command.dart';
export 'src/commands/patient_list_command.dart';
export 'src/commands/patient_readmit_command.dart';
export 'src/commands/patient_register_command.dart';
export 'src/commands/patient_withdraw_command.dart';
export 'src/errors/cli_error.dart';
export 'src/formatters/auto_formatter.dart';
export 'src/formatters/json_formatter.dart';
export 'src/formatters/output_formatter.dart';
export 'src/formatters/table_formatter.dart';
export 'src/formatters/yaml_formatter.dart';
export 'src/oidc/loopback_listener.dart';
export 'src/oidc/oidc_discovery.dart';
export 'src/oidc/pkce_pair.dart';
export 'src/oidc/token_client.dart';
export 'src/session/bff_client.dart';
export 'src/session/credential_store.dart';
export 'src/session/oidc_session.dart';
