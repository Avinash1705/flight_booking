import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/app_card.dart';
import '../widgets/boarding_pass.dart';
import '../widgets/common.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.bookingRef});
  final String bookingRef;

  Future<void> _cancel(BuildContext context, Booking b) async {
    final refund = b.price.total * kRefundFactor;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'You will receive a refund of ${inr(refund)} '
          '(${(kRefundFactor * 100).round()}% of the amount paid) to your original '
          'payment method within 5–7 business days.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep booking')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<BookingService>().cancel(b.ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking cancelled. ${inr(refund)} will be refunded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final b = context.watch<BookingService>().byRef(bookingRef);
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Booking not found',
          message: 'This booking is no longer available.',
        ),
      );
    }
    final muted = TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.65));

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${b.ref}'),
        actions: [
          IconButton(
            tooltip: 'Copy booking ID',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: b.ref));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Booking ID copied')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            StatusChip(b.status),
            const Spacer(),
            Text('Booked on ${fmtDate(b.createdAt)}', style: muted),
          ]),
          const SizedBox(height: 14),
          for (var i = 0; i < b.segments.length; i++)
            BoardingPass(booking: b, segment: i),
          const SectionTitle('Contact'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.email_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(b.email)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 18),
                const SizedBox(width: 10),
                Text('+91 ${b.phone}'),
              ]),
            ]),
          ),
          const SectionTitle('Payment summary'),
          AppCard(
            child: Column(children: [
              PriceRow('Base fare', inr(b.price.fare)),
              PriceRow('Taxes & fees', inr(b.price.taxes)),
              PriceRow('Convenience fee', inr(b.price.fee)),
              if (b.price.discount > 0)
                PriceRow('Discount (${b.promo ?? 'promo'})',
                    '- ${inr(b.price.discount)}',
                    color: AppColors.success),
              const Divider(height: 20),
              PriceRow('Total paid', inr(b.price.total), bold: true),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Paid via ${b.paymentMethod}', style: muted),
              ),
            ]),
          ),
          if (b.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () => _cancel(context, b),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel booking'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
