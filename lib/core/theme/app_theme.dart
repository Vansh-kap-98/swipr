import 'package:flutter/material.dart';

import 'slide_page_transitions.dart';

/// Neutral greys plus three signal colours. Every colour role is spelled out
/// below (no `fromSeed`), so no generated tint can drift into purple.
abstract final class AppColors {
  static const keep = Color(0xFF30D158);
  static const delete = Color(0xFFFF453A);
  static const accent = Color(0xFF1FA2FF); // sky blue
  static const accentDeep = Color(0xFF0A74D1);
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF161616);
  static const surfaceHigh = Color(0xFF242424);
  static const outline = Color(0xFF3A3A3A);
  static const muted = Color(0xFF9E9E9E);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: Colors.black,
    primaryContainer: AppColors.accentDeep,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.accent,
    onSecondary: Colors.black,
    secondaryContainer: AppColors.surfaceHigh,
    onSecondaryContainer: Colors.white,
    tertiary: AppColors.keep,
    onTertiary: Colors.black,
    tertiaryContainer: AppColors.surfaceHigh,
    onTertiaryContainer: Colors.white,
    error: AppColors.delete,
    onError: Colors.white,
    errorContainer: Color(0xFF5C1712),
    onErrorContainer: Colors.white,
    surface: AppColors.surface,
    onSurface: Colors.white,
    onSurfaceVariant: AppColors.muted,
    surfaceDim: AppColors.background,
    surfaceBright: AppColors.surfaceHigh,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.outline,
    outlineVariant: Color(0xFF2A2A2A),
    inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: AppColors.accentDeep,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  // One motion language: things slide. No ripples, no scale/fade page
  // transitions — pressed states and navigation are all horizontal/vertical
  // movement.
  const slide = SlidePageTransitionsBuilder();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: slide,
        TargetPlatform.iOS: slide,
        TargetPlatform.fuchsia: slide,
        TargetPlatform.linux: slide,
        TargetPlatform.macOS: slide,
        TargetPlatform.windows: slide,
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.outline,
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.accent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.muted,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.surfaceHigh,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.black : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surfaceHigh,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.accent),
    textTheme: Typography.whiteMountainView.apply(bodyColor: Colors.white, displayColor: Colors.white),
  );
}
