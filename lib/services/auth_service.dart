import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  const AppUser({required this.name, required this.email, this.isGuest = false});
  final String name, email;
  final bool isGuest;

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'email': email, 'isGuest': isGuest};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: j['name'] as String,
        email: j['email'] as String,
        isGuest: (j['isGuest'] as bool?) ?? false,
      );
}

/// Mock authentication service with a persisted session.
///
/// Replace the bodies of [login] and [register] with calls to your backend
/// (Firebase Auth, REST API, ...). The rest of the app only depends on
/// [user], [isLoggedIn] and [logout].
class AuthService extends ChangeNotifier {
  static const _key = 'session_user';

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
    }
  }

  Future<void> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _save(AppUser(name: _nameFromEmail(email), email: email));
  }

  Future<void> register(String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _save(AppUser(name: name, email: email));
  }

  Future<void> continueAsGuest() =>
      _save(const AppUser(name: 'Guest', email: 'guest@local', isGuest: true));

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _user = null;
    notifyListeners();
  }

  Future<void> _save(AppUser u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(u.toJson()));
    _user = u;
    notifyListeners();
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
