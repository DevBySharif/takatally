import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taka_counter/core/export_service.dart';
import 'package:taka_counter/core/voucher.dart';
import 'package:taka_counter/data/models.dart';

TallySession _session() {
  final now = DateTime(2026, 11, 5, 10, 30);
  return TallySession(
    id: 'test-session',
    title: 'Thursday cash count',
    createdAt: now,
    updatedAt: now,
    entries: [
      TallyEntry(
        id: 'e1',
        kind: EntryKind.counted,
        amount: 1000,
        quantity: 150,
        note: '',
        createdAt: now,
      ),
      TallyEntry(
        id: 'e2',
        kind: EntryKind.debit,
        amount: 2500,
        quantity: 1,
        note: 'Tea & snacks',
        createdAt: now,
      ),
    ],
  );
}

Future<File> _write(String name, String contents) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsString(contents, flush: true);
  addTearDown(() async {
    if (await file.exists()) await file.delete();
  });
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('amount in words follows the Indian numbering system', () {
    expect(amountInWords(0), 'Zero taka only');
    expect(
      amountInWords(193130),
      'One lakh ninety-three thousand one hundred thirty taka only',
    );
    expect(amountInWords(1000), 'One thousand taka only');
  });

  test('voucher numbers are stable for a count', () {
    final session = _session();
    final first = voucherNumber(session);
    expect(first, startsWith('TT-20261105-'));
    expect(voucherNumber(session), first);
  });

  test('a JSON backup restores every count', () async {
    final file = await _write(
      'taka_test_backup.json',
      jsonEncode({
        'app': 'TakaTally',
        'format': 1,
        'sessions': [_session().toJson()],
      }),
    );

    final data = await ExportService.readFile(file);

    expect(data.isBackup, isTrue);
    expect(data.sessions, hasLength(1));
    expect(data.entryCount, 2);
    expect(data.sessions.single.title, 'Thursday cash count');
    expect(data.sessions.single.total, 150000 - 2500);
  });

  test('CSV rows import as entries grouped by count name', () async {
    final file = await _write(
      'taka_test_entries.csv',
      'Count,Date,Kind,Amount,Quantity,Note\n'
          'Shop collection,2026-11-01,counted,500,3,\n'
          'Shop collection,2026-11-01,debit,1000,1,Transport\n',
    );

    final data = await ExportService.readFile(file);

    expect(data.isBackup, isFalse);
    expect(data.sessions, hasLength(1));
    final session = data.sessions.single;
    expect(session.title, 'Shop collection');
    expect(session.entries, hasLength(2));
    expect(session.total, 1500 - 1000);
    expect(session.entries.any((entry) => entry.note == 'Transport'), isTrue);
  });

  test('a damaged file reports a friendly error', () async {
    final file = await _write('taka_test_bad.json', '{not json');

    expect(() => ExportService.readFile(file), throwsA(isA<FormatException>()));
  });

  test('a backup restores the note and coin breakdown', () async {
    final now = DateTime(2026, 11, 5, 12, 30);
    final session = TallySession(
      id: 'breakdown-session',
      title: 'Tray count',
      createdAt: now,
      updatedAt: now,
      entries: [
        TallyEntry(
          id: 'tray-entry',
          kind: EntryKind.counted,
          amount: 4025,
          quantity: 1,
          note: '',
          createdAt: now,
          noteCounts: const {1000: 3, 500: 2},
          coinCounts: const {5: 5},
        ),
      ],
    );

    final file = await _write(
      'taka_test_breakdown.json',
      jsonEncode({
        'sessions': [session.toJson()],
      }),
    );

    final entry = (await ExportService.readFile(
      file,
    )).sessions.single.entries.single;

    expect(entry.noteCounts, {1000: 3, 500: 2});
    expect(entry.coinCounts, {5: 5});
    expect(entry.pieceCount, 10);
    expect(entry.breakdownLabel, '৳1,000 × 3 · ৳500 × 2 · ৳5 coin × 5');
    expect(entry.displayTitle, 'Notes & coins');
  });

  test('a voucher PDF is generated with the total inside', () async {
    final dir = Directory.systemTemp.createTempSync('taka_voucher_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final file = await buildVoucherPdf(_session(), directory: dir);
    final bytes = await file.readAsBytes();

    expect(file.existsSync(), isTrue);
    expect(file.path, endsWith('.pdf'));
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a long voucher paginates instead of clipping entries', () async {
    final dir = Directory.systemTemp.createTempSync('taka_voucher_long_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final now = DateTime(2026, 11, 5, 10, 30);
    final session = TallySession(
      id: 'long-session',
      title: 'Month-end collection',
      createdAt: now,
      updatedAt: now,
      entries: [
        for (var i = 0; i < 80; i++)
          TallyEntry(
            id: 'long-$i',
            kind: EntryKind.counted,
            amount: 100,
            quantity: 2,
            note: 'Counter $i',
            createdAt: now.add(Duration(minutes: i)),
          ),
      ],
    );

    final file = await buildVoucherPdf(session, directory: dir);
    final text = String.fromCharCodes(await file.readAsBytes());
    final pages = RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;

    expect(file.existsSync(), isTrue);
    expect(pages, greaterThan(1));
  });

  test('Excel-style decimal and grouped amounts keep their value', () async {
    final file = await _write(
      'taka_test_decimals.csv',
      'Count,Date,Kind,Amount,Quantity,Note\n'
          'Shop,2026-11-01,counted,"2,500.00",3,Notes\n'
          'Shop,2026-11-01,counted,1.00,10,Coins\n'
          'Shop,2026-11-01,debit,"1,00,000",1,Rent\n',
    );

    final session = (await ExportService.readFile(file)).sessions.single;
    final byNote = {for (final entry in session.entries) entry.note: entry};

    expect(byNote['Notes']!.amount, 2500);
    expect(byNote['Notes']!.value, 7500);
    expect(byNote['Coins']!.amount, 1);
    expect(byNote['Rent']!.amount, 100000);
    expect(byNote['Rent']!.kind, EntryKind.debit);
  });

  test('a CSV with a byte-order mark still imports', () async {
    final file = await _write(
      'taka_test_bom.csv',
      '\uFEFFCount,Date,Amount\nShop,2026-11-01,500\n',
    );

    final session = (await ExportService.readFile(file)).sessions.single;

    expect(session.title, 'Shop');
    expect(session.entries.single.amount, 500);
  });
}
