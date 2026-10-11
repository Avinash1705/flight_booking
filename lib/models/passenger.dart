class Passenger {
  const Passenger({required this.name, required this.isChild});
  final String name;
  final bool isChild;

  String get type => isChild ? 'Child' : 'Adult';

  Map<String, dynamic> toJson() => {'name': name, 'isChild': isChild};
  factory Passenger.fromJson(Map<String, dynamic> j) =>
      Passenger(name: j['name'] as String, isChild: j['isChild'] as bool);
}
