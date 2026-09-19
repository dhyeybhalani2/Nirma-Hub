import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Sun / moon switch for the app bar. Deliberately quiet: a flat chip that
/// matches the surrounding surface, and a short cross-fade between the two
/// icons rather than a spin. The button dips slightly on press.
class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
    CurvedAnimation(parent: _press, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = context.isDarkMode;

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Tooltip(
        message: isDark ? 'Light mode' : 'Dark mode',
        child: Listener(
          onPointerDown: (_) => _press.forward(),
          onPointerUp: (_) => _press.reverse(),
          onPointerCancel: (_) => _press.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: InkResponse(
              radius: 22,
              onTap: () {
                HapticFeedback.lightImpact();
                ThemeController.instance.toggle(context);
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? c.fillStrong : const Color(0xFFF8FAFC),
                      border: Border.all(color: c.border),
                    ),
                    child: AnimatedSwitcher(
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
                        size: 18,
                        color: isDark ? c.textSecondary : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
