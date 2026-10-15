import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/dunya.dart';

/// Kamp ateşi = toplam birikim. Alev ölçeği toplamla büyür
/// (`olcek` 0,5–1,15), parıltı genişler. Prototipteki `#fire` ile aynı yollar.
///
/// Canlı yanar: üç alev katmanı farklı hız ve fazda esner/eğilir (tek sinüs
/// mekanik görünür; asal oranlı iki sinüsün toplamı tekrar etmez), parıltı
/// nefes alır, tepeden kıvılcımlar yükselip söner. Besleme olunca
/// (`parlamaTetik`) alev bir an kabarır ve kıvılcım fışkırır.
/// Hareketi azalt açıksa durağan çizilir (yalnız toplam değişince büyür).
class KampAtesi extends StatefulWidget {
  const KampAtesi({super.key, required this.toplamTl, this.boyut = 150, this.parlamaTetik = 0});
  final double toplamTl;
  final double boyut;
  final int parlamaTetik;

  /// 6.000 ₺'de tam boy; üstü hafif aşar, sonsuz büyümez (ekranı taşmasın).
  static double olcek(double toplam) => (0.5 + (toplam / 6000) * 0.65).clamp(0.5, 1.15);
  static double parilti(double toplam) => (0.12 + toplam / 12000).clamp(0.12, 0.4);

  @override
  State<KampAtesi> createState() => _KampAtesiState();
}

class _KampAtesiState extends State<KampAtesi> with TickerProviderStateMixin {
  // Sürekli saat: 0–1 arası 60 sn'lik döngü; değer saniyeye çevrilip
  // sinüslere verilir (döngü sınırında sıçrama görünmesin diye uzun).
  late final AnimationController _saat =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));
  late final AnimationController _parlama =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hareketsiz = MediaQuery.of(context).disableAnimations;
    if (hareketsiz && _saat.isAnimating) _saat.stop();
    if (!hareketsiz && !_saat.isAnimating) _saat.repeat();
  }

  @override
  void didUpdateWidget(KampAtesi o) {
    super.didUpdateWidget(o);
    if (o.parlamaTetik != widget.parlamaTetik && !MediaQuery.of(context).disableAnimations) {
      _parlama.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _saat.dispose();
    _parlama.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final canli = !MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: KampAtesi.olcek(widget.toplamTl)),
      duration: Devinim.sure(context, Devinim.yavas),
      curve: Devinim.cikis,
      builder: (_, s, _) => AnimatedBuilder(
        animation: Listenable.merge([_saat, _parlama]),
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.boyut),
          painter: _AtesPainter(
            s,
            KampAtesi.parilti(widget.toplamTl),
            r,
            zaman: canli ? _saat.value * 60 : null,
            parlama: _parlama.isAnimating ? _parlama.value : 0,
          ),
        ),
      ),
    );
  }
}

class _AtesPainter extends CustomPainter {
  _AtesPainter(this.olcek, this.parilti, this.r, {this.zaman, this.parlama = 0});
  final double olcek;
  final double parilti;
  final DunyaRenkleri r;

  /// Saniye; null → durağan (hareketi azalt).
  final double? zaman;

  /// Besleme parlaması ilerlemesi (0 = yok).
  final double parlama;

  static double _dalga(double t, double f1, double f2, double faz) =>
      .6 * math.sin(t * f1 + faz) + .4 * math.sin(t * f2 + faz * 1.7);

  /// Alev katmanını tabana (60,108) göre esnet ve eğ.
  void _katman(Canvas cv, Path yol, Paint dolgu, Paint? kontur, double faz, double siddet) {
    final t = zaman;
    cv.save();
    cv.translate(60, 108);
    if (t != null) {
      final boy = 1 + siddet * .07 * _dalga(t, 7.3, 11.9, faz);
      final en = 1 - siddet * .04 * _dalga(t, 6.1, 9.7, faz + 1);
      final egim = siddet * .07 * _dalga(t, 3.1, 5.3, faz + 2);
      cv.transform(Float64List.fromList([en, 0, 0, 0, egim, boy, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
    }
    cv.translate(-60, -108);
    cv.drawPath(yol, dolgu);
    if (kontur != null) cv.drawPath(yol, kontur);
    cv.restore();
  }

  /// Kıvılcımlar: her biri kendi döngüsünde tepeden yükselir, yana salınır,
  /// küçülerek söner. Konumlar zamandan türetilir (rastgele durum yok).
  void _kivilcimlar(Canvas cv, double t, int adet, double hiz) {
    for (var i = 0; i < adet; i++) {
      final donem = 1.6 + (i % 3) * .45;
      final p = ((t * hiz + i * .37) / donem) % 1.0;
      final x = 60 + (i.isEven ? -1 : 1) * (6 + i * 3) * p + 5 * math.sin(t * 3 + i * 2.1) * p;
      final y = 46 - 58 * p;
      final rr = 2.6 * (1 - p);
      final a = (1 - p) * (p < .1 ? p / .1 : 1);
      cv.drawCircle(Offset(x, y), rr, Paint()..color = r.warm.withValues(alpha: a));
    }
  }

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
    final t = zaman;
    // Parlama: alev bir an %18 kabarır, parıltı güçlenir (yumuşak çan eğrisi).
    final kabarma = parlama > 0 ? math.sin(parlama * math.pi) : 0.0;
    final nefes = t == null ? 0.0 : .04 * math.sin(t * 2.2);
    // Parıltı yumuşak kenarlı (radyal gradyan): sert disk "sticker" gibi
    // duruyordu, ışık gibi değil.
    final yaricap = 58 * (1 + nefes + .12 * kabarma);
    final alfa = (parilti * (1 + 2 * nefes) + .2 * kabarma).clamp(0.0, .7) * 1.6;
    cv.drawCircle(
      const Offset(60, 80),
      yaricap,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(60, 80), yaricap, [
          r.warm.withValues(alpha: alfa.clamp(0.0, 1.0)),
          r.warm.withValues(alpha: (alfa * .45).clamp(0.0, 1.0)),
          r.warm.withValues(alpha: 0),
        ], const [0, .55, 1]),
    );
    // Alev: taban (60,108) sabit kalır, yukarı büyür.
    cv.save();
    cv.translate(60, 108);
    cv.scale(olcek * (1 + .18 * kabarma));
    cv.translate(-60, -108);
    _katman(cv, _dis, Paint()..color = r.petal, kontur, 0, 1);
    _katman(cv, _ic, Paint()..color = r.warm, null, 2.3, 1.4);
    _katman(cv, _oz, Paint()..color = Colors.white.withValues(alpha: .85), null, 4.1, 1.8);
    if (t != null) _kivilcimlar(cv, t, 5, 1);
    if (parlama > 0) _kivilcimlar(cv, parlama * 3, 8, 1.6);
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
  bool shouldRepaint(_AtesPainter o) =>
      o.olcek != olcek || o.parilti != parilti || o.r != r || o.zaman != zaman || o.parlama != parlama;
}
