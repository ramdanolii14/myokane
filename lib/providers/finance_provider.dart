import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../services/currency_service.dart';

class CustomCategory {
  final String id;
  final String name;
  final String emoji;
  final TransactionType type;

  CustomCategory(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.type});

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'emoji': emoji, 'type': type.index};
  factory CustomCategory.fromMap(Map<String, dynamic> m) => CustomCategory(
      id: m['id'],
      name: m['name'],
      emoji: m['emoji'],
      type: TransactionType.values[m['type']]);
}

final List<CustomCategory> _defaultIncomeCategories = [
  CustomCategory(
      id: 'gaji', name: 'Gaji', emoji: '💼', type: TransactionType.income),
  CustomCategory(
      id: 'freelance',
      name: 'Freelance',
      emoji: '💻',
      type: TransactionType.income),
  CustomCategory(
      id: 'investasi',
      name: 'Investasi',
      emoji: '📈',
      type: TransactionType.income),
  CustomCategory(
      id: 'bisnis', name: 'Bisnis', emoji: '🏪', type: TransactionType.income),
  CustomCategory(
      id: 'hadiah', name: 'Hadiah', emoji: '🎁', type: TransactionType.income),
  CustomCategory(
      id: 'lainnya_in',
      name: 'Lainnya',
      emoji: '💰',
      type: TransactionType.income),
];

final List<CustomCategory> _defaultExpenseCategories = [
  CustomCategory(
      id: 'makan', name: 'Makan', emoji: '🍜', type: TransactionType.expense),
  CustomCategory(
      id: 'transport',
      name: 'Transport',
      emoji: '🚗',
      type: TransactionType.expense),
  CustomCategory(
      id: 'belanja',
      name: 'Belanja',
      emoji: '🛍️',
      type: TransactionType.expense),
  CustomCategory(
      id: 'hiburan',
      name: 'Hiburan',
      emoji: '🎮',
      type: TransactionType.expense),
  CustomCategory(
      id: 'kesehatan',
      name: 'Kesehatan',
      emoji: '🏥',
      type: TransactionType.expense),
  CustomCategory(
      id: 'pendidikan',
      name: 'Pendidikan',
      emoji: '📚',
      type: TransactionType.expense),
  CustomCategory(
      id: 'tagihan',
      name: 'Tagihan',
      emoji: '📄',
      type: TransactionType.expense),
  CustomCategory(
      id: 'lainnya_ex',
      name: 'Lainnya',
      emoji: '💸',
      type: TransactionType.expense),
];

class FinanceProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  UserProfile _profile = UserProfile.defaultProfile;
  bool _isLoading = true;
  List<CustomCategory> _incomeCategories = List.from(_defaultIncomeCategories);
  List<CustomCategory> _expenseCategories =
      List.from(_defaultExpenseCategories);

  List<Transaction> get transactions => _transactions;
  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  List<CustomCategory> get incomeCategories => _incomeCategories;
  List<CustomCategory> get expenseCategories => _expenseCategories;

  // FIX UNTUK CHART
  List<DateTime> get last6Months {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
  }

  Map<int, double> get monthlyExpense {
    final Map<int, double> data = {};
    for (var d in last6Months) {
      data[d.month] = _transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.month == d.month &&
              t.date.year == d.year)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
    return data;
  }

  Map<int, double> get monthlyIncome {
    final Map<int, double> data = {};
    for (var d in last6Months) {
      data[d.month] = _transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.month == d.month &&
              t.date.year == d.year)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
    return data;
  }

  double get totalBalance => totalIncome - totalExpense;
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);
  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);
  double get thisMonthExpense => _transactions
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.month == DateTime.now().month)
      .fold(0.0, (s, t) => s + t.amount);

  double get todayExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get thisMonthIncome => _transactions
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.month == DateTime.now().month)
      .fold(0.0, (s, t) => s + t.amount);

  List<Transaction> get recentTransactions {
    final s = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return s.take(10).toList();
  }

  Map<String, double> get expenseByCategory {
    final Map<String, double> r = {};
    for (var t
        in _transactions.where((t) => t.type == TransactionType.expense)) {
      r[t.category] = (r[t.category] ?? 0) + t.amount;
    }
    return r;
  }

  // ─── CRUD ACTIONS ───

  // NEW: tambahan parameter currency
  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? note,
    String baseCurrency = 'IDR',
    String? originalCurrency,
    double? originalAmount,
    double? exchangeRate,
  }) async {
    _transactions.add(Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
      note: note,
      baseCurrency: baseCurrency,
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      exchangeRate: exchangeRate,
    ));
    notifyListeners();
    await _save();
  }

  // NEW: update existing transaction
  Future<void> updateTransaction(Transaction updated) async {
    final idx = _transactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _transactions[idx] = updated;
    notifyListeners();
    await _save();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clearAllTransactions() async {
    _transactions.clear();
    notifyListeners();
    await _save();
  }

  // ─── REBASE: Konversi semua transaksi ke mata uang baru ───
  // Dipanggil saat user ganti defaultCurrency di settings.
  // Mengembalikan jumlah transaksi yang berhasil dikonversi,
  // atau -1 jika gagal fetch kurs (network error).
  Future<int> rebaseAllTransactions({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return 0;
    if (_transactions.isEmpty) return 0;

    // Ambil rate sekali untuk semua transaksi (1 API call)
    final testResult = await CurrencyService.convert(
      amount: 1.0,
      from: fromCurrency,
      to: toCurrency,
    );
    if (testResult == null) return -1; // network error

    final rate = testResult.rate; // berapa [toCurrency] per 1 [fromCurrency]
    int converted = 0;

    _transactions = _transactions.map((tx) {
      // Hanya konversi transaksi yang baseCurrency-nya sama dengan fromCurrency
      if (tx.baseCurrency != fromCurrency) return tx;

      final newAmount = tx.amount * rate;

      // Jika transaksi punya originalCurrency, konversi rate-nya juga
      double? newExchangeRate;
      if (tx.hasConversion && tx.originalCurrency != null) {
        // Rate lama: 1 originalCurrency = exchangeRate fromCurrency
        // Rate baru: 1 originalCurrency = exchangeRate * rate toCurrency
        newExchangeRate = (tx.exchangeRate ?? 1.0) * rate;
      }

      converted++;
      return tx.copyWith(
        amount: newAmount,
        baseCurrency: toCurrency,
        exchangeRate: newExchangeRate ?? tx.exchangeRate,
      );
    }).toList();

    notifyListeners();
    await _save();
    return converted;
  }

  void addCategory(CustomCategory c) {
    if (c.type == TransactionType.income)
      _incomeCategories.add(c);
    else
      _expenseCategories.add(c);
    notifyListeners();
    _saveCategories();
  }

  void editCategory(String id, String name, String emoji) {
    for (var l in [_incomeCategories, _expenseCategories]) {
      int i = l.indexWhere((c) => c.id == id);
      if (i != -1) {
        l[i] =
            CustomCategory(id: id, name: name, emoji: emoji, type: l[i].type);
        break;
      }
    }
    notifyListeners();
    _saveCategories();
  }

  void deleteCategory(String id) {
    _incomeCategories.removeWhere((c) => c.id == id);
    _expenseCategories.removeWhere((c) => c.id == id);
    notifyListeners();
    _saveCategories();
  }

  Future<void> updateProfile(UserProfile p) async {
    _profile = p;
    notifyListeners();
    await _saveProfile();
  }

  // ─── LOAD & SAVE ───

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final tx = prefs.getString('transactions');
    if (tx != null)
      _transactions =
          (json.decode(tx) as List).map((e) => Transaction.fromMap(e)).toList();
    final pr = prefs.getString('profile');
    if (pr != null) _profile = UserProfile.fromJson(pr);
    final ct = prefs.getString('all_categories');
    if (ct != null) {
      final all = (json.decode(ct) as List)
          .map((e) => CustomCategory.fromMap(e))
          .toList();
      _incomeCategories =
          all.where((c) => c.type == TransactionType.income).toList();
      _expenseCategories =
          all.where((c) => c.type == TransactionType.expense).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    p.setString('transactions',
        json.encode(_transactions.map((t) => t.toMap()).toList()));
  }

  Future<void> _saveProfile() async {
    final p = await SharedPreferences.getInstance();
    p.setString('profile', _profile.toJson());
  }

  Future<void> _saveCategories() async {
    final p = await SharedPreferences.getInstance();
    p.setString(
        'all_categories',
        json.encode([..._incomeCategories, ..._expenseCategories]
            .map((c) => c.toMap())
            .toList()));
  }
}
