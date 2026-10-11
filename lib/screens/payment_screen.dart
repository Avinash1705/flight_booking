import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/booking.dart';
import '../models/booking_draft.dart';
import '../services/booking_service.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import 'confirmation_screen.dart';

class _Method {
  const _Method(this.title, this.subtitle, this.icon);
  final String title, subtitle;
  final IconData icon;
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _methods = [
    _Method('UPI', 'Pay using any UPI app', Icons.qr_code_2),
    _Method('Credit / Debit card', 'Visa, Mastercard, RuPay', Icons.credit_card),
    _Method('Net banking', 'All major banks supported', Icons.account_balance),
    _Method('Wallet', 'Paytm, PhonePe, Amazon Pay', Icons.account_balance_wallet),
  ];

  final _form = GlobalKey<FormState>();
  final _promo = TextEditingController();
  final _upi = TextEditingController();
  final _card = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();

  int _method = 0;
  bool _paying = false;
  bool _promoOk = false;
  String? _promoMsg;

  BookingDraft get d => widget.draft;

  @override
  void initState() {
    super.initState();
    if (d.promo != null) {
      _promo.text = d.promo!;
      _promoOk = true;
      _promoMsg = '${d.promo} applied';
    }
  }

  @override
  void dispose() {
    _promo.dispose();
    _upi.dispose();
    _card.dispose();
    _exp.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promo.text.trim().toUpperCase();
    final pct = kPromoCodes[code];
    setState(() {
      if (pct == null) {
        d.promo = null;
        d.discountPct = 0;
        _promoOk = false;
        _promoMsg = code.isEmpty ? 'Enter a promo code' : 'Invalid promo code';
      } else {
        d.promo = code;
        d.discountPct = pct;
        _promoOk = true;
        _promoMsg = '$code applied — you save ${inr(d.price.discount)}';
      }
    });
  }

  void _removePromo() {
    setState(() {
      d.promo = null;
      d.discountPct = 0;
      _promo.clear();
      _promoOk = false;
      _promoMsg = null;
    });
  }

  Future<void> _pay() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final booking = Booking(
      ref: genRef(),
      segments: d.segments,
      passengers: d.passengers,
      seats: Map<String, String>.from(d.seats),
      cabin: d.cabin,
      email: d.email,
      phone: d.phone,
      price: d.price,
      promo: d.promo,
      paymentMethod: _methods[_method].title,
      createdAt: DateTime.now(),
    );
    await context.read<BookingService>().add(booking);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => ConfirmationScreen(booking: booking)),
      (r) => r.isFirst,
    );
  }

  Widget _methodTile(int i) {
    final cs = Theme.of(context).colorScheme;
    final m = _methods[i];
    final selected = _method == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _method = i),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? cs.primary.withOpacity(0.07) : cs.surface,
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withOpacity(0.3),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(children: [
            Icon(m.icon, color: selected ? cs.primary : null),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(m.subtitle,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
              ]),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cs.primary : cs.outline),
          ]),
        ),
      ),
    );
  }

  Widget _methodFields() {
    switch (_method) {
      case 0:
        return TextFormField(
          controller: _upi,
          keyboardType: TextInputType.emailAddress,
          decoration:
              fieldDeco(context, 'UPI ID', icon: Icons.alternate_email, hint: 'name@bank'),
          validator: (v) => RegExp(r'^[\w.\-]{2,}@[A-Za-z]{2,}$').hasMatch(v?.trim() ?? '')
              ? null
              : 'Enter a valid UPI ID',
        );
      case 1:
        return Column(children: [
          TextFormField(
            controller: _card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            decoration: fieldDeco(context, 'Card number', icon: Icons.credit_card),
            validator: (v) => (v ?? '').length == 16 ? null : 'Enter 16-digit card number',
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                controller: _exp,
                keyboardType: TextInputType.datetime,
                decoration: fieldDeco(context, 'Expiry', hint: 'MM/YY'),
                validator: (v) => RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Use MM/YY',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cvv,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: fieldDeco(context, 'CVV'),
                validator: (v) => (v ?? '').length == 3 ? null : '3 digits',
              ),
            ),
          ]),
        ]);
      default:
        return Text(
          'You will be redirected to your provider to complete the payment (demo).',
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = d.price;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      bottomNavigationBar: BottomActionBar(
        label: _paying ? 'Processing…' : 'Pay now',
        caption: 'Total',
        value: inr(p.total),
        loading: _paying,
        onPressed: _pay,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const StepHeader(current: 2),
            const SizedBox(height: 8),
            TripSummaryCard(segments: d.segments),
            const SectionTitle('Promo code'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _promo,
                      enabled: !_promoOk,
                      textCapitalization: TextCapitalization.characters,
                      decoration: fieldDeco(context, 'Enter code',
                          icon: Icons.local_offer_outlined, hint: 'Try SKY10'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _promoOk
                      ? TextButton(onPressed: _removePromo, child: const Text('Remove'))
                      : FilledButton(onPressed: _applyPromo, child: const Text('Apply')),
                ]),
                if (_promoMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _promoMsg!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _promoOk ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
              ]),
            ),
            const SectionTitle('Price details'),
            AppCard(
              child: Column(children: [
                PriceRow(
                  'Base fare (${d.query.adults} adult${d.query.adults > 1 ? 's' : ''}'
                  '${d.query.children > 0 ? ' + ${d.query.children} child' : ''})',
                  inr(p.fare),
                ),
                PriceRow('Taxes & fees', inr(p.taxes)),
                PriceRow('Convenience fee', inr(p.fee)),
                if (p.discount > 0)
                  PriceRow('Discount (${d.promo})', '- ${inr(p.discount)}',
                      color: AppColors.success),
                const Divider(height: 20),
                PriceRow('Total payable', inr(p.total), bold: true),
              ]),
            ),
            const SectionTitle('Payment method'),
            for (var i = 0; i < _methods.length; i++) _methodTile(i),
            const SizedBox(height: 4),
            _methodFields(),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.lock_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Demo checkout — no real payment is processed.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
