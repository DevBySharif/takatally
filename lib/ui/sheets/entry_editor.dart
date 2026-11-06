import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import 'count_entry_sheet.dart';

class EntryDraft {
  const EntryDraft({
    required this.kind,
    required this.amount,
    required this.quantity,
    required this.note,
    required this.date,
    this.noteCounts = const {},
    this.coinCounts = const {},
  });

  final EntryKind kind;
  final int amount;
  final int quantity;
  final String note;
  final DateTime date;
  final Map<int, int> noteCounts;
  final Map<int, int> coinCounts;
}

Future<EntryDraft?> showEntryEditor(
  BuildContext context, {
  TallyEntry? entry,
  EntryKind initialKind = EntryKind.counted,
  int? initialAmount,
}) {
  return showTakaSheet<EntryDraft>(
    context,
    builder: (_) => EntryEditor(
      entry: entry,
      initialKind: initialKind,
      initialAmount: initialAmount,
    ),
  );
}

class EntryEditor extends StatefulWidget {
  const EntryEditor({
    super.key,
    this.entry,
    this.initialKind = EntryKind.counted,
    this.initialAmount,
  });

  final TallyEntry? entry;
  final EntryKind initialKind;
  final int? initialAmount;

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  late EntryKind _kind;
  late TextEditingController _amountController;
  late TextEditingController _quantityController;
  late TextEditingController _noteController;
  final FocusNode _quantityFocus = FocusNode();
  late int _quantity;
  late DateTime _date;
  String? _error;
  Map<int, int> _noteCounts = {};
  Map<int, int> _coinCounts = {};

  bool get _hasBreakdown => _noteCounts.isNotEmpty || _coinCounts.isNotEmpty;

