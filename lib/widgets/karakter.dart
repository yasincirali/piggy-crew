import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../models/varlik.dart';
import '../theme/dunya.dart';

/// Kumbara Takımı çizimleri — prototipteki SVG'lerin birebir Dart karşılığı.
///
/// Neden CustomPainter, neden SVG dosyası değil: sanat yönü (çini, kilim,
/// hasır deseni; mürekkep kontur) `<pattern>` kullanır ve flutter_svg
/// pattern/filter desteklemez. Burada desen, biçime clip'lenip döşenerek
/// çizilir. Yollar SVG `d` dizeleri olarak tutulur (path_drawing) ki
/// illüstratör teslimatı geldiğinde yalnız dizeler değişsin.
///
/// Koordinat alanı 110×110; `size`'a ölçeklenir.
class KarakterPainter extends CustomPainter {
  KarakterPainter({
    required this.tur,
    required this.ruh,
    this.pulSayisi = 0,
    this.parlak = false,
    this.gozKapali = false,
  });

  final VarlikTuru tur;
  final Ruh ruh;

  /// Tortu kabuğundaki altın pullar (0–3): beslendikçe artar.
  final int pulSayisi;

  /// Tortu 1.500 ₺ eşiğini geçince yıldızlar açılır.
  final bool parlak;
  final bool gozKapali;

  static const _murekkep = DunyaRenkleri.murekkep;
  static final _yolOnbellek = <String, Path>{};

  static Path _p(String d) => _yolOnbellek.putIfAbsent(d, () => parseSvgPathData(d));

