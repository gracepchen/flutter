import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// OBR Design System primitives, transcribed from the system's `tokens.json`.
///
/// Only primitive scales are reproduced here. Per-component semantic tokens
/// (button states, Buy/Sell variants, etc.) live on the source Figma file's
/// "Component Tokens" page. Pull exact values from there when you build a
/// specific component.
abstract final class ObrColors {
  // Brand red. brand-600 is the core identity colour for primary actions.
  static const Color brand50 = Color(0xFFFEF2F2);
  static const Color brand100 = Color(0xFFFDE6E6);
  static const Color brand200 = Color(0xFFFBD0D3);
  static const Color brand300 = Color(0xFFF8A9AF);
  static const Color brand400 = Color(0xFFF37984);
  static const Color brand500 = Color(0xFFE94A5C);
  static const Color brand600 = Color(0xFFC41F3E);
  static const Color brand700 = Color(0xFF8B1D41);
  static const Color brand800 = Color(0xFF612141);
  static const Color brand900 = Color(0xFF45172E);

  // Neutrals. Body copy is gray-800 or gray-700; never lighter than gray-600.
  static const Color gray0 = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF2F3F2);
  static const Color gray200 = Color(0xFFDDDDDD);
  static const Color gray300 = Color(0xFFD9D9D6);
  static const Color gray400 = Color(0xFFBBBCBC);
  static const Color gray500 = Color(0xFF86888A);
  static const Color gray600 = Color(0xFF606366);
  static const Color gray700 = Color(0xFF383B3E);
  static const Color gray800 = Color(0xFF1F2123);
  static const Color gray900 = Color(0xFF101316);

  // Green: positive values and "Buy" in trading flows.
  static const Color green100 = Color(0xFFE4EFEA);
  static const Color green200 = Color(0xFFBEDACD);
  static const Color green300 = Color(0xFF76B297);
  static const Color green400 = Color(0xFF4A9E6B);
  static const Color green500 = Color(0xFF1F8561);
  static const Color green600 = Color(0xFF0A6D42);
  static const Color green700 = Color(0xFF095933);
  static const Color green800 = Color(0xFF024423);

  // Orange: caution and "Sell" in trading flows.
  static const Color orange100 = Color(0xFFFCEAE3);
  static const Color orange200 = Color(0xFFFFCFB2);
  static const Color orange600 = Color(0xFFCC4B18);
  static const Color orange700 = Color(0xFFB73A18);
  static const Color orange800 = Color(0xFF932516);

  // Blue: informational accents.
  static const Color blue100 = Color(0xFFDEE9F7);
  static const Color blue200 = Color(0xFFCCDDF2);
  static const Color blue300 = Color(0xFF9BBFE0);
  static const Color blue400 = Color(0xFF5C99D6);
  static const Color blue500 = Color(0xFF3885BA);
  static const Color blue600 = Color(0xFF2779B0);
  static const Color blue700 = Color(0xFF0767A8);
  static const Color blue800 = Color(0xFF11608A);
  static const Color blue900 = Color(0xFF005377);

  // Rose: alert surfaces.
  static const Color rose100 = Color(0xFFFAF1F3);
  static const Color rose800 = Color(0xFF99314F);

  // Yellow: warning surfaces.
  static const Color yellow100 = Color(0xFFFCF1D7);
  static const Color yellow700 = Color(0xFF994E04);

  // Alpha tokens (tokens.json stores these as #RRGGBBAA; Flutter is 0xAARRGGBB).
  static const Color alphaBrand10 = Color(0x1AC41F3E);
  static const Color alphaDark10 = Color(0x1A101316);
  static const Color alphaDark25 = Color(0x40101316);
  static const Color alphaWhite70 = Color(0xB3FFFFFF);
  static const Color alphaWhite85 = Color(0xD9FFFFFF);
}

/// Padding, gaps and margins.
abstract final class ObrSpace {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s36 = 36;
  static const double s40 = 40;
  static const double s44 = 44;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
}

/// Fixed control, icon and avatar dimensions. Use this scale, not [ObrSpace],
/// when you mean the size of a control.
abstract final class ObrSize {
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s44 = 44;
  static const double s48 = 48;
  static const double s52 = 52;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s72 = 72;
}

abstract final class ObrRadius {
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double full = 999;
}

abstract final class ObrBorderWidth {
  static const double w1 = 1;
  static const double w2 = 2;
  static const double w4 = 4;
}

/// Most UI motion (toggle, expand, tab switch) belongs in the 150–300ms band.
abstract final class ObrDuration {
  static const Duration d100 = Duration(milliseconds: 100);
  static const Duration d150 = Duration(milliseconds: 150);
  static const Duration d200 = Duration(milliseconds: 200);
  static const Duration d250 = Duration(milliseconds: 250);
  static const Duration d300 = Duration(milliseconds: 300);
  static const Duration d400 = Duration(milliseconds: 400);
  static const Duration d500 = Duration(milliseconds: 500);
  static const Duration d600 = Duration(milliseconds: 600);
}

abstract final class ObrEasing {
  static const Curve linear = Curves.linear;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  /// For one deliberate emphasis moment only, not routine transitions.
  static const Curve bounce = Cubic(0.6, 0.1, 0.2, 1.6);
}

/// Backdrop blur for glass and scrim surfaces.
abstract final class ObrBlur {
  static const double b4 = 4;
  static const double b8 = 8;
  static const double b12 = 12;
  static const double b22 = 22;
  static const double b32 = 32;
  static const double b40 = 40;
}

/// Elevation steps. Use the lowest step that separates a surface, and don't stack them.
abstract final class ObrShadow {
  static const Color _color = ObrColors.alphaDark10;

  static const List<BoxShadow> s1 = [
    BoxShadow(color: _color, offset: Offset(0, 1), blurRadius: 4),
  ];
  static const List<BoxShadow> s2 = [
    BoxShadow(color: _color, offset: Offset(0, 2), blurRadius: 8),
  ];
  static const List<BoxShadow> s3 = [
    BoxShadow(color: _color, offset: Offset(0, 3), blurRadius: 12),
  ];
  static const List<BoxShadow> s4 = [
    BoxShadow(color: _color, offset: Offset(0, 4), blurRadius: 16),
  ];
  static const List<BoxShadow> s5 = [
    BoxShadow(color: _color, offset: Offset(0, 5), blurRadius: 20),
  ];
  static const List<BoxShadow> s6 = [
    BoxShadow(color: _color, offset: Offset(0, 6), blurRadius: 28),
  ];
}
