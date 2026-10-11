import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils.dart';
import '../models/airport.dart';
import '../models/search_query.dart';
import '../services/auth_service.dart';
import '../services/flight_service.dart';
import '../services/settings_service.dart';
import '../widgets/airport_picker.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/traveller_sheet.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Airport _from = airportByCode('LKO');
  Airport _to = airportByCode('DEL');
  DateTime _date = dateOnly(DateTime.now().add(const Duration(days: 7)));
  DateTime _returnDate = dateOnly(DateTime.now().add(const Duration(days: 10)));
  bool _roundTrip = false;
  TravellerSelection _trav = const TravellerSelection();

  static const _popular = ['BOM', 'BLR', 'DXB', 'SIN', 'GOI', 'JAI'];
  static const _popularColors = [
    [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
    [Color(0xFF10B981), Color(0xFF065F46)],
    [Color(0xFFF59E0B), Color(0xFF9A3412)],
    [Color(0xFFEC4899), Color(0xFF831843)],
    [Color(0xFF06B6D4), Color(0xFF155E75)],
    [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
  ];

  Future<void> _pickAirport(bool isFrom) async {
    final a = await showAirportPicker(
      context,
      title: isFrom ? 'Select origin' : 'Select destination',
      exclude: isFrom ? _to.code : _from.code,
    );
    if (a == null) return;
    setState(() {
      if (isFrom) {
        _from = a;
      } else {
        _to = a;
      }
    });
  }

  void _swap() => setState(() {
        final t = _from;
        _from = _to;
        _to = t;
      });

  Future<void> _pickDate({required bool isReturn}) async {
    final today = dateOnly(DateTime.now());
    final first = isReturn ? _date : today;
    final current = isReturn ? _returnDate : _date;
    final d = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: today.add(const Duration(days: 330)),
    );
    if (d == null) return;
    setState(() {
      if (isReturn) {
        _returnDate = d;
      } else {
        _date = d;
        if (_returnDate.isBefore(d)) _returnDate = d;
      }
    });
  }

  Future<void> _pickTravellers() async {
    final r = await showTravellerSheet(context, _trav);
    if (r != null) setState(() => _trav = r);
  }

  void _search() {
    context.read<SettingsService>().addRecent(_from.code, _to.code);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          query: SearchQuery(
            from: _from.code,
            to: _to.code,
            date: _date,
            returnDate: _roundTrip ? _returnDate : null,
            adults: _trav.adults,
            children: _trav.children,
            cabin: _trav.cabin,
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required String value,
    String? sub,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (sub != null)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.55))),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthService>().user;
    final recent = context.watch<SettingsService>().recent;
    final topPad = MediaQuery.of(context).padding.top;
    final firstName = (user?.name ?? 'Traveller').split(' ').first;
    final previewDate = dateOnly(DateTime.now().add(const Duration(days: 7)));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, Color.lerp(cs.primary, Colors.black, 0.4)!],
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${greeting()}, $firstName',
                    style: TextStyle(
                        color: cs.onPrimary.withOpacity(0.85), fontSize: 15)),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.onPrimary.withOpacity(0.2),
                child: Text(user?.initials ?? '?',
                    style: TextStyle(
                        color: cs.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Where would you\nlike to fly?',
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('One way'),
                          icon: Icon(Icons.arrow_right_alt)),
                      ButtonSegment(
                          value: true,
                          label: Text('Round trip'),
                          icon: Icon(Icons.sync_alt)),
                    ],
                    selected: {_roundTrip},
                    onSelectionChanged: (s) => setState(() => _roundTrip = s.first),
                  ),
                ),
                const SizedBox(height: 16),
                Stack(children: [
                  Column(children: [
                    _tile(
                      icon: Icons.flight_takeoff,
                      label: 'From',
                      value: '${_from.city} (${_from.code})',
                      sub: _from.name,
                      onTap: () => _pickAirport(true),
                    ),
                    const SizedBox(height: 10),
                    _tile(
                      icon: Icons.flight_land,
                      label: 'To',
                      value: '${_to.city} (${_to.code})',
                      sub: _to.name,
                      onTap: () => _pickAirport(false),
                    ),
                  ]),
                  Positioned(
                    right: 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: cs.surface,
                        shape: CircleBorder(
                            side: BorderSide(color: cs.outline.withOpacity(0.35))),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _swap,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.swap_vert, color: cs.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _tile(
                      icon: Icons.calendar_month,
                      label: 'Departure',
                      value: fmtDay(_date),
                      onTap: () => _pickDate(isReturn: false),
                    ),
                  ),
                  if (_roundTrip) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tile(
                        icon: Icons.event_repeat,
                        label: 'Return',
                        value: fmtDay(_returnDate),
                        onTap: () => _pickDate(isReturn: true),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 10),
                _tile(
                  icon: Icons.people_outline,
                  label: 'Travellers & cabin',
                  value:
                      '${_trav.total} traveller${_trav.total > 1 ? 's' : ''} · ${_trav.cabin}',
                  onTap: _pickTravellers,
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Search flights',
                  icon: Icons.search,
                  onPressed: _search,
                ),
              ]),
            ),
            if (recent.isNotEmpty) ...[
              const SectionTitle('Recent searches'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recent.map((r) {
                  final p = r.split('-');
                  return ActionChip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text('${p[0]} → ${p[1]}'),
                    onPressed: () => setState(() {
                      _from = airportByCode(p[0]);
                      _to = airportByCode(p[1]);
                    }),
                  );
                }).toList(),
              ),
            ],
            const SectionTitle('Popular destinations'),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _popular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final a = airportByCode(_popular[i]);
                  final fare = a.code == _from.code
                      ? null
                      : FlightService.lowestFare(_from.code, a.code, previewDate);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (a.code != _from.code) _to = a;
                    }),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _popularColors[i],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.city,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                fare == null ? a.country : 'from ${inr(fare)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
