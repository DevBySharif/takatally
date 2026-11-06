import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../core/formatters.dart';
import '../data/models.dart';

String sessionShareText(TallySession session) {
  final buffer = StringBuffer()
    ..writeln('*${session.title}*')
    ..writeln(formatDateTime(session.createdAt))
    ..writeln('')
    ..writeln('Total: ${formatMoney(session.total)}');
  if (session.totalOut > 0) {
    buffer.writeln(
      'In: ${formatMoney(session.totalIn)}  ·  Out: ${formatMoney(session.totalOut)}',
    );
  }
  buffer
    ..writeln('')
    ..writeln('Breakdown');
  for (final entry in session.entries) {
    final prefix = entry.kind == EntryKind.debit ? '−' : '+';
    final detail = entry.hasBreakdown
        ? '${entry.breakdownLabel}  (${entry.pieceCount} pcs)'
        : '৳${formatNumber(entry.amount)}  ×${entry.quantity}';
    buffer.writeln(
      '$prefix ${formatMoney(entry.value)}  ·  $detail  ·  ${entry.displayTitle}',
    );
  }
  buffer
    ..writeln('')
    ..write('Counted with Taka Counter · ${AppInfo.developer}');
  return buffer.toString();
}

Future<void> shareSession(TallySession session) async {
  await SharePlus.instance.share(
    ShareParams(
      text: sessionShareText(session),
      subject: '${session.title} · ${formatMoney(session.total)}',
    ),
  );
}

Future<void> shareApp() async {
  await SharePlus.instance.share(
    ShareParams(
      text:
          'Taka Counter — the calm, private way to count your cash. '
          'By ${AppInfo.developer}. '
          'Try it today: ${AppInfo.playStoreUrl}',
      subject: 'Taka Counter',
    ),
  );
}

Future<bool> rateApp() async {
  final market = Uri.parse('market://details?id=${AppInfo.packageId}');
  if (await canLaunchUrl(market)) {
    return launchUrl(market, mode: LaunchMode.externalApplication);
  }
  return launchUrl(
    Uri.parse(AppInfo.playStoreUrl),
    mode: LaunchMode.externalApplication,
  );
}

Future<bool> sendFeedback() async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppInfo.supportEmail,
    queryParameters: {
      'subject': 'Taka Counter feedback',
      'body': 'Hi Taka Counter team,\n\n',
    },
  );
  return launchUrl(uri);
}
