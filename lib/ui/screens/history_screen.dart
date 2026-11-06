import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../app_scope.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'history_detail_screen.dart';
import 'counter_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  _HistoryFilter _filter = _HistoryFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = context.taka;
    final sessions = _filtered(store);

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
                      if (store.sessions.length > 1)
                        RoundIconButton(
                          icon: Icons.delete_sweep_outlined,
                          tooltip: 'Clear saved history',
                          onTap: () => _clearHistory(context, store),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('History', style: context.texts.headlineLarge),
                  const SizedBox(height: 5),
                  Text(
                    'All your counts, calm and collected.',
                    style: context.texts.bodyMedium?.copyWith(
                      color: p.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: 11),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final filter in _HistoryFilter.values) ...[
                          _FilterChip(
                            label: filter.label,
                            selected: _filter == filter,
                            onTap: () {
                              AppScope.read(context).tapHaptic();
                              setState(() => _filter = filter);
                            },
                          ),
                          if (filter != _HistoryFilter.values.last)
                            const SizedBox(width: 7),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _HistorySummary(
                    total: store.historySessions
                        .fold(0, (sum, session) => sum + session.total),
                    count: store.historySessions.length,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (sessions.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                sliver: SliverToBoxAdapter(
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: EmptyState(
                      icon: _query.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.history_rounded,
                      title: _query.isNotEmpty
                          ? 'No matching counts'
                          : 'No saved counts yet',
                      message: _query.isNotEmpty
                          ? 'Try a different title, note or amount.'
                          : 'Finish your first count and it will show up here automatically.',
                      actionLabel:
                          _query.isNotEmpty ? null : 'Open counter',
                      onAction: _query.isNotEmpty
                          ? null
                          : () => Navigator.of(context).pushReplacement(
                                appRoute(const CounterScreen()),
                              ),
                    ),
                  ),
                ),
              )
            else
              ..._groupedSlivers(context, store, sessions),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  List<TallySession> _filtered(AppStore store) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final query = _query.trim().toLowerCase();

    return store.historySessions.where((session) {
      final matchesFilter = switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.today =>
          DateUtils.isSameDay(session.createdAt, now),
        _HistoryFilter.week =>
          session.createdAt.isAfter(startOfToday.subtract(const Duration(days: 7))),
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        session.title,
        formatMoney(session.total),
        formatNumber(session.total),
        formatDateShort(session.createdAt),
        ...session.entries.map((entry) => entry.note),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Widget> _groupedSlivers(
    BuildContext context,
    AppStore store,
    List<TallySession> sessions,
  ) {
    final slivers = <Widget>[];
    String? currentGroup;
    final items = <Widget>[];

    void flush() {
      if (items.isEmpty) return;
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.list(children: items.toList()),
        ),
      );
      items.clear();
    }

    for (final session in sessions) {
      final group = relativeDay(session.createdAt);
      if (group != currentGroup) {
        flush();
        currentGroup = group;
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 9),
            sliver: SliverToBoxAdapter(
              child: Text(
                group.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  color: context.taka.inkSoft,
                  letterSpacing: 1.5,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        );
      }
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _SessionCard(
            session: session,
            active: session.id == store.activeId,
            onTap: () => Navigator.of(context).push(
              appRoute(HistoryDetailScreen(sessionId: session.id)),
            ),
          ),
        ),
      );
    }
    flush();
    return slivers;
  }

  Future<void> _clearHistory(BuildContext context, AppStore store) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Clear saved history?',
      message:
          'All previous counts will be removed. Your current active count stays untouched.',
      confirmLabel: 'Clear history',
    );
    if (!confirmed || !context.mounted) return;
    store.clearHistory();
    AppSnack.show(context, 'History cleared', icon: Icons.auto_delete_outlined);
  }
}

enum _HistoryFilter {
  all('All'),
  today('Today'),
  week('This week');

  const _HistoryFilter(this.label);
  final String label;
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.texts.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search counts, notes or amounts',
        hintStyle: context.texts.bodyMedium?.copyWith(
          color: p.inkSoft.withValues(alpha: 0.7),
          fontSize: 12.5,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: p.inkSoft,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded, size: 18, color: p.inkSoft),
              ),
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.forest : p.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? p.forest : p.line),
        ),
        child: Text(
          label,
          style: context.texts.labelMedium?.copyWith(
            color: selected
                ? (p.isDark ? p.ink : Colors.white)
                : p.inkSoft,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.total, required this.count});

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.forest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: p.forestDeep.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.stacked_line_chart_rounded,
              size: 18,
              color: p.lime,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL TIME COUNTED',
                  style: context.texts.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  amount: total,
                  style: context.texts.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                  symbolStyle: context.texts.bodyMedium?.copyWith(
                    color: p.lime,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count ${plural(count, 'count')}',
              style: context.texts.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 9,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.active,
    required this.onTap,
  });

  final TallySession session;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      radius: 20,
      onTap: onTap,
      shadow: false,
      child: Row(
        children: [
          Container(
            width: 47,
            height: 51,
            decoration: BoxDecoration(
              color: active ? p.limeSoft : p.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? p.lime.withValues(alpha: 0.55) : p.line,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${session.createdAt.day}',
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: active ? p.accent : p.ink,
                  ),
                ),
                Text(
                  formatDateShort(session.createdAt).split(' ')[1].toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 7.5,
                    letterSpacing: 1,
                    color: p.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall?.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(width: 6),
                      AppPill(
                        label: 'ACTIVE',
                        background: p.limeSoft,
                        foreground: p.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        fontSize: 7.5,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTime(session.createdAt)}  ·  ${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}  ·  ${session.noteCount} ${plural(session.noteCount, 'note')}',
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(session.total),
                style: context.texts.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: p.inkSoft.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
