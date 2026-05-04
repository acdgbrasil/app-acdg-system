/// Generates `man/acdg.1` from the runtime `acdg --help` output.
///
/// Run from the CLI package root:
/// ```
/// dart run tool/generate_man.dart > man/acdg.1
/// ```
///
/// The output is groff format suitable for `man -l man/acdg.1` or installation
/// to `~/.local/share/man/man1/acdg.1` then `mandb` refresh.
library;

import 'package:cli/cli.dart';

Future<void> main() async {
  final stdout = StringBuffer();
  final stderr = StringBuffer();
  final runner = CliRunner(stdout: stdout, stderr: stderr);

  // Top-level help.
  await runner.run(['--help']);
  final topHelp = stdout.toString();
  stdout.clear();
  stderr.clear();

  // Subcommand helps (collected from CommandRunner.commands.keys).
  final subcommandHelps = <String, String>{};
  for (final name in runner.runner.commands.keys) {
    await runner.run([name, '--help']);
    subcommandHelps[name] = stdout.toString();
    stdout.clear();
    stderr.clear();
  }

  // Emit groff.
  final out = StringBuffer();
  out.writeln('.TH ACDG 1 "${_dateLabel()}" "ACDG CLI" "User Commands"');
  out.writeln('.SH NAME');
  out.writeln('acdg \\- Operate the ACDG social care system from the command line.');
  out.writeln('.SH SYNOPSIS');
  out.writeln('.B acdg');
  out.writeln('[\\fIglobal options\\fR] \\fIcommand\\fR [\\fIargs\\fR...]');
  out.writeln('.SH DESCRIPTION');
  out.writeln(_escape(topHelp));
  out.writeln('.SH COMMANDS');
  for (final entry in subcommandHelps.entries) {
    out.writeln('.SS ${entry.key}');
    out.writeln(_escape(entry.value));
  }
  out.writeln('.SH ENVIRONMENT');
  out.writeln('.TP');
  out.writeln('.B ACDG_BFF_URL');
  out.writeln(
    'BFF Web base URL (compile-time \\fB--dart-define\\fR). Default: '
    '\\fIhttp://localhost:8081\\fR.',
  );
  out.writeln('.SH FILES');
  out.writeln('.TP');
  out.writeln('.B ~/.config/acdg/credentials');
  out.writeln('OIDC session (chmod 600). Created by \\fBacdg auth login\\fR.');
  out.writeln('.SH EXIT STATUS');
  out.writeln('.TP');
  out.writeln('0   Success');
  out.writeln('.TP');
  out.writeln('1   Server error (4xx/5xx other than 401)');
  out.writeln('.TP');
  out.writeln('2   Authentication required');
  out.writeln('.TP');
  out.writeln('3   Network failure');
  out.writeln('.TP');
  out.writeln('7   Refresh token invalidated (run \\fBacdg auth login\\fR)');
  out.writeln('.TP');
  out.writeln('64  Usage error (EX_USAGE)');
  out.writeln('.SH SEE ALSO');
  out.writeln(
    '\\fBgh\\fR(1), \\fBgcloud\\fR(1) — sibling CLIs with the same '
    'PKCE Loopback authentication pattern.',
  );
  out.writeln('.SH AUTHORS');
  out.writeln('ACDG Technology — https://acdgbrasil.com.br');

  // Print to stdout so callers redirect to file.
  // ignore: avoid_print
  print(out.toString());
}

/// Escapes a help-block string for groff: the only special chars in `args`
/// help output are backslashes and dots at the start of lines.
String _escape(String input) {
  return input
      .split('\n')
      .map((line) {
        var l = line.replaceAll(r'\', r'\\');
        if (l.startsWith('.')) {
          l = '\\&$l';
        }
        return l;
      })
      .join('\n');
}

String _dateLabel() {
  final now = DateTime.now().toUtc();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
