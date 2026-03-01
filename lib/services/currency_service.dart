import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ─── Supported Currencies ───
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
  CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$'),
  CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£'),
  CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
  CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
  CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
  CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
  CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: 'CN¥'),
  CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
  CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: 'SR'),
  CurrencyInfo(code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
];

CurrencyInfo getCurrencyInfo(String code) {
  return supportedCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => CurrencyInfo(code: code, name: code, symbol: code),
  );
}

// ─── Rate cache (keyed by base currency) ───
class _RateCache {
  final Map<String, double> rates; // all rates relative to base
  final DateTime fetchedAt;
  final String baseCurrency;

  _RateCache({
    required this.rates,
    required this.fetchedAt,
    required this.baseCurrency,
  });

  bool get isExpired => DateTime.now().difference(fetchedAt).inMinutes > 30;
}

// ─── Currency Service ───
class CurrencyService {
  // Frankfurter tidak support IDR sebagai base currency —
  // IDR tidak ada di ECB (European Central Bank) dataset.
  // Solusi: selalu fetch dengan base USD, lalu cross-rate manual.
  // USD hampir universal didukung semua API kurs.
  static const String _pivotCurrency = 'USD';

  static _RateCache? _cache;

  /// Convert [amount] dari [from] ke [to].
  /// Mengembalikan null jika gagal (network error, dll).
  static Future<ConversionResult?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) {
      return ConversionResult(
        convertedAmount: amount,
        rate: 1.0,
        from: from,
        to: to,
      );
    }

    try {
      // Ambil semua rates relatif ke USD
      final rates = await _getRatesViaUSD();
      if (rates == null) return null;

      final rateFrom = rates[from];
      final rateTo = rates[to];

      if (rateFrom == null || rateTo == null) return null;

      // Cross-rate: from → USD → to
      // rateFrom = berapa USD per 1 unit [from]  → SALAH
      // rates dari API: 1 USD = X [currency]
      // Jadi rateFrom = berapa [from] per 1 USD
      // Untuk konversi: amount [from] → [to]
      //   step1: amount [from] ÷ rateFrom = amount dalam USD
      //   step2: amount USD × rateTo = amount dalam [to]
      final amountInUSD = amount / rateFrom;
      final convertedAmount = amountInUSD * rateTo;

      // Rate langsung: berapa [to] per 1 [from]
      final directRate = rateTo / rateFrom;

      return ConversionResult(
        convertedAmount: convertedAmount,
        rate: directRate,
        from: from,
        to: to,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch rates dari Frankfurter dengan base USD.
  /// Frankfurter support USD sebagai base dengan baik.
  /// IDR ada di dataset-nya via USD cross.
  static Future<Map<String, double>?> _getRatesViaUSD() async {
    // Gunakan cache jika masih valid
    if (_cache != null &&
        !_cache!.isExpired &&
        _cache!.baseCurrency == _pivotCurrency) {
      return _cache!.rates;
    }

    try {
      final uri = Uri.parse(
          'https://api.frankfurter.dev/v1/latest?base=$_pivotCurrency');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final ratesRaw = data['rates'] as Map<String, dynamic>;
      final rates = ratesRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

      // Tambah USD sendiri (1:1 terhadap pivot)
      rates[_pivotCurrency] = 1.0;

      _cache = _RateCache(
        rates: rates,
        fetchedAt: DateTime.now(),
        baseCurrency: _pivotCurrency,
      );

      return rates;
    } on SocketException {
      return null;
    } on Exception {
      return null;
    }
  }

  /// Invalidate cache (misal saat user ganti mata uang default)
  static void invalidateCache() {
    _cache = null;
  }
}

class ConversionResult {
  final double convertedAmount;
  final double rate; // berapa [to] per 1 [from]
  final String from;
  final String to;

  const ConversionResult({
    required this.convertedAmount,
    required this.rate,
    required this.from,
    required this.to,
  });
}
