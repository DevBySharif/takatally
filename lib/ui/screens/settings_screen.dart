import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/export_service.dart';
import '../../core/formatters.dart';
import '../../core/share_utils.dart';
import '../../core/theme.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final settings = store.settings;
    final p = context.taka;

    return Scaffold(
      backgroundColor: p.background,
      body: PageBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              sliver: SliverList.list(
                children: [
                  Entrance(
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        AppPill(
                          label: 'BDT ৳',
                          icon: Icons.currency_exchange_rounded,
                          background: p.surface,
                          foreground: p.inkSoft,
                          border: p.line,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Entrance(
                    delay: const Duration(milliseconds: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: context.texts.headlineLarge),
                        const SizedBox(height: 5),
                        Text(
                          'Small choices that make counting feel yours.',
                          style: context.texts.bodyMedium?.copyWith(
                            color: p.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Entrance(
                    delay: const Duration(milliseconds: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Appearance'),
                        SurfaceCard(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: _ThemeSelector(
                            mode: settings.themeMode,
                            onChanged: store.setThemeMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Counting'),
                        SurfaceCard(
                          padding:
                              const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: Icons.vibration_rounded,
                                title: 'Haptic feedback',
                                subtitle: 'A gentle tap as you count',
                                trailing: Switch.adaptive(
                                  value: settings.haptics,
                                  onChanged: store.setHaptics,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.delete_outline_rounded,
                                title: 'Confirm before deleting',
                                subtitle: 'Ask me before an entry disappears',
                                trailing: Switch.adaptive(
                                  value: settings.confirmDeletes,
                                  onChanged: store.setConfirmDeletes,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.phonelink_lock_outlined,
                                title: 'On-device storage',
                                subtitle: 'No account and no cloud required',
                                trailing: AppPill(
                                  label: 'ON',
                                  icon: Icons.lock_outline_rounded,
                                  background: p.limeSoft,
                                  foreground: p.accent,
                                  border: p.lime,
                                  fontSize: 8.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Support'),
                        SurfaceCard(
                          padding:
                              const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: Icons.star_outline_rounded,
                                title: 'Rate TakaTally',
                                subtitle: 'A review helps a lot',
                                onTap: () => _rate(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.ios_share_rounded,
                                title: 'Share the app',
                                subtitle: 'Tell a friend who counts cash',
                                onTap: shareApp,
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.mail_outline_rounded,
                                title: 'Send feedback',
                                subtitle: 'We read every message',
                                onTap: () => _feedback(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.shield_outlined,
                                title: 'Privacy & data',
                                subtitle: 'How your counts are kept',
                                onTap: () => _showPrivacy(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.info_outline_rounded,
                                title: 'About TakaTally',
                                subtitle: 'Version ${AppInfo.version}',
                                onTap: () => _showAbout(context),
                                trailing: _chevron(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(title: 'Data & backup'),
                        SurfaceCard(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: Icons.grid_on_rounded,
                                title: 'Export to Excel',
                                subtitle: 'Every count as an .xlsx sheet',
                                onTap: () => _exportExcel(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.backup_outlined,
                                title: 'Save a backup',
                                subtitle: 'Restore it any time (.json)',
                                onTap: () => _exportBackup(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.file_download_outlined,
                                title: 'Import data',
                                subtitle: 'Excel, CSV, or a backup file',
                                onTap: () => _importData(context),
                                trailing: _chevron(context),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TakaDivider(),
                              ),
                              _SettingsRow(
                                icon: Icons.add_to_drive_rounded,
                                title: 'Google Drive',
                                subtitle: 'Save exported files to Drive',
                                onTap: () => _driveHelp(context),
                                trailing: _chevron(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 240),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: p.forest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: p.lime,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.block_rounded,
                              color: p.forestDeep,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No ads. Ever.',
                                  style: context.texts.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TakaTally is free, calm and focused on one job.',
                                  style: context.texts.bodySmall?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.58),
                                    fontSize: 10.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Entrance(
                    delay: const Duration(milliseconds: 280),
                    child: Column(
                      children: [
                        TakaLogo(size: 36, showWordmark: false),
                        const SizedBox(height: 9),
                        Text(
                          'Made with care for Bangladesh',
                          style: context.texts.bodySmall?.copyWith(
                            color: p.inkSoft,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppInfo.developer,
                          style: context.texts.bodySmall?.copyWith(
                            color: p.inkSoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${AppInfo.version}',
                          style: context.texts.bodySmall?.copyWith(
                            color: p.inkSoft.withValues(alpha: 0.6),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chevron(BuildContext context) => Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: context.taka.inkSoft.withValues(alpha: 0.55),
      );

  Future<void> _rate(BuildContext context) async {
    final opened = await rateApp();
    if (!opened && context.mounted) {
      AppSnack.show(
        context,
        'The Play Store is not available on this device.',
        icon: Icons.storefront_outlined,
      );
    }
  }

  Future<void> _feedback(BuildContext context) async {
    final opened = await sendFeedback();
    if (!opened && context.mounted) {
      AppSnack.show(
        context,
        'No email app is available right now.',
        icon: Icons.mail_outline_rounded,
      );
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final store = AppScope.of(context);
    try {
      final file = await ExportService.workbook(store.sessions);
      await ExportService.shareFile(
        file,
        subject: 'TakaTally · Excel export',
        text: 'All counts exported from TakaTally.',
      );
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          'Export needs a device file system.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final store = AppScope.of(context);
    try {
      final file = await ExportService.backup(store.sessions);
      await ExportService.shareFile(
        file,
        subject: 'TakaTally · Backup',
        text: 'TakaTally backup. Keep it safe.',
      );
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          'Backup needs a device file system.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'xlsx', 'xls', 'csv', 'txt'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final pickedFile = picked.files.single;
      final path = pickedFile.path;
      if (path == null) {
        if (context.mounted) {
          AppSnack.show(
            context,
            'That file could not be read.',
            icon: Icons.error_outline_rounded,
          );
        }
        return;
      }

      final data = await ExportService.readFile(
        File(path),
        name: pickedFile.name,
      );
      if (!context.mounted) return;
      final store = AppScope.of(context);

      var replace = false;
      if (data.isBackup && store.historySessions.isNotEmpty) {
        replace = await showConfirmSheet(
              context,
              title: 'Restore this backup?',
              message:
                  '${data.entryCount} entries in ${data.sessions.length} '
                  '${plural(data.sessions.length, 'count')} will replace what '
                  'is on this phone. Choose "Merge" to keep both.',
              confirmLabel: 'Replace all',
              cancelLabel: 'Merge',
              icon: Icons.restore_rounded,
              destructive: false,
            );
      }

      if (!context.mounted) return;
      store.importSessions(data.sessions, replace: replace);
      AppSnack.show(
        context,
        'Imported ${data.entryCount} '
        '${plural(data.entryCount, 'entry', 'entries')}',
        icon: Icons.download_done_rounded,
      );
    } on FormatException catch (error) {
      if (context.mounted) {
        AppSnack.show(
          context,
          error.message,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.show(
          context,
          'That file could not be imported.',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _driveHelp(BuildContext context) async {
    await showTakaSheet<void>(
      context,
      builder: (sheetContext) {
        final p = sheetContext.taka;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 20),
              SheetHeader(
                title: 'Save to Google Drive',
                subtitle: 'Your files, your Drive — no account inside the app.',
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 18),
              for (final step in const [
                'Export Excel, a backup, or a voucher.',
                'In the Android share sheet, pick Drive.',
                'The file appears in your Drive, ready to open in Sheets.',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: p.limeSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: sheetContext.texts.bodyMedium?.copyWith(
                            color: p.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Text(
                  'Direct Drive sync with Google sign-in is the next step and '
                  'needs a Google Cloud OAuth client for this app.',
                  style: sheetContext.texts.bodySmall?.copyWith(
                    color: p.inkSoft,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    await showTakaSheet<void>(
      context,
      builder: (sheetContext) {
        final p = sheetContext.taka;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 26),
              const TakaLogo(size: 64, showWordmark: false),
              const SizedBox(height: 14),
              Text('TakaTally', style: sheetContext.texts.headlineSmall),
              const SizedBox(height: 5),
              Text(
                'Note Counter · Version ${AppInfo.version}',
                style: sheetContext.texts.bodySmall?.copyWith(
                  color: p.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A beautifully simple cash counter, built for the way Bangladesh counts. No accounts, no noise, no ads.',
                textAlign: TextAlign.center,
                style: sheetContext.texts.bodyMedium?.copyWith(
                  color: p.inkSoft,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shadow: false,
                color: p.surfaceMuted,
                child: Row(
                  children: [
                    _AboutStat(
                      label: 'COUNTS',
                      value: '${AppScope.of(sheetContext).totalSessions}',
                    ),
                    _AboutDivider(color: p.line),
                    _AboutStat(
                      label: 'ENTRIES',
                      value: '${AppScope.of(sheetContext).totalEntries}',
                    ),
                    _AboutDivider(color: p.line),
                    _AboutStat(
                      label: 'STORAGE',
                      value: 'Local',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '© ${DateTime.now().year} TakaTally',
                style: sheetContext.texts.bodySmall?.copyWith(
                  color: p.inkSoft.withValues(alpha: 0.7),
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Developed by ${AppInfo.developer}',
                style: sheetContext.texts.bodySmall?.copyWith(
                  color: p.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPrivacy(BuildContext context) async {
    await showTakaSheet<void>(
      context,
      builder: (sheetContext) {
        final p = sheetContext.taka;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 26),
              SheetHeader(
                title: 'Privacy & data',
                subtitle: 'Plain words, because that is how it should be.',
                onClose: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 22),
              _PrivacyPoint(
                icon: Icons.phone_android_rounded,
                title: 'Stored on this device',
                body:
                    'Your counts and preferences live in the app’s local storage. They are not uploaded anywhere.',
              ),
              const SizedBox(height: 16),
              _PrivacyPoint(
                icon: Icons.person_off_outlined,
                title: 'No account',
                body:
                    'There is no sign-up, no email and no profile. TakaTally never needs to know who you are.',
              ),
              const SizedBox(height: 16),
              _PrivacyPoint(
                icon: Icons.analytics_outlined,
                title: 'No tracking',
                body:
                    'No analytics, no advertising SDKs and no third-party profiling.',
              ),
              const SizedBox(height: 16),
              _PrivacyPoint(
                icon: Icons.delete_outline_rounded,
                title: 'You are in control',
                body:
                    'Delete a count at any time. Uninstalling the app removes its local data from the device.',
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.limeSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: p.lime.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: p.accent,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'TakaTally works fully offline. Your cash is your business.',
                        style: sheetContext.texts.bodySmall?.copyWith(
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeOption(
            label: 'System',
            mode: ThemeMode.system,
            selected: mode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ThemeOption(
            label: 'Light',
            mode: ThemeMode.light,
            selected: mode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ThemeOption(
            label: 'Dark',
            mode: ThemeMode.dark,
            selected: mode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return PressableScale(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
        decoration: BoxDecoration(
          color: selected ? p.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? p.forest : p.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 43,
              decoration: BoxDecoration(
                color: mode == ThemeMode.dark
                    ? const Color(0xFF0C1611)
                    : const Color(0xFFF5F3EC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: p.line.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (mode != ThemeMode.light) ...[
                    Expanded(
                      child: Container(
                        color: mode == ThemeMode.dark
                            ? const Color(0xFF14221A)
                            : const Color(0xFF14221A),
                      ),
                    ),
                  ],
                  if (mode == ThemeMode.system)
                    Container(
                      width: 1,
                      color: p.inkSoft.withValues(alpha: 0.25),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      color: mode == ThemeMode.dark
                          ? const Color(0xFF0C1611)
                          : const Color(0xFFF5F3EC),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 19,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: mode == ThemeMode.dark
                                  ? const Color(0xFFC7F36B)
                                  : const Color(0xFF173F2E),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 31,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF68736C)
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 24,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF68736C)
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: context.texts.labelSmall?.copyWith(
                color: selected ? p.ink : p.inkSoft,
                fontSize: 9.5,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 13, 11),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            size: 38,
            iconSize: 18,
            radius: 12,
            background: p.surfaceMuted,
            color: p.inkSoft,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.titleSmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: context.texts.bodySmall?.copyWith(
                    color: p.inkSoft,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return PressableScale(onTap: onTap, child: content);
  }
}

class _AboutStat extends StatelessWidget {
  const _AboutStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              fontSize: 7.5,
              letterSpacing: 1,
              color: p.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutDivider extends StatelessWidget {
  const _AboutDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: color);
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(
          icon: icon,
          size: 38,
          iconSize: 18,
          radius: 12,
          background: p.surfaceMuted,
          color: p.accent,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.texts.titleSmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: context.texts.bodySmall?.copyWith(
                  color: p.inkSoft,
                  height: 1.5,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
