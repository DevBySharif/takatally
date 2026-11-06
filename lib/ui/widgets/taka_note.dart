import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// A stylised illustration of a Bangladesh Bank note. The artwork is drawn
/// locally so the app stays fully offline and no licensed currency scans are
/// bundled.
@immutable
class TakaNoteDesign {
  const TakaNoteDesign({
    required this.value,
    required this.englishName,
    required this.banglaName,
    required this.color,
    required this.deepColor,
    required this.motif,
  });

  final int value;
  final String englishName;
  final String banglaName;
  final Color color;
  final Color deepColor;
  final IconData motif;
}

const List<TakaNoteDesign> takaNoteDesigns = [
  TakaNoteDesign(
    value: 1,
    englishName: 'One taka',
    banglaName: 'এক টাকা',
    color: Color(0xFF6C5AA8),
    deepColor: Color(0xFF42337A),
    motif: Icons.local_florist_rounded,
  ),
  TakaNoteDesign(
    value: 2,
    englishName: 'Two taka',
    banglaName: 'দুই টাকা',
    color: Color(0xFFC58A3E),
    deepColor: Color(0xFF85511A),
    motif: Icons.account_balance_rounded,
  ),
  TakaNoteDesign(
    value: 5,
    englishName: 'Five taka',
    banglaName: 'পাঁচ টাকা',
    color: Color(0xFF8C7B57),
    deepColor: Color(0xFF574A2E),
    motif: Icons.mosque_rounded,
  ),
  TakaNoteDesign(
    value: 10,
    englishName: 'Ten taka',
    banglaName: 'দশ টাকা',
    color: Color(0xFFC25C84),
    deepColor: Color(0xFF852B50),
    motif: Icons.mosque_rounded,
  ),
  TakaNoteDesign(
    value: 20,
    englishName: 'Twenty taka',
    banglaName: 'বিশ টাকা',
    color: Color(0xFF46895F),
    deepColor: Color(0xFF225737),
    motif: Icons.mosque_rounded,
  ),
  TakaNoteDesign(
    value: 50,
    englishName: 'Fifty taka',
    banglaName: 'পঞ্চাশ টাকা',
    color: Color(0xFF557FA3),
    deepColor: Color(0xFF2C4E6D),
    motif: Icons.account_balance_rounded,
  ),
  TakaNoteDesign(
    value: 100,
    englishName: 'One hundred taka',
    banglaName: 'একশত টাকা',
    color: Color(0xFF4568A8),
    deepColor: Color(0xFF213C75),
    motif: Icons.landscape_rounded,
  ),
  TakaNoteDesign(
    value: 200,
    englishName: 'Two hundred taka',
    banglaName: 'দুইশত টাকা',
    color: Color(0xFFC99A3D),
    deepColor: Color(0xFF8B6110),
    motif: Icons.park_rounded,
  ),
  TakaNoteDesign(
    value: 500,
    englishName: 'Five hundred taka',
    banglaName: 'পাঁচশত টাকা',
    color: Color(0xFF2F8273),
    deepColor: Color(0xFF13564A),
    motif: Icons.account_balance_rounded,
  ),
  TakaNoteDesign(
    value: 1000,
    englishName: 'One thousand taka',
    banglaName: 'এক হাজার টাকা',
    color: Color(0xFF7E528F),
    deepColor: Color(0xFF482754),
    motif: Icons.school_rounded,
  ),
];

class TakaNoteArt extends StatelessWidget {
  const TakaNoteArt({
    super.key,
    required this.design,
    this.width = 104,
    this.rotate = 0,
  });

