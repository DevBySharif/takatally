import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final store = await AppStore.load();

  // The web preview uses ?demo=1 to showcase the interface with real-looking
  // data. A normal install always starts with a clean, empty count.
  if (Uri.base.queryParameters['demo'] == '1') {
    store.seedDemo();
  }

  runApp(TakaApp(store: store));
}
