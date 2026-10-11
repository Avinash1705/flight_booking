/// Cabin class → fare multiplier.
const Map<String, double> kCabins = {
  'Economy': 1.0,
  'Premium Economy': 1.45,
  'Business': 2.3,
};

/// Promo code → discount percentage (applied on base fare).
const Map<String, double> kPromoCodes = {
  'SKY10': 10,
  'FLY15': 15,
  'WELCOME20': 20,
};

const double kTaxRate = 0.12;
const double kConvenienceFee = 199;
const double kChildFareFactor = 0.75;
const double kRefundFactor = 0.8;

const List<String> kAirlines = [
  'IndiGo',
  'Air India',
  'Vistara',
  'SpiceJet',
  'Akasa Air',
];

const List<String> kTimeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];
