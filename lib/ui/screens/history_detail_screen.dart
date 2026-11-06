import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/share_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../app_scope.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'counter_screen.dart';
import 'voucher_screen.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final session = _findSession(store);
    final p = context.taka;

    if (session == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: PageBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Count not found',
                  message: 'This count may have been deleted.',
                  actionLabel: 'Back to history',
                  onAction: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isActive = session.id == store.activeId;

    return Scaffold(
      backgroundColor: p.background,
      body: PageBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.receipt_long_rounded,
                        tooltip: 'Create voucher',
                        onTap: () => Navigator.of(context).push(
                          appRoute(VoucherScreen(sessionId: session.id)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.ios_share_rounded,
                        tooltip: 'Share count',
                        onTap: () => shareSession(session),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete count',
                        color: p.coral,
                        onTap: () => _delete(context, store, session),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      AppPill(
                        label: isActive ? 'ACTIVE COUNT' : 'SAVED COUNT',
                        icon: isActive
                            ? Icons.bolt_rounded
                            : Icons.archive_outlined,
                        background: isActive ? p.limeSoft : p.surfaceMuted,
                        foreground: isActive ? p.accent : p.inkSoft,
                        border: isActive ? p.lime : p.line,
                      ),
                      const Spacer(),
                      Text(
                        formatDateShort(session.createdAt),
                        style: context.texts.bodySmall?.copyWith(
                          color: p.inkSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    session.title,
                    style: context.texts.headlineLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatDateHeader(session.createdAt)}  ·  ${formatTime(session.createdAt)}',
                    style: context.texts.bodySmall?.copyWith(
                      color: p.inkSoft,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailHero(session: session),
                  const SizedBox(height: 26),
                  SectionHeading(
                    title: 'Breakdown',
                    trailing: Text(
                      '${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}',
                      style: context.texts.bodySmall?.copyWith(
                        color: p.inkSoft,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (session.entries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: EmptyState(
                      compact: true,
                      icon: Icons.receipt_long_outlined,
                      title: 'No entries in this count',
                      message:
                          'Open the counter to add your first note to this count.',
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList.separated(
                  itemCount: session.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _DetailEntryRow(
                    entry: session.entries[index],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (isActive)
                      PrimaryButton(
                        label: 'Open in counter',
                        icon: Icons.payments_outlined,
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            appRoute(const CounterScreen()),
                          );
                        },
                      )
                    else
                      PrimaryButton(
                        label: 'Start a fresh count',
                        icon: Icons.add_rounded,
                        onTap: () {
                          store.startNewSession();
                          Navigator.of(context).pushReplacement(
                            appRoute(const CounterScreen()),
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Shared counts include every entry and note.',
                      style: context.texts.bodySmall?.copyWith(
                        color: p.inkSoft,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TallySession? _findSession(AppStore store) {
    for (final session in store.sessions) {
      if (session.id == sessionId) return session;
    }
    return null;
  }

  Future<void> _delete(
    BuildContext context,
    AppStore store,
    TallySession session,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete this count?',
      message:
          '“${session.title}” and all ${session.entryCount} entries will be permanently deleted.',
      confirmLabel: 'Delete count',
    );
    if (!confirmed || !context.mounted) return;
    store.deleteSession(session.id);
    AppSnack.show(context, 'Count deleted', icon: Icons.delete_outline_rounded);
    Navigator.of(context).maybePop();
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.session});

  final TallySession session;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.forest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: p.forestDeep.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.lime.withValues(alpha: 0.10),
                border: Border.all(
                  color: p.lime.withValues(alpha: 0.08),
                  width: 22,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 12,
            child: RotatedTakaWatermark(
              size: 132,
              opacity: 0.055,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL TAKA',
                  style: context.texts.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedMoney(
                  amount: session.total,
                  style: context.texts.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    letterSpacing: -1,
                  ),
                  symbolStyle: context.texts.headlineSmall?.copyWith(
                    color: p.lime,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'CASH IN',
                        value: formatMoney(session.totalIn),
                        color: p.lime,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 29,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    Expanded(
                      child: _HeroStat(
                        label: 'CASH OUT',
                        value: formatMoney(session.totalOut),
                        color: p.coral,
                        alignCenter: true,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 29,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    Expanded(
                      child: _HeroStat(
                        label: 'ENTRIES',
                        value: '${session.entryCount}',
                        color: Colors.white,
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    this.alignCenter = false,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignCenter;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : alignCenter
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.43),
            fontSize: 7.5,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DetailEntryRow extends StatelessWidget {
  const _DetailEntryRow({required this.entry});

  final TallyEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final isDebit = entry.kind == EntryKind.debit;
    final isCredit = entry.kind == EntryKind.credit;
    final accent = isDebit ? p.coral : p.accent;
    final soft = isDebit ? p.coralSoft : (isCredit ? p.limeSoft : p.surfaceMuted);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              isDebit ? '−' : isCredit ? '+' : '৳',
              style: TextStyle(
                fontFamily: isDebit || isCredit ? 'Manrope' : 'NotoSansBengali',
                fontSize: 16,
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
                  style: context.texts.titleSmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.hasBreakdown
                      ? '${entry.breakdownPreview}  ·  ${formatTime(entry.createdAt)}'
                      : entry.kind == EntryKind.counted
                          ? '৳${formatNumber(entry.amount)} × ${entry.quantity}  ·  ${formatTime(entry.createdAt)}'
                          : '${entry.kind.heading}  ·  ${formatTime(entry.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color: p.inkSoft,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isDebit
                ? formatMoney(-entry.value, signed: true)
                : isCredit
                    ? formatMoney(entry.value, signed: true)
                    : formatMoney(entry.value),
            style: context.texts.titleSmall?.copyWith(
              color: isDebit ? p.coral : p.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
