import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  await tester.pump(const Duration(milliseconds: 900));
}

Future<AppStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  final store = await AppStore.load();
  store.seedDemo();
  return store;
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
  // Image encoding happens on the engine's raster thread; it must run outside
  // the fake-async zone or the test process hangs at shutdown.
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<GlobalKey> _pumpApp(WidgetTester tester, AppStore store) async {
  final key = GlobalKey();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(key: key, child: TakaApp(store: store)),
  );
  await _settle(tester);
  return key;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('capture visual screens', (tester) async {
    final store = await _freshStore();
    final key = await _pumpApp(tester, store);
    await _capture(tester, key, '01_home_light');

    await tester.tap(find.text('Open counter'));
    await _settle(tester);
    await _capture(tester, key, '02_counter');

    await tester.tap(find.text('Add note'));
    await _settle(tester);
    // Fill the sheet so the store shot shows a real amount instead of an
    // empty field with a disabled button.
    await tester.tap(find.text('৳1000'));
    await _settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('entry-quantity-field')),
      '15',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    await _capture(tester, key, '03_add_entry');

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('History').first);
    await _settle(tester);
    await _capture(tester, key, '04_history');

    await tester.tap(find.text('Thursday cash count').first);
    await _settle(tester);
    await _capture(tester, key, '05_history_detail');

    await tester.tap(find.byIcon(Icons.receipt_long_rounded).first);
    await _settle(tester);
    await _capture(tester, key, '15_voucher');
    await tester.pageBack();
    await _settle(tester);

    await tester.pageBack();
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('Note counter'));
    await _settle(tester);
    await _capture(tester, key, '06_note_counter');

    // Type a realistic tray so the store shot shows meaningful totals.
    await tester.tap(find.text('Type'));
    await _settle(tester);
    for (final (key, value) in [
      ('bulk-note-1000', '24'),
      ('bulk-note-500', '8'),
      ('bulk-note-100', '16'),
      ('bulk-coin-1', '35'),
    ]) {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await _settle(tester);
      await tester.enterText(field, value);
      await _settle(tester);
    }
    await tester.tap(find.text('Apply counts'));
    await _settle(tester);
    await _capture(tester, key, '07_note_counter_filled');
    await tester.tap(find.textContaining('to count'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await _settle(tester);

    // Reopen the tray count from the ledger: the breakdown is kept and editable.
    await tester.tap(find.text('Open counter'));
    await _settle(tester);
    await tester.tap(find.text('Notes & coins'));
    await _settle(tester);
    await _capture(tester, key, '17_breakdown');
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('Settings').first);
    await _settle(tester);
    await _capture(tester, key, '08_settings');
    await tester.scrollUntilVisible(
      find.text('Export to Excel'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // Nudge back up so the support row above is not clipped by the viewport.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 70));
    await _settle(tester);
    await _capture(tester, key, '16_settings_data');

    // Scroll back to the top so the header's back button exists again.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await _settle(tester);
    await tester.pageBack();
    await _settle(tester);

    store.setThemeMode(ThemeMode.dark);
    await _settle(tester);
    await _capture(tester, key, '09_home_dark');
  });

  testWidgets('capture dark screens', (tester) async {
    final store = await _freshStore();
    store.setThemeMode(ThemeMode.dark);
    final key = await _pumpApp(tester, store);
    await _capture(tester, key, '10_home_dark_full');

    await tester.tap(find.text('Open counter'));
    await _settle(tester);
    await _capture(tester, key, '11_counter_dark');

    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('Note counter'));
    await _settle(tester);
    await _capture(tester, key, '12_note_counter_dark');
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await _settle(tester);

    await tester.tap(find.text('History').first);
    await _settle(tester);
    await _capture(tester, key, '13_history_dark');
    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('Settings').first);
    await _settle(tester);
    await _capture(tester, key, '14_settings_dark');
  });
}
