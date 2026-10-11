import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifications = true;
  List<String> _recent = [];

  ThemeMode get themeMode => _themeMode;
  bool get notifications => _notifications;

  /// Recent routes as "FROM-TO" strings, newest first.
  List<String> get recent => List.unmodifiable(_recent);

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt('theme_mode') ?? 0;
    final safe = (idx < 0 || idx >= ThemeMode.values.length) ? 0 : idx;
    _themeMode = ThemeMode.values[safe];
    _notifications = p.getBool('notifications') ?? true;
    _recent = p.getStringList('recent_searches') ?? [];
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt('theme_mode', m.index);
  }

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('notifications', v);
  }

  Future<void> addRecent(String from, String to) async {
    final item = '$from-$to';
    _recent = [item, ..._recent.where((e) => e != item)].take(5).toList();
    notifyListeners();
    (await SharedPreferences.getInstance())
        .setStringList('recent_searches', _recent);
  }
}
