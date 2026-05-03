/// ASCII table renderer for tty stdout.
///
/// Two supported shapes:
///   * `Map<String, dynamic>` → 2-column key/value table.
///   * `List<Map<String, dynamic>>` → header row + body rows (shared keys).
///
/// Anything else falls back to the value's `toString()` (single-cell row) so
/// the CLI never crashes on unexpected payloads. Empty list emits the
/// `(no results)` sentinel — friendlier than a header-only table.
library;

import 'output_formatter.dart';

/// Renders payloads as fixed-width ASCII tables.
final class TableFormatter implements OutputFormatter {
  const TableFormatter();

  static const String _emptySentinel = '(no results)\n';

  @override
  String format(Object? data) => switch (data) {
    null => '(null)\n',
    Map<String, Object?>() => _formatMap(data),
    List<Object?>() => _formatList(data),
    _ => '${data.toString()}\n',
  };

  String _formatMap(Map<String, Object?> map) {
    if (map.isEmpty) return _emptySentinel;
    final rows = map.entries
        .map((e) => [e.key, _stringify(e.value)])
        .toList(growable: false);
    return _renderRows(headers: const ['KEY', 'VALUE'], rows: rows);
  }

  String _formatList(List<Object?> list) {
    if (list.isEmpty) return _emptySentinel;

    // List of Maps → tabular shape with shared headers.
    final allMaps = list.every((e) => e is Map<String, Object?>);
    if (allMaps) {
      final maps = list.cast<Map<String, Object?>>();
      // Preserve insertion order of the first map; append any new keys after.
      final headers = <String>[];
      for (final m in maps) {
        for (final k in m.keys) {
          if (!headers.contains(k)) headers.add(k);
        }
      }
      final rows = maps
          .map(
            (m) => headers.map((h) => _stringify(m[h])).toList(growable: false),
          )
          .toList(growable: false);
      return _renderRows(headers: headers, rows: rows);
    }

    // Fallback — render scalars one per line as a single-column table.
    final rows = list.map((e) => [_stringify(e)]).toList(growable: false);
    return _renderRows(headers: const ['VALUE'], rows: rows);
  }

  /// Pads every column to the widest cell, separates with two spaces, and
  /// underlines the header with dashes.
  String _renderRows({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final widths = List<int>.generate(headers.length, (i) {
      var max = headers[i].length;
      for (final r in rows) {
        if (i < r.length && r[i].length > max) max = r[i].length;
      }
      return max;
    });

    final buffer = StringBuffer();
    _writeRow(buffer, headers, widths);
    _writeRow(
      buffer,
      widths.map((w) => '-' * w).toList(growable: false),
      widths,
    );
    for (final row in rows) {
      _writeRow(buffer, row, widths);
    }
    return buffer.toString();
  }

  void _writeRow(StringBuffer out, List<String> cells, List<int> widths) {
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) out.write('  ');
      out.write(cells[i].padRight(widths[i]));
    }
    out.write('\n');
  }

  String _stringify(Object? value) => value?.toString() ?? '';
}
