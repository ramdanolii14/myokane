import 'package:intl/intl.dart';

/// Format amount as IDR (default, backward-compat)
String formatCurrency(double amount) {
  return formatCurrencyWithCode(amount, 'IDR');
}

/// Format amount using the given ISO currency code.
/// Falls back to 2 decimal digits for non-IDR currencies.
String formatCurrencyWithCode(double amount, String currencyCode) {
  switch (currencyCode) {
    case 'IDR':
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
    case 'JPY':
    case 'KRW':
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: _currencySymbol(currencyCode),
        decimalDigits: 0,
      ).format(amount);
    default:
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: _currencySymbol(currencyCode),
        decimalDigits: 2,
      ).format(amount);
  }
}

String _currencySymbol(String code) {
  const symbols = {
    'IDR': 'Rp ',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'SGD': 'S\$',
    'MYR': 'RM',
    'AUD': 'A\$',
    'CNY': 'CN¥',
    'KRW': '₩',
    'SAR': 'SR',
    'AED': 'AED ',
  };
  return symbols[code] ?? '$code ';
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy', 'id_ID').format(date);
}

String formatDateShort(DateTime date) {
  return DateFormat('dd MMM', 'id_ID').format(date);
}

String formatMonth(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];
  return months[month];
}
