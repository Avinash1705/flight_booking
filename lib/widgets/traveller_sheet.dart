import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'common.dart';

class TravellerSelection {
  const TravellerSelection({
    this.adults = 1,
    this.children = 0,
    this.cabin = 'Economy',
  });
  final int adults, children;
  final String cabin;
  int get total => adults + children;
}

Future<TravellerSelection?> showTravellerSheet(
  BuildContext context,
  TravellerSelection initial,
) {
  return showModalBottomSheet<TravellerSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TravellerSheet(initial: initial),
  );
}

class _TravellerSheet extends StatefulWidget {
  const _TravellerSheet({required this.initial});
  final TravellerSelection initial;

  @override
  State<_TravellerSheet> createState() => _TravellerSheetState();
}

class _TravellerSheetState extends State<_TravellerSheet> {
  late int _adults = widget.initial.adults;
  late int _children = widget.initial.children;
  late String _cabin = widget.initial.cabin;

  Widget _counter(String title, String subtitle, int value,
      VoidCallback? onMinus, VoidCallback? onPlus) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ]),
      ),
      IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
      SizedBox(
        width: 28,
        child: Text('$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _adults + _children < 9;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Travellers & cabin',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          _counter('Adults', '12+ years', _adults,
              _adults > 1 ? () => setState(() => _adults--) : null,
              canAdd ? () => setState(() => _adults++) : null),
          _counter('Children', '2–11 years (25% off)', _children,
              _children > 0 ? () => setState(() => _children--) : null,
              canAdd ? () => setState(() => _children++) : null),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: kCabins.keys
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _cabin == c,
                        onSelected: (_) => setState(() => _cabin = c),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.pop(
              context,
              TravellerSelection(
                  adults: _adults, children: _children, cabin: _cabin),
            ),
          ),
        ]),
      ),
    );
  }
}
