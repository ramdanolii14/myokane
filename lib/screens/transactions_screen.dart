import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../animations/animated_widgets.dart';
import '../screens/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'Semua';
  String _search = '';
  final filters = ['Semua', 'Pemasukan', 'Pengeluaran'];

  // ─── Long press context menu ───
  void _showContextMenu(
      BuildContext context, Transaction tx, AppTheme theme) async {
    final sp = context.read<SettingsProvider>();
    sp.triggerHaptic(type: HapticType.heavy);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              // Transaction preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Text(_emoji(tx.category),
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textPrimary)),
                          Text(formatDate(tx.date),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Text(
                      '${tx.type == TransactionType.income ? '+' : '-'}${formatCurrencyWithCode(tx.amount, sp.settings.defaultCurrency)}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: tx.type == TransactionType.income
                              ? incomeColor
                              : expenseColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Edit button
              _ActionTile(
                icon: Icons.edit_rounded,
                label: 'Edit Transaksi',
                color: theme.accent,
                theme: theme,
                onTap: () async {
                  Navigator.pop(context);
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddTransactionSheet(editTransaction: tx),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Delete button
              _ActionTile(
                icon: Icons.delete_rounded,
                label: 'Hapus Transaksi',
                color: expenseColor,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, tx, theme);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, Transaction tx, AppTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Transaksi?',
            style: TextStyle(
                color: theme.textPrimary, fontWeight: FontWeight.w900)),
        content: Text('Transaksi "${tx.title}" akan dihapus permanen.',
            style:
                TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color: theme.textMuted, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(
                    color: expenseColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<FinanceProvider>().deleteTransaction(tx.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi dihapus',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: theme.textPrimary)),
          backgroundColor: theme.surface2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        final filtered = finance.transactions.where((tx) {
          final mf = _filter == 'Semua' ||
              (_filter == 'Pemasukan' && tx.type == TransactionType.income) ||
              (_filter == 'Pengeluaran' && tx.type == TransactionType.expense);
          final ms = _search.isEmpty ||
              tx.title.toLowerCase().contains(_search.toLowerCase()) ||
              tx.category.toLowerCase().contains(_search.toLowerCase());
          return mf && ms;
        }).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: theme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: theme.textMuted, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            // Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: filters.asMap().entries.map((e) {
                  final active = _filter == e.value;
                  return TapScale(
                    onTap: () => setState(() => _filter = e.value),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? theme.accent : theme.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active ? theme.accent : theme.border),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? (theme.isDark
                                      ? const Color(0xFF0D0F14)
                                      : Colors.white)
                                  : theme.textMuted)),
                    ),
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 100.ms),

            // Long press hint
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text('${filtered.length} transaksi',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.touch_app_rounded,
                      size: 11, color: theme.textMuted),
                  const SizedBox(width: 4),
                  Text('Tahan untuk edit/hapus',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? _empty(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final tx = filtered[i];
                        final showDate =
                            i == 0 || !_sameDay(filtered[i - 1].date, tx.date);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDate)
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: 8, top: i > 0 ? 16 : 0),
                                child: Text(formatDate(tx.date),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: theme.textMuted,
                                        letterSpacing: .5)),
                              ),
                            // Long press wrapper
                            GestureDetector(
                              onLongPress: () =>
                                  _showContextMenu(context, tx, theme),
                              child: TransactionCard(
                                tx: tx,
                                theme: theme,
                                animIndex: i,
                                enableSwipeDelete: true,
                                onDelete: () =>
                                    finance.deleteTransaction(tx.id),
                                onEdit: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      AddTransactionSheet(editTransaction: tx),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  Widget _empty(AppTheme theme) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: const TextStyle(fontSize: 60))
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Tidak ada transaksi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimary)),
            const SizedBox(height: 8),
            Text('Coba ubah filter atau kata kunci',
                style: TextStyle(fontSize: 13, color: theme.textMuted)),
          ],
        ),
      );
}

// ─── Context menu action tile ───
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppTheme theme;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}
