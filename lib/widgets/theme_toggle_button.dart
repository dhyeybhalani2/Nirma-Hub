import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Sun / moon switch for the app bar. Styled exactly like the notification
/// bell beside it - a bare icon in an [IconButton], no chip or outline - with
/// a short cross-fade when the icon swaps.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return IconButton(
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: () {
        HapticFeedback.lightImpact();
        ThemeController.instance.toggle(context);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
          key: ValueKey<bool>(isDark),
          color: context.c.text,
          size: 24,
        ),
      ),
    );
  }
}
