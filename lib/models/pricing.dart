import '../core/constants.dart';
import 'flight.dart';

class PriceBreakdown {
  const PriceBreakdown({
    required this.fare,
    required this.taxes,
    required this.fee,
    required this.discount,
  });

  final double fare, taxes, fee, discount;

  double get total => fare + taxes + fee - discount;

  factory PriceBreakdown.calculate({
    required List<Flight> segments,
    required String cabin,
    required int adults,
    required int children,
    double discountPct = 0,
  }) {
    final mult = kCabins[cabin] ?? 1.0;
    final perAdult = segments.fold<double>(0, (s, f) => s + f.price * mult);
    final fare = perAdult * adults + perAdult * kChildFareFactor * children;
    return PriceBreakdown(
      fare: fare,
      taxes: fare * kTaxRate,
      fee: kConvenienceFee,
      discount: fare * discountPct / 100,
    );
  }

  Map<String, dynamic> toJson() =>
      {'fare': fare, 'taxes': taxes, 'fee': fee, 'discount': discount};

  factory PriceBreakdown.fromJson(Map<String, dynamic> j) => PriceBreakdown(
        fare: (j['fare'] as num).toDouble(),
        taxes: (j['taxes'] as num).toDouble(),
        fee: (j['fee'] as num).toDouble(),
        discount: (j['discount'] as num).toDouble(),
      );
}
