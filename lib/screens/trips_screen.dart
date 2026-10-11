import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils.dart';
import '../models/airport.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<BookingService>().items;
    List<Booking> by(BookingStatus s) => all.where((b) => b.status == s).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My trips',
              style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ]),
        ),
        body: TabBarView(children: [
          _TripList(
            trips: by(BookingStatus.confirmed),
            emptyTitle: 'No upcoming trips',
            emptyMessage: 'Book a flight and it will show up here.',
          ),
          _TripList(
            trips: by(BookingStatus.completed),
            emptyTitle: 'No completed trips',
            emptyMessage: 'Your past journeys will appear here.',
          ),
          _TripList(
            trips: by(BookingStatus.cancelled),
            emptyTitle: 'No cancelled trips',
            emptyMessage: 'Cancelled bookings will appear here.',
          ),
        ]),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({
    required this.trips,
    required this.emptyTitle,
    required this.emptyMessage,
  });
  final List<Booking> trips;
  final String emptyTitle, emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return EmptyState(
        icon: Icons.luggage_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.65));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (_, i) {
        final b = trips[i];
        final f = b.first;
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => TripDetailScreen(bookingRef: b.ref)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${b.ref}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: cs.primary)),
              const Spacer(),
              StatusChip(b.status),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Text(f.from,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(b.isRoundTrip ? Icons.sync_alt : Icons.arrow_right_alt,
                    color: cs.outline),
              ),
              Text(f.to,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(inr(b.price.total),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            Text('${airportByCode(f.from).city} to ${airportByCode(f.to).city}',
                style: muted),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
              const SizedBox(width: 6),
              Text('${fmtDay(f.depart)} · ${fmtTime(f.depart)}', style: muted),
              const Spacer(),
              Icon(Icons.people_outline, size: 16, color: cs.outline),
              const SizedBox(width: 4),
              Text('${b.passengers.length}', style: muted),
            ]),
          ]),
        );
      },
    );
  }
}
