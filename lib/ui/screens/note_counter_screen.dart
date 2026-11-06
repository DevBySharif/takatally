import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../app_scope.dart';
import '../navigation.dart';
import '../sheets/count_entry_sheet.dart';
import '../widgets/common.dart';
import '../widgets/taka_note.dart';
import 'counter_screen.dart';

/// A full-screen counting table. It deliberately uses its own dark "felt"
/// treatment so it feels like a tool you open to count cash, not another
/// ledger screen.
class NoteCounterScreen extends StatefulWidget {
  const NoteCounterScreen({super.key});

  @override
  State<NoteCounterScreen> createState() => _NoteCounterScreenState();
}

class _NoteCounterScreenState extends State<NoteCounterScreen> {
  final Map<int, int> _noteCounts = {};
  final Map<int, int> _coinCounts = {};

  static int _sum(Map<int, int> counts) =>
      counts.entries.fold(0, (sum, e) => sum + e.key * e.value);

  static int _pieces(Map<int, int> counts) =>
      counts.values.fold(0, (sum, qty) => sum + qty);

  static int _types(Map<int, int> counts) =>
      counts.values.where((qty) => qty > 0).length;

  int get _noteTotal => _sum(_noteCounts);
  int get _coinTotal => _sum(_coinCounts);
  int get _total => _noteTotal + _coinTotal;
  int get _notePieces => _pieces(_noteCounts);
  int get _coinPieces => _pieces(_coinCounts);
  int get _typeCount => _types(_noteCounts) + _types(_coinCounts);

  void _add(Map<int, int> counts, int value, {int step = 1}) {
    final store = AppScope.read(context);
    if (step == 1) {
      store.tapHaptic();
    } else {
      store.mediumHaptic();
    }
    setState(() {
      counts.update(value, (qty) => qty + step, ifAbsent: () => step);
    });
  }

  void _remove(Map<int, int> counts, int value) {
    final store = AppScope.read(context);
    final current = counts[value] ?? 0;
    if (current == 0) return;
    store.tapHaptic();
    setState(() {
      if (current <= 1) {
        counts.remove(value);
      } else {
        counts[value] = current - 1;
      }
    });
  }

  Future<void> _typeQuantity(
    Map<int, int> counts,
    int value,
    String label,
    String bangla,
  ) async {
    final current = counts[value] ?? 0;
    final next = await showCountEntrySheet(
      context,
      title: label,
      subtitle: '$bangla · type a quantity instead of tapping +',
      initial: current,
      denomination: value,
    );
    if (next == null || !mounted) return;
    AppScope.read(context).tapHaptic();
    setState(() {
      if (next <= 0) {
        counts.remove(value);
      } else {
        counts[value] = next;
      }
    });
  }

  Future<void> _typeAll() async {
    final result = await showCountBulkSheet(
      context,
      notes: Map<int, int>.of(_noteCounts),
      coins: Map<int, int>.of(_coinCounts),
    );
    if (result == null || !mounted) return;
    AppScope.read(context).successHaptic();
    setState(() {
      _noteCounts
        ..clear()
        ..addAll(result.notes);
      _coinCounts
        ..clear()
        ..addAll(result.coins);
    });
  }

  void _reset() {
    if (_total == 0) return;
    final previousNotes = Map<int, int>.of(_noteCounts);
    final previousCoins = Map<int, int>.of(_coinCounts);
    AppScope.read(context).mediumHaptic();
    setState(() {
      _noteCounts.clear();
      _coinCounts.clear();
    });
    AppSnack.show(
      context,
      'Tray cleared',
      icon: Icons.refresh_rounded,
      actionLabel: 'Undo',
      onAction: () => setState(() {
        _noteCounts.addAll(previousNotes);
        _coinCounts.addAll(previousCoins);
      }),
    );
  }

