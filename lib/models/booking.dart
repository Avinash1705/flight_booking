import 'flight.dart';
import 'passenger.dart';
import 'pricing.dart';

enum BookingStatus { confirmed, completed, cancelled }

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Booking {
  const Booking({
    required this.ref,
    required this.segments,
    required this.passengers,
    required this.seats,
    required this.cabin,
    required this.email,
    required this.phone,
    required this.price,
    required this.paymentMethod,
    required this.createdAt,
    this.promo,
    this.cancelled = false,
  });

  final String ref, cabin, email, phone, paymentMethod;
  final List<Flight> segments;
  final List<Passenger> passengers;

  /// Seat assignments keyed by "segmentIndex-passengerIndex".
  final Map<String, String> seats;
  final PriceBreakdown price;
  final String? promo;
  final DateTime createdAt;
  final bool cancelled;

  Flight get first => segments.first;
  bool get isRoundTrip => segments.length > 1;
  String get route => isRoundTrip
      ? '${first.from} ⇄ ${first.to}'
      : '${first.from} → ${first.to}';

  String? seatFor(int segment, int passenger) => seats['$segment-$passenger'];

  BookingStatus get status {
    if (cancelled) return BookingStatus.cancelled;
    if (segments.last.arrive.isBefore(DateTime.now())) {
      return BookingStatus.completed;
    }
    return BookingStatus.confirmed;
  }

  Booking copyWith({bool? cancelled}) => Booking(
        ref: ref,
        segments: segments,
        passengers: passengers,
        seats: seats,
        cabin: cabin,
        email: email,
        phone: phone,
        price: price,
        paymentMethod: paymentMethod,
        createdAt: createdAt,
        promo: promo,
        cancelled: cancelled ?? this.cancelled,
      );

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'cabin': cabin,
        'email': email,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'segments': segments.map((e) => e.toJson()).toList(),
        'passengers': passengers.map((e) => e.toJson()).toList(),
        'seats': seats,
        'price': price.toJson(),
        'promo': promo,
        'createdAt': createdAt.toIso8601String(),
        'cancelled': cancelled,
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        ref: j['ref'] as String,
        cabin: j['cabin'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String,
        paymentMethod: j['paymentMethod'] as String,
        segments: (j['segments'] as List)
            .map((e) => Flight.fromJson(e as Map<String, dynamic>))
            .toList(),
        passengers: (j['passengers'] as List)
            .map((e) => Passenger.fromJson(e as Map<String, dynamic>))
            .toList(),
        seats: Map<String, String>.from(j['seats'] as Map),
        price: PriceBreakdown.fromJson(j['price'] as Map<String, dynamic>),
        promo: j['promo'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        cancelled: (j['cancelled'] as bool?) ?? false,
      );
}
