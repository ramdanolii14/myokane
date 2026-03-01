import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  bool get isDark => _settings.isDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_settings');
    if (raw != null) {
      _settings = AppSettings.fromJson(raw);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', _settings.toJson());
  }

  Future<void> setDark(bool v) async {
    _settings = _settings.copyWith(isDark: v);
    notifyListeners();
    await _save();
  }

  Future<void> setAccent(int idx) async {
    _settings = _settings.copyWith(accentIndex: idx);
    notifyListeners();
    await _save();
  }

  Future<void> setNavBarStyle(NavBarStyle s) async {
    _settings = _settings.copyWith(navBarStyle: s);
    notifyListeners();
    await _save();
  }

  Future<void> setSecurityMode(SecurityMode mode) async {
    _settings = _settings.copyWith(securityMode: mode);
    notifyListeners();
    await _save();
  }

  Future<void> setPin(String pin) async {
    _settings = _settings.copyWith(
      securityMode: SecurityMode.pin,
      pinCode: pin,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setPattern(List<int> pattern) async {
    _settings = _settings.copyWith(
      securityMode: SecurityMode.pattern,
      patternCode: pattern,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setBiometric(bool v) async {
    _settings = _settings.copyWith(
      biometricEnabled: v,
      securityMode: v ? SecurityMode.biometric : SecurityMode.none,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setHaptic(bool v) async {
    _settings = _settings.copyWith(hapticFeedback: v);
    notifyListeners();
    await _save();
  }

  Future<void> setShowBalance(bool v) async {
    _settings = _settings.copyWith(showBalanceOnHome: v);
    notifyListeners();
    await _save();
  }

  // ─── NEW: Currency ───
  Future<void> setCurrency(String code) async {
    _settings = _settings.copyWith(defaultCurrency: code);
    notifyListeners();
    await _save();
  }

  // ─── NEW: Daily Budget ───
  Future<void> setDailyBudget(double amount) async {
    _settings = _settings.copyWith(dailyBudget: amount);
    notifyListeners();
    await _save();
  }

  Future<void> disableSecurity() async {
    _settings = AppSettings(
      isDark: _settings.isDark,
      accentIndex: _settings.accentIndex,
      navBarStyle: _settings.navBarStyle,
      securityMode: SecurityMode.none,
      hapticFeedback: _settings.hapticFeedback,
      showBalanceOnHome: _settings.showBalanceOnHome,
      defaultCurrency: _settings.defaultCurrency,
      dailyBudget: _settings.dailyBudget,
    );
    notifyListeners();
    await _save();
  }

  void triggerHaptic({HapticType type = HapticType.light}) {
    if (!_settings.hapticFeedback) return;
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

enum HapticType { light, medium, heavy, selection }
