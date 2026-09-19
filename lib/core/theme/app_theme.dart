import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Semantic palette of the app. Every screen reads its colours from here
/// (`context.c.text`, `context.c.card` ...) so light and dark stay in sync.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final bool isDark;

  // Surfaces
  final Color bg; // page background
  final Color card; // cards, app bars, sheets
  final Color fill; // input fields, subtle wells
  final Color fillStrong; // chips, pressed wells, skeleton base
  final Color border; // hairlines
  final Color borderStrong; // input outlines

  // Text
  final Color text; // headings
  final Color textSoft; // strong body
  final Color textSecondary; // body
  final Color textMuted; // captions
  final Color textFaint; // hints, disabled

  // Brand
  final Color accent; // brand red for text / icons / borders
  final Color accentFill; // brand red as a button fill (white label on top)
  final Color accentSoft; // tinted red background
  final Color accentSoftBorder;

  // The signature dark "hero" card (SGPA dashboard, banners, snackbars)
  final Color hero;
  final Color heroBorder;

  // Solid high-contrast button (navy in light, light slate in dark)
  final Color solid;
  final Color onSolid;

  // Status
  final Color success;
  final Color successFill; // green as a button fill (white label on top)
  final Color successSoft;
  final Color successBorder;
  final Color warning;
  final Color warningText;
  final Color warningSoft;
  final Color warningBorder;
  final Color danger;
  final Color dangerFill; // red as a button fill (white label on top)
  final Color dangerSoft;
  final Color dangerBorder;
  final Color info;
  final Color infoFill; // blue as a button fill (white label on top)
  final Color infoSoft;
  final Color infoBorder;
  final Color purple;
  final Color purpleSoft;
  final Color purpleBorder;

  final Color shadow;

  const AppColors({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.fill,
    required this.fillStrong,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSoft,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentFill,
    required this.accentSoft,
    required this.accentSoftBorder,
    required this.hero,
    required this.heroBorder,
    required this.solid,
    required this.onSolid,
    required this.success,
    required this.successFill,
    required this.successSoft,
    required this.successBorder,
    required this.warning,
    required this.warningText,
    required this.warningSoft,
    required this.warningBorder,
    required this.danger,
    required this.dangerFill,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.info,
    required this.infoFill,
    required this.infoSoft,
    required this.infoBorder,
    required this.purple,
    required this.purpleSoft,
    required this.purpleBorder,
    required this.shadow,
  });

  static const AppColors light = AppColors(
    isDark: false,
    bg: Color(0xFFF1F4F9),
    card: Color(0xFFFFFFFF),
    fill: Color(0xFFF8FAFC),
    fillStrong: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    text: Color(0xFF0F172A),
    textSoft: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    accent: Color(0xFFC62828),
    accentFill: Color(0xFFC62828),
    accentSoft: Color(0xFFFEF2F2),
    accentSoftBorder: Color(0xFFFECACA),
    hero: Color(0xFF0F172A),
    heroBorder: Color(0xFF1E293B),
    solid: Color(0xFF0F172A),
    onSolid: Color(0xFFFFFFFF),
    success: Color(0xFF10B981),
    successFill: Color(0xFF10B981),
    successSoft: Color(0xFFD1FAE5),
    successBorder: Color(0xFFA7F3D0),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFFB45309),
    warningSoft: Color(0xFFFEF3C7),
    warningBorder: Color(0xFFFDE68A),
    danger: Color(0xFFEF4444),
    dangerFill: Color(0xFFEF4444),
    dangerSoft: Color(0xFFFEE2E2),
    dangerBorder: Color(0xFFFECACA),
    info: Color(0xFF2563EB),
    infoFill: Color(0xFF2563EB),
    infoSoft: Color(0xFFEFF6FF),
    infoBorder: Color(0xFFBFDBFE),
    purple: Color(0xFF6B21A8),
    purpleSoft: Color(0xFFF3E8FF),
    purpleBorder: Color(0xFFD8B4FE),
    shadow: Color(0xFF0F172A),
  );

  /// Warm graphite night palette. A charcoal rather than a blue-grey, sitting
  /// just off pure black so surfaces read as material, with each one a clear
  /// step lighter than the one behind it (page -> card -> hero/button).
  static const AppColors dark = AppColors(
    isDark: true,
    bg: Color(0xFF0B0B0C),
    card: Color(0xFF1B1B1C),
    fill: Color(0xFF131314),
    fillStrong: Color(0xFF242426),
    border: Color(0xFF2E2E30),
    borderStrong: Color(0xFF45454A),
    text: Color(0xFFFAFAF9),
    textSoft: Color(0xFFEDEDEC),
    textSecondary: Color(0xFFD2D2D0),
    textMuted: Color(0xFFA3A3A1),
    textFaint: Color(0xFF7C7C7A),
    accent: Color(0xFFFF6B66),
    accentFill: Color(0xFFC62828),
    accentSoft: Color(0xFF2B1517),
    accentSoftBorder: Color(0xFF55242A),
    hero: Color(0xFF343436),
    heroBorder: Color(0xFF4B4B4E),
    solid: Color(0xFFFAFAF9),
    onSolid: Color(0xFF0B0B0C),
    success: Color(0xFF34D399),
    successFill: Color(0xFF0C7E5A),
    successSoft: Color(0xFF102A23),
    successBorder: Color(0xFF1C5240),
    warning: Color(0xFFFBBF24),
    warningText: Color(0xFFFCD34D),
    warningSoft: Color(0xFF2C2312),
    warningBorder: Color(0xFF5E4614),
    danger: Color(0xFFFB7A7A),
    dangerFill: Color(0xFFB5342B),
    dangerSoft: Color(0xFF2E1718),
    dangerBorder: Color(0xFF5E2429),
    info: Color(0xFF60A5FA),
    infoFill: Color(0xFF1D4ED8),
    infoSoft: Color(0xFF121D31),
    infoBorder: Color(0xFF1F3B6D),
    purple: Color(0xFFD8B4FE),
    purpleSoft: Color(0xFF251A38),
    purpleBorder: Color(0xFF4C2C7C),
    shadow: Color(0xFF000000),
  );

  /// Picks the right value without going through the palette, for the odd
  /// one-off colour: `context.c.pick(lightColor, darkColor)`.
  Color pick(Color lightValue, Color darkValue) => isDark ? darkValue : lightValue;

  /// A category tint (subject icons, tags) stays as-is in light mode and is
  /// lifted toward white in dark mode so it never sinks into the background.
  Color tint(Color base) => isDark ? Color.lerp(base, Colors.white, 0.42)! : base;

  /// Pastel tag background: unchanged in light, a low-alpha wash in dark.
  Color pastel(Color lightPastel, Color base) =>
      isDark ? base.withValues(alpha: 0.18) : lightPastel;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      bg: l(bg, other.bg),
      card: l(card, other.card),
      fill: l(fill, other.fill),
      fillStrong: l(fillStrong, other.fillStrong),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      text: l(text, other.text),
      textSoft: l(textSoft, other.textSoft),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      accentFill: l(accentFill, other.accentFill),
      accentSoft: l(accentSoft, other.accentSoft),
      accentSoftBorder: l(accentSoftBorder, other.accentSoftBorder),
      hero: l(hero, other.hero),
      heroBorder: l(heroBorder, other.heroBorder),
      solid: l(solid, other.solid),
      onSolid: l(onSolid, other.onSolid),
      success: l(success, other.success),
      successFill: l(successFill, other.successFill),
      successSoft: l(successSoft, other.successSoft),
      successBorder: l(successBorder, other.successBorder),
      warning: l(warning, other.warning),
      warningText: l(warningText, other.warningText),
      warningSoft: l(warningSoft, other.warningSoft),
      warningBorder: l(warningBorder, other.warningBorder),
      danger: l(danger, other.danger),
      dangerFill: l(dangerFill, other.dangerFill),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      dangerBorder: l(dangerBorder, other.dangerBorder),
      info: l(info, other.info),
      infoFill: l(infoFill, other.infoFill),
      infoSoft: l(infoSoft, other.infoSoft),
      infoBorder: l(infoBorder, other.infoBorder),
      purple: l(purple, other.purple),
      purpleSoft: l(purpleSoft, other.purpleSoft),
      purpleBorder: l(purpleBorder, other.purpleBorder),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The active semantic palette.
  AppColors get c => Theme.of(this).extension<AppColors>() ?? AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFC62828), // Nirma Red Focus
      brightness: brightness,
      primary: isDark ? const Color(0xFFE8E8E6) : const Color(0xFF1A2B48), // Navy
      onPrimary: isDark ? const Color(0xFF0B0B0C) : Colors.white,
      surface: c.card,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: c.card,
      surfaceContainerLow: c.fill,
      surfaceContainer: c.bg,
      surfaceContainerHigh: isDark ? const Color(0xFF242426) : const Color(0xFFE2E8F0),
      surfaceContainerHighest: isDark ? const Color(0xFF2E2E30) : const Color(0xFFCBD5E1),
      outline: c.borderStrong,
      outlineVariant: c.border,
      error: c.danger,
    );

    final overlay = (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: c.card,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Inter',
      colorScheme: scheme,
      extensions: [c],
      dividerColor: c.border,
      // Same ripple feel in both modes, just tinted for the surface it sits on.
      splashColor: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.06),
      highlightColor: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: c.card,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlay,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.accent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.hero,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Holds the user's light / dark choice and persists it.
/// Until the user taps the toggle once, the app follows the system setting.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'app_theme_mode';
  SharedPreferences? _prefs;

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    switch (prefs.getString(_prefsKey)) {
      case 'dark':
        value = ThemeMode.dark;
      case 'light':
        value = ThemeMode.light;
      default:
        value = ThemeMode.system;
    }
  }

  bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  void toggle(BuildContext context) {
    final goDark = !isDark(context);
    value = goDark ? ThemeMode.dark : ThemeMode.light;
    _prefs?.setString(_prefsKey, goDark ? 'dark' : 'light');
  }
}
