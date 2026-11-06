import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/share_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../app_scope.dart';
import '../navigation.dart';
import '../sheets/entry_editor.dart';
import '../widgets/common.dart';
import 'note_counter_screen.dart';
import 'voucher_screen.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final session = store.activeSession;
    final p = context.taka;

    return Scaffold(
      backgroundColor: p.background,
      body: PageBackground(
        safeBottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  AppPill(
                    label: formatDateShort(session.createdAt),
                    icon: Icons.calendar_today_outlined,
                    background: p.surface,
                    foreground: p.inkSoft,
                    border: p.line,
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'Count options',
                    onTap: () => _showMenu(context, store, session),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  session.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.texts.headlineLarge,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: PressableScale(
                                  onTap: () => _rename(context, store),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: p.surfaceMuted,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: p.line),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: p.inkSoft,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatDateHeader(session.createdAt)}  ·  Tap an entry to edit',
                            style: context.texts.bodySmall?.copyWith(
                              color: p.inkSoft,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'CASH IN',
                                  amount: session.totalIn,
                                  icon: Icons.south_west_rounded,
                                  color: p.accent,
                                  soft: p.limeSoft,
                                  onTap: () => _addEntry(
                                    context,
                                    store,
                                    initialKind: EntryKind.credit,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'CASH OUT',
                                  amount: session.totalOut,
                                  icon: Icons.north_east_rounded,
                                  color: p.coral,
                                  soft: p.coralSoft,
                                  onTap: () => _addEntry(
                                    context,
                                    store,
                                    initialKind: EntryKind.debit,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              AppPill(
                                label:
                                    '${session.noteCount} ${plural(session.noteCount, 'note')}',
                                icon: Icons.layers_outlined,
                                background: p.surface,
                                foreground: p.inkSoft,
                                border: p.line,
                              ),
                              const SizedBox(width: 7),
                              AppPill(
                                label:
                                    '${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}',
                                icon: Icons.receipt_long_outlined,
                                background: p.surface,
                                foreground: p.inkSoft,
                                border: p.line,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SurfaceCard(
                            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                            radius: 20,
                            color: p.isDark
                                ? p.surface
                                : p.limeSoft.withValues(alpha: 0.45),
                            borderColor:
                                p.lime.withValues(alpha: p.isDark ? 0.30 : 0.7),
                            onTap: () => Navigator.of(context).push(
                              appRoute(const NoteCounterScreen()),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: p.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: p.line),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.style_rounded,
                                    size: 20,
                                    color: p.accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Open note counter',
                                        style: context.texts.titleSmall
                                            ?.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Notes + coins, added as one total',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.texts.bodySmall
                                            ?.copyWith(
                                          color: p.inkSoft,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: p.inkSoft.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SectionHeading(
                            title: 'Breakdown',
                            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                            trailing: PressableScale(
                              onTap: () => _addEntry(context, store),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: p.lime,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 15,
                                      color: p.forestDeep,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Add note',
                                      style:
                                          context.texts.labelMedium?.copyWith(
                                        color: p.forestDeep,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (session.entries.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                      sliver: SliverToBoxAdapter(
                        child: SurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              _CashIllustration(),
                              EmptyState(
                                compact: true,
                                icon: Icons.add_card_rounded,
                                title: 'Start with your first note',
                                message:
                                    'Choose a denomination, set how many notes, and the total updates instantly.',
                                actionLabel: 'Add an entry',
                                onAction: () => _addEntry(context, store),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
                      sliver: SliverList.separated(
                        itemCount: session.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final entry = session.entries[index];
                          return Dismissible(
                            key: ValueKey(entry.id),
                            direction: DismissDirection.endToStart,
                            background: _DismissBackground(),
                            confirmDismiss: (_) async {
                              if (!store.settings.confirmDeletes) return true;
                              return showConfirmSheet(
                                context,
                                title: 'Remove this entry?',
                                message:
                                    '“${entry.displayTitle}” will be removed from this count.',
                                confirmLabel: 'Remove',
                                cancelLabel: 'Keep',
                              );
                            },
                            onDismissed: (_) {
                              _deleteEntry(context, store, session, entry);
                            },
                            child: _EntryRow(
                              entry: entry,
                              onTap: () => _editEntry(
                                context,
                                store,
                                session,
                                entry,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TotalBar(
        total: session.total,
        onAdd: () => _addEntry(context, store),
        onShare: () => shareSession(session),
      ),
    );
  }

  Future<void> _addEntry(
    BuildContext context,
    AppStore store, {
    EntryKind initialKind = EntryKind.counted,
  }) async {
    store.tapHaptic();
    final draft = await showEntryEditor(
      context,
      initialKind: initialKind,
    );
    if (draft == null) return;
    store.addEntry(
      TallyEntry(
        id: store.createId(),
        kind: draft.kind,
        amount: draft.amount,
        quantity: draft.quantity,
        note: draft.note,
        createdAt: draft.date,
        noteCounts: draft.noteCounts,
        coinCounts: draft.coinCounts,
      ),
    );
    if (context.mounted) {
      AppSnack.show(
        context,
        'Entry added to your count',
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  Future<void> _editEntry(
    BuildContext context,
    AppStore store,
    TallySession session,
    TallyEntry entry,
  ) async {
    store.tapHaptic();
    final draft = await showEntryEditor(context, entry: entry);
    if (draft == null) return;
    if (draft.amount < 0) {
      if (context.mounted) {
        _deleteEntry(context, store, session, entry);
      }
      return;
    }
    store.updateEntry(
      session.id,
      entry.copyWith(
        kind: draft.kind,
        amount: draft.amount,
        quantity: draft.quantity,
        note: draft.note,
        createdAt: draft.date,
        noteCounts: draft.noteCounts,
        coinCounts: draft.coinCounts,
      ),
    );
    if (context.mounted) {
      AppSnack.show(context, 'Entry updated', icon: Icons.edit_outlined);
    }
  }

  void _deleteEntry(
    BuildContext context,
    AppStore store,
    TallySession session,
    TallyEntry entry,
  ) {
    store.deleteEntry(session.id, entry.id);
    AppScope.read(context).mediumHaptic();
    AppSnack.show(
      context,
      'Entry removed',
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Undo',
      onAction: () => store.addEntry(entry, sessionId: session.id),
    );
  }

  Future<void> _rename(BuildContext context, AppStore store) async {
    final title = await showRenameDialog(
      context,
      initial: store.activeSession.title,
    );
    if (title != null) {
      store.renameActiveSession(title);
      if (context.mounted) {
        AppSnack.show(context, 'Count renamed', icon: Icons.edit_outlined);
      }
    }
  }

  Future<void> _showMenu(
    BuildContext context,
    AppStore store,
    TallySession session,
  ) async {
    store.tapHaptic();
    final action = await showTakaSheet<_CounterAction>(
      context,
      builder: (sheetContext) {
        final p = sheetContext.taka;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 22),
              SheetHeader(
                title: 'Count options',
                subtitle: 'Everything for this count, in one place.',
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 5),
                shadow: false,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.style_rounded,
                      label: 'Open note counter',
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_CounterAction.noteCounter),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TakaDivider(),
                    ),
                    _MenuTile(
                      icon: Icons.edit_outlined,
                      label: 'Rename this count',
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_CounterAction.rename),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TakaDivider(),
                    ),
                    _MenuTile(
                      icon: Icons.add_rounded,
                      label: 'Start a new count',
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_CounterAction.newCount),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TakaDivider(),
                    ),
                    _MenuTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Create a voucher',
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_CounterAction.voucher),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TakaDivider(),
                    ),
                    _MenuTile(
                      icon: Icons.ios_share_rounded,
                      label: 'Share this count',
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_CounterAction.share),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 5),
                shadow: false,
                child: _MenuTile(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear all entries',
                  color: p.coral,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CounterAction.clear),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;
    switch (action) {
      case _CounterAction.noteCounter:
        Navigator.of(context).push(appRoute(const NoteCounterScreen()));
      case _CounterAction.rename:
        await _rename(context, store);
      case _CounterAction.newCount:
        store.startNewSession();
        if (context.mounted) {
          AppSnack.show(context, 'Fresh count started');
        }
      case _CounterAction.share:
        await shareSession(session);
      case _CounterAction.voucher:
        await Navigator.of(context).push(
          appRoute(VoucherScreen(sessionId: session.id)),
        );
      case _CounterAction.clear:
        final confirmed = await showConfirmSheet(
          context,
          title: 'Clear this count?',
          message:
              'All ${session.entryCount} entries will be removed. This cannot be undone.',
          confirmLabel: 'Clear count',
        );
        if (confirmed) {
          store.clearEntries();
          if (context.mounted) {
            AppSnack.show(context, 'Count cleared');
          }
        }
    }
  }
}

enum _CounterAction { noteCounter, rename, newCount, share, voucher, clear }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      radius: 21,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                size: 30,
                iconSize: 15,
                radius: 10,
                background: soft,
                color: color,
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: p.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: p.inkSoft,
              fontSize: 8.5,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              amount: amount,
              style: context.texts.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              symbolStyle: context.texts.bodyMedium?.copyWith(
                fontSize: 12,
                color: p.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.onTap});

  final TallyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final isDebit = entry.kind == EntryKind.debit;
    final isCredit = entry.kind == EntryKind.credit;
    final accent = isDebit ? p.coral : p.accent;
    final soft = isDebit ? p.coralSoft : (isCredit ? p.limeSoft : p.surfaceMuted);

    final right = isDebit
        ? formatMoney(-entry.value, signed: true)
        : isCredit
            ? formatMoney(entry.value, signed: true)
            : formatMoney(entry.value);

    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                isDebit ? '−' : isCredit ? '+' : '৳',
                style: TextStyle(
                  fontFamily: isDebit || isCredit ? 'Manrope' : 'NotoSansBengali',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleSmall?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.hasBreakdown
                        ? '${entry.breakdownPreview}  ·   ${formatTime(entry.createdAt)}'
                        : entry.kind == EntryKind.counted
                            ? '৳${formatNumber(entry.amount)} × ${entry.quantity}  ·   ${formatTime(entry.createdAt)}'
                            : '${entry.kind.heading}  ·  ${formatTime(entry.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(
                      color: p.inkSoft,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  right,
                  style: context.texts.titleSmall?.copyWith(
                    color: isDebit ? p.coral : p.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: p.inkSoft.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      padding: const EdgeInsets.only(right: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: p.coral,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 5),
          Text(
            'Remove',
            style: context.texts.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.total,
    required this.onAdd,
    required this.onShare,
  });

  final int total;
  final VoidCallback onAdd;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.background.withValues(alpha: 0),
            p.background,
            p.background,
          ],
          stops: const [0, 0.32, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            decoration: BoxDecoration(
              color: p.forest,
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: p.forestDeep.withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL TAKA',
                        style: context.texts.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 8.5,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      AnimatedMoney(
                        amount: total,
                        style: context.texts.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                          letterSpacing: -0.6,
                        ),
                        symbolStyle: context.texts.titleSmall?.copyWith(
                          color: p.lime,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                  size: 42,
                  background: Colors.white.withValues(alpha: 0.09),
                  color: Colors.white,
                  border: false,
                  tooltip: 'Share count',
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Add entry',
                  child: PressableScale(
                    onTap: onAdd,
                    scale: 0.92,
                    child: Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        color: p.lime,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: p.forestDeep,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return SizedBox(
      height: 74,
      width: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: _note(p, p.goldSoft, p.gold),
          ),
          Positioned(
            top: 10,
            child: Transform.rotate(
              angle: 0.05,
              child: _note(p, p.limeSoft, p.lime),
            ),
          ),
          Positioned(
            top: 18,
            child: Transform.rotate(
              angle: -0.02,
              child: _note(p, p.surface, p.line),
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(TakaPalette p, Color fill, Color border) {
    return Container(
      width: 108,
      height: 46,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              color: p.forest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '৳',
              style: TextStyle(
                fontFamily: 'NotoSansBengali',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: p.lime,
                height: 1,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'TAKA',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: p.ink.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color ?? p.inkSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: context.texts.bodyMedium?.copyWith(
                  color: color ?? p.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: p.inkSoft.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
