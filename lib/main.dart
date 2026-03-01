import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Providers
import 'providers/finance_provider.dart';
import 'providers/settings_provider.dart';

// Models
import 'models/app_settings.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/saldo_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_banner.dart';

// Utils & Animations
import 'utils/theme.dart';
import 'animations/animated_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Setup Provider secara manual untuk memanggil load data di awal
  final settingsProvider = SettingsProvider();
  final financeProvider = FinanceProvider();

  // Pastikan data dimuat sebelum runApp agar tidak terjadi "White Screen" atau data kosong
  await Future.wait([
    settingsProvider.load(),
    financeProvider.loadData(),
  ]);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: financeProvider),
      ],
      child: const DompetkulApp(),
    ),
  );
}

class DompetkulApp extends StatefulWidget {
  const DompetkulApp({super.key});

  @override
  State<DompetkulApp> createState() => _DompetkulAppState();
}

class _DompetkulAppState extends State<DompetkulApp> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, FinanceProvider>(
      builder: (context, sp, finance, _) {
        // Pengecekan loading
        if (!sp.isLoaded || finance.isLoading) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final appThemeData = buildAppTheme(sp.settings);

        // LOGIKA PENENTUAN HALAMAN UTAMA
        Widget home;

        // Cek apakah user baru (nama kosong)
        if (finance.profile.name.isEmpty) {
          home = OnboardingScreen(
            onDone: () {
              // Provider notifyListeners() akan trigger rebuild otomatis
              // karena DompetkulApp menggunakan Consumer2
            },
          );
        } else if (sp.settings.securityMode != SecurityMode.none &&
            !_unlocked) {
          home = LockScreen(onUnlocked: () {
            setState(() => _unlocked = true);
          });
        } else {
          home = const HomeShell();
        }

        return AnimatedTheme(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          data: appThemeData.toThemeData(),
          child: MaterialApp(
            title: 'MyOkane',
            debugShowCheckedModeBanner: false,
            theme: appThemeData.toThemeData(),
            home: home,
            builder: (ctx, child) {
              return AnimatedSwitcher(
                duration: 300.ms,
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _navAnim;

  final _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    SaldoScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavItem(Icons.grid_view_rounded, 'Dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'Transaksi'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Saldo'),
    _NavItem(Icons.person_rounded, 'Profil'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _navAnim = List.generate(
      5,
      (idx) => AnimationController(
        vsync: this,
        duration: 300.ms,
        value: idx == 0 ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _navAnim) c.dispose();
    super.dispose();
  }

  void _onNav(int idx) {
    if (_currentIndex == idx) return;
    context.read<SettingsProvider>().triggerHaptic(type: HapticType.selection);

    _navAnim[_currentIndex].reverse();
    setState(() => _currentIndex = idx);
    _navAnim[idx].forward();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final settings = sp.settings;
    final appTheme = buildAppTheme(settings);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            appTheme.isDark ? Brightness.light : Brightness.dark,
      ),
      child: UpdateBannerWrapper(
        theme: appTheme,
        child: AnimatedContainer(
          duration: 400.ms,
          color: appTheme.bg,
          child: Scaffold(
            backgroundColor: appTheme.bg,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: _AppBar(theme: appTheme, pageIndex: _currentIndex),
            ),
            body: AnimatedSwitcher(
              duration: 280.ms,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0.03, 0), end: Offset.zero)
                      .animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
            floatingActionButton: _buildFAB(appTheme),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: _buildNavBar(appTheme, settings),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(AppTheme theme) {
    return TapScale(
      onTap: _showAddTransaction,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.accent, theme.accent.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          size: 28,
          color: theme.isDark ? const Color(0xFF0D0F14) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildNavBar(AppTheme theme, AppSettings settings) {
    switch (settings.navBarStyle) {
      case NavBarStyle.floating:
        return _FloatingNavBar(
            theme: theme,
            current: _currentIndex,
            items: _navItems,
            onTap: _onNav,
            anims: _navAnim);
      case NavBarStyle.solid:
        return _SolidNavBar(
            theme: theme,
            current: _currentIndex,
            items: _navItems,
            onTap: _onNav,
            anims: _navAnim);
      case NavBarStyle.minimal:
        return _MinimalNavBar(
            theme: theme,
            current: _currentIndex,
            items: _navItems,
            onTap: _onNav,
            anims: _navAnim);
    }
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

// ── AppBar Widget ──
class _AppBar extends StatelessWidget {
  final AppTheme theme;
  final int pageIndex;

  const _AppBar({required this.theme, required this.pageIndex});

  static const _titles = [
    'Dashboard',
    'Transaksi',
    'Saldo',
    'Profil',
    'Pengaturan'
  ];

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: theme.bg,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [theme.accent, theme.accent.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: 200.ms,
                child: Text(
                  _titles[pageIndex],
                  key: ValueKey(pageIndex),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary),
                ),
              ),
              const Spacer(),
              TapScale(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                      size: 20, color: theme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolidNavBar extends StatelessWidget {
  final AppTheme theme;
  final int current;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final List<AnimationController> anims;

  const _SolidNavBar({
    required this.theme,
    required this.current,
    required this.items,
    required this.onTap,
    required this.anims,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: _buildNavList(items, theme, current, onTap, anims),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final AppTheme theme;
  final int current;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final List<AnimationController> anims;

  const _FloatingNavBar({
    required this.theme,
    required this.current,
    required this.items,
    required this.onTap,
    required this.anims,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12 + 8),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: _buildNavList(items, theme, current, onTap, anims),
        ),
      ),
    );
  }
}

class _MinimalNavBar extends StatelessWidget {
  final AppTheme theme;
  final int current;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;
  final List<AnimationController> anims;

  const _MinimalNavBar({
    required this.theme,
    required this.current,
    required this.items,
    required this.onTap,
    required this.anims,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      color: theme.bg,
      child: Row(
        children:
            _buildNavList(items, theme, current, onTap, anims, minimal: true),
      ),
    );
  }
}

List<Widget> _buildNavList(
  List<_NavItem> items,
  AppTheme theme,
  int current,
  ValueChanged<int> onTap,
  List<AnimationController> anims, {
  bool minimal = false,
}) {
  return items.asMap().entries.map((e) {
    final idx = e.key;
    final active = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: 250.ms,
              padding: EdgeInsets.symmetric(
                  horizontal: minimal ? 8 : 12, vertical: 4),
              decoration: BoxDecoration(
                color: active && !minimal
                    ? theme.accent.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: anims[idx], curve: Curves.elasticOut),
                ),
                child: Icon(
                  e.value.icon,
                  size: 22,
                  color: active ? theme.accent : theme.textMuted,
                ),
              ),
            ),
            if (!minimal) ...[
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: 200.ms,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? theme.accent : theme.textMuted,
                ),
                child: Text(e.value.label),
              ),
            ] else ...[
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: 250.ms,
                width: active ? 4 : 0,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ],
        ),
      ),
    );
  }).toList();
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
