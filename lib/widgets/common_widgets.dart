import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../animations/animated_widgets.dart';
import '../services/currency_service.dart';

// ─── Transaction Card with animation ───
class TransactionCard extends StatelessWidget {
  final Transaction tx;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final AppTheme theme;
  final int animIndex;
  final bool enableSwipeDelete;

  const TransactionCard({
    super.key,
    required this.tx,
    required this.theme,
    this.onDelete,
    this.onEdit,
    this.animIndex = 0,
    this.enableSwipeDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    // Read current default currency from settings
    final currency = context.read<SettingsProvider>().settings.defaultCurrency;

    Widget card = TapScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (isIncome ? incomeColor : expenseColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_emoji(tx.category),
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: theme.textPrimary)),
                      const SizedBox(height: 3),
                      Text(
                        '${tx.category} • ${formatDateShort(tx.date)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      // Display using the transaction's baseCurrency so amounts
                      // always show with the correct symbol regardless of what
                      // the user's current default currency setting is.
                      '${isIncome ? '+' : '-'}${formatCurrencyWithCode(tx.amount, tx.baseCurrency)}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isIncome ? incomeColor : expenseColor),
                    ),
                    // Show original currency if this was a cross-currency entry
                    if (tx.hasConversion)
                      Text(
                        '${getCurrencyInfo(tx.originalCurrency!).symbol}${_formatOriginal(tx.originalAmount!, tx.originalCurrency!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    // Show a subtle badge if baseCurrency differs from current default
                    if (!tx.hasConversion && tx.baseCurrency != currency)
                      Text(
                        tx.baseCurrency,
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.accent.withOpacity(0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ─── Note ───
            if (tx.note != null && tx.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 12, color: theme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tx.note!,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Conversion info pill ───
            if (tx.hasConversion) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: 11, color: theme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Kurs: 1 ${tx.originalCurrency} ≈ ${tx.exchangeRate!.toStringAsFixed(tx.exchangeRate! < 1 ? 6 : 2)} ${tx.baseCurrency}',
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (enableSwipeDelete) {
      card = Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: expenseColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_rounded, color: expenseColor),
        ),
        child: card,
      );
    }

    return card
        .animate(delay: Duration(milliseconds: 60 * animIndex))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }

  String _formatOriginal(double amount, String currency) {
    if (currency == 'IDR' || currency == 'JPY' || currency == 'KRW') {
      return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return amount.toStringAsFixed(2);
  }

  String _emoji(String cat) {
    const map = {
      'Gaji': '💼',
      'Freelance': '💻',
      'Investasi': '📈',
      'Bisnis': '🏪',
      'Hadiah': '🎁',
      'Makan': '🍜',
      'Transport': '🚗',
      'Belanja': '🛍️',
      'Hiburan': '🎮',
      'Kesehatan': '🏥',
      'Pendidikan': '📚',
      'Tagihan': '📄',
    };
    return map[cat] ?? '💰';
  }
}

// ─── Section Title ───
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final AppTheme? theme;

  const SectionTitle(
      {super.key, required this.title, this.trailing, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: t?.textPrimary ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Stats Mini Card ───
class StatsMiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  final AppTheme theme;

  const StatsMiniCard({
    super.key,
    required this.label,
    required this.amount,
    required this.isIncome,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currency = context.read<SettingsProvider>().settings.defaultCurrency;

    return Expanded(
      child: TapScale(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (isIncome ? incomeColor : expenseColor)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isIncome ? incomeColor : expenseColor,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedNumber(
                value: amount,
                formatter: (v) => formatCurrencyWithCode(v, currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isIncome ? incomeColor : expenseColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Themed SnackBar helper ───
SnackBar themedSnack(String msg, AppTheme theme) => SnackBar(
      content: Text(msg,
          style:
              TextStyle(fontWeight: FontWeight.w700, color: theme.textPrimary)),
      backgroundColor: theme.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );
