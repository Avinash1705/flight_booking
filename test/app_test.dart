import 'package:flight_booking/core/utils.dart';
import 'package:flight_booking/models/pricing.dart';
import 'package:flight_booking/services/flight_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inr uses Indian digit grouping', () {
    expect(inr(999), '₹999');
    expect(inr(1000), '₹1,000');
    expect(inr(123456), '₹1,23,456');
    expect(inr(12345678), '₹1,23,45,678');
  });

  test('flight schedule is deterministic for a route and date', () {
    final date = DateTime.now().add(const Duration(days: 10));
    final a = FlightService.generate('DEL', 'BOM', date);
    final b = FlightService.generate('DEL', 'BOM', date);
    expect(a.map((f) => f.id).toList(), b.map((f) => f.id).toList());
    expect(a, isNotEmpty);
  });

  test('price breakdown adds up and applies child discount', () {
    final date = DateTime.now().add(const Duration(days: 10));
    final f = FlightService.generate('DEL', 'BOM', date).first;
    final p = PriceBreakdown.calculate(
      segments: [f],
      cabin: 'Economy',
      adults: 2,
      children: 1,
      discountPct: 10,
    );
    expect(p.fare, closeTo(f.price * 2.75, 0.001));
    expect(p.discount, closeTo(p.fare * 0.1, 0.001));
    expect(p.total, closeTo(p.fare + p.taxes + p.fee - p.discount, 0.001));
  });
}