  final TakaNoteDesign design;
  final double width;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    final art = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.075),
        boxShadow: [
          BoxShadow(
            color: design.deepColor.withValues(alpha: 0.28),
            blurRadius: width * 0.12,
            offset: Offset(0, width * 0.045),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.075),
        child: AspectRatio(
          aspectRatio: 2.1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [design.color, design.deepColor],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                  ),
                  CustomPaint(painter: _NoteTexturePainter(design: design)),
                  Positioned(
                    left: w * 0.055,
                    top: h * 0.10,
                    right: w * 0.40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বাংলাদেশ ব্যাংক',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'NotoSansBengali',
                            fontSize: h * 0.105,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        SizedBox(height: h * 0.02),
                        Text(
                          'BANGLADESH BANK',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: h * 0.068,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: h * 0.012,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: w * 0.055,
                    bottom: h * 0.09,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bengaliNumerals('${design.value}'),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'NotoSansBengali',
                            fontSize: h * 0.36,
                            height: 0.92,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.96),
                          ),
                        ),
                        SizedBox(width: w * 0.025),
                        Padding(
                          padding: EdgeInsets.only(bottom: h * 0.04),
                          child: Text(
                            'টাকা',
                            style: TextStyle(
                              fontFamily: 'NotoSansBengali',
                              fontSize: h * 0.10,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: w * 0.065,
                    top: h * 0.33,
                    child: Container(
                      width: h * 0.46,
                      height: h * 0.50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(h * 0.23, h * 0.25),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.36),
                          width: h * 0.012,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.24),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        design.motif,
                        size: h * 0.21,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                  Positioned(
                    right: w * 0.06,
                    bottom: h * 0.10,
                    child: Text(
                      '৳ ${formatNumber(design.value)}',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: h * 0.095,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (rotate == 0) return SizedBox(width: width, child: art);
    return Transform.rotate(angle: rotate, child: SizedBox(width: width, child: art));
  }
}

class _NoteTexturePainter extends CustomPainter {
  const _NoteTexturePainter({required this.design});

  final TakaNoteDesign design;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fine = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, h * 0.012);

    for (var i = 0; i < 5; i++) {
      final y = h * (0.24 + i * 0.13);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < w; x += w / 6) {
        path.quadraticBezierTo(
          x + w / 12,
          y + math.sin((x / w) * math.pi * 2.4) * h * 0.035,
          x + w / 6,
          y,
        );
      }
      canvas.drawPath(path, fine);
    }

    final center = Offset(w * 0.79, h * 0.58);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, h * (0.20 + i * 0.075), fine);
    }

    final thread = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.64, 0, math.max(1, w * 0.014), h),
      thread,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.665, 0, math.max(0.6, w * 0.005), h),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.10),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sheen);
  }

  @override
  bool shouldRepaint(covariant _NoteTexturePainter oldDelegate) =>
      oldDelegate.design != design;
}

/// A stylised illustration of a Bangladeshi taka coin.
@immutable
class TakaCoinDesign {
  const TakaCoinDesign({
    required this.value,
    required this.englishName,
    required this.banglaName,
    required this.color,
    required this.deepColor,
  });

  final int value;
  final String englishName;
  final String banglaName;
  final Color color;
  final Color deepColor;
}

const List<TakaCoinDesign> takaCoinDesigns = [
  TakaCoinDesign(
    value: 1,
    englishName: 'One taka coin',
    banglaName: 'এক টাকা',
    color: Color(0xFFC3CCD2),
    deepColor: Color(0xFF6F7C86),
  ),
  TakaCoinDesign(
    value: 2,
    englishName: 'Two taka coin',
    banglaName: 'দুই টাকা',
    color: Color(0xFFE0B75C),
    deepColor: Color(0xFF8E6816),
  ),
  TakaCoinDesign(
    value: 5,
    englishName: 'Five taka coin',
    banglaName: 'পাঁচ টাকা',
    color: Color(0xFFD19A45),
    deepColor: Color(0xFF7C4E12),
  ),
];

class TakaCoinArt extends StatelessWidget {
  const TakaCoinArt({
    super.key,
    required this.design,
    this.size = 64,
  });

  final TakaCoinDesign design;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(design.color, Colors.white, 0.38)!,
            design.color,
            design.deepColor,
          ],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(
          color: design.deepColor,
          width: math.max(1.2, size * 0.024),
        ),
        boxShadow: [
          BoxShadow(
            color: design.deepColor.withValues(alpha: 0.32),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.075),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.34),
            blurRadius: size * 0.05,
            offset: Offset(-size * 0.03, -size * 0.04),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CoinRingPainter(deepColor: design.deepColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bengaliNumerals('${design.value}'),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: size * 0.34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.97),
                ),
              ),
              Text(
                'টাকা',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: size * 0.125,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinRingPainter extends CustomPainter {
  const _CoinRingPainter({required this.deepColor});

  final Color deepColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.05)
      ..color = deepColor.withValues(alpha: 0.38);
    canvas.drawCircle(center, radius * 0.80, innerRing);

    final notch = Paint()..color = Colors.white.withValues(alpha: 0.38);
    final notchRadius = math.max(0.5, radius * 0.02);
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final orbit = radius * 0.905;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * orbit,
          center.dy + math.sin(angle) * orbit,
        ),
        notchRadius,
        notch,
      );
    }

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.12),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sheen);
  }

  @override
  bool shouldRepaint(covariant _CoinRingPainter oldDelegate) =>
      oldDelegate.deepColor != deepColor;
}
