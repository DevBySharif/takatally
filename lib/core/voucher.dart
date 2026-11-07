import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models.dart';
import 'app_info.dart';
import 'formatters.dart';

const _forest = PdfColor.fromInt(0xFF173F2E);
const _lime = PdfColor.fromInt(0xFFC7F36B);
const _cream = PdfColor.fromInt(0xFFF6F2E8);
const _ink = PdfColor.fromInt(0xFF17211B);
const _inkSoft = PdfColor.fromInt(0xFF5C6B62);
const _line = PdfColor.fromInt(0xFFDCD6C6);

/// A stable voucher number for a count, e.g. `TT-20261105-4821`.
String voucherNumber(TallySession session) {
  final date = session.createdAt;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final seed = session.id.codeUnits.fold<int>(7, (sum, unit) => sum + unit);
  final serial = (seed % 9000 + 1000).toString();
  return 'TT-${date.year}$month$day-$serial';
}

/// Builds a printable A5 cash-count voucher and returns its PDF bytes.
///
/// Long counts continue onto as many A5 pages as they need: the entry table
/// repeats its header and the signature block only appears once, on the last
/// page, so a busy shop never loses entries off the bottom of the sheet.
Future<Uint8List> buildVoucherPdfBytes(TallySession session) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansBengali-400.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansBengali-700.ttf'),
  );

  final doc = pw.Document(
    title: 'Cash count voucher · ${session.title}',
    author: AppInfo.developer,
    creator: AppInfo.name,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final entries = session.entries;

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.fromLTRB(26, 32, 26, 26),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: _cream),
        ),
      ),
      footer: (context) => _runningFooter(),
      build: (context) => [
        _titleBlock(session),
        pw.SizedBox(height: 14),
        _table(entries),
        pw.SizedBox(height: 12),
        _totalBlock(session),
        pw.SizedBox(height: 10),
        pw.Text(
          'In words: ${amountInWords(session.total)}',
          style: pw.TextStyle(fontSize: 9, color: _inkSoft),
        ),
        pw.SizedBox(height: 24),
        _signatureBlock(),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.8, color: _line),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated with ${AppInfo.name} by ${AppInfo.developer}',
          style: pw.TextStyle(fontSize: 7.5, color: _inkSoft),
        ),
      ],
    ),
  );

  return doc.save();
}

/// A stable, human-readable filename for the exported voucher.
String voucherPdfName(TallySession session) {
  final slug = session.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final stamp = formatDateShort(session.createdAt).replaceAll(' ', '-');
  final serial = voucherNumber(session).split('-').last;
  return 'voucher-${slug.isEmpty ? 'count' : slug}-$stamp-$serial.pdf';
}

/// Builds the voucher as a PDF file in the temporary folder.
Future<File> buildVoucherPdf(
  TallySession session, {
  Directory? directory,
}) async {
  final bytes = await buildVoucherPdfBytes(session);
  final dir = directory ?? await getTemporaryDirectory();
  final file = File(
    '${dir.path}${Platform.pathSeparator}${voucherPdfName(session)}',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

pw.Widget _runningFooter() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'TakaTally · cash count voucher',
        style: pw.TextStyle(fontSize: 7, color: _inkSoft),
      ),
      pw.Text(
        'Counted with care in Bangladesh',
        style: pw.TextStyle(fontSize: 7, color: _inkSoft),
      ),
    ],
  );
}

pw.Widget _titleBlock(TallySession session) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'CASH COUNT VOUCHER',
        style: pw.TextStyle(
          fontSize: 9,
          letterSpacing: 2.4,
          color: _inkSoft,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        session.title,
        style: pw.TextStyle(
          fontSize: 17,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _meta('VOUCHER', voucherNumber(session)),
          _meta('DATE', formatDateTime(session.createdAt)),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 0.8, color: _line),
    ],
  );
}

pw.Widget _meta(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 6.5,
          letterSpacing: 1.4,
          color: _inkSoft,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 9, color: _ink)),
    ],
  );
}