  Paint _dolgu(Color c) => Paint()..color = c;
  Paint _cizgi(double w, [Color c = _murekkep]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _sekil(Canvas cv, Path p, Color dolgu, {double kontur = 2}) {
    cv.drawPath(p, _dolgu(dolgu));
    if (kontur > 0) cv.drawPath(p, _cizgi(kontur));
  }

  void _golge(Canvas cv, double cx, double cy, double rx) {
    cv.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: 12),
        _dolgu(const Color(0x47000000)));
  }

  // ── Desenler: biçime clip'lenir, döşenir ───────────────────────────────
  void _cini(Canvas cv, Path sekil) {
    cv.save();
    cv.clipPath(sekil);
    cv.drawRect(const Rect.fromLTWH(0, 0, 110, 110), _dolgu(const Color(0xFF2B6FD6)));
    final yildiz = _p('M7 1l1.8 4.2L13 7l-4.2 1.8L7 13l-1.8-4.2L1 7l4.2-1.8z');
    for (var y = 0.0; y < 110; y += 14) {
      for (var x = 0.0; x < 110; x += 14) {
        cv.save();
        cv.translate(x, y);
        cv.drawPath(yildiz, _dolgu(const Color(0xFFFFFAF0)));
        cv.drawCircle(const Offset(7, 7), 1.6, _dolgu(const Color(0xFFE8540E)));
        cv.restore();
      }
    }
    cv.restore();
  }

  void _kilim(Canvas cv, Path sekil) {
    cv.save();
    cv.clipPath(sekil);
    cv.drawRect(const Rect.fromLTWH(0, 0, 110, 110), _dolgu(const Color(0xFFB3261E)));
    final ust = _p('M0 8l6-6 6 6');
    final alt = _p('M0 4l6 5 6-5');
    for (var y = 0.0; y < 110; y += 10) {
      for (var x = 0.0; x < 110; x += 12) {
        cv.save();
        cv.translate(x, y);
        cv.drawPath(ust, _cizgi(2, const Color(0xFFF7D774)));
        cv.drawPath(alt, _cizgi(1.2, const Color(0xFF1F3B73)));
        cv.restore();
      }
    }
    cv.restore();
  }

  void _hasir(Canvas cv, Path sekil) {
    cv.save();
    cv.clipPath(sekil);
    cv.drawRect(const Rect.fromLTWH(0, 0, 110, 110), _dolgu(const Color(0xFF4FCF80)));
    final cz = _cizgi(1.4, const Color(0xB32F9E5A));
    for (var i = 4.0; i < 110; i += 8) {
      cv.drawLine(Offset(0, i), Offset(110, i), cz);
      cv.drawLine(Offset(i, 0), Offset(i, 110), cz);
    }
    cv.restore();
  }

  // ── Yüz parçaları ──────────────────────────────────────────────────────
  void _goz(Canvas cv, double cx, double cy, double r, Color kapak, {Color iris = _murekkep, double irisR = 3.9}) {
    cv.drawCircle(Offset(cx, cy), r, _dolgu(const Color(0xFFFFFAF0)));
    cv.drawCircle(Offset(cx, cy), r, _cizgi(1.5));
    if (gozKapali) {
      // Kapak: yarım daire, tüm gözü örter.
      final kapakYolu = Path()
        ..addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r + .3), math.pi, math.pi)
        ..close();
      cv.drawPath(kapakYolu, _dolgu(kapak));
      cv.drawPath(kapakYolu, _cizgi(1.5));
      cv.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), _cizgi(1.5));
      return;
    }
    cv.drawCircle(Offset(cx + 1, cy + 1), irisR, _dolgu(iris));
    if (iris != _murekkep) cv.drawCircle(Offset(cx + 1, cy + 1), irisR * .55, _dolgu(_murekkep));
    cv.drawCircle(Offset(cx + 3.5, cy - 2.5), 1.8, _dolgu(Colors.white));
  }

  void _yanak(Canvas cv, double cx, double cy) {
    cv.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 7),
        _dolgu(const Color(0xBFF28C8C)));
  }

  /// Ağız: ruh hâline göre tek yol. Konum karaktere göre (x,y) kaydırılır.
  void _agiz(Canvas cv, double dx, double dy) {
    final d = switch (ruh) {
      Ruh.mutlu => 'M46 42q9 9 18 0',
      Ruh.duz => 'M48 45h14',
      Ruh.uzgun => 'M47 48q8-7 16 0',
    };
    cv.save();
    cv.translate(dx, dy);
    cv.drawPath(_p(d), _cizgi(2.6));
    cv.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 110;
    canvas.save();
    canvas.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    canvas.scale(s);
    switch (tur) {
      case VarlikTuru.altin:
        _tortu(canvas);
      case VarlikTuru.dolar:
        _zipzip(canvas);
      case VarlikTuru.euro:
        _baykus(canvas);
      case VarlikTuru.nakit:
        _sincap(canvas);
    }
    canvas.restore();
  }

  void _tortu(Canvas cv) {
    _golge(cv, 55, 101, 40);
    _sekil(cv, _p('M14 86c0-30 18-50 41-50s41 20 41 50z'), const Color(0xFFE0A800));
    final kabuk = _p('M22 86c0-24 14-40 33-40s33 16 33 40z');
    _cini(cv, kabuk);
    cv.drawPath(kabuk, _cizgi(2));
    cv.drawLine(const Offset(12, 86), const Offset(98, 86), _cizgi(2.5));
    // Yıldızlar (parladığında).
    if (parlak) {
      for (final d in [
        'M28 60l3 7 7 3-7 3-3 7-3-7-7-3 7-3z',
        'M80 56l3 7 7 3-7 3-3 7-3-7-7-3 7-3z',
        'M55 42l2.5 6 6 2.5-6 2.5-2.5 6-2.5-6-6-2.5 6-2.5z',
      ]) {
        _sekil(cv, _p(d), const Color(0xFFFFF3B0));
      }
    }
    // Altın pullar.
    const pullar = [Offset(34, 76), Offset(55, 66), Offset(76, 76)];
    for (var i = 0; i < pulSayisi.clamp(0, 3); i++) {
      cv.drawCircle(pullar[i], 4.5, _dolgu(const Color(0xFFF7D774)));
      cv.drawCircle(pullar[i], 4.5, _cizgi(1.5));
    }
    // Ayaklar.
    for (final x in [20.0, 74.0]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 84, 16, 13), const Radius.circular(6.5));
      cv.drawRRect(r, _dolgu(const Color(0xFFC98A00)));
      cv.drawRRect(r, _cizgi(2));
    }
    // Baş.
    const ten = Color(0xFFF5C76A);
    cv.drawCircle(const Offset(55, 34), 22, _dolgu(ten));
    cv.drawCircle(const Offset(55, 34), 22, _cizgi(2));
    cv.drawPath(_p('M44 16q11-8 22 0'), _cizgi(2));
    _goz(cv, 47, 32, 7, ten);
    _goz(cv, 63, 32, 7, ten);
    _yanak(cv, 40, 44);
    _yanak(cv, 70, 44);
    _agiz(cv, 0, 0);
  }

  void _zipzip(Canvas cv) {
    _golge(cv, 55, 101, 34);
    const yesil = Color(0xFF4FCF80);
    _sekil(cv, _p('M34 46c-6-24 0-44 7-44s13 20 7 44z'), yesil);
    _sekil(cv, _p('M62 46c-6-24 0-44 7-44s13 20 7 44z'), yesil);
    cv.drawPath(_p('M38 40c-3-16 1-30 3-30s6 14 3 30z'), _dolgu(const Color(0xFFF28C8C)));
    cv.drawPath(_p('M66 40c-3-16 1-30 3-30s6 14 3 30z'), _dolgu(const Color(0xFFF28C8C)));
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(55, 68), width: 68, height: 64));
    _hasir(cv, govde);
    cv.drawPath(govde, _cizgi(2));
    final karin = Rect.fromCenter(center: const Offset(55, 84), width: 32, height: 24);
    cv.drawOval(karin, _dolgu(const Color(0xFFEAFBEA)));
    cv.drawOval(karin, _cizgi(1.5));
    _goz(cv, 44, 60, 8, yesil, irisR: 4.4);
    _goz(cv, 66, 60, 8, yesil, irisR: 4.4);
    _yanak(cv, 37, 72);
    _yanak(cv, 73, 72);
    _sekil(cv, _p('M51 73l4 4 4-4z'), const Color(0xFFF28C8C), kontur: 1.2);
    _agiz(cv, 0, 36);
    cv.drawPath(_p('M40 86l-4 8M70 86l4 8'), _cizgi(2));
  }

  void _baykus(Canvas cv) {
    _golge(cv, 55, 101, 34);
    const lacivert = Color(0xFF1F3B73);
    cv.drawPath(_p('M22 32l16 12M88 32l-16 12'), _cizgi(11));
    cv.drawPath(_p('M22 32l16 12M88 32l-16 12'), _cizgi(8, lacivert));
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(55, 62), width: 72, height: 76));
    _sekil(cv, govde, lacivert);
    final kusak = _p('M30 70q25-16 50 0v10q-25 16-50 0z');
    _kilim(cv, kusak);
    cv.drawPath(kusak, _cizgi(1.5));
    final yuz = Rect.fromCenter(center: const Offset(55, 60), width: 48, height: 36);
    cv.drawOval(yuz, _dolgu(const Color(0xFFDBE7FF)));
    cv.drawOval(yuz, _cizgi(1.5));
    // Nazar gözleri: açık mavi halka + beyaz + mavi iris + siyah göz bebeği.
    for (final cx in [42.0, 68.0]) {
      cv.drawCircle(Offset(cx, 56), 12, _dolgu(const Color(0xFF7FC8FF)));
      _goz(cv, cx, 56, 10, lacivert, iris: const Color(0xFF2B6FD6), irisR: 6.2);
    }
    _yanak(cv, 35, 68);
    _yanak(cv, 75, 68);
    _sekil(cv, _p('M50 67l5 8 5-8z'), const Color(0xFFF5B82E));
    _agiz(cv, 0, 38);
    cv.drawPath(_p('M44 99l-3 6M66 99l3 6M55 99v6'), _cizgi(3, const Color(0xFFF5B82E)));
  }

  void _sincap(Canvas cv) {
    _golge(cv, 52, 101, 34);
    const turuncu = Color(0xFFE8540E);
    final kuyruk = _p('M70 50c30-30 46-10 42 20-3 22-24 36-38 26z');
    _kilim(cv, kuyruk);
    cv.drawPath(kuyruk, _cizgi(2));
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(46, 64), width: 60, height: 64));
    _sekil(cv, govde, turuncu);
    _sekil(cv, _p('M22 42l5-18 11 12M70 42l-5-18-11 12'), turuncu);
    final karin = Rect.fromCenter(center: const Offset(46, 78), width: 32, height: 24);
    cv.drawOval(karin, _dolgu(const Color(0xFFFFE3C2)));
    cv.drawOval(karin, _cizgi(1.5));
    _goz(cv, 36, 58, 7, turuncu);
    _goz(cv, 56, 58, 7, turuncu);
    _yanak(cv, 29, 70);
    _yanak(cv, 63, 70);
    cv.drawPath(_p('M43 71l3 4 3-4z'), _dolgu(_murekkep));
    _agiz(cv, -9, 34);
    cv.drawCircle(const Offset(46, 98), 10, _dolgu(const Color(0xFFF7D774)));
    cv.drawCircle(const Offset(46, 98), 10, _cizgi(2));
    final tp = TextPainter(
      text: const TextSpan(
        text: '₺',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _murekkep),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(cv, Offset(46 - tp.width / 2, 98 - tp.height / 2));
  }

  @override
  bool shouldRepaint(KarakterPainter o) =>
      o.tur != tur || o.ruh != ruh || o.pulSayisi != pulSayisi || o.parlak != parlak || o.gozKapali != gozKapali;
}

