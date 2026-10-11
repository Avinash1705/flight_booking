import 'flight.dart';
import 'passenger.dart';
import 'pricing.dart';
import 'search_query.dart';

/// Mutable state carried through the checkout steps
/// (travellers → seats → payment).
class BookingDraft {
  BookingDraft({required this.query, required this.segments});

  final SearchQuery query;
  final List<Flight> segments;

  List<Passenger> passengers = [];
  final Map<String, String> seats = {};
  String email = '';
  String phone = '';
  String? promo;
  double discountPct = 0;

  String get cabin => query.cabin;

  PriceBreakdown get price => PriceBreakdown.calculate(
        segments: segments,
        cabin: query.cabin,
        adults: query.adults,
        children: query.children,
        discountPct: discountPct,
      );
}
