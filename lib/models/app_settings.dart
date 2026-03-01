import 'dart:convert';
import 'package:flutter/material.dart';

// ─── Accent Color Presets ───
class AccentPreset {
  final String name;
  final Color color;
  final String emoji;
  const AccentPreset(this.name, this.color, this.emoji);
}

const List<AccentPreset> accentPresets = [
  AccentPreset('Mint', Color(0xFF6EE7B7), '🌿'),
  AccentPreset('Ocean', Color(0xFF60A5FA), '🌊'),
  AccentPreset('Sakura', Color(0xFFF472B6), '🌸'),
  AccentPreset('Sunset', Color(0xFFFB923C), '🌅'),
  AccentPreset('Lavender', Color(0xFFA78BFA), '💜'),
  AccentPreset('Gold', Color(0xFFFBBF24), '✨'),
  AccentPreset('Coral', Color(0xFFF87171), '🪸'),
  AccentPreset('Lime', Color(0xFFA3E635), '🍋'),
];

// ─── Security Mode ───
enum SecurityMode { none, pin, pattern, biometric }

// ─── NavBar Style ───
enum NavBarStyle { floating, solid, minimal }

class AppSettings {
  final bool isDark;
  final int accentIndex;
  final SecurityMode securityMode;
  final String? pinCode;
  final List<int>? patternCode;
  final bool biometricEnabled;
  final NavBarStyle navBarStyle;
  final String navAccentHex;
  final bool hapticFeedback;
  final bool showBalanceOnHome;

  // ─── Currency ───
  final String defaultCurrency; // e.g. 'IDR', 'USD', 'EUR'

  // ─── Daily Budget ───
  final double dailyBudget; // 0 means not set

  const AppSettings({
    this.isDark = true,
    this.accentIndex = 0,
    this.securityMode = SecurityMode.none,
    this.pinCode,
    this.patternCode,
    this.biometricEnabled = false,
    this.navBarStyle = NavBarStyle.solid,
    this.navAccentHex = '',
    this.hapticFeedback = true,
    this.showBalanceOnHome = true,
    this.defaultCurrency = 'IDR',
    this.dailyBudget = 0,
  });

  Color get accentColor => accentPresets[accentIndex].color;
  AccentPreset get accent => accentPresets[accentIndex];

  AppSettings copyWith({
    bool? isDark,
    int? accentIndex,
    SecurityMode? securityMode,
    String? pinCode,
    List<int>? patternCode,
    bool? biometricEnabled,
    NavBarStyle? navBarStyle,
    String? navAccentHex,
    bool? hapticFeedback,
    bool? showBalanceOnHome,
    String? defaultCurrency,
    double? dailyBudget,
  }) {
    return AppSettings(
      isDark: isDark ?? this.isDark,
      accentIndex: accentIndex ?? this.accentIndex,
      securityMode: securityMode ?? this.securityMode,
      pinCode: pinCode ?? this.pinCode,
      patternCode: patternCode ?? this.patternCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      navBarStyle: navBarStyle ?? this.navBarStyle,
      navAccentHex: navAccentHex ?? this.navAccentHex,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showBalanceOnHome: showBalanceOnHome ?? this.showBalanceOnHome,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      dailyBudget: dailyBudget ?? this.dailyBudget,
    );
  }

  Map<String, dynamic> toMap() => {
        'isDark': isDark,
        'accentIndex': accentIndex,
        'securityMode': securityMode.index,
        'pinCode': pinCode,
        'patternCode': patternCode,
        'biometricEnabled': biometricEnabled,
        'navBarStyle': navBarStyle.index,
        'navAccentHex': navAccentHex,
        'hapticFeedback': hapticFeedback,
        'showBalanceOnHome': showBalanceOnHome,
        'defaultCurrency': defaultCurrency,
        'dailyBudget': dailyBudget,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        isDark: m['isDark'] ?? true,
        accentIndex: m['accentIndex'] ?? 0,
        securityMode: SecurityMode.values[m['securityMode'] ?? 0],
        pinCode: m['pinCode'],
        patternCode:
            m['patternCode'] != null ? List<int>.from(m['patternCode']) : null,
        biometricEnabled: m['biometricEnabled'] ?? false,
        navBarStyle: NavBarStyle.values[m['navBarStyle'] ?? 0],
        navAccentHex: m['navAccentHex'] ?? '',
        hapticFeedback: m['hapticFeedback'] ?? true,
        showBalanceOnHome: m['showBalanceOnHome'] ?? true,
        defaultCurrency: m['defaultCurrency'] ?? 'IDR',
        dailyBudget: (m['dailyBudget'] ?? 0).toDouble(),
      );

  String toJson() => json.encode(toMap());
  factory AppSettings.fromJson(String s) => AppSettings.fromMap(json.decode(s));
}
