import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/booking.dart';
import '../widgets/boarding_pass.dart';
import '../widgets/common.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    size: 64, color: AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'E-ticket sent to ${booking.email}',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
          ),
          const SizedBox(height: 12),
          Center(
            child: ActionChip(
              avatar: const Icon(Icons.copy, size: 16),
              label: Text('Booking ID  ${booking.ref}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: booking.ref));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking ID copied')),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < booking.segments.length; i++)
            BoardingPass(booking: booking, segment: i),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Back to home',
            icon: Icons.home_outlined,
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
