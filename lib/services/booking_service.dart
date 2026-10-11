import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';

/// Stores bookings per user on the device. Swap for an API-backed
/// repository when you add a backend.
class BookingService extends ChangeNotifier {
  String _key = 'bookings_guest@local';
  List<Booking> _items = [];

  List<Booking> get items => List.unmodifiable(_items);

  Future<void> load(String userKey) async {
    _key = 'bookings_${userKey.toLowerCase()}';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final list = <Booking>[];
    for (final s in raw) {
      try {
        list.add(Booking.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // skip corrupted entries
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _items = list;
    notifyListeners();
  }

  Booking? byRef(String ref) {
    for (final b in _items) {
      if (b.ref == ref) return b;
    }
    return null;
  }

  Future<void> add(Booking b) async {
    _items = [b, ..._items];
    notifyListeners();
    await _persist();
  }

  Future<void> cancel(String ref) async {
    _items = _items
        .map((b) => b.ref == ref ? b.copyWith(cancelled: true) : b)
        .toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _items.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }
}
