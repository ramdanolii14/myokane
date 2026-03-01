import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_profile.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../animations/animated_widgets.dart';
import 'category_manage_screen.dart';
import 'settings_screen.dart';

const _avatarColors = [
  Color(0xFF6EE7B7),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFFFB923C),
  Color(0xFFA78BFA),
  Color(0xFFFBBF24),
];

const _avatarLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _avatarColor(int idx) =>
      _avatarColors[idx.clamp(0, _avatarColors.length - 1)];

  String _avatarLabel(UserProfile p) {
    if (p.name.isNotEmpty) return p.name[0].toUpperCase();
    return _avatarLabels[p.avatarColorIndex.clamp(0, _avatarLabels.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    final currency = sp.settings.defaultCurrency;
    return Consumer<FinanceProvider>(
      builder: (ctx, finance, _) {
        final p = finance.profile;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            children: [
              // ─── Hero Card with Cover Banner ───
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [theme.cardGradientStart, theme.cardGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.cardBorder),
                ),
                child: Column(
                  children: [
                    // Cover Banner 16:9
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: p.coverImagePath != null &&
                                    File(p.coverImagePath!).existsSync()
                                ? Image.file(
                                    File(p.coverImagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.accent.withOpacity(0.35),
                                          theme.accent.withOpacity(0.08),
                                          theme.cardGradientEnd,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: theme.accent.withOpacity(0.3),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                          ),
                          // Edit cover button (top-right)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: TapScale(
                              onTap: () =>
                                  _editProfile(context, theme, finance),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_camera_rounded,
                                        size: 13, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'Edit Sampul',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar overlapping cover
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Column(
                        children: [
                          TapScale(
                            onTap: () => _editProfile(context, theme, finance),
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: _avatarColor(p.avatarColorIndex),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: theme.cardGradientStart,
                                        width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              _avatarColor(p.avatarColorIndex)
                                                  .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8)),
                                    ],
                                  ),
                                  child: p.imagePath != null &&
                                          File(p.imagePath!).existsSync()
                                      ? ClipOval(
                                          child: Image.file(
                                            File(p.imagePath!),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _avatarLabel(p),
                                            style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                        color: theme.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: theme.cardGradientStart,
                                            width: 2)),
                                    child: const Icon(Icons.edit_rounded,
                                        size: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.name,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: theme.textPrimary),
                          ),
                          if (p.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              p.email,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard(Icons.receipt_long_rounded,
                      '${finance.transactions.length}', 'Transaksi', theme),
                  const SizedBox(width: 12),
                  _statCard(
                      Icons.account_balance_wallet_rounded,
                      formatCurrencyWithCode(finance.totalBalance, currency),
                      'Saldo',
                      theme),
                ],
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 20),
              _menuSection(theme, 'Akun', [
                _Item(Icons.person_rounded, 'Edit Profil',
                    () => _editProfile(context, theme, finance)),
                if (p.phone.isNotEmpty)
                  _Item(Icons.phone_android_rounded, p.phone, null),
                if (p.email.isNotEmpty)
                  _Item(Icons.email_rounded, p.email, null),
              ]).animate(delay: 160.ms).fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 16),
              _menuSection(theme, 'Kustomisasi', [
                _Item(
                    Icons.category_rounded,
                    'Kelola Kategori',
                    () => Navigator.push(
                        context, slideRoute(const CategoryManageScreen()))),
              ]).animate(delay: 220.ms).fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 16),
              _menuSection(theme, 'Data', [
                _Item(Icons.delete_outline_rounded, 'Hapus Semua Transaksi',
                    () => _confirmClear(context, theme, finance),
                    isDestructive: true),
              ]).animate(delay: 280.ms).fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 16),
              Text(
                'MyOkane v7.1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w600),
              ).animate(delay: 340.ms).fadeIn(),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(IconData icon, String value, String label, AppTheme theme) {
    return Expanded(
      child: TapScale(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: theme.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: theme.textPrimary))),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuSection(AppTheme theme, String title, List<_Item> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: theme.textMuted,
                  letterSpacing: .5)),
        ),
        Container(
          decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border)),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              return Column(
                children: [
                  RippleButton(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              size: 20,
                              color: item.isDestructive
                                  ? expenseColor
                                  : theme.textMuted),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Text(item.label,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: item.isDestructive
                                          ? expenseColor
                                          : theme.textPrimary),
                                  overflow: TextOverflow.ellipsis)),
                          if (item.onTap != null)
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: theme.textMuted),
                        ],
                      ),
                    ),
                  ),
                  if (e.key < items.length - 1)
                    Divider(height: 1, color: theme.border, indent: 54),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _editProfile(
      BuildContext context, AppTheme theme, FinanceProvider finance) {
    final p = finance.profile;
    final nameCtrl = TextEditingController(text: p.name);
    final emailCtrl = TextEditingController(text: p.email);
    final phoneCtrl = TextEditingController(text: p.phone);
    int selectedColor = p.avatarColorIndex;
    String? currentImagePath = p.imagePath;
    String? currentCoverPath = p.coverImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          decoration: BoxDecoration(
              color: theme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: theme.border,
                          borderRadius: BorderRadius.circular(2))),
                ),
                Text('Edit Profil',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary)),
                const SizedBox(height: 20),

                // ─── Foto Sampul ───
                Text('Foto Sampul',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textMuted)),
                const SizedBox(height: 8),
                TapScale(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 90);
                    if (picked == null) return;
                    final cropped = await ImageCropper().cropImage(
                      sourcePath: picked.path,
                      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
                      compressQuality: 85,
                      uiSettings: [
                        AndroidUiSettings(
                          toolbarTitle: 'Crop Sampul',
                          toolbarColor: theme.accent,
                          toolbarWidgetColor: Colors.white,
                          lockAspectRatio: true,
                          hideBottomControls: false,
                        ),
                        IOSUiSettings(
                          title: 'Crop Sampul',
                          aspectRatioLockEnabled: true,
                          resetAspectRatioEnabled: false,
                        ),
                      ],
                    );
                    if (cropped != null) {
                      setS(() => currentCoverPath = cropped.path);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: currentCoverPath != null &&
                              File(currentCoverPath!).existsSync()
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(currentCoverPath!),
                                    fit: BoxFit.cover),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded,
                                            size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Ganti',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: theme.surface2,
                                border: Border.all(color: theme.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: 32,
                                      color: theme.accent.withOpacity(0.6)),
                                  const SizedBox(height: 8),
                                  Text('Tambah Foto Sampul',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textMuted)),
                                  Text('Rasio 16:9 otomatis dicrop',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: theme.textMuted
                                              .withOpacity(0.6))),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                if (currentCoverPath != null) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () => setS(() => currentCoverPath = null),
                      child: Text('Hapus foto sampul',
                          style: TextStyle(
                              color: theme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // ─── Foto Profil ───
                Text('Foto Profil',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textMuted)),
                const SizedBox(height: 8),
                Center(
                  child: TapScale(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setS(() => currentImagePath = picked.path);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _avatarColors[selectedColor],
                            shape: BoxShape.circle,
                          ),
                          child: currentImagePath != null &&
                                  File(currentImagePath!).existsSync()
                              ? ClipOval(
                                  child: Image.file(
                                    File(currentImagePath!),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    nameCtrl.text.isNotEmpty
                                        ? nameCtrl.text[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                                color: theme.accent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: theme.surface, width: 2)),
                            child: const Icon(Icons.photo_camera_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setS(() => currentImagePath = picked.path);
                      }
                    },
                    child: Text('Pilih foto dari galeri',
                        style: TextStyle(
                            color: theme.accent, fontWeight: FontWeight.w700)),
                  ),
                ),
                if (currentImagePath != null) ...[
                  Center(
                    child: TextButton(
                      onPressed: () => setS(() => currentImagePath = null),
                      child: Text('Hapus foto',
                          style: TextStyle(
                              color: theme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  ),
                ],

                // Warna avatar (fallback kalau tidak ada foto)
                if (currentImagePath == null) ...[
                  const SizedBox(height: 4),
                  Text('Warna avatar',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_avatarColors.length, (i) {
                      final sel = selectedColor == i;
                      return TapScale(
                        onTap: () => setS(() => selectedColor = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _avatarColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  sel ? theme.textPrimary : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Fields ───
                _editField(
                    nameCtrl, 'Nama', Icons.person_outline_rounded, theme),
                const SizedBox(height: 12),
                _editField(
                    emailCtrl, 'Email', Icons.mail_outline_rounded, theme,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _editField(phoneCtrl, 'No. HP', Icons.phone_outlined, theme,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),

                // ─── Simpan ───
                TapScale(
                  onTap: () {
                    finance.updateProfile(UserProfile(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      avatarEmoji: nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim()[0].toUpperCase()
                          : _avatarLabels[selectedColor],
                      avatarColorIndex: selectedColor,
                      imagePath: currentImagePath,
                      coverImagePath: currentCoverPath,
                      joinDate: p.joinDate,
                    ));
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Text('Simpan',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.isDark
                                  ? const Color(0xFF0D0F14)
                                  : Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    AppTheme theme, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: theme.textMuted, fontWeight: FontWeight.w700),
        prefixIcon: Icon(icon, color: theme.textMuted, size: 18),
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
      ),
    );
  }

  void _confirmClear(
      BuildContext context, AppTheme theme, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: theme.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hapus Semua?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary)),
              const SizedBox(height: 12),
              Text('Semua transaksi dihapus permanen.',
                  style: TextStyle(
                      color: theme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal',
                          style: TextStyle(
                              color: theme.textMuted,
                              fontWeight: FontWeight.w800))),
                  const SizedBox(width: 8),
                  TapScale(
                    onTap: () {
                      finance.clearAllTransactions();
                      Navigator.pop(context);
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: expenseColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('Hapus',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
  const _Item(this.icon, this.label, this.onTap, {this.isDestructive = false});
}
