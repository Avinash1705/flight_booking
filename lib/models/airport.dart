class Airport {
  const Airport(this.code, this.city, this.name, this.country);
  final String code, city, name, country;

  bool matches(String query) {
    final q = query.toLowerCase();
    return code.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        country.toLowerCase().contains(q);
  }
}

const List<Airport> kAirports = [
  Airport('DEL', 'Delhi', 'Indira Gandhi International', 'India'),
  Airport('BOM', 'Mumbai', 'Chhatrapati Shivaji Maharaj Intl', 'India'),
  Airport('LKO', 'Lucknow', 'Chaudhary Charan Singh Intl', 'India'),
  Airport('BLR', 'Bengaluru', 'Kempegowda International', 'India'),
  Airport('CCU', 'Kolkata', 'Netaji Subhas Chandra Bose Intl', 'India'),
  Airport('HYD', 'Hyderabad', 'Rajiv Gandhi International', 'India'),
  Airport('MAA', 'Chennai', 'Chennai International', 'India'),
  Airport('GOI', 'Goa', 'Dabolim / Manohar International', 'India'),
  Airport('PNQ', 'Pune', 'Pune International', 'India'),
  Airport('AMD', 'Ahmedabad', 'Sardar Vallabhbhai Patel Intl', 'India'),
  Airport('JAI', 'Jaipur', 'Jaipur International', 'India'),
  Airport('DXB', 'Dubai', 'Dubai International', 'UAE'),
  Airport('SIN', 'Singapore', 'Changi Airport', 'Singapore'),
  Airport('BKK', 'Bangkok', 'Suvarnabhumi Airport', 'Thailand'),
  Airport('LHR', 'London', 'Heathrow Airport', 'United Kingdom'),
];

Airport airportByCode(String code) => kAirports.firstWhere(
      (a) => a.code == code,
      orElse: () => Airport(code, code, code, ''),
    );
