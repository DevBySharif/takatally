import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/taka_note.dart';

/// Numeric input for a single denomination, so a whole bundle can be typed
/// instead of tapped out with the + and − buttons.
Future<int?> showCountEntrySheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required int initial,
  required int denomination,
}) {
  return showTakaSheet<int>(
    context,
    builder: (sheetContext) => _CountEntrySheet(
      title: title,
      subtitle: subtitle,
      initial: initial,
      denomination: denomination,
    ),
  );
}

class _CountEntrySheet extends StatefulWidget {
  const _CountEntrySheet({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.denomination,
  });

  final String title;
  final String subtitle;
  final int initial;
  final int denomination;

  @override
  State<_CountEntrySheet> createState() => _CountEntrySheetState();
}

class _CountEntrySheetState extends State<_CountEntrySheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == 0 ? '' : '${widget.initial}',
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_controller.text.trim()) ?? 0;

  void _apply() => Navigator.of(context).pop(_quantity);

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final pieces = _quantity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 18),
          SheetHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW MANY?',
                  style: context.texts.labelSmall?.copyWith(
                    color: p.inkSoft,
                    fontSize: 8.5,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('count-entry-field'),
                        controller: _controller,
                        focusNode: _focus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _apply(),
                        style: context.texts.displayLarge?.copyWith(
                          fontSize: 44,
                          color: p.ink,
                          letterSpacing: -1.5,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: context.texts.displayLarge?.copyWith(
                            fontSize: 44,
                            color: p.inkSoft.withValues(alpha: 0.35),
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        pieces == 1 ? 'piece' : 'pieces',
                        style: context.texts.bodyMedium?.copyWith(
                          color: p.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatMoney(pieces * widget.denomination)} in this denomination',
                  style: context.texts.bodySmall?.copyWith(
                    color: p.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in const [0, 10, 25, 50, 100, 200])
                _PresetChip(
                  label: preset == 0 ? 'Clear' : '$preset',
                  active: pieces == preset,
                  onTap: () {
                    _controller.text = preset == 0 ? '' : '$preset';
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Set count',
                  icon: Icons.check_rounded,
                  height: 52,
                  onTap: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return PressableScale(
      onTap: onTap,
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? p.limeSoft : p.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? p.lime : p.line),
        ),
        child: Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? p.accent : p.inkSoft,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulk typing
// ---------------------------------------------------------------------------

/// One sheet with a field per note and coin, so a full tray can be entered
/// with the keyboard.
Future<({Map<int, int> notes, Map<int, int> coins})?> showCountBulkSheet(
  BuildContext context, {
  required Map<int, int> notes,
  required Map<int, int> coins,
}) {
  return showTakaSheet<({Map<int, int> notes, Map<int, int> coins})>(
    context,
    builder: (sheetContext) => _CountBulkSheet(notes: notes, coins: coins),
  );
}

class _CountBulkSheet extends StatefulWidget {
  const _CountBulkSheet({required this.notes, required this.coins});

  final Map<int, int> notes;
  final Map<int, int> coins;

  @override
  State<_CountBulkSheet> createState() => _CountBulkSheetState();
}

class _CountBulkSheetState extends State<_CountBulkSheet> {
  final Map<int, TextEditingController> _noteFields = {};
  final Map<int, TextEditingController> _coinFields = {};

  @override
  void initState() {
    super.initState();
    for (final design in takaNoteDesigns) {
      _noteFields[design.value] = TextEditingController(
        text: _seed(widget.notes[design.value]),
      );
    }
    for (final design in takaCoinDesigns) {
      _coinFields[design.value] = TextEditingController(
        text: _seed(widget.coins[design.value]),
      );
    }
  }

  String _seed(int? value) =>
      value == null || value == 0 ? '' : '$value';

  @override
  void dispose() {
    for (final controller in _noteFields.values) {
      controller.dispose();
    }
    for (final controller in _coinFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _read(Map<int, TextEditingController> fields, int value) {
    final text = fields[value]?.text.trim() ?? '';
    final parsed = int.tryParse(text) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  int get _total {
    var total = 0;
    for (final design in takaNoteDesigns) {
      total += design.value * _read(_noteFields, design.value);
    }
    for (final design in takaCoinDesigns) {
      total += design.value * _read(_coinFields, design.value);
    }
    return total;
  }

  void _apply() {
    final notes = <int, int>{};
    final coins = <int, int>{};
    for (final design in takaNoteDesigns) {
      final quantity = _read(_noteFields, design.value);
      if (quantity > 0) notes[design.value] = quantity;
    }
    for (final design in takaCoinDesigns) {
      final quantity = _read(_coinFields, design.value);
      if (quantity > 0) coins[design.value] = quantity;
    }
    Navigator.of(context).pop((notes: notes, coins: coins));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            children: [
              const SheetGrabber(),
              const SizedBox(height: 16),
              SheetHeader(
                title: 'Type your counts',
                subtitle: 'Fill only what is in the tray, then apply.',
                onClose: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulkSection(
                  title: 'Banknotes',
                  children: [
                    for (final design in takaNoteDesigns)
                      _BulkField(
                        fieldKey: ValueKey('bulk-note-${design.value}'),
                        value: design.value,
                        label: '৳${formatNumber(design.value)} note',
                        bangla: design.banglaName,
                        controller: _noteFields[design.value]!,
                        onChanged: () => setState(() {}),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _BulkSection(
                  title: 'Coins',
                  children: [
                    for (final design in takaCoinDesigns)
                      _BulkField(
                        fieldKey: ValueKey('bulk-coin-${design.value}'),
                        value: design.value,
                        label: '৳${formatNumber(design.value)} coin',
                        bangla: design.banglaName,
                        controller: _coinFields[design.value]!,
                        onChanged: () => setState(() {}),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.line)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Tray total',
                      style: context.texts.bodySmall?.copyWith(
                        color: p.inkSoft,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(_total),
                      style: context.texts.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Apply counts',
                  icon: Icons.check_rounded,
                  height: 52,
                  onTap: _apply,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BulkSection extends StatelessWidget {
  const _BulkSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.texts.labelSmall?.copyWith(
            color: p.inkSoft,
            fontSize: 9,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TakaDivider(),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BulkField extends StatelessWidget {
  const _BulkField({
    required this.fieldKey,
    required this.value,
    required this.label,
    required this.bangla,
    required this.controller,
    required this.onChanged,
  });

  final Key fieldKey;
  final int value;
  final String label;
  final String bangla;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.texts.titleSmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bangla,
                  style: context.texts.bodySmall?.copyWith(
                    color: p.inkSoft,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 74,
            child: TextField(
              key: fieldKey,
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onChanged: (_) => onChanged(),
              style: context.texts.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                hintStyle: context.texts.titleSmall?.copyWith(
                  fontSize: 14,
                  color: p.inkSoft.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: p.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.accent, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
