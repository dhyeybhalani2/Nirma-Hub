import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai/core/theme/app_theme.dart';
import 'package:ai/widgets/theme_toggle_button.dart';

void main() {
  testWidgets('sun/moon button flips the theme and remembers it', (tester) async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    ThemeController.instance.init(prefs);

    late BuildContext inner;
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance,
        builder: (_, mode, __) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            appBar: AppBar(actions: const [ThemeToggleButton()]),
            body: Builder(builder: (c) {
              inner = c;
              return const SizedBox();
            }),
          ),
        ),
      ),
    );

    expect(inner.c.isDark, isFalse);
    expect(inner.c.card, AppColors.light.card);

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    expect(ThemeController.instance.value, ThemeMode.dark);
    expect(inner.c.isDark, isTrue);
    expect(inner.c.card, AppColors.dark.card);
    expect(prefs.getString('app_theme_mode'), 'dark');

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(inner.c.isDark, isFalse);
    expect(prefs.getString('app_theme_mode'), 'light');
  });
}
