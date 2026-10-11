import 'dart:math';

import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/airport.dart';
import '../models/booking.dart';
import 'common.dart';

/// Boarding-pass style ticket for one flight segment of a [Booking].
class BoardingPass extends StatelessWidget {
  const BoardingPass({super.key, required this.booking, required this.segment});
  final Booking booking;
  final int segment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final f = booking.segments[segment];
    final from = airportByCode(f.from);
    final to = airportByCode(f.to);
    final h = stableHash(f.id);
    final gate = 'A${h % 24 + 1}';
    final terminal = 'T${h % 3 + 1}';
    final boarding = f.depart.subtract(const Duration(minutes: 45));
    final label = TextStyle(
      fontSize: 11,
      letterSpacing: 0.5,
      color: cs.onSurface.withOpacity(0.55),
    );

    Widget kv(String k, String v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k.toUpperCase(), style: label),
              const SizedBox(height: 3),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    final tag = booking.isRoundTrip
        ? (segment == 0 ? 'OUTBOUND' : 'RETURN')
        : 'BOARDING PASS';

    return Opacity(
      opacity: booking.cancelled ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: [
            Container(
              color: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(Icons.flight, color: cs.onPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${f.airline} · ${f.code}',
                      style: TextStyle(
                          color: cs.onPrimary, fontWeight: FontWeight.w700)),
                ),
                Text(tag,
                    style: TextStyle(
                        color: cs.onPrimary.withOpacity(0.8),
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(from.code,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    Text(from.city, style: label),
                  ]),
                  Expanded(
                    child: Column(children: [
                      const RotatedBox(
                          quarterTurns: 1, child: Icon(Icons.flight, size: 22)),
                      Text(fmtDur(f.duration), style: label),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(to.code,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    Text(to.city, style: label),
                  ]),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  kv('Departs', '${fmtTime(f.depart)} · ${fmtDay(f.depart)}'),
                  kv('Arrives', '${fmtTime(f.arrive)} · ${fmtDay(f.arrive)}'),
                ]),
              ]),
            ),
            Row(children: [
              Container(
                width: 12,
                height: 24,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12)),
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: DashedDivider(),
                ),
              ),
              Container(
                width: 12,
                height: 24,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  kv('Gate', gate),
                  kv('Terminal', terminal),
                  kv('Boarding', fmtTime(boarding)),
                  kv('Cabin', booking.cabin),
                ]),
                const SizedBox(height: 16),
                for (var i = 0; i < booking.passengers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text(booking.passengers[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(booking.passengers[i].type, style: label),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.seatFor(segment, i) ?? 'Auto',
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ]),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BarcodePainter(booking.ref, cs.onSurface),
                  ),
                ),
                const SizedBox(height: 6),
                Text(booking.ref,
                    style: const TextStyle(
                        letterSpacing: 4, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed, this.color);
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(stableHash(seed));
    final p = Paint()..color = color;
    double x = 0;
    while (x < size.width) {
      final w = 1.0 + rnd.nextInt(3);
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
      x += w + 1.5 + rnd.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) =>
      old.seed != seed || old.color != color;
}
