import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../utils/theme.dart';
import '../animations/animated_widgets.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  bool _error = false;
  int _attempts = 0;
  static const int _maxAttempts = 5;
  static const int _cooldownSeconds = 30;

  // Cooldown
  int _cooldownLeft = 0;
  Timer? _cooldownTimer;

  // Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  bool get _isLocked => _cooldownLeft > 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownLeft = _cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownLeft--;
        if (_cooldownLeft <= 0) {
          t.cancel();
          _attempts = 0;
          _error = false;
        }
      });
    });
  }

  void _onKey(String val) {
    if (_isLocked || _input.length >= 6) return;
    setState(() {
      _input += val;
      _error = false;
    });
    if (_input.length == 6) {
      _checkPin();
    }
  }

  void _onDelete() {
    if (_isLocked || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _checkPin() {
    final sp = context.read<SettingsProvider>();
    final correct = sp.settings.pinCode;
    if (_input == correct) {
      widget.onUnlocked();
    } else {
      _attempts++;
      _shakeCtrl.forward(from: 0);
      if (_attempts >= _maxAttempts) {
        setState(() {
          _error = false;
          _input = '';
        });
        _startCooldown();
      } else {
        setState(() {
          _error = true;
          _input = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [theme.accent, theme.accent.withOpacity(0.6)]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                      child: Text(
                    _isLocked ? '🔒' : '🔐',
                    style: const TextStyle(fontSize: 36),
                  )),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLocked ? 'Akses Dikunci' : 'Masukkan PIN',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary),
                ),
                const SizedBox(height: 8),

                // Status text
                if (_isLocked) ...[
                  Text(
                    'Terlalu banyak percobaan gagal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Countdown chip
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_rounded,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Coba lagi dalam $_cooldownLeft detik',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    _error
                        ? 'PIN salah! ${_maxAttempts - _attempts}x percobaan tersisa'
                        : 'Masukkan PIN kamu',
                    style: TextStyle(
                      fontSize: 14,
                      color: _error ? Colors.redAccent : theme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // PIN dots with shake
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) {
                    final offset = _error
                        ? 8 *
                            (0.5 -
                                (_shakeAnim.value - _shakeAnim.value.floor()))
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset * 12, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < _input.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? (_error ? Colors.redAccent : theme.accent)
                              : _isLocked
                                  ? Colors.redAccent.withOpacity(0.3)
                                  : theme.border,
                          border: Border.all(
                              color:
                                  filled ? Colors.transparent : theme.border),
                        ),
                      );
                    }),
                  ),
                ),

                // Attempt indicator dots
                if (!_isLocked && _attempts > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxAttempts, (i) {
                      final used = i < _attempts;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: used
                              ? Colors.redAccent
                              : Colors.redAccent.withOpacity(0.2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_maxAttempts - _attempts} percobaan tersisa',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.redAccent.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                // Numpad
                _buildNumpad(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(AppTheme theme) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 72);
            final disabled = _isLocked;
            return TapScale(
              onTap: disabled
                  ? null
                  : () {
                      if (key == '⌫') {
                        _onDelete();
                      } else {
                        _onKey(key);
                      }
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: disabled ? 0.35 : 1.0,
                child: Container(
                  width: 80,
                  height: 72,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: key == '⌫' ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
