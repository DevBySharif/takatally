import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taka_counter/app.dart';
import 'package:taka_counter/data/store.dart';

void main() {
  testWidgets('home renders and demo data is calculated correctly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.seedDemo();

    expect(store.activeSession.total, 193130);

    await tester.pumpWidget(TakaApp(store: store));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Count every taka.'), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);
    expect(
      find.textContaining('1,93,130', findRichText: true),
      findsWidgets,
    );
  });
}
