import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_info.dart';
import '../../core/formatters.dart';
import '../../core/share_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../app_scope.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import 'counter_screen.dart';
import 'history_detail_screen.dart';
import 'history_screen.dart';
import 'note_counter_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final session = store.activeSession;
    final p = context.taka;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: p.background,
      body: PageBackground(
        safeBottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList.list(
                children: [
                  Entrance(
                    child: Row(
                      children: [
                        TakaLogo(size: 43),
                        const Spacer(),
                        RoundIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Settings',
                          onTap: () => Navigator.of(context).push(
                            appRoute(const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Entrance(
                    delay: const Duration(milliseconds: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMMM')
                              .format(now)
                              .toUpperCase(),
                          style: context.texts.labelSmall?.copyWith(
                            color: p.inkSoft,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${greetingFor(now)}.',
                          style: context.texts.bodyLarge?.copyWith(
                            color: p.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Count every taka.',
                          style: context.texts.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Entrance(
                    delay: const Duration(milliseconds: 90),
                    child: _HeroCard(
                      session: session,
                      onOpen: () => _openCounter(context),
                      onNew: () => _newCount(context, store),
                      onShare: () => shareSession(session),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Entrance(
                    delay: Duration(milliseconds: 140),
                    child: SectionHeading(
                      title: 'Quick tools',
                      padding: EdgeInsets.fromLTRB(2, 0, 2, 12),
                    ),
                  ),
                  Entrance(
                    delay: const Duration(milliseconds: 170),
                    child: _QuickToolsGrid(
                      onCounter: () => _openCounter(context),
                      onHistory: () => Navigator.of(context).push(
                        appRoute(const HistoryScreen()),
                      ),
                      onNotes: () => Navigator.of(context).push(
                        appRoute(const NoteCounterScreen()),
                      ),
                      onSettings: () => Navigator.of(context).push(
                        appRoute(const SettingsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Entrance(
                    delay: const Duration(milliseconds: 220),
                    child: SectionHeading(
                      title: 'Recent counts',
                      trailing: store.hasHistory
                          ? PressableScale(
                              onTap: () => Navigator.of(context).push(
                                appRoute(const HistoryScreen()),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'View all',
                                    style: context.texts.labelMedium?.copyWith(
                                      color: p.accent,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: p.accent,
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  Entrance(
                    delay: const Duration(milliseconds: 250),
                    child: store.recentSessions.isEmpty
                        ? SurfaceCard(
                            padding: EdgeInsets.zero,
                            child: EmptyState(
                              compact: true,
                              icon: Icons.payments_outlined,
                              title: 'A clean slate',
                              message:
                                  'Add your first note and watch the total build up.',
                              actionLabel: 'Start counting',
                              onAction: () => _openCounter(context),
                            ),
                          )
                        : SurfaceCard(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                for (var i = 0;
                                    i < store.recentSessions.length;
                                    i++) ...[
                                  _RecentRow(
                                    session: store.recentSessions[i],
                                    active: i == 0 &&
                                        store.recentSessions[i].id ==
                                            session.id,
                                    onTap: () => Navigator.of(context).push(
                                      appRoute(
                                        HistoryDetailScreen(
                                          sessionId:
                                              store.recentSessions[i].id,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (i < store.recentSessions.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: TakaDivider(),
                                    ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  Entrance(
                    delay: const Duration(milliseconds: 280),
                    child: const _PrivateCard(),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 310),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Taka Counter ${AppInfo.version}',
                              style: context.texts.bodySmall?.copyWith(
                                color: p.inkSoft,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: p.inkSoft.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: shareApp,
                              child: Text(
                                'Share the app',
                                style: context.texts.bodySmall?.copyWith(
                                  color: p.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          AppInfo.developer,
                          style: context.texts.bodySmall?.copyWith(
                            color: p.inkSoft.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCounter(BuildContext context) {
    Navigator.of(context).push(appRoute(const CounterScreen()));
  }

  void _newCount(BuildContext context, AppStore store) {
    store.mediumHaptic();
    store.startNewSession();
    AppSnack.show(
      context,
      'Fresh count started',
      icon: Icons.auto_awesome_rounded,
    );
    _openCounter(context);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.session,
    required this.onOpen,
    required this.onNew,
    required this.onShare,
  });

  final TallySession session;
  final VoidCallback onOpen;
  final VoidCallback onNew;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final isEmpty = session.isEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.forest,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: p.forestDeep.withValues(alpha: 0.26),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44,
            top: -58,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.lime.withValues(alpha: 0.10),
                border: Border.all(
                  color: p.lime.withValues(alpha: 0.12),
                  width: 26,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 22,
            child: RotatedTakaWatermark(
              size: 172,
              color: Colors.white,
              opacity: 0.055,
            ),
          ),
          Positioned.fill(
            child: DottedPattern(
              color: Colors.white,
              opacity: 0.075,
              spacing: 22,
              dotSize: 1.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isEmpty ? p.gold : p.lime,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEmpty ? 'NEW COUNT' : 'ACTIVE COUNT',
                            style: context.texts.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.add_rounded,
                      onTap: onNew,
                      size: 36,
                      background: Colors.white.withValues(alpha: 0.10),
                      color: p.lime,
                      border: false,
                      tooltip: 'Start a new count',
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: onShare,
                      size: 36,
                      background: Colors.white.withValues(alpha: 0.10),
                      color: Colors.white,
                      border: false,
                      tooltip: 'Share this count',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'TOTAL IN THIS COUNT',
                  style: context.texts.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 9.5,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedMoney(
                  amount: session.total,
                  style: context.texts.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 39,
                    letterSpacing: -1.5,
                  ),
                  symbolStyle: context.texts.headlineSmall?.copyWith(
                    color: p.lime,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEmpty
                          ? 'Ready when you are'
                          : '${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}  ·  ${_age(session.updatedAt)}',
                      style: context.texts.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: isEmpty ? 'Start counting' : 'Open counter',
                        icon: Icons.arrow_forward_rounded,
                        onTap: onOpen,
                        background: p.lime,
                        foreground: p.forestDeep,
                        height: 49,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'History',
                      child: PressableScale(
                        onTap: () {
                          Navigator.of(context).push(
                            appRoute(const HistoryScreen()),
                          );
                        },
                        child: Container(
                          width: 49,
                          height: 49,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 21,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
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

  static String _age(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _QuickToolsGrid extends StatelessWidget {
  const _QuickToolsGrid({
    required this.onCounter,
    required this.onHistory,
    required this.onNotes,
    required this.onSettings,
  });

  final VoidCallback onCounter;
  final VoidCallback onHistory;
  final VoidCallback onNotes;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 120,
      ),
      children: [
        _ToolCard(
          title: 'Cash counter',
          subtitle: 'Your cash ledger',
          icon: Icons.payments_outlined,
          color: p.accent,
          background: p.limeSoft,
          onTap: onCounter,
        ),
        _ToolCard(
          title: 'History',
          subtitle: 'Every count, saved',
          icon: Icons.history_rounded,
          color: p.accent,
          background: p.skySoft,
          onTap: onHistory,
        ),
        _ToolCard(
          title: 'Note counter',
          subtitle: 'Notes, coins, one total',
          icon: Icons.style_rounded,
          color: p.ink,
          background: p.goldSoft,
          onTap: onNotes,
        ),
        _ToolCard(
          title: 'Settings',
          subtitle: 'Make it yours',
          icon: Icons.tune_rounded,
          color: p.accent,
          background: p.coralSoft,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      radius: 21,
      onTap: onTap,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                size: 38,
                iconSize: 18,
                radius: 12,
                background: background,
                color: color,
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: p.inkSoft.withValues(alpha: 0.55),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
              color: p.inkSoft,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
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
    return PressableScale(
      onTap: onTap,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active ? p.limeSoft : p.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '${session.createdAt.day}',
                style: context.texts.titleMedium?.copyWith(
                  color: active ? p.accent : p.ink,
                  fontWeight: FontWeight.w800,
                ),
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
                        const SizedBox(width: 7),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${relativeDay(session.createdAt)} · ${formatTime(session.createdAt)}  ·  ${session.entryCount} ${plural(session.entryCount, 'entry', 'entries')}',
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
            Text(
              formatMoney(session.total),
              style: context.texts.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: p.inkSoft.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateCard extends StatelessWidget {
  const _PrivateCard();

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return SurfaceCard(
      color: p.limeSoft,
      borderColor: p.lime.withValues(alpha: p.isDark ? 0.22 : 0.55),
      shadow: false,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: p.isDark ? 0.35 : 0.68),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shield_outlined, color: p.accent, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by design',
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'No account, no cloud. Your counts stay on this phone.',
                  style: context.texts.bodySmall?.copyWith(
                    color: p.inkSoft,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_outline_rounded,
            color: p.forest.withValues(alpha: 0.7),
            size: 18,
          ),
        ],
      ),
    );
  }
}
