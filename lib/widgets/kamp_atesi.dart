import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/dunya.dart';

/// Kamp ateşi = toplam birikim. Alev ölçeği toplamla büyür
/// (`olcek` 0,5–1,15), parıltı genişler. Prototipteki `#fire` ile aynı yollar.
class KampAtesi extends StatelessWidget {
  const KampAtesi({super.key, required this.toplamTl, this.boyut = 150});
  final double toplamTl;
  final double boyut;

  /// 6.000 ₺'de tam boy; üstü hafif aşar, sonsuz büyümez (ekranı taşmasın).
  static double olcek(double toplam) => (0.5 + (toplam / 6000) * 0.65).clamp(0.5, 1.15);
  static double parilti(double toplam) => (0.12 + toplam / 12000).clamp(0.12, 0.4);

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: olcek(toplamTl)),
      duration: Devinim.sure(context, Devinim.yavas),
      curve: Devinim.cikis,
      builder: (_, s, _) => CustomPaint(
        size: Size.square(boyut),
        painter: _AtesPainter(s, parilti(toplamTl), r),
      ),
    );
  }
}

class _AtesPainter extends CustomPainter {
  _AtesPainter(this.olcek, this.parilti, this.r);
  final double olcek;
  final double parilti;
  final DunyaRenkleri r;

  static final _dis = parseSvgPathData(
      'M60 108c-30-16-34-50-10-70 2 18 12 25 16 30 0-24 12-34 28-44-5 22 9 34 13 50 7 23-12 42-47 34z');
  static final _ic = parseSvgPathData(
      'M60 104c-14-9-16-27-5-38 1 10 7 14 9 16 0-13 7-19 15-24-3 13 5 19 7 28 3 13-7 22-26 18z');
  static final _oz = parseSvgPathData(
      'M60 100c-6-4-7-12-2-17 0 4 3 6 4 7 0-6 3-8 7-11-1 6 2 9 3 13 1 6-3 10-12 8z');

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 120;
    cv.save();
    cv.scale(s);
    final kontur = Paint()
      ..color = DunyaRenkleri.murekkep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    cv.drawCircle(const Offset(60, 78), 52, Paint()..color = r.warm.withValues(alpha: parilti));
    // Alev: taban (60,108) sabit kalır, yukarı büyür.
    cv.save();
    cv.translate(60, 108);
    cv.scale(olcek);
    cv.translate(-60, -108);
    cv.drawPath(_dis, Paint()..color = r.petal);
    cv.drawPath(_dis, kontur);
    cv.drawPath(_ic, Paint()..color = r.warm);
    cv.drawPath(_oz, Paint()..color = Colors.white.withValues(alpha: .85));
    cv.restore();
    // Odunlar.
    final o1 = RRect.fromRectAndRadius(const Rect.fromLTWH(18, 104, 84, 12), const Radius.circular(6));
    final o2 = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 98, 60, 10), const Radius.circular(5));
    cv.drawRRect(o1, Paint()..color = r.soil);
    cv.drawRRect(o1, kontur);
    cv.drawRRect(o2, Paint()..color = r.soil2);
    cv.drawRRect(o2, kontur);
    final damar = Paint()
      ..color = DunyaRenkleri.murekkep.withValues(alpha: .5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    cv.drawLine(const Offset(26, 110), const Offset(34, 110), damar);
    cv.drawLine(const Offset(50, 110), const Offset(60, 110), damar);
    cv.drawLine(const Offset(80, 110), const Offset(88, 110), damar);
    cv.restore();
  }

  @override
  bool shouldRepaint(_AtesPainter o) => o.olcek != olcek || o.parilti != parilti || o.r != r;
}