  void _commit() {
    if (_total == 0) return;
    final store = AppScope.read(context);
    final added = _total;
    store.addEntry(
      TallyEntry(
        id: store.createId(),
        kind: EntryKind.counted,
        amount: added,
        quantity: 1,
        note: '',
        createdAt: DateTime.now(),
        noteCounts: Map<int, int>.of(_noteCounts),
        coinCounts: Map<int, int>.of(_coinCounts),
      ),
    );
    setState(() {
      _noteCounts.clear();
      _coinCounts.clear();
    });
    store.successHaptic();
    AppSnack.show(
      context,
      'Added ${formatMoney(added)} as one entry',
      actionLabel: 'Open',
      onAction: () =>
          Navigator.of(context).push(appRoute(const CounterScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFF09120C),
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarContrastEnforced: false,
              statusBarBrightness: Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFF09120C),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const _MatBackground(),
                  SafeArea(
                    bottom: false,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverList.list(
                            children: [
                              Row(
                                children: [
                                  RoundIconButton(
                                    icon: Icons.close_rounded,
                                    tooltip: 'Close',
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC7F36B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'COUNTING MODE',
                                          style: context.texts.labelSmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.66,
                                                ),
                                                fontSize: 8.5,
                                                letterSpacing: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Note counter',
                                style: context.texts.headlineLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Stack what is in front of you. The tray total goes into your count as one entry.',
                                style: context.texts.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.58),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _TraySummary(
                                total: _total,
                                notePieces: _notePieces,
                                coinPieces: _coinPieces,
                                typeCount: _typeCount,
                                onClear: _total == 0 ? null : _reset,
                                onType: _typeAll,
                              ),
                              const SizedBox(height: 26),
                              const SectionHeading(
                                title: 'Coins',
                                trailing: _TapHint(),
                              ),
                              Row(
                                children: [
                                  for (
                                    var i = 0;
                                    i < takaCoinDesigns.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: _CoinTile(
                                        design: takaCoinDesigns[i],
                                        quantity:
                                            _coinCounts[takaCoinDesigns[i]
                                                .value] ??
                                            0,
                                        onAdd: () => _add(
                                          _coinCounts,
                                          takaCoinDesigns[i].value,
                                        ),
                                        onAddTen: () => _add(
                                          _coinCounts,
                                          takaCoinDesigns[i].value,
                                          step: 10,
                                        ),
                                        onRemove: () => _remove(
                                          _coinCounts,
                                          takaCoinDesigns[i].value,
                                        ),
                                        onType: () => _typeQuantity(
                                          _coinCounts,
                                          takaCoinDesigns[i].value,
                                          '৳${formatNumber(takaCoinDesigns[i].value)} coin',
                                          takaCoinDesigns[i].banglaName,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 28),
                              const SectionHeading(
                                title: 'Banknotes',
                                trailing: _TapHint(),
                              ),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 9,
                                  crossAxisSpacing: 9,
                                  childAspectRatio: 0.93,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final design = takaNoteDesigns[index];
                              return _NoteTile(
                                design: design,
                                quantity: _noteCounts[design.value] ?? 0,
                                onAdd: () => _add(_noteCounts, design.value),
                                onAddTen: () =>
                                    _add(_noteCounts, design.value, step: 10),
                                onRemove: () =>
                                    _remove(_noteCounts, design.value),
                                onType: () => _typeQuantity(
                                  _noteCounts,
                                  design.value,
                                  '৳${formatNumber(design.value)} note',
                                  design.banglaName,
                                ),
                              );
                            }, childCount: takaNoteDesigns.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _AddBar(
                total: _total,
                onAdd: _total == 0 ? null : _commit,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatBackground extends StatelessWidget {
  const _MatBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4834), Color(0xFF0D1B13), Color(0xFF09120C)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: CustomPaint(painter: _MatPainter()),
    );
  }
}

class _MatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (var y = 14.0; y < size.height; y += 26) {
      for (var x = 14.0; x < size.width; x += 26) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    final ringCenter = Offset(size.width * 0.92, size.height * 0.03);
    canvas.drawCircle(ringCenter, 130, ring);
    canvas.drawCircle(ringCenter, 176, ring);

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFC7F36B).withValues(alpha: 0.13),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width * 0.95, 0), radius: 300),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), glow);
  }

  @override
  bool shouldRepaint(covariant _MatPainter oldDelegate) => false;
}

class _TapHint extends StatelessWidget {
  const _TapHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.42),
        ),
        const SizedBox(width: 4),
        Text(
          'Tap · hold ×10',
          style: context.texts.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _TraySummary extends StatelessWidget {
  const _TraySummary({
    required this.total,
    required this.notePieces,
    required this.coinPieces,
    required this.typeCount,
    required this.onType,
    this.onClear,
  });

  final int total;
  final int notePieces;
  final int coinPieces;
  final int typeCount;
  final VoidCallback onType;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: total > 0
                    ? TakaPalette.light.lime
                    : Colors.white.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'IN THE TRAY',
              style: context.texts.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 8.5,
                letterSpacing: 1.6,
              ),
            ),
            const Spacer(),
            _TrayPill(
              icon: Icons.keyboard_alt_outlined,
              label: 'Type',
              onTap: onType,
            ),
            if (onClear != null) ...[
              const SizedBox(width: 7),
              _TrayPill(
                icon: Icons.refresh_rounded,
                label: 'Clear',
                onTap: onClear!,
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        AnimatedMoney(
          amount: total,
          style: context.texts.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
            letterSpacing: -2,
          ),
          symbolStyle: context.texts.headlineMedium?.copyWith(
            color: TakaPalette.light.lime,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          total == 0
              ? 'Nothing counted yet — start with a note or coin.'
              : '$notePieces ${plural(notePieces, 'note', 'notes')}  ·  '
                    '$coinPieces ${plural(coinPieces, 'coin', 'coins')}  ·  '
                    '$typeCount ${plural(typeCount, 'type', 'types')}',
          style: context.texts.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TrayPill extends StatelessWidget {
  const _TrayPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.62)),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinTile extends StatelessWidget {
  const _CoinTile({
    required this.design,
    required this.quantity,
    required this.onAdd,
    required this.onAddTen,
    required this.onRemove,
    required this.onType,
  });

  final TakaCoinDesign design;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onAddTen;
  final VoidCallback onRemove;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final active = quantity > 0;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
      radius: 20,
      color: active ? p.limeSoft.withValues(alpha: 0.62) : null,
      borderColor: active ? p.lime.withValues(alpha: 0.80) : null,
      child: Column(
        children: [
          PressableScale(
            key: ValueKey('coin-art-${design.value}'),
            onTap: onAdd,
            onLongPress: onAddTen,
            scale: 0.94,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                TakaCoinArt(design: design, size: 62),
                if (active)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: _CountBadge(value: quantity, size: 21),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '৳${formatNumber(design.value)}',
            maxLines: 1,
            style: context.texts.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            design.banglaName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepButton(
                    icon: Icons.remove_rounded,
                    enabled: active,
                    onTap: onRemove,
                    size: 26,
                  ),
                  PressableScale(
                    onTap: onType,
                    scale: 0.9,
                    child: SizedBox(
                      width: 20,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: context.texts.titleSmall?.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          decorationColor: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add_rounded,
                    enabled: true,
                    onTap: onAdd,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.design,
    required this.quantity,
    required this.onAdd,
    required this.onAddTen,
    required this.onRemove,
    required this.onType,
  });

  final TakaNoteDesign design;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onAddTen;
  final VoidCallback onRemove;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final active = quantity > 0;
    final subtotal = design.value * quantity;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
      radius: 20,
      color: active ? p.limeSoft.withValues(alpha: 0.62) : null,
      borderColor: active ? p.lime.withValues(alpha: 0.80) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressableScale(
            key: ValueKey('note-art-${design.value}'),
            onTap: onAdd,
            onLongPress: onAddTen,
            scale: 0.97,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) =>
                      TakaNoteArt(design: design, width: constraints.maxWidth),
                ),
                if (active)
                  Positioned(
                    right: -4,
                    top: -5,
                    child: _CountBadge(value: quantity, size: 22),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '৳${formatNumber(design.value)} note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 4),
                Text(
                  '৳${formatNumber(subtotal)}',
                  maxLines: 1,
                  style: context.texts.bodySmall?.copyWith(
                    color: p.lime,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            design.banglaName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9.5,
            ),
          ),
          const Spacer(),
          Center(
            child: _Stepper(
              quantity: quantity,
              onAdd: onAdd,
              onRemove: onRemove,
              onType: onType,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value, required this.size});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: TakaPalette.light.lime,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TakaPalette.dark.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: context.texts.labelSmall?.copyWith(
          color: TakaPalette.dark.forestDeep,
          fontSize: 9.5,
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onType,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: quantity > 0,
            onTap: onRemove,
            size: 28,
          ),
          PressableScale(
            onTap: onType,
            scale: 0.9,
            child: SizedBox(
              width: 22,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: context.texts.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: quantity > 0
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: true,
            onTap: onAdd,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.size = 28,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onTap : null,
      scale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: enabled
              ? Border.all(color: Colors.white.withValues(alpha: 0.10))
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.52,
          color: enabled
              ? Colors.white.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({required this.total, this.onAdd});

  final int total;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF09120C).withValues(alpha: 0),
            const Color(0xFF09120C),
            const Color(0xFF09120C),
          ],
          stops: const [0, 0.3, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: PrimaryButton(
            label: total > 0
                ? 'Add ${formatMoney(total)} to count'
                : 'Add to count',
            icon: Icons.playlist_add_rounded,
            height: 56,
            background: p.lime,
            foreground: p.forestDeep,
            enabled: total > 0,
            onTap: onAdd,
          ),
        ),
      ),
    );
  }
}
