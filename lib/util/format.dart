import 'package:intl/intl.dart';

final NumberFormat _cad = NumberFormat.currency(
  locale: 'en_CA',
  symbol: r'$',
  decimalDigits: 2,
);

/// U+2212 MINUS SIGN. Screen readers say "minus", and it has the same width
/// as "+" in most typefaces.
const String _minus = '−';

/// `$124,820.42`
String formatCad(double value) => _cad.format(value);

/// `+$1,284.20` or `−$812.50`
String formatSignedCad(double value) =>
    '${value < 0 ? _minus : '+'}${_cad.format(value.abs())}';

/// `+1.04%` or `−0.80%`
String formatSignedPercent(double value, {int decimals = 2}) =>
    '${value < 0 ? _minus : '+'}${value.abs().toStringAsFixed(decimals)}%';

final NumberFormat _price = NumberFormat('#,##0.00', 'en_CA');
final NumberFormat _whole = NumberFormat('#,##0', 'en_CA');

/// `1,234.56` (no currency symbol), for quotes shown next to a currency code.
String formatPrice(double value) => _price.format(value);

/// `3,100`
String formatWhole(num value) => _whole.format(value);
