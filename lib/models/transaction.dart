import 'dart:convert';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;

  /// Amount stored in [baseCurrency].
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;

  /// The currency in which [amount] is stored.
  /// Defaults to 'IDR' for old transactions (backward-compat).
  final String baseCurrency;

  // Multi-currency fields (optional)
  final String? originalCurrency; // currency user typed (e.g. 'USD')
  final double? originalAmount; // amount in originalCurrency
  final double? exchangeRate; // 1 originalCurrency = exchangeRate baseCurrency

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.baseCurrency = 'IDR',
    this.originalCurrency,
    this.originalAmount,
    this.exchangeRate,
  });

  bool get hasConversion =>
      originalCurrency != null &&
      originalAmount != null &&
      exchangeRate != null;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    String? baseCurrency,
    String? originalCurrency,
    double? originalAmount,
    double? exchangeRate,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      originalAmount: originalAmount ?? this.originalAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'baseCurrency': baseCurrency,
      'originalCurrency': originalCurrency,
      'originalAmount': originalAmount,
      'exchangeRate': exchangeRate,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      type: TransactionType.values[map['type']],
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      baseCurrency: map['baseCurrency'] ?? 'IDR',
      originalCurrency: map['originalCurrency'],
      originalAmount: map['originalAmount']?.toDouble(),
      exchangeRate: map['exchangeRate']?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());
  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));
}

class CategoryItem {
  final String name;
  final String emoji;
  final TransactionType type;

  const CategoryItem({
    required this.name,
    required this.emoji,
    required this.type,
  });
}

const List<CategoryItem> incomeCategories = [
  CategoryItem(name: 'Gaji', emoji: '💼', type: TransactionType.income),
  CategoryItem(name: 'Freelance', emoji: '💻', type: TransactionType.income),
  CategoryItem(name: 'Investasi', emoji: '📈', type: TransactionType.income),
  CategoryItem(name: 'Bisnis', emoji: '🏪', type: TransactionType.income),
  CategoryItem(name: 'Hadiah', emoji: '🎁', type: TransactionType.income),
  CategoryItem(name: 'Lainnya', emoji: '💰', type: TransactionType.income),
];

const List<CategoryItem> expenseCategories = [
  CategoryItem(name: 'Makan', emoji: '🍜', type: TransactionType.expense),
  CategoryItem(name: 'Transport', emoji: '🚗', type: TransactionType.expense),
  CategoryItem(name: 'Belanja', emoji: '🛍️', type: TransactionType.expense),
  CategoryItem(name: 'Hiburan', emoji: '🎮', type: TransactionType.expense),
  CategoryItem(name: 'Kesehatan', emoji: '🏥', type: TransactionType.expense),
  CategoryItem(name: 'Pendidikan', emoji: '📚', type: TransactionType.expense),
  CategoryItem(name: 'Tagihan', emoji: '📄', type: TransactionType.expense),
  CategoryItem(name: 'Lainnya', emoji: '💸', type: TransactionType.expense),
];
