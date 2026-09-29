import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'obr_tokens.dart';

/// OBR type scale. Sizes and line heights come from `tokens.json`.
///
/// One family, Whitney, in Light, Book (400), Medium (500) and Semibold (600).
/// It falls back to Arial and then the platform font until the licensed
/// font files are bundled (see pubspec.yaml).
abstract final class ObrType {
  static const String family = 'Whitney';
  static const List<String> fallback = <String>['Arial'];

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      height: lineHeight / size,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: ObrColors.gray800,
    );
  }

  // Display: page heroes (28–36).
  static final TextStyle displayLg = _style(36, 44, FontWeight.w500);
  static final TextStyle displayLgSemibold = _style(36, 44, FontWeight.w600);
  static final TextStyle displayMd = _style(32, 40, FontWeight.w500);
  static final TextStyle displayMdSemibold = _style(32, 40, FontWeight.w600);
  static final TextStyle displaySm = _style(28, 32, FontWeight.w500);
  static final TextStyle displaySmSemibold = _style(28, 32, FontWeight.w600);

  // Heading: section and card titles (17–24).
  static final TextStyle headingLg = _style(24, 28, FontWeight.w500);
  static final TextStyle headingLgSemibold = _style(24, 28, FontWeight.w600);
  static final TextStyle headingMd = _style(22, 28, FontWeight.w500);
  static final TextStyle headingMdSemibold = _style(22, 28, FontWeight.w600);
  static final TextStyle headingSm = _style(20, 24, FontWeight.w500);
  static final TextStyle headingSmSemibold = _style(20, 24, FontWeight.w600);
  static final TextStyle headingXs = _style(18, 20, FontWeight.w600);
  static final TextStyle headingSubhead = _style(17, 20, FontWeight.w500);

  /// All-caps eyebrow. Apply `.toUpperCase()` to the string.
  static final TextStyle headingCaption =
      _style(16, 20, FontWeight.w500, letterSpacing: 1.6);

  // Body: paragraph and UI copy (14–16).
  static final TextStyle bodyLg = _style(16, 24, FontWeight.w500);
  static final TextStyle bodyLgBook = _style(16, 24, FontWeight.w400);
  static final TextStyle bodyLgSemibold = _style(16, 24, FontWeight.w600);
  static final TextStyle bodyMd = _style(14, 20, FontWeight.w500);
  static final TextStyle bodyMdBook = _style(14, 20, FontWeight.w400);

  // Label: form labels and compact UI text (14–16).
  static final TextStyle labelLg = _style(16, 20, FontWeight.w500);
  static final TextStyle labelLgBook = _style(16, 20, FontWeight.w400);
  static final TextStyle labelLgSemibold = _style(16, 20, FontWeight.w600);
  static final TextStyle labelMd = _style(14, 16, FontWeight.w500);
  static final TextStyle labelMdBook = _style(14, 16, FontWeight.w400);

  /// 12/16 caption, built from the standalone font-size-12 and line-height-16 tokens.
  static final TextStyle caption = _style(12, 16, FontWeight.w400);
  static final TextStyle captionSemibold = _style(12, 16, FontWeight.w600);

  /// Monetary values and percentages use tabular figures so columns line up
  /// and numbers don't shift width when they update.
  static TextStyle tabular(TextStyle style) => style.copyWith(
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      );
}
