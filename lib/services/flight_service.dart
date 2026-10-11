import 'dart:math';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/airport.dart';
import '../models/flight.dart';

/// Mock flight search. Replace [search] with a real API (Amadeus, Duffel, ...).
class FlightService {
  static const _domestic = [
    'Airbus A320neo',
    'Boeing 737-800',
    'Airbus A321neo',
    'ATR 72-600',
  ];
  static const _international = [
    'Boeing 787-9',
    'Airbus A330-300',
    'Boeing 777-300ER',
  ];

  static Future<List<Flight>> search(String from, String to, DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return generate(from, to, date);
  }

  /// Cheapest economy fare for a day, or null when there are no flights.
  static double? lowestFare(String from, String to, DateTime date) {
    final list = generate(from, to, date);
    if (list.isEmpty) return null;
    return list.map((f) => f.price).reduce(min);
  }

  /// Deterministic pseudo-random schedule for a route and date.
  static List<Flight> generate(String from, String to, DateTime date) {
    final d = dateOnly(date);
    final now = DateTime.now();
    final rnd = Random(stableHash('$from$to${d.year}${d.month}${d.day}'));
    final intl = airportByCode(from).country != airportByCode(to).country;
    final daysAhead = d.difference(dateOnly(now)).inDays;
    final flights = <Flight>[];

    for (var i = 0; i < 10; i++) {
      final airline = kAirlines[rnd.nextInt(kAirlines.length)];
      final dep = DateTime(d.year, d.month, d.day, 5 + i * 2, rnd.nextInt(4) * 15);
      final stops = rnd.nextInt(100) < 18 ? 1 : 0;
      final minutes =
          (intl ? 210 : 85) + rnd.nextInt(70) + stops * (70 + rnd.nextInt(50));
      var price = (intl ? 13500 : 3200) + rnd.nextInt(intl ? 8500 : 4200);
      final peak = (dep.hour >= 7 && dep.hour <= 10) || (dep.hour >= 17 && dep.hour <= 20);
      if (peak) price = (price * 1.18).round();
      if (stops == 1) price = (price * 0.88).round();
      if (daysAhead < 3) price = (price * 1.25).round();
      final number = 100 + rnd.nextInt(900);
      final aircraft = intl
          ? _international[rnd.nextInt(_international.length)]
          : _domestic[rnd.nextInt(_domestic.length)];

      if (sameDay(d, now) && !dep.isAfter(now)) continue;

      flights.add(Flight(
        id: '$from$to-${dep.millisecondsSinceEpoch}',
        airline: airline,
        code: '${airline.substring(0, 2).toUpperCase()}-$number',
        from: from,
        to: to,
        depart: dep,
        arrive: dep.add(Duration(minutes: minutes)),
        price: price.toDouble(),
        stops: stops,
        aircraft: aircraft,
        baggageKg: intl ? 25 : 15,
      ));
    }
    return flights;
  }
}