  List<({int value, int quantity, bool coin})> get _breakdownItems {
    final notes = _noteCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    final coins = _coinCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final value in notes)
        (value: value, quantity: _noteCounts[value]!, coin: false),
      for (final value in coins)
        (value: value, quantity: _coinCounts[value]!, coin: true),
    ];
  }

  int get _breakdownTotal {
    var total = 0;
    _noteCounts.forEach((value, qty) => total += value * qty);
    _coinCounts.forEach((value, qty) => total += value * qty);
    return total;
  }

  int get _pieceCount =>
      _noteCounts.values.fold(0, (sum, qty) => sum + qty) +
      _coinCounts.values.fold(0, (sum, qty) => sum + qty);

  static const _quickAmounts = <int>[
    5000,
    2000,
    1000,
    500,
    200,
    100,
    50,
    20,
    10,
    5,
    1,
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _kind = entry?.kind ?? widget.initialKind;
    _quantity = entry?.quantity ?? 1;
    _date = entry?.createdAt ?? DateTime.now();
    _amountController = TextEditingController(
      text: entry?.amount.toString() ??
          widget.initialAmount?.toString() ??
          '',
    );
    _noteController = TextEditingController(text: entry?.note ?? '');
    _quantityController = TextEditingController(text: _quantity.toString());
    _quantityFocus.addListener(_syncQuantityField);
    _noteCounts = Map<int, int>.of(entry?.noteCounts ?? const {});
    _coinCounts = Map<int, int>.of(entry?.coinCounts ?? const {});
    // The amount is derived from the breakdown, so show it grouped like the
    // rest of the app instead of a raw digit string.
    if (_hasBreakdown) {
      _amountController.text = formatNumber(_breakdownTotal);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  int get _amount {
    if (_hasBreakdown) return _breakdownTotal;
    final digits = _amountController.text.replaceAll(',', '').trim();
    return int.tryParse(digits) ?? 0;
  }

  /// Reads the typed quantity, falling back to 1 while the field is empty.
  int get _typedQuantity {
    final parsed = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (parsed <= 0) return 1;
    return parsed.clamp(1, 9999);
  }

  int get _total {
    if (_hasBreakdown) return _breakdownTotal;
    return _amount * (_kind == EntryKind.counted ? _typedQuantity : 1);
  }

  void _syncQuantityField() {
    if (_quantityFocus.hasFocus) return;
    final text = _quantityController.text.trim();
    final parsed = int.tryParse(text) ?? 0;
    if (parsed <= 0) {
      _quantityController.text = _quantity.toString();
    } else {
      _quantity = parsed.clamp(1, 9999);
      _quantityController.text = _quantity.toString();
    }
    _quantityController.selection = TextSelection.collapsed(
      offset: _quantityController.text.length,
    );
  }

  void _onQuantityTyped(String raw) {
    final parsed = int.tryParse(raw.trim()) ?? 0;
    if (parsed <= 0) return;
    setState(() => _quantity = parsed.clamp(1, 9999));
  }

  void _setKind(EntryKind kind) {
    if (_kind == kind) return;
    final store = AppScope.read(context);
    store.tapHaptic();
    setState(() {
      _kind = kind;
      if (kind != EntryKind.counted) {
        _quantity = 1;
        _quantityController.text = '1';
        final derived = _breakdownTotal;
        _noteCounts = {};
        _coinCounts = {};
        // Keep the number, drop the display grouping so it stays editable.
        if (derived > 0) _amountController.text = '$derived';
      }
      _error = null;
    });
  }

  void _setAmount(int value) {
    _amountController.text = value.toString();
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
    AppScope.read(context).tapHaptic();
    setState(() => _error = null);
  }

  void _changeQuantity(int delta) {
    final next = (_typedQuantity + delta).clamp(1, 9999);
    if (next == _typedQuantity) return;
    AppScope.read(context).tapHaptic();
    setState(() {
      _quantity = next;
      _quantityController.text = next.toString();
      _quantityController.selection = TextSelection.collapsed(
        offset: _quantityController.text.length,
      );
    });
  }

  Future<void> _editBreakdownItem(
    ({int value, int quantity, bool coin}) item,
  ) async {
    final next = await showCountEntrySheet(
      context,
      title: '৳${formatNumber(item.value)} ${item.coin ? 'coin' : 'note'}',
      subtitle: 'Change how many are in this count',
      initial: item.quantity,
      denomination: item.value,
    );
    if (next == null || !mounted) return;
    final target = item.coin ? _coinCounts : _noteCounts;
    setState(() {
      if (next <= 0) {
        target.remove(item.value);
      } else {
        target[item.value] = next;
      }
      _amountController.text = formatNumber(_breakdownTotal);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    });
    AppScope.read(context).tapHaptic();
  }

  Future<void> _editAllBreakdown() async {
    final result = await showCountBulkSheet(
      context,
      notes: Map<int, int>.of(_noteCounts),
      coins: Map<int, int>.of(_coinCounts),
    );
    if (result == null || !mounted) return;
    setState(() {
      _noteCounts = Map<int, int>.of(result.notes);
      _coinCounts = Map<int, int>.of(result.coins);
      _amountController.text = formatNumber(_breakdownTotal);
      _amountController.selection = TextSelection.collapsed(
        offset: _amountController.text.length,
      );
    });
    AppScope.read(context).successHaptic();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: 'When was this counted?',
    );
    if (picked != null && mounted) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  void _save() {
    final amount = _hasBreakdown ? _breakdownTotal : _amount;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      HapticFeedback.vibrate();
      return;
    }
    if (amount > 999999999) {
      setState(() => _error = 'That amount is too large.');
      HapticFeedback.vibrate();
      return;
    }
    final store = AppScope.read(context);
    store.successHaptic();
    final quantity = _hasBreakdown
        ? 1
        : (_kind == EntryKind.counted ? _typedQuantity : 1);
    Navigator.of(context).pop(
      EntryDraft(
        kind: _kind,
        amount: amount,
        quantity: quantity,
        note: _noteController.text.trim(),
        date: _date,
        noteCounts: _hasBreakdown ? Map<int, int>.of(_noteCounts) : const {},
        coinCounts: _hasBreakdown ? Map<int, int>.of(_coinCounts) : const {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final editing = widget.entry != null;
    final accent = _kind == EntryKind.debit ? p.coral : p.forest;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 20),
            SheetHeader(
              title: editing ? 'Edit entry' : 'Add to count',
              subtitle: switch (_kind) {
                EntryKind.credit => 'Money coming in. Add it in seconds.',
                EntryKind.debit => 'Money going out. Add it in seconds.',
                EntryKind.counted => 'Every note counts. Add it in seconds.',
              },
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 22),
            _KindSelector(
              selected: _kind,
              onChanged: _setKind,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _error == null ? p.line : p.coral,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '৳',
                    style: context.texts.displaySmall?.copyWith(
                      color: accent,
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('entry-amount-field'),
                      controller: _amountController,
                      readOnly: _hasBreakdown,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      style: context.texts.displaySmall?.copyWith(
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: context.texts.displaySmall?.copyWith(
                          fontSize: 33,
                          fontWeight: FontWeight.w800,
                          color: p.inkSoft.withValues(alpha: 0.35),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  if (!_hasBreakdown && _amountController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _amountController.clear();
                        setState(() => _error = null);
                      },
                      icon: Icon(
                        Icons.cancel_rounded,
                        size: 19,
                        color: p.inkSoft.withValues(alpha: 0.55),
                      ),
                    ),
                  if (_hasBreakdown)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      child: Icon(
                        Icons.grid_view_rounded,
                        size: 17,
                        color: p.inkSoft.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _error!,
                  style: context.texts.bodySmall?.copyWith(color: p.coral),
                ),
              ),
            ],
            if (_kind == EntryKind.counted) ...[
              const SizedBox(height: 14),
              if (_hasBreakdown)
                _BreakdownCard(
                  items: _breakdownItems,
                  total: _breakdownTotal,
                  pieceCount: _pieceCount,
                  onEditItem: _editBreakdownItem,
                  onEditAll: _editAllBreakdown,
                  onClear: () => setState(() {
                    _noteCounts = {};
                    _coinCounts = {};
                  }),
                )
              else ...[
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _quickAmounts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final value = _quickAmounts[index];
                      final selected = _amount == value;
                      return PressableScale(
                        onTap: () => _setAmount(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? p.forest : p.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? p.forest : p.line,
                            ),
                          ),
                          child: Text(
                            '৳$value',
                            style: context.texts.labelMedium?.copyWith(
                              color: selected
                                  ? (p.isDark ? p.ink : Colors.white)
                                  : p.inkSoft,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _QuantityStepper(
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  onChanged: _onQuantityTyped,
                  onMinus: () => _changeQuantity(-1),
                  onPlus: () => _changeQuantity(1),
                ),
              ],
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _kind == EntryKind.debit
                    ? p.coralSoft.withValues(alpha: p.isDark ? 0.5 : 0.65)
                    : p.limeSoft.withValues(alpha: p.isDark ? 0.5 : 0.75),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    _kind == EntryKind.debit
                        ? Icons.remove_circle_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 19,
                    color: accent,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _kind == EntryKind.debit
                          ? 'Taking out'
                          : 'Adding to count',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_hasBreakdown) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$_pieceCount pieces',
                      style:
                          context.texts.bodySmall?.copyWith(color: p.inkSoft),
                    ),
                  ] else if (_kind == EntryKind.counted &&
                      _typedQuantity > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      '৳${formatNumber(_amount)} × $_typedQuantity',
                      style:
                          context.texts.bodySmall?.copyWith(color: p.inkSoft),
                    ),
                  ],
                  const SizedBox(width: 7),
                  Text(
                    formatMoney(
                      _kind == EntryKind.debit ? -_total : _total,
                      signed: true,
                    ),
                    style: context.texts.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      hintText: 'Add a note (optional)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 19),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _DateButton(date: _date, onTap: _pickDate),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: editing ? 'Save changes' : 'Add to counter',
              icon: editing ? Icons.check_rounded : Icons.add_rounded,
              onTap: _save,
              enabled: _amount > 0,
              height: 56,
            ),
            if (editing) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    EntryDraft(
                      kind: _kind,
                      amount: -1,
                      quantity: 1,
                      note: '',
                      date: _date,
                    ),
                  ),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: p.coral),
                  label: Text(
                    'Delete this entry',
                    style: TextStyle(color: p.coral),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.items,
    required this.total,
    required this.pieceCount,
    required this.onEditItem,
    required this.onEditAll,
    required this.onClear,
  });

  final List<({int value, int quantity, bool coin})> items;
  final int total;
  final int pieceCount;
  final ValueChanged<({int value, int quantity, bool coin})> onEditItem;
  final VoidCallback onEditAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'NOTES & COINS',
                style: context.texts.labelSmall?.copyWith(
                  color: p.inkSoft,
                  fontSize: 8.5,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                '$pieceCount ${pieceCount == 1 ? 'piece' : 'pieces'}',
                style: context.texts.bodySmall?.copyWith(
                  color: p.inkSoft,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) TakaDivider(),
            _BreakdownRow(
              item: items[i],
              onTap: () => onEditItem(items[i]),
            ),
          ],
          TakaDivider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total  ${formatMoney(total)}',
                  style: context.texts.titleSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('breakdown-edit-all'),
                onPressed: onEditAll,
                style: TextButton.styleFrom(
                  foregroundColor: p.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit all'),
              ),
              TextButton(
                key: const ValueKey('breakdown-clear'),
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: p.inkSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.onTap});

  final ({int value, int quantity, bool coin}) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final subtotal = item.value * item.quantity;
    return PressableScale(
      key: ValueKey('breakdown-${item.coin ? 'coin' : 'note'}-${item.value}'),
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '৳${formatNumber(item.value)} ${item.coin ? 'coin' : 'note'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '× ${item.quantity}',
              style: context.texts.bodySmall?.copyWith(
                color: p.inkSoft,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 66,
              child: Text(
                formatMoney(subtotal),
                textAlign: TextAlign.right,
                style: context.texts.titleSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 13,
              color: p.inkSoft.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onChanged});

  final EntryKind selected;
  final ValueChanged<EntryKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: EntryKind.values.map((kind) {
          final active = kind == selected;
          final accent = kind == EntryKind.debit ? p.coral : p.forest;
          return Expanded(
            child: PressableScale(
              onTap: () => onChanged(kind),
              scale: 0.97,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 43,
                decoration: BoxDecoration(
                  color: active ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      kind.icon,
                      size: 16,
                      color: active
                          ? Colors.white
                          : p.inkSoft.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kind.label,
                      style: context.texts.labelMedium?.copyWith(
                        color: active ? Colors.white : p.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onMinus,
    required this.onPlus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, size: 19, color: p.inkSoft),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of notes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap to type',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(color: p.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            height: 38,
            child: TextField(
              key: const ValueKey('entry-quantity-field'),
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: onChanged,
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              onSubmitted: (_) => focusNode.unfocus(),
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: p.surfaceMuted,
                hintText: '1',
                hintStyle: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: p.inkSoft.withValues(alpha: 0.35),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(width: 6),
          _StepButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return PressableScale(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: p.line),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: p.ink),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 17, color: p.ink),
            const SizedBox(width: 7),
            Text(
              isToday ? 'Today' : formatDateShort(date),
              style: context.texts.labelMedium?.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