/// Canlı karakter: yavaş salınım (bob), ara sıra göz kırpma, `hop` ile zıplama.
/// Hareketi azalt açıksa salınım ve kırpma durur; yalnız durum değişir.
class Karakter extends StatefulWidget {
  const Karakter({
    super.key,
    required this.tur,
    required this.ruh,
    this.boyut = 110,
    this.pulSayisi = 0,
    this.parlak = false,
    this.gecikme = Duration.zero,
    this.hopTetik = 0,
  });

  final VarlikTuru tur;
  final Ruh ruh;
  final double boyut;
  final int pulSayisi;
  final bool parlak;
  final Duration gecikme;

  /// Her değişimde bir zıplama oynatır (üst widget sayaç artırır).
  final int hopTetik;

  @override
  State<Karakter> createState() => _KarakterState();
}

class _KarakterState extends State<Karakter> with TickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  late final AnimationController _hop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _kapali = false;
  final _rnd = math.Random();
  // Zamanlayıcılar alanda tutulur ve dispose'da iptal edilir; aksi hâlde
  // widget ağacı kalktıktan sonra sarkan timer kalır (testler yakalar).
  Timer? _bobGecikme;
  Timer? _kirpma;

  @override
  void initState() {
    super.initState();
    _bobGecikme = Timer(widget.gecikme, () {
      if (mounted && !MediaQuery.of(context).disableAnimations) _bob.repeat(reverse: true);
    });
    _kirpmaPlanla();
  }

  void _kirpmaPlanla() {
    _kirpma = Timer(Duration(milliseconds: 2500 + _rnd.nextInt(3500)), () {
      if (!mounted) return;
      if (!MediaQuery.of(context).disableAnimations) {
        setState(() => _kapali = true);
        _kirpma = Timer(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          setState(() => _kapali = false);
          _kirpmaPlanla();
        });
        return;
      }
      _kirpmaPlanla();
    });
  }

  @override
  void didUpdateWidget(Karakter o) {
    super.didUpdateWidget(o);
    if (o.hopTetik != widget.hopTetik && !MediaQuery.of(context).disableAnimations) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bobGecikme?.cancel();
    _kirpma?.cancel();
    _bob.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _hop]),
      builder: (context, child) {
        final bobY = -4 * Curves.easeInOut.transform(_bob.value);
        final h = _hop.value;
        // Zıplama: yukarı −14, hafif sıkış/genişle (squash & stretch).
        final hopY = -14 * math.sin(h * math.pi);
        final sx = 1 + .08 * math.sin(h * math.pi * 2);
        final sy = 1 - .08 * math.sin(h * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, bobY + hopY),
          child: Transform.scale(scaleX: sx, scaleY: sy, alignment: Alignment.bottomCenter, child: child),
        );
      },
      child: CustomPaint(
        size: Size.square(widget.boyut),
        painter: KarakterPainter(
          tur: widget.tur,
          ruh: widget.ruh,
          pulSayisi: widget.pulSayisi,
          parlak: widget.parlak,
          gozKapali: _kapali,
        ),
      ),
    );
  }
}
