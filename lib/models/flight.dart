class Flight {
  const Flight({
    required this.id,
    required this.airline,
    required this.code,
    required this.from,
    required this.to,
    required this.depart,
    required this.arrive,
    required this.price,
    required this.stops,
    required this.aircraft,
    required this.baggageKg,
  });

  final String id, airline, code, from, to, aircraft;
  final DateTime depart, arrive;

  /// Economy fare per adult, in INR.
  final double price;
  final int stops, baggageKg;

  Duration get duration => arrive.difference(depart);

  Map<String, dynamic> toJson() => {
        'id': id,
        'airline': airline,
        'code': code,
        'from': from,
        'to': to,
        'depart': depart.toIso8601String(),
        'arrive': arrive.toIso8601String(),
        'price': price,
        'stops': stops,
        'aircraft': aircraft,
        'baggageKg': baggageKg,
      };

  factory Flight.fromJson(Map<String, dynamic> j) => Flight(
        id: j['id'] as String,
        airline: j['airline'] as String,
        code: j['code'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        depart: DateTime.parse(j['depart'] as String),
        arrive: DateTime.parse(j['arrive'] as String),
        price: (j['price'] as num).toDouble(),
        stops: j['stops'] as int,
        aircraft: j['aircraft'] as String,
        baggageKg: j['baggageKg'] as int,
      );
}
