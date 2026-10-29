import 'package:flutter/material.dart';

import '../models/cizim.dart';
import '../theme/dunya.dart';

/// Normalize çizimi verilen alana çizer. [tekRenk] verilirse tüm çizgiler o
/// renkte (doluluğun soluk izi); yoksa her çizgi kendi boyasında.
class CizimBoyaci extends CustomPainter {
  const CizimBoyaci(this.cizim, {this.tekRenk});

  final Cizim cizim;
  final Color? tekRenk;

  /// Kalınlık alana oranlı: kartta 72 pt'lik çizim de aynı karakterde görünür.
  static double kalinlik(Size s) => s.shortestSide * .045;

  @override
  void paint(Canvas canvas, Size s) {
    final k = kalinlik(s);
    for (final c in cizim.cizgiler) {
      if (c.noktalar.isEmpty) continue;
      final boya = Paint()
        ..color = tekRenk ?? DunyaRenkleri.boyalar[c.renk.clamp(0, DunyaRenkleri.boyalar.length - 1)]
        ..strokeWidth = k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      Offset o(Offset p) => Offset(p.dx * s.width, p.dy * s.height);
      if (c.noktalar.length == 1) {
        // Tek dokunuş nokta olur (çocuk göz, düğme çizer).
        canvas.drawCircle(o(c.noktalar.first), k / 2, boya..style = PaintingStyle.fill);
        continue;
      }
      final yol = Path()..moveTo(o(c.noktalar.first).dx, o(c.noktalar.first).dy);
      for (final p in c.noktalar.skip(1)) {
        final q = o(p);
        yol.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(yol, boya);
    }
  }

  @override
  bool shouldRepaint(CizimBoyaci eski) => eski.cizim != cizim || eski.tekRenk != tekRenk;
}
