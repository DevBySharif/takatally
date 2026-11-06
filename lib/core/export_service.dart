import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import 'formatters.dart';

/// Result of reading an exported file back into the app.
class ImportedData {
  const ImportedData({
    required this.sessions,
    required this.isBackup,
    this.sourceName,
  });

  final List<TallySession> sessions;

  /// A full backup replaces everything. An entry export is added as a new count.
  final bool isBackup;
  final String? sourceName;

  int get entryCount =>
      sessions.fold(0, (sum, session) => sum + session.entries.length);
}

class ExportService {
  const ExportService._();

  static String _stamp([DateTime? at]) {
    final date = at ?? DateTime.now();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<File> _tempFile(String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.parent.create(recursive: true);
    return file;
  }

  // ---------------------------------------------------------------------------
  // Excel
  // ---------------------------------------------------------------------------

  /// Builds a two-sheet workbook: one summary row per count and one row per
  /// entry. The same column layout is understood by [readFile], so an exported
  /// sheet can be imported again.
  static Future<File> workbook(List<TallySession> sessions) async {
    final counts = sessions.where((s) => s.entries.isNotEmpty).toList();
    final source = counts.isEmpty ? sessions : counts;

    final book = Excel.createExcel();
    final summary = book['Summary'];
    final entries = book['Entries'];
    book.delete('Sheet1');

    summary.appendRow([
      TextCellValue('Count'),
      TextCellValue('Date'),
      TextCellValue('Entries'),
      TextCellValue('Money in'),
      TextCellValue('Money out'),
      TextCellValue('Total'),
    ]);

    entries.appendRow([
      TextCellValue('Count'),
      TextCellValue('Date'),
      TextCellValue('Kind'),
      TextCellValue('Amount'),
      TextCellValue('Quantity'),
      TextCellValue('Value'),
      TextCellValue('Note'),
      TextCellValue('Breakdown'),
    ]);

    for (final session in source) {
      summary.appendRow([
        TextCellValue(session.title),
        TextCellValue(formatDateTime(session.createdAt)),
        IntCellValue(session.entryCount),
        IntCellValue(session.totalIn),
        IntCellValue(session.totalOut),
        IntCellValue(session.total),
      ]);

      for (final entry in session.entries) {
        entries.appendRow([
          TextCellValue(session.title),
          TextCellValue(formatDateTime(entry.createdAt)),
          TextCellValue(entry.kind.label),
          IntCellValue(entry.amount),
          IntCellValue(entry.quantity),
          IntCellValue(entry.signedValue),
          TextCellValue(entry.note),
          TextCellValue(entry.breakdownLabel),
        ]);
      }
    }

    summary.setColumnWidth(0, 30);
    summary.setColumnWidth(1, 22);
    summary.setColumnWidth(5, 16);
    entries.setColumnWidth(0, 30);
    entries.setColumnWidth(1, 22);
    entries.setColumnWidth(6, 34);
    entries.setColumnWidth(7, 36);

    final bytes = book.encode();
    final file = await _tempFile('taka-counter-${_stamp()}.xlsx');
    await file.writeAsBytes(bytes ?? const [], flush: true);
    return file;
  }

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  static Future<File> backup(List<TallySession> sessions) async {
    final payload = <String, dynamic>{
      'app': 'Taka Counter',
      'format': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
    };
    final file = await _tempFile('taka-counter-backup-${_stamp()}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  // ---------------------------------------------------------------------------
  // Sharing
  // ---------------------------------------------------------------------------

  static Future<void> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject, text: text),
    );
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  static Future<ImportedData> readFile(File file, {String? name}) async {
    final fileName = name ?? file.uri.pathSegments.last;
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.json')) {
      final text = _stripBom(await file.readAsString());
      return _readJson(text, fileName);
    }
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      final bytes = await file.readAsBytes();
      return _readExcel(bytes, fileName);
    }
    if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      final text = _stripBom(await file.readAsString());
      return _readCsv(text, fileName);
    }

    // Fall back to sniffing the content so a renamed file still works.
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return _readExcel(bytes, fileName);
    }
    final text = _stripBom(utf8.decode(bytes, allowMalformed: true));
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _readJson(text, fileName);
    }
    return _readCsv(text, fileName);
  }

  static String _stripBom(String text) =>
      text.startsWith('\uFEFF') ? text.substring(1) : text;

  static ImportedData _readJson(String text, String fileName) {
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const FormatException('This file is not valid JSON.');
    }

    dynamic rawSessions;
    var isBackup = false;
    if (decoded is Map<String, dynamic>) {
      rawSessions = decoded['sessions'] ?? decoded['counts'];
      isBackup = rawSessions != null;
    } else if (decoded is List) {
      rawSessions = decoded;
      isBackup = true;
    }

    if (rawSessions is! List) {
      throw const FormatException('No counts found in this file.');
    }

    final sessions = <TallySession>[];
    for (final raw in rawSessions) {
      if (raw is! Map) continue;
      sessions.add(TallySession.fromJson(Map<String, dynamic>.from(raw)));
    }
    if (sessions.isEmpty) {
      throw const FormatException('No counts found in this file.');
    }
    return ImportedData(
      sessions: sessions,
      isBackup: isBackup,
      sourceName: fileName,
    );
  }

  static ImportedData _readExcel(List<int> bytes, String fileName) {
    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('This Excel file could not be opened.');
    }

    final sheet =
        book.tables['Entries'] ??
        (book.tables.isNotEmpty ? book.tables.values.first : null);
    if (sheet == null) {
      throw const FormatException('This workbook has no sheets.');
    }

    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      rows.add(
        row.map((cell) => cell?.value?.toString().trim() ?? '').toList(),
      );
    }
    return _rowsToEntries(rows, fileName);
  }

  static ImportedData _readCsv(String text, String fileName) {
    final rows = _parseCsv(text);
    return _rowsToEntries(rows, fileName);
  }

  static ImportedData _rowsToEntries(List<List<String>> rows, String fileName) {
    if (rows.isEmpty) {
      throw const FormatException('This file is empty.');
    }

    final header = rows.first
        .map((cell) => cell.toLowerCase().trim())
        .toList(growable: false);

    int indexOf(List<String> names) {
      for (final name in names) {
        final index = header.indexOf(name);
        if (index >= 0) return index;
      }
      return -1;
    }

    final countIndex = indexOf(['count', 'session', 'title']);
    final dateIndex = indexOf(['date', 'time', 'createdat']);
    final kindIndex = indexOf(['kind', 'type']);
    final amountIndex = indexOf(['amount', 'rate', 'denomination']);
    final quantityIndex = indexOf(['quantity', 'qty', 'pieces']);
    final valueIndex = indexOf(['value', 'total']);
    final noteIndex = indexOf(['note', 'notes', 'description']);

    if (amountIndex < 0) {
      throw const FormatException(
        'The sheet needs an "Amount" column to import.',
      );
    }

    final grouped = <String, List<TallyEntry>>{};
    final fallbackTitle = fileName.replaceAll(
      RegExp(r'\.(xlsx|xls|csv|txt)$'),
      '',
    );

    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      String cell(int index) =>
          index >= 0 && index < row.length ? row[index].trim() : '';

      final amount = _toInt(cell(amountIndex));
      if (amount <= 0) continue;

      var quantity = quantityIndex >= 0 ? _toInt(cell(quantityIndex)) : 1;
      if (quantity <= 0) quantity = 1;

      final kind = _toKind(cell(kindIndex));
      final note = noteIndex >= 0 ? cell(noteIndex) : '';
      final date = _toDate(cell(dateIndex));
      final title = countIndex >= 0 && cell(countIndex).isNotEmpty
          ? cell(countIndex)
          : (fallbackTitle.isEmpty ? 'Imported count' : fallbackTitle);

      // Some exported rows repeat a computed "value" instead of amount/qty.
      final value = valueIndex >= 0 ? _toInt(cell(valueIndex)) : 0;
      final resolvedAmount = value != 0 && quantity == 1 ? value.abs() : amount;

      grouped
          .putIfAbsent(title, () => [])
          .add(
            TallyEntry(
              id: 'import-${date.microsecondsSinceEpoch}-${grouped[title]!.length}',
              kind: kind,
              amount: resolvedAmount,
              quantity: quantity,
              note: note,
              createdAt: date,
            ),
          );
    }

    final sessions = <TallySession>[];
    grouped.forEach((title, entries) {
      if (entries.isEmpty) return;
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      sessions.add(
        TallySession(
          id: 'import-${entries.first.createdAt.microsecondsSinceEpoch}',
          title: title,
          createdAt: entries.first.createdAt,
          updatedAt: entries.last.createdAt,
          entries: entries.reversed.toList(),
        ),
      );
    });

    if (sessions.isEmpty) {
      throw const FormatException('No rows with a valid amount were found.');
    }
    return ImportedData(
      sessions: sessions,
      isBackup: false,
      sourceName: fileName,
    );
  }

  static int _toInt(String value) {
    final negative = value.contains('-') || value.contains('−');
    var text = value.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (text.isEmpty) return 0;

    // "1,00,000" (Indian) and "1,000,000" (western) are grouping.
    if (RegExp(r'^\d{1,3}(,\d{2,3})+(\.\d+)?$').hasMatch(text)) {
      text = text.replaceAll(',', '');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(text)) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '.');
    }

    final parsed = double.tryParse(text);
    if (parsed == null) return 0;
    final rounded = parsed.round();
    return negative && rounded > 0 ? -rounded : rounded;
  }

  static EntryKind _toKind(String value) {
    return switch (value.toLowerCase()) {
      'credit' || 'in' || 'money in' || 'income' => EntryKind.credit,
      'debit' || 'out' || 'money out' || 'expense' => EntryKind.debit,
      _ => EntryKind.counted,
    };
  }

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static DateTime _toDate(String value) {
    final clean = value.trim();
    final direct = DateTime.tryParse(clean);
    if (direct != null) return direct;

    // The app exports dates as "05 Nov 2026 · 12:30 PM"; Excel shows the same
    // text, so read it back instead of resetting every entry to now.
    final display = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})[a-z]*\s+(\d{4})'
      r'(?:\s*[^\d]?\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?)?$',
    ).firstMatch(clean);
    if (display != null) {
      final day = int.parse(display.group(1)!);
      final month = _months[display.group(2)!.toLowerCase()];
      final year = int.parse(display.group(3)!);
      if (month != null) {
        var hour = int.tryParse(display.group(4) ?? '') ?? 0;
        final minute = int.tryParse(display.group(5) ?? '') ?? 0;
        final meridiem = display.group(6)?.toLowerCase();
        if (meridiem == 'pm' && hour < 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
        return DateTime(year, month, day, hour, minute);
      }
    }

    final formats = [
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'),
      RegExp(r'^(\d{2})-(\d{2})-(\d{4})$'),
      RegExp(r'^(\d{4})/(\d{2})/(\d{2})$'),
    ];
    for (var i = 0; i < formats.length; i++) {
      final match = formats[i].firstMatch(clean);
      if (match == null) continue;
      final int day;
      final int month;
      final int year;
      if (i == 2) {
        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);
      } else {
        day = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        year = int.parse(match.group(3)!);
      }
      if (month < 1 || month > 12 || day < 1 || day > 31) return DateTime.now();
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }

  static List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (char == '\n') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else if (char != '\r') {
        field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
