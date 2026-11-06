import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taka_counter/app.dart';
import 'package:taka_counter/data/models.dart';
import 'package:taka_counter/data/store.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('a note quantity can be typed instead of tapped in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final before = store.activeSession.entryCount;

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await tester.tap(find.text('Open counter'));
    await _settle(tester);

    await tester.tap(find.text('Add note'));
    await _settle(tester);

    await tester.enterText(
      find.byKey(const ValueKey('entry-amount-field')),
      '500',
    );
    await tester.enterText(
      find.byKey(const ValueKey('entry-quantity-field')),
      '25',
    );
    await _settle(tester);

    // ৳500 × 25 shows up in the sheet before saving.
    expect(find.textContaining('৳500 × 25'), findsWidgets);

    await tester.ensureVisible(find.text('Add to counter'));
    await _settle(tester);
    await tester.tap(find.text('Add to counter'));
    await _settle(tester);

    final entries = store.activeSession.entries;
    expect(store.activeSession.entryCount, before + 1);
    expect(entries.first.kind, EntryKind.counted);
    expect(entries.first.amount, 500);
    expect(entries.first.quantity, 25);
    expect(entries.first.value, 12500);
  });

  testWidgets('a note-counter breakdown can be reopened and edited', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.addEntry(
      TallyEntry(
        id: 'breakdown-entry',
        kind: EntryKind.counted,
        amount: 4025,
        quantity: 1,
        note: '',
        createdAt: DateTime(2026, 11, 5, 12, 30),
        noteCounts: const {1000: 3, 500: 2},
        coinCounts: const {5: 5},
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await tester.tap(find.text('Open counter'));
    await _settle(tester);

    // The count row shows the breakdown preview, and the entry reopens with
    // every denomination listed.
    expect(find.text('Notes & coins'), findsOneWidget);
    await tester.tap(find.text('Notes & coins'));
    await _settle(tester);

    expect(find.text('NOTES & COINS'), findsOneWidget);
    expect(find.textContaining('10 pieces'), findsWidgets);

    // Tap the ৳1,000 row and type a new count instead of tapping +.
    await tester.tap(find.byKey(const ValueKey('breakdown-note-1000')));
    await _settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('count-entry-field')),
      '5',
    );
    await _settle(tester);
    await tester.tap(find.text('Set count'));
    await _settle(tester);

    // 5 × ৳1,000 + 2 × ৳500 + 5 × ৳5 = ৳6,025
    expect(find.text('6,025'), findsOneWidget);

    await tester.ensureVisible(find.text('Save changes'));
    await _settle(tester);
    await tester.tap(find.text('Save changes'));
    await _settle(tester);

    final entry = store.activeSession.entries.single;
    expect(entry.amount, 6025);
    expect(entry.noteCounts, {1000: 5, 500: 2});
    expect(entry.coinCounts, {5: 5});
    expect(entry.pieceCount, 12);
  });
}
