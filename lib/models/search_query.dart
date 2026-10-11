class SearchQuery {
  const SearchQuery({
    required this.from,
    required this.to,
    required this.date,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.cabin = 'Economy',
  });

  final String from, to, cabin;
  final DateTime date;
  final DateTime? returnDate;
  final int adults, children;

  bool get isRoundTrip => returnDate != null;
  int get travellers => adults + children;

  SearchQuery withDate(DateTime d) {
    final r = returnDate;
    return SearchQuery(
      from: from,
      to: to,
      date: d,
      returnDate: (r != null && r.isBefore(d)) ? d : r,
      adults: adults,
      children: children,
      cabin: cabin,
    );
  }
}
