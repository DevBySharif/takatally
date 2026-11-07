import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/export_service.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/voucher.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// A printable cash-count voucher for one count. It previews the same layout
/// that is exported as a PDF, so what you see is what you share.
class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  bool _busy = false;

  TallySession? _findSession(AppStore store) {
    for (final session in store.sessions) {
      if (session.id == widget.sessionId) return session;
    }
    return null;
  }

  Future<void> _run(Future<String?> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final message = await task();
      if (mounted && message != null) {
        AppSnack.show(
          context,
          message,
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnack.show(
          context,
          'Could not create the PDF. Try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _downloadPdf(TallySession session) async {
    final bytes = await buildVoucherPdfBytes(session);
    final name = voucherPdfName(session);
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save voucher PDF',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    if (kIsWeb) return 'PDF download started';
    if (path == null) return null;
    return 'Saved $name';
  }

  Future<String?> _printPdf(TallySession session) async {
    final bytes = await buildVoucherPdfBytes(session);
    await Printing.layoutPdf(
      name: voucherPdfName(session),
      onLayout: (_) async => bytes,
    );
    return null;
  }

  Future<String?> _sharePdf(TallySession session) async {
    final file = await buildVoucherPdf(session);
    await ExportService.shareFile(
      file,
      subject: 'Cash count voucher · ${session.title}',
      text: 'Voucher ${voucherNumber(session)} · ${formatMoney(session.total)}',
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final session = _findSession(store);
    final p = context.taka;

    if (session == null) {
      return Scaffold(
        backgroundColor: p.background,
        body: PageBackground(
          child: Center(
            child: Text('This count is no longer available.',
                style: context.texts.bodyMedium),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      body: PageBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 210),
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
                        icon: Icons.grid_on_rounded,
                        tooltip: 'Export Excel',
                        onTap: _busy
                            ? null
                            : () => _run(
                                  () async {
                                    final file = await ExportService.workbook(
                                      [session],
                                    );
                                    await ExportService.shareFile(
                                      file,
                                      subject:
                                          '${session.title} · Excel export',
                                      text:
                                          'Count sheet for ${session.title}',
                                    );
                                    return 'Excel ready';
                                  },
                                ),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.picture_as_pdf_rounded,
                        tooltip: 'Share PDF',
                        onTap: _busy
                            ? null
                            : () => _run(() => _sharePdf(session)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Voucher', style: context.texts.headlineLarge),
                  const SizedBox(height: 5),
                  Text(
                    'Download or print it, or hand it over with the cash.',
                    style: context.texts.bodyMedium?.copyWith(
                      color: p.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _VoucherPaper(session: session),
                  const SizedBox(height: 18),
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    shadow: false,
                    color: p.surfaceMuted,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 18,
                          color: p.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Download saves the PDF to Files or Drive. '
                            'Print opens your phone’s print dialog. '
                            'Everything is generated on this phone.',
                            style: context.texts.bodySmall?.copyWith(
                              color: p.inkSoft,
                              height: 1.45,
                            ),
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
      bottomNavigationBar: Container(
        color: p.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: _busy ? 'Preparing…' : 'Download PDF',
                  icon: Icons.file_download_outlined,
                  height: 54,
                  enabled: !_busy,
                  onTap: () => _run(() => _downloadPdf(session)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'Print',
                        icon: Icons.print_outlined,
                        expanded: true,
                        height: 48,
                        onTap: _busy ? null : () => _run(() => _printPdf(session)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GhostButton(
                        label: 'Share',
                        icon: Icons.ios_share_rounded,
                        expanded: true,
                        height: 48,
                        onTap: _busy ? null : () => _run(() => _sharePdf(session)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoucherPaper extends StatelessWidget {
  const _VoucherPaper({required this.session});

  final TallySession session;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final paper = p.isDark ? p.surface : const Color(0xFFFDFBF4);

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: p.isDark ? 0.35 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const TakaLogo(size: 34, showWordmark: false),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Taka',
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 11,
                            letterSpacing: -0.2,
                            color: p.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'Tally',
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 11,
                            letterSpacing: -0.2,
                            color: p.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'CASH, MADE CLEAR',
                    style: context.texts.labelSmall?.copyWith(
                      fontSize: 7,
                      letterSpacing: 1.6,
                      color: p.inkSoft,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.forest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'BDT ৳',
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 7.5,
                    letterSpacing: 1,
                    color: p.lime,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'CASH COUNT VOUCHER',
            style: context.texts.labelSmall?.copyWith(
              fontSize: 8,
              letterSpacing: 2.2,
              color: p.inkSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            session.title,
            style: context.texts.headlineSmall?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Meta(
                  label: 'VOUCHER',
                  value: voucherNumber(session),
                ),
              ),
              Expanded(
                child: _Meta(
                  label: 'DATE',
                  value: formatDateTime(session.createdAt),
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'DESCRIPTION',
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 7,
                            letterSpacing: 1.2,
                            color: p.inkSoft,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'QTY',
                          textAlign: TextAlign.right,
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 7,
                            letterSpacing: 1.2,
                            color: p.inkSoft,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 7,
                            letterSpacing: 1.2,
                            color: p.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (session.entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No entries in this count.',
                      style: context.texts.bodySmall?.copyWith(
                        color: p.inkSoft,
                      ),
                    ),
                  ),
                for (final entry in session.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: p.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            entry.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 11,
                              color: p.ink,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${entry.quantity}',
                            textAlign: TextAlign.right,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 11,
                              color: p.inkSoft,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatMoney(entry.signedValue),
                            textAlign: TextAlign.right,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: entry.signedValue < 0
                                  ? p.coral
                                  : p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.forest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL COUNTED',
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 7.5,
                        letterSpacing: 1.4,
                        color: p.lime,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(session.total),
                      style: context.texts.headlineSmall?.copyWith(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${session.entryCount} '
                  '${plural(session.entryCount, 'entry', 'entries')}',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 9.5,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'In words: ${amountInWords(session.total)}',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              color: p.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: _Signature(label: 'Counted by', p: p)),
              const SizedBox(width: 22),
              Expanded(child: _Signature(label: 'Received by', p: p)),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: p.line),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generated with TakaTally',
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 7,
                  color: p.inkSoft.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'by DevBySharif',
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 7,
                  color: p.inkSoft.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(
            fontSize: 7,
            letterSpacing: 1.2,
            color: p.inkSoft,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Signature extends StatelessWidget {
  const _Signature({required this.label, required this.p});

  final String label;
  final TakaPalette p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: p.line),
        const SizedBox(height: 5),
        Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 9,
            color: p.inkSoft,
          ),
        ),
      ],
    );
  }
}
