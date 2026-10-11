import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/airport.dart';
import '../models/booking_draft.dart';
import '../models/flight.dart';
import '../models/pricing.dart';
import '../models/search_query.dart';
import '../services/flight_service.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import '../widgets/flight_card.dart';
import 'passenger_screen.dart';

enum SortBy { cheapest, fastest, earliest }

class FlightFilters {
  int? maxStops;
  Set<String> airlines = {};
  Set<String> slots = {};
  RangeValues? price;

  bool get isActive =>
      maxStops != null || airlines.isNotEmpty || slots.isNotEmpty || price != null;

  FlightFilters copy() => FlightFilters()
    ..maxStops = maxStops
    ..airlines = {...airlines}
    ..slots = {...slots}
    ..price = price;
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.query, this.outbound});

  final SearchQuery query;

  /// Set when choosing the return leg of a round trip.
  final Flight? outbound;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  SearchQuery get q => widget.query;
  bool get _isReturn => widget.outbound != null;
  String get _from => _isReturn ? q.to : q.from;
  String get _to => _isReturn ? q.from : q.to;
  double get _mult => kCabins[q.cabin] ?? 1;

  late final DateTime _center;
  late DateTime _date;
  late Future<List<Flight>> _future;
  SortBy _sort = SortBy.cheapest;
  FlightFilters _filters = FlightFilters();

  DateTime get _minDate =>
      _isReturn ? dateOnly(widget.outbound!.arrive) : dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _center = dateOnly(_isReturn ? q.returnDate! : q.date);
    _date = _center;
    _future = FlightService.search(_from, _to, _date);
  }

  void _setDate(DateTime d) {
    setState(() {
      _date = d;
      _filters = FlightFilters();
      _future = FlightService.search(_from, _to, d);
    });
  }

  List<Flight> _apply(List<Flight> all) {
    final list = all.where((f) {
      if (_filters.maxStops != null && f.stops > _filters.maxStops!) return false;
      if (_filters.airlines.isNotEmpty && !_filters.airlines.contains(f.airline)) {
        return false;
      }
      if (_filters.slots.isNotEmpty && !_filters.slots.contains(timeSlot(f.depart))) {
        return false;
      }
      final r = _filters.price;
      if (r != null) {
        final p = f.price * _mult;
        if (p < r.start || p > r.end) return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case SortBy.cheapest:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortBy.fastest:
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case SortBy.earliest:
        list.sort((a, b) => a.depart.compareTo(b.depart));
        break;
    }
    return list;
  }

  Future<void> _openFilters(List<Flight> all) async {
    final res = await showModalBottomSheet<FlightFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(all: all, mult: _mult, initial: _filters),
    );
    if (res != null) setState(() => _filters = res);
  }

  Future<void> _select(Flight f) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetailsSheet(flight: f, query: q),
    );
    if (ok != true || !mounted) return;

    if (q.isRoundTrip && !_isReturn) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultsScreen(query: q.withDate(_date), outbound: f),
        ),
      );
    } else {
      final segments = _isReturn ? [widget.outbound!, f] : [f];
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PassengerScreen(
            draft: BookingDraft(query: q, segments: segments),
          ),
        ),
      );
    }
  }

  Widget _dateStrip() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (var i = -3; i <= 3; i++)
            Builder(builder: (context) {
              final d = DateTime(_center.year, _center.month, _center.day + i);
              final enabled = !d.isBefore(_minDate);
              final selected = sameDay(d, _date);
              final fare = enabled ? FlightService.lowestFare(_from, _to, d) : null;
              final fg = selected ? cs.onPrimary : cs.onSurface;
              return Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: selected ? cs.primary : cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: selected
                              ? cs.primary
                              : cs.outline.withOpacity(0.25)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: enabled ? () => _setDate(d) : null,
                      child: Container(
                        width: 78,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(fmtDay(d).split(',').first + ' ${d.day}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: fg)),
                            const SizedBox(height: 4),
                            Text(
                              fare == null ? '—' : inr(fare),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: fg.withOpacity(0.85)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, {bool badge = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badge ? cs.primary.withOpacity(0.1) : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: badge ? cs.primary : cs.outline.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: badge ? cs.primary : null),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: badge ? cs.primary : null)),
      ]),
    );
  }

  String _sortLabel(SortBy s) {
    switch (s) {
      case SortBy.cheapest:
        return 'Cheapest';
      case SortBy.fastest:
        return 'Fastest';
      case SortBy.earliest:
        return 'Earliest';
    }
  }

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const AppCard(
        margin: EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ShimmerBox(width: 40, height: 40, radius: 13),
            SizedBox(width: 12),
            ShimmerBox(width: 120, height: 14),
          ]),
          SizedBox(height: 18),
          ShimmerBox(height: 22),
          SizedBox(height: 18),
          ShimmerBox(width: 160, height: 14),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outbound = widget.outbound;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _isReturn
                ? 'Choose return flight'
                : '${airportByCode(_from).city} → ${airportByCode(_to).city}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            '${_isReturn ? '${airportByCode(_from).city} → ${airportByCode(_to).city} · ' : ''}'
            '${fmtDay(_date)} · ${q.travellers} traveller${q.travellers > 1 ? 's' : ''} · ${q.cabin}',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withOpacity(0.65)),
          ),
        ]),
      ),
      body: Column(children: [
        if (outbound != null)
          Container(
            width: double.infinity,
            color: AppColors.success.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Outbound: ${outbound.from} ${fmtTime(outbound.depart)} → ${outbound.to} · ${outbound.airline} ${outbound.code}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        _dateStrip(),
        Expanded(
          child: FutureBuilder<List<Flight>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return _skeleton();
              if (snap.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off,
                  title: 'Something went wrong',
                  message: 'We could not load flights. Please try again.',
                  actionLabel: 'Retry',
                  onAction: () => _setDate(_date),
                );
              }
              final all = snap.data ?? const <Flight>[];
              if (all.isEmpty) {
                return const EmptyState(
                  icon: Icons.flight_outlined,
                  title: 'No flights on this day',
                  message: 'Try another date from the strip above.',
                );
              }
              final list = _apply(all);
              final cheapestId = all.reduce((a, b) => a.price <= b.price ? a : b).id;
              final fastestId =
                  all.reduce((a, b) => a.duration <= b.duration ? a : b).id;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(children: [
                    Expanded(
                      child: Text('${list.length} flights',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    PopupMenuButton<SortBy>(
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => SortBy.values
                          .map((s) => PopupMenuItem(
                              value: s, child: Text(_sortLabel(s))))
                          .toList(),
                      child: _toolbarButton(Icons.sort, _sortLabel(_sort)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openFilters(all),
                      child: _toolbarButton(Icons.tune, 'Filter',
                          badge: _filters.isActive),
                    ),
                  ]),
                ),
                Expanded(
                  child: list.isEmpty
                      ? EmptyState(
                          icon: Icons.filter_alt_off,
                          title: 'No flights match your filters',
                          message: 'Try removing some filters.',
                          actionLabel: 'Clear filters',
                          onAction: () =>
                              setState(() => _filters = FlightFilters()),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final f = list[i];
                            String? tag;
                            if (f.id == cheapestId) {
                              tag = 'Cheapest';
                            } else if (f.id == fastestId) {
                              tag = 'Fastest';
                            }
                            return FlightCard(
                              flight: f,
                              price: f.price * _mult,
                              tag: tag,
                              onTap: () => _select(f),
                            );
                          },
                        ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── Details sheet ─────────────────────────

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.flight, required this.query});
  final Flight flight;
  final SearchQuery query;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = flight;
    final mult = kCabins[query.cabin] ?? 1;
    final unit = f.price * mult;
    final muted = TextStyle(color: cs.onSurface.withOpacity(0.65), fontSize: 13);

    Widget info(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ]),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AirlineLogo(f.airline, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.airline,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${f.code} · ${f.aircraft}', style: muted),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fmtTime(f.depart),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text('${airportByCode(f.from).city} (${f.from})', style: muted),
            ]),
            Expanded(
              child: Column(children: [
                Text(fmtDur(f.duration), style: muted),
                Divider(color: cs.outline.withOpacity(0.5)),
                Text(f.stops == 0 ? 'Non-stop' : '${f.stops} stop', style: muted),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtTime(f.arrive),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text('${airportByCode(f.to).city} (${f.to})', style: muted),
            ]),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          info(Icons.luggage_outlined,
              'Baggage: 7 kg cabin + ${f.baggageKg} kg check-in'),
          info(Icons.event_seat_outlined, 'Cabin: ${query.cabin}'),
          info(Icons.restaurant_outlined,
              query.cabin == 'Economy' ? 'Meals available for purchase' : 'Complimentary meal included'),
          info(Icons.currency_rupee, 'Refundable: ${(kRefundFactor * 100).round()}% refund on cancellation'),
          const Divider(),
          const SizedBox(height: 8),
          PriceRow('Adult fare × ${query.adults}', inr(unit * query.adults)),
          if (query.children > 0)
            PriceRow('Child fare × ${query.children}',
                inr(unit * kChildFareFactor * query.children)),
          Text('Taxes and fees are added at checkout.', style: muted),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Select this flight · ${inr(PriceBreakdown.calculate(segments: [f], cabin: query.cabin, adults: query.adults, children: query.children).fare)}',
            onPressed: () => Navigator.pop(context, true),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Filter sheet ─────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.all, required this.mult, required this.initial});
  final List<Flight> all;
  final double mult;
  final FlightFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FlightFilters _f;
  late double _min, _max;
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    _f = widget.initial.copy();
    final prices = widget.all.map((e) => e.price * widget.mult).toList();
    _min = prices.reduce(min).floorToDouble();
    _max = prices.reduce(max).ceilToDouble();
    if (_max <= _min) _max = _min + 1;
    final r = _f.price;
    _range = r == null
        ? RangeValues(_min, _max)
        : RangeValues(max(r.start, _min), min(r.end, _max));
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final airlines = widget.all.map((e) => e.airline).toSet().toList()..sort();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filters',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          _heading('Stops'),
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: const Text('Any'),
              selected: _f.maxStops == null,
              onSelected: (_) => setState(() => _f.maxStops = null),
            ),
            ChoiceChip(
              label: const Text('Non-stop'),
              selected: _f.maxStops == 0,
              onSelected: (_) => setState(() => _f.maxStops = 0),
            ),
            ChoiceChip(
              label: const Text('Up to 1 stop'),
              selected: _f.maxStops == 1,
              onSelected: (_) => setState(() => _f.maxStops = 1),
            ),
          ]),
          _heading('Departure time'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final s in kTimeSlots)
              FilterChip(
                label: Text(s),
                selected: _f.slots.contains(s),
                onSelected: (v) => setState(() {
                  if (v) {
                    _f.slots.add(s);
                  } else {
                    _f.slots.remove(s);
                  }
                }),
              ),
          ]),
          _heading('Airlines'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final a in airlines)
              FilterChip(
                label: Text(a),
                selected: _f.airlines.contains(a),
                onSelected: (v) => setState(() {
                  if (v) {
                    _f.airlines.add(a);
                  } else {
                    _f.airlines.remove(a);
                  }
                }),
              ),
          ]),
          _heading('Price (per adult)'),
          RangeSlider(
            values: _range,
            min: _min,
            max: _max,
            labels: RangeLabels(inr(_range.start), inr(_range.end)),
            onChanged: (v) => setState(() => _range = v),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(inr(_range.start)),
            Text(inr(_range.end)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, FlightFilters()),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  _f.price = (_range.start <= _min && _range.end >= _max)
                      ? null
                      : _range;
                  Navigator.pop(context, _f);
                },
                child: const Text('Apply'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
