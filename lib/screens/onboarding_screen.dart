import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../models/user_profile.dart';
import '../utils/theme.dart';
import '../animations/animated_widgets.dart';

// ─── Reusable avatar widget (dipakai juga di dashboard & profile) ───
class UserAvatar extends StatelessWidget {
  final UserProfile profile;
  final double size;
  final double fontSize;

  const UserAvatar({
    super.key,
    required this.profile,
    this.size = 46,
    this.fontSize = 20,
  });

  static const _avatarColors = [
    Color(0xFF6EE7B7),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFFA3E635),
  ];

  Color get _bgColor =>
      _avatarColors[profile.avatarColorIndex % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.imagePath != null && profile.imagePath!.isNotEmpty;
    if (hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.file(
          File(profile.imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgColor, _bgColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: _bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String get _initials {
    final name = profile.name.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Onboarding Screen ───
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Step: 0 = profil, 1 = tema
  int _step = 0;

  // Step 1 – Profil
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  int _selectedColorIndex = 0;
  String? _imagePath;
  bool _loading = false;

  // Step 2 – Tema
  bool _isDark = true;
  int _accentIndex = 0;
  NavBarStyle _navBarStyle = NavBarStyle.solid;

  static const _avatarColors = [
    Color(0xFF6EE7B7),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFFB923C),
    Color(0xFFA78BFA),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFFA3E635),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _removePhoto() => setState(() => _imagePath = null);

  void _nextStep() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final finance = context.read<FinanceProvider>();
    final sp = context.read<SettingsProvider>();

    await finance.updateProfile(UserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: '',
      avatarEmoji: '',
      avatarColorIndex: _selectedColorIndex,
      imagePath: _imagePath,
      joinDate: DateTime.now(),
    ));

    await sp.setDark(_isDark);
    await sp.setAccent(_accentIndex);
    await sp.setNavBarStyle(_navBarStyle);

    widget.onDone();
  }

  String get _previewInitials {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color get _selectedColor =>
      _avatarColors[_selectedColorIndex % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final previewTheme =
        AppTheme(isDark: _isDark, accent: accentPresets[_accentIndex].color);

    return Scaffold(
      backgroundColor: previewTheme.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: _step == 0
            ? _buildProfileStep(previewTheme)
            : _buildThemeStep(previewTheme),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 1 – PROFIL
  // ══════════════════════════════════════════════════════════════

  Widget _buildProfileStep(AppTheme theme) {
    return SafeArea(
      key: const ValueKey('profile_step'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.accent, theme.accent.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 28,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

            const SizedBox(height: 28),

            _StepIndicator(current: 0, total: 2, theme: theme)
                .animate(delay: 80.ms)
                .fadeIn(),

            const SizedBox(height: 20),

            Text(
              'Selamat datang',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.textPrimary,
              ),
            ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.05),

            const SizedBox(height: 6),

            Text(
              'Lengkapi profil kamu untuk memulai',
              style: TextStyle(
                fontSize: 15,
                color: theme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 36),

            // ── Avatar Preview + Photo Picker ──
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        _imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.file(
                                  File(_imagePath!),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : AnimatedContainer(
                                duration: 200.ms,
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _selectedColor,
                                      _selectedColor.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedColor.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _previewInitials,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                        // Camera badge
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.bg, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: theme.isDark
                                  ? const Color(0xFF0D0F14)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TapScale(
                        onTap: _pickImage,
                        child: Text(
                          'Pilih Foto',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_imagePath != null) ...[
                        Text('  •  ', style: TextStyle(color: theme.textMuted)),
                        TapScale(
                          onTap: _removePhoto,
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 24),

            // ── Color Picker (hanya tampil jika belum pilih foto) ──
            if (_imagePath == null) ...[
              Text(
                'Warna avatar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: theme.textMuted,
                  letterSpacing: .5,
                ),
              ).animate(delay: 260.ms).fadeIn(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_avatarColors.length, (i) {
                  final selected = _selectedColorIndex == i;
                  return TapScale(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: 150.ms,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _avatarColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _avatarColors[i].withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ).animate(delay: 280.ms).fadeIn(),
              const SizedBox(height: 24),
            ],

            // ── Input fields ──
            _field(
              _nameCtrl,
              'Nama lengkap *',
              Icons.person_outline_rounded,
              theme,
            ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 14),

            _field(
              _emailCtrl,
              'Email (opsional)',
              Icons.mail_outline_rounded,
              theme,
              keyboardType: TextInputType.emailAddress,
            ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 36),

            // ── Tombol Lanjut ──
            TapScale(
              onTap: _nameCtrl.text.trim().isEmpty ? null : _nextStep,
              child: AnimatedContainer(
                duration: 200.ms,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _nameCtrl.text.trim().isEmpty
                      ? theme.accent.withOpacity(0.4)
                      : theme.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _nameCtrl.text.trim().isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: theme.accent.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.isDark
                            ? const Color(0xFF0D0F14)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color:
                          theme.isDark ? const Color(0xFF0D0F14) : Colors.white,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  STEP 2 – TEMA
  // ══════════════════════════════════════════════════════════════

  Widget _buildThemeStep(AppTheme theme) {
    return SafeArea(
      key: const ValueKey('theme_step'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Tombol Back
            TapScale(
              onTap: () => setState(() => _step = 0),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: theme.textPrimary,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            _StepIndicator(current: 1, total: 2, theme: theme)
                .animate(delay: 60.ms)
                .fadeIn(),

            const SizedBox(height: 20),

            Text(
              'Personalisasi Tema',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.textPrimary,
              ),
            ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.05),

            const SizedBox(height: 6),

            Text(
              'Pilih tampilan yang kamu suka',
              style: TextStyle(
                fontSize: 15,
                color: theme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 32),

            // ── Mode Gelap / Terang ──
            _sectionLabel('Mode Tampilan', theme),
            const SizedBox(height: 12),
            Row(
              children: [
                _ModeCard(
                  label: 'Gelap',
                  emoji: '🌙',
                  selected: _isDark,
                  onTap: () => setState(() => _isDark = true),
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _ModeCard(
                  label: 'Terang',
                  emoji: '☀️',
                  selected: !_isDark,
                  onTap: () => setState(() => _isDark = false),
                  theme: theme,
                ),
              ],
            ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 28),

            // ── Warna Aksen ──
            _sectionLabel('Warna Aksen', theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(accentPresets.length, (i) {
                final preset = accentPresets[i];
                final selected = _accentIndex == i;
                return TapScale(
                  onTap: () => setState(() => _accentIndex = i),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: preset.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: preset.color.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            preset.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 28),

            // ── Gaya Navbar ──
            _sectionLabel('Gaya Navbar', theme),
            const SizedBox(height: 12),
            Column(
              children: [
                _NavStyleCard(
                  label: 'Solid',
                  description: 'Bar penuh di bawah layar',
                  icon: Icons.table_rows_rounded,
                  style: NavBarStyle.solid,
                  selected: _navBarStyle == NavBarStyle.solid,
                  onTap: () => setState(() => _navBarStyle = NavBarStyle.solid),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _NavStyleCard(
                  label: 'Floating',
                  description: 'Bar melayang dengan sudut bulat',
                  icon: Icons.flip_to_front_rounded,
                  style: NavBarStyle.floating,
                  selected: _navBarStyle == NavBarStyle.floating,
                  onTap: () =>
                      setState(() => _navBarStyle = NavBarStyle.floating),
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _NavStyleCard(
                  label: 'Minimal',
                  description: 'Ikon saja tanpa label teks',
                  icon: Icons.remove_rounded,
                  style: NavBarStyle.minimal,
                  selected: _navBarStyle == NavBarStyle.minimal,
                  onTap: () =>
                      setState(() => _navBarStyle = NavBarStyle.minimal),
                  theme: theme,
                ),
              ],
            ).animate(delay: 260.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 36),

            // ── Tombol Mulai ──
            TapScale(
              onTap: _loading ? null : _submit,
              child: AnimatedContainer(
                duration: 200.ms,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Mulai',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _isDark
                                    ? const Color(0xFF0D0F14)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.rocket_launch_rounded,
                              size: 18,
                              color: _isDark
                                  ? const Color(0xFF0D0F14)
                                  : Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────

  Widget _sectionLabel(String text, AppTheme theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: theme.textMuted,
        letterSpacing: .5,
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    AppTheme theme, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: theme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: theme.textMuted, size: 20),
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  HELPER WIDGETS (di luar class state)
// ══════════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final AppTheme theme;

  const _StepIndicator({
    required this.current,
    required this.total,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                (done || active) ? theme.accent : theme.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;

  const _ModeCard({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TapScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? theme.accent.withOpacity(0.15) : theme.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.accent : theme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? theme.accent : theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavStyleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final NavBarStyle style;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;

  const _NavStyleCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.style,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? theme.accent.withOpacity(0.1) : theme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.accent : theme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? theme.accent.withOpacity(0.2)
                    : theme.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? theme.accent : theme.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? theme.accent : theme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: theme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
