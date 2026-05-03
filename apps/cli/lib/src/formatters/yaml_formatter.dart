/// Minimal YAML emitter — explicit zero new dependency.
///
/// `package:yaml` ships a parser, not a writer. Rather than pull in a
/// third-party `yaml_writer`, C01 hand-rolls a recursive emitter covering
/// the shapes the CLI actually returns: `Map`, `List`, scalars (String,
/// num, bool, null). Edge cases (multiline strings, tags, anchors, complex
/// keys) are out of scope; future tickets can swap in a richer writer
/// behind the same [OutputFormatter] interface.
library;

import 'output_formatter.dart';

/// Renders payloads as YAML 1.2 block style.
final class YamlFormatter implements OutputFormatter {
  const YamlFormatter();

  @override
  String format(Object? data) {
    final buffer = StringBuffer();
    _emit(buffer, data, indent: 0);
    return buffer.toString();
  }

  void _emit(StringBuffer out, Object? value, {required int indent}) =>
      switch (value) {
        null => out.writeln('null'),
        Map<String, Object?>() => _emitMap(out, value, indent: indent),
        List<Object?>() => _emitList(out, value, indent: indent),
        _ => out.writeln(_scalar(value)),
      };

  void _emitMap(
    StringBuffer out,
    Map<String, Object?> map, {
    required int indent,
  }) {
    if (map.isEmpty) {
      out.writeln('{}');
      return;
    }
    final pad = ' ' * indent;
    map.forEach((key, value) {
      switch (value) {
        case Map<String, Object?>() when value.isNotEmpty:
          out.writeln('$pad$key:');
          _emitMap(out, value, indent: indent + 2);
        case List<Object?>() when value.isNotEmpty:
          out.writeln('$pad$key:');
          _emitList(out, value, indent: indent);
        case _:
          out.writeln('$pad$key: ${_scalar(value)}');
      }
    });
  }

  void _emitList(StringBuffer out, List<Object?> list, {required int indent}) {
    if (list.isEmpty) {
      out.writeln('[]');
      return;
    }
    final pad = ' ' * indent;
    for (final item in list) {
      switch (item) {
        case Map<String, Object?>() when item.isNotEmpty:
          out.writeln('$pad-');
          _emitMap(out, item, indent: indent + 2);
        case List<Object?>() when item.isNotEmpty:
          out.writeln('$pad-');
          _emitList(out, item, indent: indent + 2);
        case _:
          out.writeln('$pad- ${_scalar(item)}');
      }
    }
  }

  String _scalar(Object? value) => switch (value) {
    null => 'null',
    bool() => value ? 'true' : 'false',
    num() => value.toString(),
    String() => value,
    _ => value.toString(),
  };
}
