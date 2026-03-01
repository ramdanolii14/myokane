import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../animations/animated_widgets.dart';
import '../services/currency_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final Transaction? editTransaction;
  const AddTransactionSheet({super.key, this.editTransaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  TransactionType _type = TransactionType.expense;
  String? _category;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late AnimationController _typeAnim;

  // ─── Currency ───
  late String _selectedCurrency;
  ConversionResult? _conversionResult;
  bool _loadingRate = false;

  bool get _isEditMode => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    _typeAnim = AnimationController(vsync: this, duration: 300.ms);

    final sp = context.read<SettingsProvider>();
    _selectedCurrency = sp.settings.defaultCurrency;

    if (_isEditMode) {
      final tx = widget.editTransaction!;
      _type = tx.type;
      _category = tx.category;
      _titleCtrl.text = tx.title;
      _date = tx.date;
      _noteCtrl.text = tx.note ?? '';

      if (tx.hasConversion) {
        _selectedCurrency = tx.originalCurrency!;
        _amountCtrl.text = tx.originalAmount!.toStringAsFixed(
          tx.originalCurrency == 'IDR' ? 0 : 2,
        );
        _conversionResult = ConversionResult(
          convertedAmount: tx.amount,
          rate: tx.exchangeRate!,
          from: tx.originalCurrency!,
          to: sp.settings.defaultCurrency,
        );
      } else {
        _amountCtrl.text = tx.amount.toStringAsFixed(
          sp.settings.defaultCurrency == 'IDR' ? 0 : 2,
        );
      }
    }

    _amountCtrl.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _typeAnim.dispose();
    super.dispose();
  }

  void _switchType(TransactionType t) {
    if (_type == t) return;
    setState(() {
      _type = t;
      _category = null;
    });
    _typeAnim.forward(from: 0);
    context.read<SettingsProvider>().triggerHaptic(type: HapticType.medium);
  }

  void _onAmountChanged() {
    final defaultCurrency =
        context.read<SettingsProvider>().settings.defaultCurrency;
    if (_selectedCurrency != defaultCurrency) {
      _fetchRate();
    }
  }

  Future<void> _fetchRate() async {
    final defaultCurrency =
        context.read<SettingsProvider>().settings.defaultCurrency;
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _conversionResult = null);
      return;
    }
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) return;

    setState(() => _loadingRate = true);

    final result = await CurrencyService.convert(
      amount: amount,
      from: _selectedCurrency,
      to: defaultCurrency,
    );

    if (mounted) {
      setState(() {
        _conversionResult = result;
        _loadingRate = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Pilih kategori dulu yaa 😊',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }

    final sp = context.read<SettingsProvider>();
    final defaultCurrency = sp.settings.defaultCurrency;
    final rawAmount = double.parse(_amountCtrl.text);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    double finalAmount;
    String? origCurrency;
    double? origAmount;
    double? rate;

    if (_selectedCurrency != defaultCurrency) {
      if (_conversionResult == null) {
        final result = await CurrencyService.convert(
          amount: rawAmount,
          from: _selectedCurrency,
          to: defaultCurrency,
        );
        if (result == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                  'Gagal mengambil kurs. Periksa koneksi internet.',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))));
          return;
        }
        if (result != null) {
          finalAmount = result.convertedAmount;
          origCurrency = _selectedCurrency;
          origAmount = rawAmount;
          rate = result.rate;
        } else {
          return;
        }
      } else {
        finalAmount = _conversionResult!.convertedAmount;
        origCurrency = _selectedCurrency;
        origAmount = rawAmount;
        rate = _conversionResult!.rate;
      }
    } else {
      finalAmount = rawAmount;
    }

    setState(() => _saving = true);
    sp.triggerHaptic(type: HapticType.heavy);

    final fp = context.read<FinanceProvider>();

    if (_isEditMode) {
      final updated = widget.editTransaction!.copyWith(
        title: _titleCtrl.text.trim(),
        amount: finalAmount,
        type: _type,
        category: _category!,
        date: _date,
        note: note,
        baseCurrency: defaultCurrency,
        originalCurrency: origCurrency,
        originalAmount: origAmount,
        exchangeRate: rate,
      );
      await fp.updateTransaction(updated);
    } else {
      await fp.addTransaction(
        title: _titleCtrl.text.trim(),
        amount: finalAmount,
        type: _type,
        category: _category!,
        date: _date,
        note: note,
        baseCurrency: defaultCurrency,
        originalCurrency: origCurrency,
        originalAmount: origAmount,
        exchangeRate: rate,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.read<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    final defaultCurrency = sp.settings.defaultCurrency;
    final fp = context.watch<FinanceProvider>();
    final cats = _type == TransactionType.income
        ? fp.incomeCategories
        : fp.expenseCategories;
    final typeColor =
        _type == TransactionType.income ? incomeColor : expenseColor;
    final defaultCurrencyInfo = getCurrencyInfo(defaultCurrency);

    return Container(
      decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: DraggableScrollableSheet(
        initialChildSize: 1,
        expand: false,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: theme.border,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(_isEditMode ? 'Edit Transaksi' : 'Catat Transaksi',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: theme.textPrimary))
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.05),

                const SizedBox(height: 20),
                // Type switcher
                Container(
                  decoration: BoxDecoration(
                      color: theme.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border)),
                  child: Row(children: [
                    _typeBtn(TransactionType.income, '📥  Pemasukan', theme),
                    _typeBtn(TransactionType.expense, '📤  Pengeluaran', theme)
                  ]),
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 20),
                _label('JUMLAH', theme),

                // Currency picker + amount field
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          _showCurrencyPicker(context, theme, defaultCurrency),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedCurrency != defaultCurrency
                                ? theme.accent
                                : theme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getCurrencyInfo(_selectedCurrency).symbol,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _selectedCurrency != defaultCurrency
                                    ? theme.accent
                                    : typeColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCurrency,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more_rounded,
                                size: 16, color: theme.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.textPrimary),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                              color: theme.textMuted,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                          filled: true,
                          fillColor: theme.surface2,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: theme.accent, width: 2)),
                          errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: expenseColor)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Masukkan jumlah';
                          final d = double.tryParse(v);
                          if (d == null || d <= 0) return 'Jumlah tidak valid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 140.ms),

                // Conversion info box
                if (_selectedCurrency != defaultCurrency) ...[
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.accent.withOpacity(0.3)),
                    ),
                    child: _loadingRate
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: theme.accent),
                              ),
                              const SizedBox(width: 10),
                              Text('Mengambil kurs...',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textMuted,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        : _conversionResult != null
                            ? Row(
                                children: [
                                  Icon(Icons.swap_horiz_rounded,
                                      size: 16, color: theme.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      // FIX: gunakan _formatRate agar IDR tampil dengan pemisah ribuan
                                      '1 $_selectedCurrency ≈ ${_formatRate(_conversionResult!.rate, defaultCurrency)} $defaultCurrency  →  ${defaultCurrencyInfo.symbol}${_formatConverted(_conversionResult!.convertedAmount, defaultCurrency)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.accent,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 14, color: theme.textMuted),
                                  const SizedBox(width: 8),
                                  Text('Ketuk jumlah untuk lihat konversi',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textMuted,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                  ),
                ],

                const SizedBox(height: 16),
                _label('KETERANGAN', theme),
                TextFormField(
                  controller: _titleCtrl,
                  style: TextStyle(
                      color: theme.textPrimary, fontWeight: FontWeight.w700),
                  decoration: _inputDeco('Contoh: Makan siang, Gaji...', theme),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Masukkan keterangan' : null,
                ).animate().fadeIn(delay: 180.ms),

                const SizedBox(height: 16),
                _label('KATEGORI', theme),
                AnimatedSwitcher(
                  duration: 250.ms,
                  child: Wrap(
                    key: ValueKey(_type),
                    spacing: 8,
                    runSpacing: 8,
                    children: cats.map((cat) {
                      final active = _category == cat.name;
                      return TapScale(
                        onTap: () => setState(() => _category = cat.name),
                        child: AnimatedContainer(
                          duration: 150.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? typeColor.withOpacity(0.18)
                                : theme.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: active ? typeColor : theme.border),
                          ),
                          child: Text(
                            '${cat.emoji} ${cat.name}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? theme.textPrimary
                                    : theme.textMuted),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 220.ms),

                const SizedBox(height: 16),
                _label('TANGGAL', theme),
                TapScale(
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                            colorScheme: ColorScheme.dark(
                                primary: theme.accent,
                                surface: theme.surface2)),
                        child: child!,
                      ),
                    );
                    if (p != null) setState(() => _date = p);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: theme.textMuted),
                        const SizedBox(width: 10),
                        Text(formatDate(_date),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.textPrimary)),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: theme.textMuted),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 260.ms),

                const SizedBox(height: 16),
                _label('CATATAN (OPSIONAL)', theme),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: TextStyle(
                      color: theme.textPrimary, fontWeight: FontWeight.w600),
                  decoration: _inputDeco('Tambahkan catatan...', theme),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),
                TapScale(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: theme.accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.isDark
                                      ? const Color(0xFF0D0F14)
                                      : Colors.white))
                          : Text(
                              _isEditMode
                                  ? 'Simpan Perubahan'
                                  : 'Simpan Transaksi',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: theme.isDark
                                      ? const Color(0xFF0D0F14)
                                      : Colors.white)),
                    ),
                  ),
                ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format rate dengan pemisah ribuan — penting untuk IDR yang angkanya besar
  /// Contoh: 16801.0 → "16.801" (IDR), 0.000059 → "0.000059" (BTC style)
  String _formatRate(double rate, String toCurrency) {
    if (rate >= 1000) {
      // Untuk mata uang dengan rate besar (IDR, KRW, JPY, dll) — pakai pemisah ribuan
      return NumberFormat('#,###', 'id_ID').format(rate.round());
    } else if (rate >= 1) {
      return NumberFormat('#,##0.##', 'id_ID').format(rate);
    } else {
      // Rate kecil (< 1), tampilkan desimal yang cukup
      return rate.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '');
    }
  }

  /// Format converted amount dengan pemisah ribuan sesuai mata uang
  String _formatConverted(double amount, String currency) {
    if (currency == 'IDR' || currency == 'KRW' || currency == 'JPY') {
      // Mata uang tanpa desimal — pakai pemisah ribuan
      return NumberFormat('#,###', 'id_ID').format(amount.round());
    }
    return NumberFormat('#,##0.##', 'id_ID').format(amount);
  }

  void _showCurrencyPicker(
      BuildContext context, AppTheme theme, String defaultCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Pilih Mata Uang',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary)),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: theme.border),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: supportedCurrencies.length,
                  itemBuilder: (_, i) {
                    final c = supportedCurrencies[i];
                    final isDefault = c.code == defaultCurrency;
                    final isSelected = c.code == _selectedCurrency;
                    return TapScale(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = c.code;
                          _conversionResult = null;
                        });
                        Navigator.pop(context);
                        if (c.code != defaultCurrency &&
                            _amountCtrl.text.isNotEmpty) {
                          _fetchRate();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accent.withOpacity(0.12)
                              : theme.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isSelected ? theme.accent : theme.border),
                        ),
                        child: Row(
                          children: [
                            Text(c.symbol,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? theme.accent
                                        : theme.textPrimary)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.code,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: theme.textPrimary)),
                                  Text(c.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.textMuted,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Default',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: theme.accent)),
                              ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.check_circle_rounded,
                                    color: theme.accent, size: 20),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _typeBtn(TransactionType type, String label, AppTheme theme) {
    final active = _type == type;
    final color = type == TransactionType.income ? incomeColor : expenseColor;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(type),
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : Colors.transparent),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? color : theme.textMuted)),
        ),
      ),
    );
  }

  Widget _label(String t, AppTheme theme) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.textMuted,
                letterSpacing: .5)),
      );

  InputDecoration _inputDeco(String hint, AppTheme theme) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
        filled: true,
        fillColor: theme.surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.accent)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
