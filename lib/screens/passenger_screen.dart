import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils.dart';
import '../models/booking_draft.dart';
import '../models/passenger.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import 'seat_screen.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _names;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  BookingDraft get d => widget.draft;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    final regName = (user != null && !user.isGuest) ? user.name : '';
    final regEmail = (user != null && !user.isGuest) ? user.email : '';
    _names = List.generate(d.query.travellers, (i) {
      if (i < d.passengers.length) {
        return TextEditingController(text: d.passengers[i].name);
      }
      return TextEditingController(text: i == 0 ? regName : '');
    });
    _email = TextEditingController(text: d.email.isNotEmpty ? d.email : regEmail);
    _phone = TextEditingController(text: d.phone);
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    d.passengers = List.generate(
      _names.length,
      (i) => Passenger(
        name: _names[i].text.trim(),
        isChild: i >= d.query.adults,
      ),
    );
    d.email = _email.text.trim();
    d.phone = _phone.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => SeatScreen(draft: d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final adults = d.query.adults;
    return Scaffold(
      appBar: AppBar(title: const Text('Traveller details')),
      bottomNavigationBar: BottomActionBar(
        label: 'Continue to seats',
        caption: 'Total',
        value: inr(d.price.total),
        onPressed: _continue,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const StepHeader(current: 0),
            const SizedBox(height: 8),
            TripSummaryCard(segments: d.segments),
            const SectionTitle('Travellers'),
            Text(
              'Enter names exactly as they appear on a government-issued ID.',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _names.length; i++)
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i < adults ? 'Adult ${i + 1}' : 'Child ${i - adults + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _names[i],
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDeco(context, 'Full name',
                          icon: Icons.badge_outlined),
                      validator: (v) => RegExp(r"^[A-Za-z][A-Za-z .'-]{2,}$")
                              .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid name (letters only)',
                    ),
                  ],
                ),
              ),
            const SectionTitle('Contact details'),
            AppCard(
              child: Column(children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: fieldDeco(context, 'Email',
                      icon: Icons.email_outlined,
                      hint: 'Tickets will be sent here'),
                  validator: (v) =>
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: fieldDeco(context, 'Mobile number',
                      icon: Icons.phone_outlined, hint: '10-digit number'),
                  validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Enter a valid 10-digit mobile number',
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
