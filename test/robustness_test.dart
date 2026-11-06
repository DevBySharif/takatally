import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taka_counter/app.dart';
import 'package:taka_counter/data/store.dart';

Future<void> _loadFonts() async {
  final manrope = FontLoader('Manrope');
  for (final weight in [400, 500, 600, 700, 800]) {
    manrope.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
  }
  await manrope.load();

  final bengali = FontLoader('NotoSansBengali');
  for (final weight in [400, 600, 700]) {
    bengali.addFont(
      rootBundle.load('assets/fonts/NotoSansBengali-$weight.ttf'),
    );
  }
  await bengali.load();

  final icons = FontLoader('MaterialIcons');
  icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label).first;
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('busy screens fit a small phone with large text', (tester) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'home overflowed');

    await _tapText(tester, 'Open counter');
    expect(tester.takeException(), isNull, reason: 'counter overflowed');
    expect(find.byTooltip('Count options'), findsOneWidget);

    await tester.tap(find.byTooltip('Back').first);
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'home (return) overflowed');

    await _tapText(tester, 'History');
    expect(tester.takeException(), isNull, reason: 'history overflowed');

    await tester.tap(find.byTooltip('Back').first);
    await _settle(tester);

    await _tapText(tester, 'Note counter');
    expect(tester.takeException(), isNull, reason: 'note counter overflowed');

    await tester.tap(find.byTooltip('Close').first);
    await _settle(tester);

    await _tapText(tester, 'Settings');
    expect(tester.takeException(), isNull, reason: 'settings overflowed');
  });

  testWidgets('the entry editor opens on a small phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TakaApp(store: store));
    await _settle(tester);

    await _tapText(tester, 'Open counter');
    await tester.tap(find.byTooltip('Add entry').first);
    await _settle(tester);

    expect(tester.takeException(), isNull, reason: 'editor overflowed');
    expect(find.text('Add to count'), findsOneWidget);
  });

  test('fonts are bundled for the runtime renders', () {
    expect(Directory('assets/fonts').existsSync(), isTrue);
  });
}
