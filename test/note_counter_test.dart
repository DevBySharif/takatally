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
  testWidgets('note counter totals notes and coins into one added amount', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await tester.tap(find.text('Note counter'));
    await _settle(tester);

    expect(find.text('Note counter'), findsOneWidget);
    expect(find.text('Banknotes'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('note-art-2')));
    await tester.tap(find.byKey(const ValueKey('note-art-2')));
    await tester.tap(find.byKey(const ValueKey('coin-art-5')));
    await tester.tap(find.byKey(const ValueKey('coin-art-5')));
    await _settle(tester);

    expect(find.textContaining('2 notes'), findsOneWidget);
    expect(find.textContaining('2 coins'), findsOneWidget);
    expect(find.textContaining('2 types'), findsOneWidget);
    expect(find.textContaining('৳14', findRichText: true), findsWidgets);

    final beforeTotal = store.activeSession.total;
    final beforeEntries = store.activeSession.entryCount;

    await tester.tap(find.textContaining('to count'));
    await _settle(tester);

    final session = store.activeSession;
    expect(session.total, beforeTotal + 14);
    expect(session.entryCount, beforeEntries + 1);

    final entry = session.entries.first;
    expect(entry.kind, EntryKind.counted);
    expect(entry.amount, 14);
    expect(entry.quantity, 1);
    expect(entry.noteCounts, {2: 2});
    expect(entry.coinCounts, {5: 2});
    expect(entry.hasBreakdown, isTrue);
    expect(entry.pieceCount, 4);

    expect(find.textContaining('Nothing counted yet'), findsOneWidget);
  });

  testWidgets('holding a denomination adds ten at a time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await tester.tap(find.text('Note counter'));
    await _settle(tester);

    await tester.longPress(find.byKey(const ValueKey('coin-art-2')));
    await _settle(tester);

    expect(find.textContaining('10 coins'), findsOneWidget);
    expect(find.textContaining('৳20', findRichText: true), findsWidgets);
  });

  testWidgets('counts can be typed instead of tapped', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await tester.tap(find.text('Note counter'));
    await _settle(tester);

    await tester.tap(find.text('Type'));
    await _settle(tester);

    expect(find.text('Type your counts'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('bulk-note-1000')),
      '3',
    );
    await tester.enterText(
      find.byKey(const ValueKey('bulk-note-500')),
      '2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('bulk-coin-5')),
      '5',
    );
    await _settle(tester);

    await tester.tap(find.text('Apply counts'));
    await _settle(tester);

    // 3 × ৳1,000 + 2 × ৳500 + 5 × ৳5
    expect(find.textContaining('৳4,025', findRichText: true), findsWidgets);
    expect(find.textContaining('5 coins'), findsOneWidget);
  });
}
