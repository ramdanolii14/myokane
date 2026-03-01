import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../animations/animated_widgets.dart';

class SaldoScreen extends StatelessWidget {
  const SaldoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    final currency = sp.settings.defaultCurrency;
    return Consumer<FinanceProvider>(
      builder: (ctx, finance, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [theme.cardGradientStart, theme.cardGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                        color: theme.accent.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 15))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('SALDO TERSEDIA',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                    const SizedBox(height: 16),
                    BounceIn(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.accent,
                            theme.accent.withOpacity(0.6)
                          ]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: theme.accent.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: const Center(
                            child: Text('💰', style: TextStyle(fontSize: 36))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    sp.settings.showBalanceOnHome
                        ? AnimatedNumber(
                            value: finance.totalBalance,
                            formatter: (v) =>
                                formatCurrencyWithCode(v, currency),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: finance.totalBalance >= 0
                                  ? theme.textPrimary
                                  : expenseColor,
                            ),
                          )
                        : Text('••••••••',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: theme.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: finance.totalBalance >= 0
                            ? incomeColor.withOpacity(0.12)
                            : expenseColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              finance.totalBalance >= 0
                                  ? Icons.verified_rounded
                                  : Icons.warning_rounded,
                              size: 14,
                              color: finance.totalBalance >= 0
                                  ? incomeColor
                                  : expenseColor),
                          const SizedBox(width: 6),
                          Text(
                              finance.totalBalance >= 0
                                  ? 'Keuangan Anda Sehat'
                                  : 'Pengeluaran Melebihi Pemasukan',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: finance.totalBalance >= 0
                                      ? incomeColor
                                      : expenseColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),
              Row(
                children: [
                  _card(
                          '📥',
                          'Total Masuk',
                          finance.totalIncome,
                          incomeColor,
                          '${finance.transactions.where((t) => t.type.index == 0).length} transaksi',
                          theme,
                          currency)
                      .animate(delay: 120.ms)
                      .fadeIn()
                      .slideX(begin: -0.05),
                  const SizedBox(width: 12),
                  _card(
                          '📤',
                          'Total Keluar',
                          finance.totalExpense,
                          expenseColor,
                          '${finance.transactions.where((t) => t.type.index == 1).length} transaksi',
                          theme,
                          currency)
                      .animate(delay: 160.ms)
                      .fadeIn()
                      .slideX(begin: 0.05),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _card('📅', 'Masuk Bulan Ini', finance.thisMonthIncome,
                          theme.accent, 'Bulan berjalan', theme, currency)
                      .animate(delay: 200.ms)
                      .fadeIn()
                      .slideX(begin: -0.05),
                  const SizedBox(width: 12),
                  _card(
                          '🧾',
                          'Keluar Bulan Ini',
                          finance.thisMonthExpense,
                          const Color(0xFFF472B6),
                          'Bulan berjalan',
                          theme,
                          currency)
                      .animate(delay: 240.ms)
                      .fadeIn()
                      .slideX(begin: 0.05),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Pie Chart Pemasukan & Pengeluaran ───
              Align(
                  alignment: Alignment.centerLeft,
                  child:
                      SectionTitle(title: 'Distribusi Keuangan', theme: theme)),
              const SizedBox(height: 14),
              _pieChartSection(finance, theme, currency) // ← tambah currency
                  .animate(delay: 260.ms)
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: 24),

              Align(
                  alignment: Alignment.centerLeft,
                  child: SectionTitle(title: 'Rasio keuangan', theme: theme)),
              const SizedBox(height: 14),
              _savingsRate(finance, theme)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: 24),

              Align(
                  alignment: Alignment.centerLeft,
                  child:
                      SectionTitle(title: 'Ringkasan Bulanan', theme: theme)),
              const SizedBox(height: 14),
              _monthlySummary(finance, theme, currency)
                  .animate(delay: 380.ms)
                  .fadeIn(duration: 500.ms),
            ],
          ),
        );
      },
    );
  }

  // ─── Stat Card ───
  Widget _card(String emoji, String label, double amount, Color color,
      String sub, AppTheme theme, String currency) {
    return Expanded(
      child: TapScale(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle))
              ]),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatCurrencyWithCode(amount, currency),
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color))),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 10, color: theme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pie Chart Section ───
  // FIX: tambah parameter currency agar bisa dipakai di dalam method
  Widget _pieChartSection(FinanceProvider f, AppTheme theme, String currency) {
    final totalIn = f.totalIncome;
    final totalEx = f.totalExpense;
    final total = totalIn + totalEx;
    final incomeRatio = total > 0 ? totalIn / total : 0.0;
    final expenseRatio = total > 0 ? totalEx / total : 0.0;

    return Row(
      children: [
        // Income Pie
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                Text('Pemasukan',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: incomeRatio),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => CustomPaint(
                      painter: _PieChartPainter(
                        ratio: v,
                        activeColor: incomeColor,
                        bgColor: theme.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(incomeRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: incomeColor),
                ),
                const SizedBox(height: 2),
                Text(formatCurrencyWithCode(totalIn, currency),
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Expense Pie
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                Text('Pengeluaran',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: expenseRatio),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => CustomPaint(
                      painter: _PieChartPainter(
                        ratio: v,
                        activeColor: expenseColor,
                        bgColor: theme.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(expenseRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: expenseColor),
                ),
                const SizedBox(height: 2),
                Text(formatCurrencyWithCode(totalEx, currency),
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Savings Rate ───
  Widget _savingsRate(FinanceProvider f, AppTheme theme) {
    final rate = f.totalIncome > 0
        ? ((f.totalBalance / f.totalIncome) * 100).clamp(0, 100).toDouble()
        : 0.0;
    final rateColor = rate >= 30
        ? incomeColor
        : rate >= 10
            ? const Color(0xFFFBBF24)
            : expenseColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${rate.toStringAsFixed(0)}% dari total pemasukan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary)),
              Text(
                  rate >= 30
                      ? '🟢 Bagus'
                      : rate >= 10
                          ? '🟡 Cukup'
                          : '🔴 Kurang',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rate / 100),
            duration: 800.ms,
            curve: Curves.easeOut,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: theme.border,
                  valueColor: AlwaysStoppedAnimation(rateColor)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rate >= 30
                ? 'Luar biasa! Anda menabung ${rate.toStringAsFixed(0)}% dari penghasilan.'
                : rate >= 10
                    ? 'Cukup baik! Coba tingkatkan tabungan Anda.'
                    : 'Perlu perhatian. Kurangi pengeluaran tidak perlu.',
            style: TextStyle(
                fontSize: 12,
                color: theme.textMuted,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Summary ───
  Widget _monthlySummary(FinanceProvider f, AppTheme theme, String currency) {
    final me = f.monthlyExpense;
    final mi = f.monthlyIncome;
    final months = f.last6Months;
    return Container(
      decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border)),
      child: Column(
        children: months.asMap().entries.map((entry) {
          final monthDate = entry.value;
          final inc = mi[monthDate.month] ?? 0;
          final exp = me[monthDate.month] ?? 0;
          final net = inc - exp;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
                border: Border(
                    bottom: entry.key < months.length - 1
                        ? BorderSide(color: theme.border)
                        : BorderSide.none)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(formatMonth(monthDate.month),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.textMuted))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Masuk: ${formatCurrencyWithCode(inc, currency)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: incomeColor,
                              fontWeight: FontWeight.w700)),
                      Text('Keluar: ${formatCurrencyWithCode(exp, currency)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: expenseColor,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Net',
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.textMuted,
                            fontWeight: FontWeight.w700)),
                    Text(formatCurrencyWithCode(net, currency),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: net >= 0 ? incomeColor : expenseColor)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Pie Chart Painter ───
class _PieChartPainter extends CustomPainter {
  final double ratio;
  final Color activeColor;
  final Color bgColor;

  _PieChartPainter({
    required this.ratio,
    required this.activeColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (ratio > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -1.5707963,
        ratio * 6.2831853,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.ratio != ratio || old.activeColor != activeColor;
}
