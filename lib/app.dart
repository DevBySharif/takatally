import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'data/store.dart';
import 'ui/app_scope.dart';
import 'ui/screens/home_screen.dart';

class TakaApp extends StatelessWidget {
  const TakaApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return MaterialApp(
            title: 'Taka Counter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: store.settings.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 280),
            themeAnimationCurve: Curves.easeOutCubic,
            home: const HomeScreen(),
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final p = context.taka;
              final overlay = (dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.background,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    dark ? Brightness.light : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
                statusBarBrightness:
                    dark ? Brightness.dark : Brightness.light,
              );
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlay,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
