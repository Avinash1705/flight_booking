import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/flight.dart';
import 'app_card.dart';

const _logoColors = [
  Color(0xFF0B5FFF),
  Color(0xFFE5484D),
  Color(0xFF7C3AED),
  Color(0xFFF59E0B),
  Color(0xFFFF6A00),
];

Color airlineColor(String airline) =>
    _logoColors[stableHash(airline) % _logoColors.length];

class AirlineLogo extends StatelessWidget {
  const AirlineLogo(this.airline, {super.key, this.size = 40});
  final String airline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = airlineColor(airline);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        airline[0],
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.45),
      ),
    );
  }
}

class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.flight,
    required this.price,
    required this.onTap,
    this.tag,
  });

  final Flight flight;
  final double price;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6));

    Widget endpoint(String time, String code, CrossAxisAlignment a) => Column(
          crossAxisAlignment: a,
          children: [
            Text(time,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(code, style: muted),
          ],
        );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(children: [
        Row(children: [
          AirlineLogo(flight.airline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flight.airline,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${flight.code} · ${flight.aircraft}', style: muted),
              ],
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tag!,
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          endpoint(fmtTime(flight.depart), flight.from, CrossAxisAlignment.start),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                Text(fmtDur(flight.duration), style: muted),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Divider(height: 1, color: cs.outline.withOpacity(0.5))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Icon(Icons.flight, size: 16),
                    ),
                  ),
                  Expanded(child: Divider(height: 1, color: cs.outline.withOpacity(0.5))),
                ]),
                const SizedBox(height: 4),
                Text(
                  flight.stops == 0 ? 'Non-stop' : '${flight.stops} stop',
                  style: muted.copyWith(
                    color: flight.stops == 0 ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
          endpoint(fmtTime(flight.arrive), flight.to, CrossAxisAlignment.end),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, color: cs.outline.withOpacity(0.2)),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.luggage_outlined, size: 16, color: cs.onSurface.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text('${flight.baggageKg} kg check-in', style: muted),
          const Spacer(),
          Text(inr(price),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: cs.primary)),
          Text(' /adult', style: muted),
        ]),
      ]),
    );
  }
}
