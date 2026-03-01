import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../animations/animated_widgets.dart';
import '../screens/onboarding_screen.dart' show UserAvatar;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Tracks which alert level was dismissed. Once dismissed, won't re-appear
  // unless the level escalates (near → over).
  String? _dismissedLevel;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    final currency = sp.settings.defaultCurrency;

    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        if (finance.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final dailyBudget = sp.settings.dailyBudget;
        final todayExp = finance.todayExpense;

        // Determine alert level
        _BudgetAlertLevel? alertLevel;
        if (dailyBudget > 0) {
          final ratio = todayExp / dailyBudget;
          if (todayExp >= dailyBudget) {
            alertLevel = _BudgetAlertLevel.over;
          } else if (ratio >= 0.8) {
            alertLevel = _BudgetAlertLevel.near;
          }
        }

        // If level escalated from near → over, reset dismiss so user sees it once more
        if (_dismissedLevel == _BudgetAlertLevel.near.name &&
            alertLevel == _BudgetAlertLevel.over) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _dismissedLevel = null);
          });
        }

        final showBanner =
            alertLevel != null && _dismissedLevel != alertLevel.name;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(finance, theme)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.05),
              const SizedBox(height: 24),

              // ─── Budget Alert Banner ───
              if (showBanner) ...[
                _BudgetAlertBanner(
                  level: alertLevel!,
                  todayExpense: todayExp,
                  dailyBudget: dailyBudget,
                  theme: theme,
                  currency: currency,
                  onDismiss: () {
                    setState(() {
                      _dismissedLevel = alertLevel!.name;
                    });
                  },
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.08, curve: Curves.easeOut),
                const SizedBox(height: 16),
              ],

              _buildBalanceCard(
                      finance, theme, sp.settings.showBalanceOnHome, currency)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 16),
              _buildIncomeExpenseRow(finance, theme, currency)
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .slideY(begin: 0.05),

              // ─── Daily Budget Progress Card ───
              if (dailyBudget > 0) ...[
                const SizedBox(height: 16),
                _buildDailyBudgetCard(finance, theme, dailyBudget, currency)
                    .animate(delay: 250.ms)
                    .fadeIn()
                    .slideY(begin: 0.05),
              ],

              const SizedBox(height: 24),
              _buildMonthSummary(finance, theme, currency)
                  .animate(delay: 280.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'Transaksi Terbaru',
                theme: theme,
              ).animate(delay: 340.ms).fadeIn(),
              const SizedBox(height: 12),
              if (finance.recentTransactions.isEmpty)
                _buildEmptyTransactions(theme).animate(delay: 380.ms).fadeIn()
              else
                ...finance.recentTransactions
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (e) => TransactionCard(
                        tx: e.value,
                        theme: theme,
                        animIndex: e.key,
                        onDelete: () => finance.deleteTransaction(e.value.id),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ─── Daily Budget Progress Card ───
  Widget _buildDailyBudgetCard(FinanceProvider finance, AppTheme theme,
      double dailyBudget, String currency) {
    final todayExp = finance.todayExpense;
    final ratio = (todayExp / dailyBudget).clamp(0.0, 1.0);
    final isOver = todayExp >= dailyBudget;
    final isNear = ratio >= 0.8 && !isOver;
    final progressColor = isOver
        ? Colors.redAccent
        : isNear
            ? Colors.orangeAccent
            : Colors.green.shade400;
    final remaining = dailyBudget - todayExp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOver
              ? Colors.redAccent.withOpacity(0.4)
              : isNear
                  ? Colors.orangeAccent.withOpacity(0.4)
                  : theme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.today_rounded,
                        size: 15, color: progressColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PENGELUARAN HARI INI',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                isOver
                    ? '⚠ MELEWATI BATAS'
                    : '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: theme.border,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dipakai',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700)),
                  Text(
                    formatCurrencyWithCode(todayExp, currency),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: progressColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isOver ? 'Kelebihan' : 'Sisa',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700)),
                  Text(
                    isOver
                        ? '+ ${formatCurrencyWithCode(todayExp - dailyBudget, currency)}'
                        : formatCurrencyWithCode(remaining, currency),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isOver ? Colors.redAccent : incomeColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Batas',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700)),
                  Text(
                    formatCurrencyWithCode(dailyBudget, currency),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FinanceProvider finance, AppTheme theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
            ? 'Selamat Siang'
            : 'Selamat Malam';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting 👋',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textMuted,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              finance.profile.name.isEmpty ? 'Pengguna' : finance.profile.name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimary),
            ),
          ],
        ),
        TapScale(
          child: UserAvatar(
            profile: finance.profile,
            size: 46,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(FinanceProvider finance, AppTheme theme,
      bool showBalance, String currency) {
    final isNegative = finance.totalBalance < 0;
    final badgeColor = isNegative ? Colors.redAccent : theme.accent;
    final badgeLabel = isNegative ? '⚠ MINUS' : 'AKTIF';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardGradientStart, theme.cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isNegative ? Colors.redAccent.withOpacity(0.5) : theme.cardBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              width: 32,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL SALDO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: theme.textMuted,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: badgeColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            showBalance
                ? AnimatedNumber(
                    value: finance.totalBalance,
                    formatter: (v) => formatCurrencyWithCode(v, currency),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  )
                : Text(
                    '••••••••',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.textMuted,
                    ),
                  ),
            const SizedBox(height: 20),
            Container(height: 1, color: theme.cardBorder),
            const SizedBox(height: 16),
            Row(
              children: [
                _balanceStatItem(
                  label: 'Total Masuk',
                  value: formatCurrencyWithCode(finance.totalIncome, currency),
                  color: incomeColor,
                  icon: Icons.arrow_downward_rounded,
                  theme: theme,
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: theme.cardBorder,
                ),
                _balanceStatItem(
                  label: 'Total Keluar',
                  value: formatCurrencyWithCode(finance.totalExpense, currency),
                  color: expenseColor,
                  icon: Icons.arrow_upward_rounded,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required AppTheme theme,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.textMuted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(
      FinanceProvider finance, AppTheme theme, String currency) {
    return Row(
      children: [
        _monthStatCard(
          label: 'Pemasukan Bulan Ini',
          value: finance.thisMonthIncome,
          color: incomeColor,
          icon: Icons.trending_up_rounded,
          theme: theme,
          currency: currency,
        ),
        const SizedBox(width: 12),
        _monthStatCard(
          label: 'Pengeluaran Bulan Ini',
          value: finance.thisMonthExpense,
          color: expenseColor,
          icon: Icons.trending_down_rounded,
          theme: theme,
          currency: currency,
        ),
      ],
    );
  }

  Widget _monthStatCard({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required AppTheme theme,
    required String currency,
  }) {
    return Expanded(
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
            Container(
              height: 3,
              width: 32,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedNumber(
              value: value,
              formatter: (v) => formatCurrencyWithCode(v, currency),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSummary(
      FinanceProvider finance, AppTheme theme, String currency) {
    final balance = finance.thisMonthIncome - finance.thisMonthExpense;
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RINGKASAN BULAN INI',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  color: theme.textMuted,
                ),
              ),
              Text(
                _monthName(DateTime.now().month),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: theme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow(
            label: 'Pemasukan',
            value: formatCurrencyWithCode(finance.thisMonthIncome, currency),
            color: incomeColor,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _summaryRow(
            label: 'Pengeluaran',
            value: formatCurrencyWithCode(finance.thisMonthExpense, currency),
            color: expenseColor,
            theme: theme,
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: theme.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selisih',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${formatCurrencyWithCode(balance, currency)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isPositive ? incomeColor : expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required Color color,
    required AppTheme theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildEmptyTransactions(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: theme.textMuted, size: 40),
          const SizedBox(height: 12),
          Text('Belum ada transaksi',
              style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER'
    ];
    return months[month];
  }
}

// ─── Budget Alert Level ───
enum _BudgetAlertLevel { near, over }

// ─── Budget Alert Banner Widget ───
class _BudgetAlertBanner extends StatelessWidget {
  final _BudgetAlertLevel level;
  final double todayExpense;
  final double dailyBudget;
  final AppTheme theme;
  final String currency;
  final VoidCallback onDismiss;

  const _BudgetAlertBanner({
    required this.level,
    required this.todayExpense,
    required this.dailyBudget,
    required this.theme,
    required this.currency,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = level == _BudgetAlertLevel.over;
    final bannerColor = isOver ? Colors.redAccent : Colors.orangeAccent;
    final icon = isOver ? Icons.warning_rounded : Icons.info_rounded;
    final title = isOver
        ? 'Batas Pengeluaran Terlampaui!'
        : 'Mendekati Batas Pengeluaran';
    final ratio = (todayExpense / dailyBudget * 100).toStringAsFixed(0);
    final subtitle = isOver
        ? 'Pengeluaran hari ini (${formatCurrencyWithCode(todayExpense, currency)}) sudah melewati batas ${formatCurrencyWithCode(dailyBudget, currency)}.'
        : 'Sudah $ratio% dari batas harian. Sisa ${formatCurrencyWithCode(dailyBudget - todayExpense, currency)}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerColor.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: bannerColor, size: 18),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: bannerColor.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dismiss button
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close_rounded, color: bannerColor, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
