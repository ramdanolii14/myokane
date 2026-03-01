import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/finance_provider.dart';
import '../models/app_settings.dart';
import '../utils/theme.dart';
import '../animations/animated_widgets.dart';
import '../services/update_checker.dart';
import '../services/currency_service.dart';
import '../utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  final Future<String> _currentVersion = UpdateChecker.currentVersion;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    final info = await UpdateChecker.check();
    if (mounted) {
      setState(() {
        _updateInfo = info;
        _isCheckingUpdate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, sp, _) {
        final s = sp.settings;
        final theme = buildAppTheme(s);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(theme: theme, title: 'Tampilan', children: [
                // Dark / Light mode toggle
                _SettingTile(
                  theme: theme,
                  icon: s.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Mode Tampilan',
                  subtitle: s.isDark ? 'Mode Gelap aktif' : 'Mode Terang aktif',
                  onTap: () => sp.setDark(!s.isDark),
                  trailing: _AnimatedSwitch(
                    value: s.isDark,
                    accent: theme.accent,
                    onChanged: (v) => sp.setDark(v),
                  ),
                ),
                _Divider(theme: theme),

                // Accent color picker
                _SettingTile(
                  theme: theme,
                  icon: Icons.palette_rounded,
                  title: 'Warna Aksen',
                  subtitle: '${s.accent.emoji} ${s.accent.name}',
                  trailing: GestureDetector(
                    onTap: () => _showAccentPicker(context, sp, theme),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: theme.accent.withOpacity(0.5),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ),
                _Divider(theme: theme),

                // Nav bar style
                _SettingTile(
                  theme: theme,
                  icon: Icons.navigation_rounded,
                  title: 'Gaya Nav Bar',
                  subtitle: _navStyleName(s.navBarStyle),
                  onTap: () => _showNavStylePicker(context, sp, theme),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.textMuted, size: 18),
                ),
              ]),
              _Section(theme: theme, title: 'Keamanan', children: [
                _SettingTile(
                  theme: theme,
                  icon: Icons.pin_rounded,
                  title: 'PIN',
                  subtitle: s.securityMode == SecurityMode.pin
                      ? 'Aktif ✓'
                      : 'Nonaktif',
                  onTap: () => _showSetPin(context, sp, theme),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.textMuted, size: 18),
                ),
                if (s.securityMode != SecurityMode.none) ...[
                  _Divider(theme: theme),
                  _SettingTile(
                    theme: theme,
                    icon: Icons.lock_open_rounded,
                    title: 'Nonaktifkan Semua Kunci',
                    titleColor: expenseColor,
                    subtitle: 'Hapus semua metode keamanan',
                    onTap: () => _confirmDisableSecurity(context, sp, theme),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: theme.textMuted, size: 18),
                  ),
                ],
              ]),

              // ─── NEW: Mata Uang ───
              _Section(theme: theme, title: 'Mata Uang', children: [
                _SettingTile(
                  theme: theme,
                  icon: Icons.currency_exchange_rounded,
                  title: 'Mata Uang Utama',
                  subtitle: () {
                    final info = getCurrencyInfo(s.defaultCurrency);
                    return '${info.symbol}  ${s.defaultCurrency} — ${info.name}';
                  }(),
                  onTap: () => _showCurrencyPicker(context, sp, theme),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.textMuted, size: 18),
                ),
              ]),

              _Section(theme: theme, title: 'Anggaran', children: [
                _SettingTile(
                  theme: theme,
                  icon: Icons.today_rounded,
                  title: 'Batas Pengeluaran Harian',
                  subtitle: s.dailyBudget > 0
                      ? formatCurrency(s.dailyBudget)
                      : 'Belum diset',
                  onTap: () => _showDailyBudgetPicker(context, sp, theme),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: theme.textMuted, size: 18),
                ),
              ]),

              _Section(theme: theme, title: 'Pengalaman', children: [
                _SettingTile(
                  theme: theme,
                  icon: Icons.vibration_rounded,
                  title: 'Getaran / Haptic',
                  subtitle: 'Feedback saat menekan tombol',
                  onTap: () => sp.setHaptic(!s.hapticFeedback),
                  trailing: _AnimatedSwitch(
                    value: s.hapticFeedback,
                    accent: theme.accent,
                    onChanged: (v) => sp.setHaptic(v),
                  ),
                ),
                _Divider(theme: theme),
                _SettingTile(
                  theme: theme,
                  icon: Icons.visibility_rounded,
                  title: 'Tampilkan Saldo di Beranda',
                  subtitle: 'Sembunyikan saldo untuk privasi',
                  onTap: () => sp.setShowBalance(!s.showBalanceOnHome),
                  trailing: _AnimatedSwitch(
                    value: s.showBalanceOnHome,
                    accent: theme.accent,
                    onChanged: (v) => sp.setShowBalance(v),
                  ),
                ),
              ]),
              _Section(theme: theme, title: 'Tentang', children: [
                // ── Tempat 1: subtitle versi ──
                FutureBuilder<String>(
                  future: _currentVersion,
                  builder: (context, snap) {
                    final ver = snap.data ?? '...';
                    return _SettingTile(
                      theme: theme,
                      icon: Icons.info_rounded,
                      title: 'Versi Aplikasi',
                      subtitle: 'v$ver',
                      onTap: () => _showAboutMe(context, theme),
                      trailing: _buildUpdateBadge(theme),
                    );
                  },
                ),
                _Divider(theme: theme),
                _SettingTile(
                  theme: theme,
                  icon: Icons.system_update_rounded,
                  title: 'Cek Update',
                  subtitle: _updateStatusText(),
                  onTap: _isCheckingUpdate ? null : _checkUpdate,
                  trailing: _isCheckingUpdate
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: theme.accent),
                        )
                      : Icon(Icons.refresh_rounded,
                          color: theme.textMuted, size: 18),
                ),
                _Divider(theme: theme),
                _SettingTile(
                  theme: theme,
                  icon: Icons.code_rounded,
                  title: 'Official Github',
                  subtitle: 'github.com/ramdanolii14/myokane',
                  onTap: () async {
                    final url = Uri.parse(
                        'https://github.com/ramdanolii14/myokane/releases');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  trailing: Icon(Icons.open_in_new_rounded,
                      color: theme.textMuted, size: 16),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpdateBadge(AppTheme theme) {
    if (_isCheckingUpdate) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
      );
    }
    if (_updateInfo == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border),
        ),
        child: Text('...',
            style: TextStyle(
                fontSize: 11,
                color: theme.textMuted,
                fontWeight: FontWeight.w800)),
      );
    }
    if (_updateInfo!.hasUpdate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upgrade_rounded,
                size: 11, color: Colors.orangeAccent),
            const SizedBox(width: 4),
            Text('Update!',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Latest',
          style: TextStyle(
              fontSize: 11, color: theme.accent, fontWeight: FontWeight.w800)),
    );
  }

  String _updateStatusText() {
    if (_isCheckingUpdate) return 'Sedang mengecek...';
    if (_updateInfo == null) return 'Ketuk untuk cek update';
    if (_updateInfo!.isError)
      return _updateInfo!.errorMessage ?? 'Gagal cek update';
    if (_updateInfo!.hasUpdate) {
      return 'v${_updateInfo!.latestVersion} tersedia — ketuk untuk unduh';
    }
    return 'Aplikasi sudah versi terbaru ✓';
  }

  String _navStyleName(NavBarStyle s) {
    switch (s) {
      case NavBarStyle.floating:
        return 'Melayang (Floating)';
      case NavBarStyle.solid:
        return 'Solid';
      case NavBarStyle.minimal:
        return 'Minimal';
    }
  }

  void _showAccentPicker(
      BuildContext context, SettingsProvider sp, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        theme: theme,
        title: 'Pilih Warna Aksen',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _AccentPresetGrid(
            theme: theme,
            selected: sp.settings.accentIndex,
            onSelect: (i) {
              sp.setAccent(i);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _showNavStylePicker(
      BuildContext context, SettingsProvider sp, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        theme: theme,
        title: 'Gaya Navigation Bar',
        child: Column(
          children: NavBarStyle.values.map((style) {
            final active = sp.settings.navBarStyle == style;
            return TapScale(
              onTap: () {
                sp.setNavBarStyle(style);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      active ? theme.accent.withOpacity(0.15) : theme.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: active ? theme.accent : theme.border),
                ),
                child: Row(
                  children: [
                    Text(_navStyleIcon(style),
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _navStyleName(style),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: active ? theme.accent : theme.textPrimary),
                      ),
                    ),
                    if (active)
                      Icon(Icons.check_circle_rounded,
                          color: theme.accent, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _navStyleIcon(NavBarStyle s) {
    switch (s) {
      case NavBarStyle.floating:
        return '🫧';
      case NavBarStyle.solid:
        return '▬';
      case NavBarStyle.minimal:
        return '·';
    }
  }

  // ─── NEW: Currency Picker — pakai DraggableScrollableSheet agar bisa scroll ───
  void _showCurrencyPicker(
      BuildContext context, SettingsProvider sp, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // ── Fixed header ──
              const SizedBox(height: 12),
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Pilih Mata Uang Utama',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary)),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Semua transaksi disimpan dalam mata uang ini. '
                  'Kamu tetap bisa input dalam mata uang lain saat mencatat.',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.textMuted,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.border),
              // ── Scrollable list ──
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: supportedCurrencies.length,
                  itemBuilder: (_, i) {
                    final c = supportedCurrencies[i];
                    final isSelected = sp.settings.defaultCurrency == c.code;
                    return TapScale(
                      onTap: () async {
                        if (isSelected) {
                          Navigator.pop(context);
                          return;
                        }

                        final oldCurrency = sp.settings.defaultCurrency;
                        final fp = context.read<FinanceProvider>();
                        final hasTransactions = fp.transactions.isNotEmpty;

                        // Tutup bottom sheet dulu
                        Navigator.pop(context);

                        // Tanya konfirmasi jika ada transaksi
                        if (hasTransactions) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text('Konversi Transaksi?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: theme.textPrimary)),
                              content: Text(
                                'Semua ${fp.transactions.length} transaksi akan dikonversi dari $oldCurrency ke ${c.code} menggunakan kurs saat ini.\n\nProses ini tidak bisa dibatalkan.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Batal',
                                      style: TextStyle(color: theme.textMuted)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Konversi',
                                      style: TextStyle(
                                          color: theme.accent,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }

                        // Ganti currency di settings dulu
                        await sp.setCurrency(c.code);
                        CurrencyService.invalidateCache();

                        // Lakukan rebase jika ada transaksi
                        if (hasTransactions && context.mounted) {
                          // Tampilkan loading snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Mengkonversi transaksi ke ${c.code}...',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 10),
                              backgroundColor: theme.surface2,
                            ),
                          );

                          final result = await fp.rebaseAllTransactions(
                            fromCurrency: oldCurrency,
                            toCurrency: c.code,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result == -1
                                      ? '⚠ Gagal ambil kurs. Cek koneksi internet.'
                                      : result == 0
                                          ? '✅ Mata uang diubah ke ${c.code}'
                                          : '✅ $result transaksi dikonversi ke ${c.code}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: result == -1
                                    ? Colors.redAccent
                                    : theme.surface2,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );

                            // Jika gagal, kembalikan currency ke semula
                            if (result == -1) {
                              await sp.setCurrency(oldCurrency);
                            }
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accent.withOpacity(0.15)
                              : theme.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected ? theme.accent : theme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.accent.withOpacity(0.2)
                                    : theme.border.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  c.symbol,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? theme.accent
                                          : theme.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.code,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? theme.accent
                                              : theme.textPrimary)),
                                  Text(c.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.textMuted,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: theme.accent, size: 22)
                            else
                              Icon(Icons.radio_button_unchecked_rounded,
                                  color: theme.border, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetPin(BuildContext context, SettingsProvider sp, AppTheme theme) {
    String? firstPin;
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    bool confirming = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _BottomSheet(
          theme: theme,
          title: confirming ? 'Konfirmasi PIN' : 'Buat PIN Baru',
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              children: [
                Text(
                  confirming ? 'Masukkan PIN yang sama' : 'PIN 6 digit',
                  style: TextStyle(
                      color: theme.textMuted, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Pinput(
                  length: 6,
                  controller: confirming ? ctrl2 : ctrl1,
                  obscureText: true,
                  obscuringCharacter: '●',
                  autofocus: true,
                  defaultPinTheme: PinTheme(
                    width: 50,
                    height: 58,
                    textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary),
                    decoration: BoxDecoration(
                      color: theme.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.border, width: 1.5),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 50,
                    height: 58,
                    textStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.accent, width: 2),
                    ),
                  ),
                  onCompleted: (pin) {
                    if (!confirming) {
                      firstPin = pin;
                      setS(() => confirming = true);
                      ctrl2.clear();
                    } else {
                      if (pin == firstPin) {
                        sp.setPin(pin);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snack('✅ PIN berhasil diset!', theme),
                        );
                      } else {
                        ctrl2.clear();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          _snack('❌ PIN tidak cocok', theme),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDailyBudgetPicker(
      BuildContext context, SettingsProvider sp, AppTheme theme) {
    final ctrl = TextEditingController(
      text: sp.settings.dailyBudget > 0
          ? sp.settings.dailyBudget.toStringAsFixed(0)
          : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheet(
        theme: theme,
        title: 'Batas Pengeluaran Harian',
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan batas pengeluaran harian kamu. App akan memberi peringatan jika melebihi batas ini.',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Contoh: 100000',
                  hintStyle: TextStyle(
                      color: theme.textMuted, fontWeight: FontWeight.w600),
                  prefixText: '  ',
                  filled: true,
                  fillColor: theme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Reset button
                  if (sp.settings.dailyBudget > 0)
                    Expanded(
                      child: TapScale(
                        onTap: () {
                          sp.setDailyBudget(0);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: expenseColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: expenseColor.withOpacity(0.4)),
                          ),
                          child: const Center(
                            child: Text('Reset',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: expenseColor)),
                          ),
                        ),
                      ),
                    ),
                  if (sp.settings.dailyBudget > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TapScale(
                      onTap: () {
                        final val = double.tryParse(ctrl.text) ?? 0;
                        sp.setDailyBudget(val);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          _snack(
                              val > 0
                                  ? '✅ Batas harian diset: ${formatCurrency(val)}'
                                  : '✅ Batas harian dihapus',
                              theme),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('Simpan',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: theme.isDark
                                      ? const Color(0xFF0D0F14)
                                      : Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutMe(BuildContext context, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheet(
        theme: theme,
        title: 'Tentang Aplikasi',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              // App Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'res/mipmap-xxhdpi/ic_launcher.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.accent, theme.accent.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                        child: Icon(Icons.account_balance_wallet_rounded,
                            size: 38, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('MyOkane',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary)),
              const SizedBox(height: 4),
              Text('Your Financial Record Book',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.accent,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  'Aplikasi keuangan pribadi yang dibuat dengan menggunakan Flutter. '
                  'Dirancang untuk membantu kamu mengelola keuangan dengan mudah dan menyenangkan.',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // ── Tempat 2: chip versi di _showAboutMe ──
              Row(
                children: [
                  FutureBuilder<String>(
                    future: _currentVersion,
                    builder: (context, snap) {
                      final ver = snap.data ?? '...';
                      return _aboutChip(
                          'v$ver', Icons.rocket_launch_rounded, theme);
                    },
                  ),
                  const SizedBox(width: 10),
                  _aboutChip('Stable', Icons.verified_rounded, theme),
                  const SizedBox(width: 10),
                  _aboutChip('Flutter', Icons.flutter_dash_rounded, theme),
                ],
              ),

              // Update status banner
              if (_updateInfo != null) ...[
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _updateInfo!.hasUpdate
                        ? Colors.orangeAccent.withOpacity(0.12)
                        : incomeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _updateInfo!.hasUpdate
                          ? Colors.orangeAccent.withOpacity(0.4)
                          : incomeColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _updateInfo!.hasUpdate
                            ? Icons.upgrade_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: _updateInfo!.hasUpdate
                            ? Colors.orangeAccent
                            : incomeColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _updateInfo!.hasUpdate
                              ? 'Update tersedia: v${_updateInfo!.latestVersion}'
                              : 'Kamu sudah pakai versi terbaru ✓',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _updateInfo!.hasUpdate
                                ? Colors.orangeAccent
                                : incomeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Download update button (jika ada update)
              if (_updateInfo?.hasUpdate == true) ...[
                TapScale(
                  onTap: () async {
                    final url = Uri.parse(UpdateChecker.releasesUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.download_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Unduh Update',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Official Github button
              TapScale(
                onTap: () async {
                  final url = Uri.parse(
                      'https://github.com/ramdanolii14/myokane/releases');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _updateInfo?.hasUpdate == true
                        ? theme.surface2
                        : theme.accent,
                    borderRadius: BorderRadius.circular(16),
                    border: _updateInfo?.hasUpdate == true
                        ? Border.all(color: theme.border)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_rounded,
                          color: _updateInfo?.hasUpdate == true
                              ? theme.textMuted
                              : (theme.isDark
                                  ? const Color(0xFF0D0F14)
                                  : Colors.white),
                          size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Official Github',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _updateInfo?.hasUpdate == true
                                ? theme.textMuted
                                : (theme.isDark
                                    ? const Color(0xFF0D0F14)
                                    : Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutChip(String label, IconData icon, AppTheme theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.accent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.accent, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.accent)),
          ],
        ),
      ),
    );
  }

  void _confirmDisableSecurity(
      BuildContext context, SettingsProvider sp, AppTheme theme) {
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        theme: theme,
        title: 'Nonaktifkan Kunci?',
        content:
            'Semua metode keamanan akan dihapus. App bisa dibuka tanpa password.',
        confirmLabel: 'Nonaktifkan',
        confirmColor: expenseColor,
        onConfirm: () => sp.disableSecurity(),
      ),
    );
  }

  SnackBar _snack(String msg, AppTheme theme) => SnackBar(
        content: Text(msg,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: theme.textPrimary)),
        backgroundColor: theme.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      );
}

// ─── Helper widgets ───

class _Section extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final List<Widget> children;
  final int delay;

  const _Section(
      {required this.theme,
      required this.title,
      required this.children,
      this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.textMuted,
                  letterSpacing: .5),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05);
  }
}

class _SettingTile extends StatelessWidget {
  final AppTheme theme;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool Function()? onTileToggle; // ← dikembalikan, tidak dihapus lagi!

  const _SettingTile({
    required this.theme,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.onTileToggle,
  });

  @override
  Widget build(BuildContext context) {
    return RippleButton(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? theme.textPrimary),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppTheme theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: theme.border, indent: 70);
}

class _AnimatedSwitch extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _AnimatedSwitch(
      {required this.value, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: 250.ms,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: value ? accent : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: 250.ms,
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _AccentPresetGrid extends StatelessWidget {
  final AppTheme theme;
  final int selected;
  final ValueChanged<int> onSelect;

  const _AccentPresetGrid(
      {required this.theme, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .9,
      ),
      itemCount: accentPresets.length,
      itemBuilder: (_, i) {
        final preset = accentPresets[i];
        final active = selected == i;
        return TapScale(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: active ? preset.color.withOpacity(0.15) : theme.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? preset.color : theme.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: 200.ms,
                  width: active ? 32 : 26,
                  height: active ? 32 : 26,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: preset.color.withOpacity(0.5),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preset.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? preset.color : theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final Widget child;

  const _BottomSheet(
      {required this.theme, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimary)),
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StyledDialog extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String content;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _StyledDialog({
    required this.theme,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimary)),
            const SizedBox(height: 12),
            Text(content,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.5)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal',
                      style: TextStyle(
                          color: theme.textMuted, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: confirmColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