pw.Widget _table(List<TallyEntry> entries) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _line, width: 0.8),
    ),
    child: pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _cell(
              _label('DESCRIPTION'),
              padding: const pw.EdgeInsets.fromLTRB(10, 7, 4, 7),
            ),
            _cell(
              _label('QTY', align: pw.TextAlign.right),
              padding: const pw.EdgeInsets.fromLTRB(4, 7, 4, 7),
            ),
            _cell(
              _label('AMOUNT', align: pw.TextAlign.right),
              padding: const pw.EdgeInsets.fromLTRB(4, 7, 10, 7),
            ),
          ],
        ),
        if (entries.isEmpty)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 18,
                ),
                child: pw.Text(
                  'No entries in this count.',
                  style: pw.TextStyle(fontSize: 9, color: _inkSoft),
                ),
              ),
              pw.SizedBox(),
              pw.SizedBox(),
            ],
          ),
        for (final entry in entries)
          pw.TableRow(
            children: [
              _cell(
                pw.Text(
                  entry.displayTitle,
                  style: pw.TextStyle(fontSize: 8.5, color: _ink),
                ),
                padding: const pw.EdgeInsets.fromLTRB(10, 5.5, 4, 5.5),
              ),
              _cell(
                pw.Text(
                  '${entry.hasBreakdown ? entry.pieceCount : entry.quantity}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 8.5, color: _inkSoft),
                ),
                padding: const pw.EdgeInsets.fromLTRB(4, 5.5, 4, 5.5),
              ),
              _cell(
                pw.Text(
                  _money(entry.signedValue),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: entry.signedValue < 0 ? _inkSoft : _ink,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                padding: const pw.EdgeInsets.fromLTRB(4, 5.5, 10, 5.5),
              ),
            ],
          ),
      ],
    ),
  );
}

pw.Widget _cell(pw.Widget child, {required pw.EdgeInsets padding}) {
  return pw.Padding(padding: padding, child: child);
}

pw.Widget _totalBlock(TallySession session) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: pw.BoxDecoration(
      color: _forest,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TOTAL COUNTED',
              style: pw.TextStyle(
                fontSize: 8,
                letterSpacing: 1.6,
                color: _lime,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              _money(session.total),
              style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
            ),
            if (session.totalOut > 0) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Out ${_money(session.totalOut)}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

pw.Widget _signatureBlock() {
  return pw.Row(
    children: [
      pw.Expanded(child: _signature('Counted by')),
      pw.SizedBox(width: 26),
      pw.Expanded(child: _signature('Received by')),
    ],
  );
}

pw.Widget _label(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Text(
    text,
    textAlign: align,
    style: pw.TextStyle(
      fontSize: 6.5,
      letterSpacing: 1.2,
      color: _inkSoft,
      fontWeight: pw.FontWeight.bold,
    ),
  );
}

pw.Widget _signature(String label) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(height: 0.8, color: _line),
      pw.SizedBox(height: 4),
      pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: _inkSoft)),
    ],
  );
}

String _money(int value) {
  final sign = value < 0 ? '−' : '';
  return '$sign৳${formatNumber(value.abs())}';
}

const _ones = [
  '',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

String _underHundred(int value) {
  if (value < 20) return _ones[value];
  final tens = value ~/ 10;
  final ones = value % 10;
  return '${_tens[tens]}${ones == 0 ? '' : '-${_ones[ones]}'}';
}

String _underThousand(int value) {
  final hundreds = value ~/ 100;
  final rest = value % 100;
  final parts = <String>[];
  if (hundreds > 0) parts.add('${_ones[hundreds]} hundred');
  if (rest > 0) parts.add(_underHundred(rest));
  return parts.join(' ');
}

String _words(int value) {
  if (value == 0) return 'zero';
  final crore = value ~/ 10000000;
  final lakh = (value % 10000000) ~/ 100000;
  final thousand = (value % 100000) ~/ 1000;
  final rest = value % 1000;
  final parts = <String>[];
  if (crore > 0) parts.add('${_underThousand(crore)} crore');
  if (lakh > 0) parts.add('${_underThousand(lakh)} lakh');
  if (thousand > 0) parts.add('${_underThousand(thousand)} thousand');
  if (rest > 0) parts.add(_underThousand(rest));
  return parts.join(' ');
}

/// Indian-system amount in words, e.g. `One lakh ninety-three thousand ...`.
String amountInWords(int amount) {
  if (amount == 0) return 'Zero taka only';
  final negative = amount < 0;
  final text = _words(amount.abs());
  final capitalised = text.isEmpty
      ? text
      : '${text[0].toUpperCase()}${text.substring(1)}';
  return '${negative ? 'Minus ' : ''}$capitalised taka only';
}
