import 'dart:math';

import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/airport.dart';
import '../models/booking_draft.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import 'payment_screen.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  int _seg = 0;
  int _pax = 0;

  BookingDraft get d => widget.draft;

  late final List<Set<String>> _blocked = d.segments.map((f) {
    final r = Random(stableHash('seat${f.id}'));
    return <String>{
      for (var i = 0; i < 30; i++) '${1 + r.nextInt(12)}${'ABCDEF'[r.nextInt(6)]}',
    };
  }).toList();

  void _select(String id) {
    setState(() {
      d.seats['$_seg-$_pax'] = id;
      // jump to the next passenger without a seat on this flight
      for (var step = 1; step < d.passengers.length; step++) {
        final next = (_pax + step) % d.passengers.length;
        if (!d.seats.containsKey('$_seg-$next')) {
          _pax = next;
          break;
        }
      }
    });
  }

  Widget _seat(String id) {
    final cs = Theme.of(context).colorScheme;
    final blocked = _blocked[_seg].contains(id);
    final mine = d.seats['$_seg-$_pax'] == id;
    final other = !mine &&
        d.seats.entries.any((e) => e.key.startsWith('$_seg-') && e.value == id);
    final unavailable = blocked || other;

    Color bg;
    Color fg;
    if (unavailable) {
      bg = cs.onSurface.withOpacity(0.1);
      fg = cs.onSurface.withOpacity(0.35);
    } else if (mine) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else {
      bg = cs.primary.withOpacity(0.08);
      fg = cs.primary;
    }

    return GestureDetector(
      onTap: unavailable ? null : () => _select(id),
      child: Container(
        width: 36,
        height: 40,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: (unavailable || mine)
              ? null
              : Border.all(color: cs.primary.withOpacity(0.35)),
        ),
        child: other
            ? Icon(Icons.person, size: 16, color: fg)
            : blocked
                ? Icon(Icons.close, size: 14, color: fg)
                : Text(id.substring(id.length - 1),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }

  Widget _legend(Color c, String text, {bool border = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
          border: border
              ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4))
              : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Future<void> _next() async {
    final missing = d.segments.length * d.passengers.length - d.seats.length;
    if (missing > 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seats not selected'),
          content: Text(
              '$missing seat${missing > 1 ? 's' : ''} will be assigned automatically at check-in. Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Go back')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (go != true) return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => PaymentScreen(draft: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Select seats')),
      bottomNavigationBar: BottomActionBar(
        label: 'Continue to payment',
        caption: 'Total',
        value: inr(d.price.total),
        onPressed: _next,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StepHeader(current: 1),
          if (d.segments.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < d.segments.length; i++)
                ChoiceChip(
                  label: Text(
                      '${airportByCode(d.segments[i].from).code} → ${airportByCode(d.segments[i].to).code}'),
                  selected: _seg == i,
                  onSelected: (_) => setState(() {
                    _seg = i;
                    _pax = 0;
                  }),
                ),
            ]),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < d.passengers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: const Icon(Icons.person_outline, size: 18),
                      label: Text(
                          '${d.passengers[i].name.split(' ').first} · ${d.seats['$_seg-$i'] ?? '–'}'),
                      selected: _pax == i,
                      onSelected: (_) => setState(() => _pax = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 6, children: [
            _legend(cs.primary.withOpacity(0.08), 'Available', border: true),
            _legend(cs.primary, 'Selected'),
            _legend(cs.onSurface.withOpacity(0.1), 'Occupied'),
          ]),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(children: [
              Icon(Icons.flight, color: cs.outline),
              Text('FRONT', style: TextStyle(fontSize: 11, letterSpacing: 2, color: cs.outline)),
              const SizedBox(height: 8),
              for (var r = 1; r <= 12; r++)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final c in ['A', 'B', 'C']) _seat('$r$c'),
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Text('$r',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                    ),
                  ),
                  for (final c in ['D', 'E', 'F']) _seat('$r$c'),
                ]),
            ]),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
