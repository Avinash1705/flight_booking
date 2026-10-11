import 'package:flutter/material.dart';

import '../models/airport.dart';
import 'common.dart';

Future<Airport?> showAirportPicker(
  BuildContext context, {
  required String title,
  String? exclude,
}) {
  return showModalBottomSheet<Airport>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AirportPicker(title: title, exclude: exclude),
  );
}

class _AirportPicker extends StatefulWidget {
  const _AirportPicker({required this.title, this.exclude});
  final String title;
  final String? exclude;

  @override
  State<_AirportPicker> createState() => _AirportPickerState();
}

class _AirportPickerState extends State<_AirportPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = kAirports
        .where((a) =>
            a.code != widget.exclude && (_q.isEmpty || a.matches(_q)))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration:
                  fieldDeco(context, 'Search city or airport', icon: Icons.search),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No airports found'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final a = list[i];
                      return ListTile(
                        leading: Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(a.code,
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800)),
                        ),
                        title: Text('${a.city}, ${a.country}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(a.name),
                        onTap: () => Navigator.pop(ctx, a),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
