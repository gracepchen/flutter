// Newer Flutter releases moved CupertinoPageTransitionsBuilder from the
// material library into cupertino. This import covers both old and new SDKs.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'obr_tokens.dart';
import 'obr_typography.dart';

/// Maps OBR primitives onto Material's [ThemeData] so stock widgets
/// (AppBar, Divider, chips, text fields) pick up the system by default.
abstract final class ObrTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: ObrColors.brand600,
      onPrimary: ObrColors.gray0,
      primaryContainer: ObrColors.brand100,
      onPrimaryContainer: ObrColors.brand800,
      secondary: ObrColors.brand700,
      onSecondary: ObrColors.gray0,
      surface: ObrColors.gray0,
      onSurface: ObrColors.gray800,
      onSurfaceVariant: ObrColors.gray600,
      outline: ObrColors.gray200,
      outlineVariant: ObrColors.gray100,
      error: ObrColors.rose800,
      onError: ObrColors.gray0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ObrColors.gray50,
      fontFamily: ObrType.family,
      fontFamilyFallback: ObrType.fallback,
      textTheme: TextTheme(
        displayLarge: ObrType.displayLg,
        displayMedium: ObrType.displayMd,
        displaySmall: ObrType.displaySm,
        headlineLarge: ObrType.headingLg,
        headlineMedium: ObrType.headingMd,
        headlineSmall: ObrType.headingSm,
        titleLarge: ObrType.headingSmSemibold,
        titleMedium: ObrType.bodyLgSemibold,
        titleSmall: ObrType.bodyMd,
        bodyLarge: ObrType.bodyLgBook,
        bodyMedium: ObrType.bodyMdBook,
        bodySmall: ObrType.caption,
        labelLarge: ObrType.labelLgSemibold,
        labelMedium: ObrType.labelMd,
        labelSmall: ObrType.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ObrColors.gray50,
        foregroundColor: ObrColors.gray800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: ObrType.headingSmSemibold,
      ),
      dividerTheme: const DividerThemeData(
        color: ObrColors.gray200,
        thickness: ObrBorderWidth.w1,
        space: ObrBorderWidth.w1,
      ),
      // Platform-native route motion: Android predictive back and iOS
      // edge-swipe. Android also needs android:enableOnBackInvokedCallback="true"
      // in AndroidManifest.xml (see README).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
