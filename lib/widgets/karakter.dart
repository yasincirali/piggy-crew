import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

import '../models/varlik.dart';
import '../services/ses_servisi.dart';
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
    this.agizAcik = false,
    this.bakis = Offset.zero,
  });

  final VarlikTuru tur;
  final Ruh ruh;

  /// Beslenirken çiğneme: ağız yuvarlak açılır (ruh hâlinden bağımsız).
  final bool agizAcik;

  /// Bakış yönü (−1…1): göz bebekleri göz içinde bu yöne kayar. Boşta etrafa
  /// bakma ve beslenirken düşen paraya bakma için.
  final Offset bakis;

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
    // Bebek göz içinde kalır: kayma payı (r − irisR) ile sınırlı.
    final pay = math.max(0.0, r - irisR - .8);
    final b = Offset(cx + 1 + bakis.dx * pay, cy + 1 + bakis.dy * pay);
    cv.drawCircle(b, irisR, _dolgu(iris));
    if (iris != _murekkep) cv.drawCircle(b, irisR * .55, _dolgu(_murekkep));
    cv.drawCircle(b + const Offset(2.5, -3.5), 1.8, _dolgu(Colors.white));
  }

  void _yanak(Canvas cv, double cx, double cy) {
    cv.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 7),
        _dolgu(const Color(0xBFF28C8C)));
  }

  /// Ağız: ruh hâline göre tek yol. Konum karaktere göre (x,y) kaydırılır.
  void _agiz(Canvas cv, double dx, double dy) {
    if (agizAcik) {
      final o = Rect.fromCenter(center: Offset(55 + dx, 45 + dy), width: 13, height: 10);
      cv.drawOval(o, _dolgu(_murekkep));
      cv.drawOval(Rect.fromCenter(center: Offset(55 + dx, 48 + dy), width: 7, height: 3.5),
          _dolgu(const Color(0xFFF28C8C)));
      return;
    }
    final d = switch (ruh) {
      Ruh.mutlu => 'M46 42q9 9 18 0',
      // Bulutlu yüz sakin: düz ağız, ağlama/küskünlük yok.
      Ruh.duz || Ruh.bulutlu => 'M48 45h14',
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
        style: TextStyle(fontFamily: govdeFontu, fontSize: 12, fontWeight: FontWeight.w700, color: _murekkep),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(cv, Offset(46 - tp.width / 2, 98 - tp.height / 2));
  }

  @override
  bool shouldRepaint(KarakterPainter o) =>
      o.tur != tur || o.ruh != ruh || o.pulSayisi != pulSayisi || o.parlak != parlak || o.gozKapali != gozKapali || o.agizAcik != agizAcik || o.bakis != bakis;
}

/// Ağız merkezi (110×110 alanında) — besleme paraları buraya düşer.
Offset _agizMerkezi(VarlikTuru t) => switch (t) {
      VarlikTuru.altin => const Offset(55, 45),
      VarlikTuru.dolar => const Offset(55, 81),
      VarlikTuru.euro => const Offset(55, 83),
      VarlikTuru.nakit => const Offset(46, 79),
    };

enum _Bosta { kipir, ziplama, gerinme, keyif, etrafaBak, dans }

/// Çizgi film zıplaması (0–1 → dikey kayma, en/boy ölçeği).
///
/// Neden düz sinüs değil: sempati "hazırlık + abartı + yerleşme"den gelir.
/// Önce çömelir (basılır, genişler), havada uzar, yere basık iner ve küçük
/// bir yaylanmayla oturur. Aynı eğri dokunma, sevinç ve boşta zıplamasında.
({double y, double sx, double sy}) ziplamaEgrisi(double t, double yukseklik) {
  const hazirlik = .18, inis = .74;
  if (t <= 0 || t >= 1) return (y: 0, sx: 1, sy: 1);
  if (t < hazirlik) {
    final c = math.sin(t / hazirlik * math.pi); // çömel, kalkışta bırak
    return (y: 0, sx: 1 + .1 * c, sy: 1 - .13 * c);
  }
  if (t < inis) {
    final u = (t - hazirlik) / (inis - hazirlik);
    final uzama = .12 * math.sin(u * math.pi) * (1 - u) * 1.6; // kalkışta uzar, tepede toparlanır
    return (y: -yukseklik * 4 * u * (1 - u), sx: 1 - uzama * .7, sy: 1 + uzama);
  }
  // Yere basma + sönen yaylanma (iki salınım).
  final v = (t - inis) / (1 - inis);
  final yay = math.sin(v * math.pi * 2.5) * math.pow(1 - v, 2);
  return (y: 0, sx: 1 + .12 * yay, sy: 1 - .14 * yay);
}

/// Canlı karakter.
///
/// Katmanlar (hareketi azalt açıksa hepsi durur; sesler yine çalar):
/// - Salınım ve ara sıra göz kırpma (her zaman).
/// - Boşta (`bosta`): 6–13 sn'de bir kendiliğinden küçük bir hareket:
///   kıpırdanma, minik zıplama, gerinip esneme, keyifle sallanma, etrafa
///   bakma ya da iki adımlık dans. Yalnız
///   kampta açık; sayfalarda ve listelerde kapalı ki ekran kalabalıklaşmasın.
/// - Tepki (`tepkiTetik`): dokununca zıplar, kıpırdar, kendi sesini çıkarır.
/// - Yeme (`yemeTetik`): besleme sonrası üç para yukarıdan ağzına düşer; her
///   birinde ağız açılır, çiğner, "tın" sesi ve hafif titreşim gelir. Sonunda
///   sevinç zıplaması ve kısa arpej. ~1,4 sn: her para tek tek sayılacak kadar
///   uzun (tatmin bu sayımdan gelir), tekrar beslemek isteyecek kadar kısa.
///   Konfeti yok (ürün kararı): ödül karakterin kendi sevinci.
class Karakter extends StatefulWidget {
  const Karakter({
    super.key,
    required this.tur,
    required this.ruh,
    this.boyut = 110,
    this.pulSayisi = 0,
    this.parlak = false,
    this.gecikme = Duration.zero,
    this.tepkiTetik = 0,
    this.yemeTetik = 0,
    this.bosta = false,
    this.ses,
  });

  final VarlikTuru tur;
  final Ruh ruh;
  final double boyut;
  final int pulSayisi;
  final bool parlak;
  final Duration gecikme;

  /// Her artışta dokunma tepkisi oynar (üst widget sayaç artırır).
  final int tepkiTetik;

  /// Her artışta besleme (yeme) sahnesi oynar.
  final int yemeTetik;

  /// Kendiliğinden ara sıra hareket etsin mi (kamp).
  final bool bosta;

  /// Ses çalıcı; null ise sessiz (sayfalar, testler).
  final void Function(Ses)? ses;

  @override
  State<Karakter> createState() => _KarakterState();
}

class _KarakterState extends State<Karakter> with TickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  late final AnimationController _hop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
  late final AnimationController _kipir =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _bostaC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  // Teselli: bulutluyken dokununca bulut çekilir, güneş açar, sonra bulut
  // yavaşça geri gelir (fiyat değişmedi; yalan söylemeyiz, ama karakter
  // çocuğun ilgisine sevinir).
  late final AnimationController _teselli =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  Timer? _gunesSabit;
  bool _gunesAcik = false;
  late final AnimationController _yeme =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..addListener(_yemeSesleri);
  bool _kapali = false;
  _Bosta _bostaTur = _Bosta.kipir;
  final _rnd = math.Random();
  // Zamanlayıcılar alanda tutulur ve dispose'da iptal edilir; aksi hâlde
  // widget ağacı kalktıktan sonra sarkan timer kalır (testler yakalar).
  Timer? _bobGecikme;
  Timer? _kirpma;
  Timer? _bostaZaman;
  Timer? _sessizSevinc;

  // Yeme zaman çizelgesi (0–1): paraların düşmeye başladığı anlar, düşüş
  // süresi, "yum" ve sevinç zıplamasının başı.
  static const _paraBasla = [0.0, 0.16, 0.32];
  static const _dusus = 0.24;
  static const _yumAni = 0.6;
  static const _sevincAni = 0.66;
  int _calinanPara = 0;
  bool _yumCalindi = false;
  bool _sevincCalindi = false;

  bool get _hareketsiz => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _bobGecikme = Timer(widget.gecikme, () {
      if (mounted && !_hareketsiz) _bob.repeat(reverse: true);
    });
    _kirpmaPlanla();
    if (widget.bosta) _bostaPlanla();
  }

  void _kirpmaPlanla() {
    _kirpma = Timer(Duration(milliseconds: 2500 + _rnd.nextInt(3500)), () {
      if (!mounted) return;
      if (!_hareketsiz) {
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

  void _bostaPlanla() {
    _bostaZaman?.cancel();
    _bostaZaman = Timer(Duration(milliseconds: 6000 + _rnd.nextInt(7000)), () {
      if (!mounted || !widget.bosta) return;
      final mesgul = _hop.isAnimating || _yeme.isAnimating || _kipir.isAnimating;
      if (!_hareketsiz && !mesgul) {
        _bostaTur = _Bosta.values[_rnd.nextInt(_Bosta.values.length)];
        _bostaC.forward(from: 0);
      }
      _bostaPlanla();
    });
  }

  void _yemeSesleri() {
    final t = _yeme.value;
    while (_calinanPara < _paraBasla.length && t >= _paraBasla[_calinanPara] + _dusus) {
      _calinanPara++;
      widget.ses?.call(Ses.para);
      HapticFeedback.lightImpact();
    }
    if (!_yumCalindi && t >= _yumAni) {
      _yumCalindi = true;
      widget.ses?.call(Ses.yum);
    }
    if (!_sevincCalindi && t >= _sevincAni) {
      _sevincCalindi = true;
      widget.ses?.call(Ses.yasasin);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void didUpdateWidget(Karakter o) {
    super.didUpdateWidget(o);
    if (o.tepkiTetik != widget.tepkiTetik) {
      widget.ses?.call(widget.tur.ses);
      if (widget.ruh == Ruh.bulutlu) {
        if (_hareketsiz) {
          setState(() => _gunesAcik = true);
          _gunesSabit?.cancel();
          _gunesSabit = Timer(const Duration(milliseconds: 2600), () {
            if (mounted) setState(() => _gunesAcik = false);
          });
        } else {
          _teselli.forward(from: 0);
        }
      }
      if (!_hareketsiz) {
        _bostaC.stop();
        _hop.forward(from: 0);
        _kipir.forward(from: 0);
      }
    }
    if (o.yemeTetik != widget.yemeTetik) {
      if (_hareketsiz) {
        // Hareket yok, sevinç sesle gelir.
        widget.ses?.call(Ses.para);
        _sessizSevinc?.cancel();
        _sessizSevinc = Timer(const Duration(milliseconds: 280), () {
          if (mounted) widget.ses?.call(Ses.yasasin);
        });
      } else {
        _calinanPara = 0;
        _yumCalindi = false;
        _sevincCalindi = false;
        _bostaC.stop();
        _yeme.forward(from: 0);
      }
    }
    if (o.bosta != widget.bosta) {
      widget.bosta ? _bostaPlanla() : _bostaZaman?.cancel();
    }
  }

  @override
  void dispose() {
    _bobGecikme?.cancel();
    _kirpma?.cancel();
    _bostaZaman?.cancel();
    _sessizSevinc?.cancel();
    _gunesSabit?.cancel();
    _teselli.dispose();
    _bob.dispose();
    _hop.dispose();
    _kipir.dispose();
    _bostaC.dispose();
    _yeme.dispose();
    super.dispose();
  }

  /// i. paranın düşüş ilerlemesi (0–1); düşmüyorsa null.
  double? _paraIlerleme(int i) {
    if (!_yeme.isAnimating) return null;
    final p = (_yeme.value - _paraBasla[i]) / _dusus;
    return (p > 0 && p < 1) ? p : null;
  }

  /// Çiğneme nabzı (0–1): bir para ağza vardıktan sonraki kısa sıkışma.
  double _cigneme() {
    if (!_yeme.isAnimating) return 0;
    var c = 0.0;
    for (final b in _paraBasla) {
      final x = (_yeme.value - (b + _dusus)) / 0.07;
      if (x > 0 && x < 1) c = math.max(c, math.sin(x * math.pi));
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _hop, _kipir, _bostaC, _yeme, _teselli]),
      builder: (context, _) {
        // Salınım = nefes: hafif yükselme + göğüs şişmesi.
        final nefes = Curves.easeInOut.transform(_bob.value);
        var y = -4 * nefes;
        var sx = 1.0 - .012 * nefes, sy = 1.0 + .02 * nefes, aci = 0.0;
        var gozKapali = _kapali;
        var bakis = Offset.zero;

        void zipla(double t, double yukseklik) {
          final z = ziplamaEgrisi(t, yukseklik);
          y += z.y;
          sx *= z.sx;
          sy *= z.sy;
        }

        // Dokunma: çömel–zıpla–yaylan, üstüne sönen kıpırtı.
        if (_hop.isAnimating) zipla(_hop.value, 16);
        final k = _kipir.value;
        aci += .09 * math.sin(k * math.pi * 4) * (1 - k);
        if (_kipir.isAnimating && k > .1 && k < .7) gozKapali = true;

        // Boşta.
        if (_bostaC.isAnimating) {
          final b = _bostaC.value;
          switch (_bostaTur) {
            case _Bosta.kipir:
              aci += .06 * math.sin(b * math.pi * 4) * (1 - b);
            case _Bosta.ziplama:
              zipla(b, 9);
            case _Bosta.gerinme:
              // Yavaş uzan, tepede bir an dur, bırak (esneme gibi).
              final g = math.sin(math.pi * Curves.easeInOut.transform(b));
              sy += .09 * g;
              sx -= .05 * g;
              if (b > .3 && b < .75) gozKapali = true;
            case _Bosta.keyif:
              // Gözler kapalı, yana hafif yaslanıp mırlanır gibi sallanma.
              if (b > .1 && b < .9) gozKapali = true;
              aci += .07 * math.sin(b * math.pi) * math.sin(b * math.pi * 3);
            case _Bosta.etrafaBak:
              // Önce sola, sonra sağa bakar; baş bakışla aynı yana eğilir.
              final d = b < .5 ? -math.sin(b * 2 * math.pi) : math.sin((b - .5) * 2 * math.pi);
              bakis = Offset(d, -.2 * d.abs());
              aci += .05 * d;
            case _Bosta.dans:
              // İki küçük sekme, her birinde başka yana eğilerek.
              final yarim = b < .5 ? b * 2 : (b - .5) * 2;
              zipla(yarim, 6);
              aci += (b < .5 ? -.08 : .08) * math.sin(yarim * math.pi);
          }
        }

        // Yeme: çiğneme sıkışması, ağız; sonda sevinç zıplaması.
        var agizAcik = false;
        if (_yeme.isAnimating) {
          final c = _cigneme();
          sx += .07 * c;
          sy -= .07 * c;
          for (var i = 0; i < _paraBasla.length; i++) {
            final p = _paraIlerleme(i);
            if (p != null && p > .45) agizAcik = true;
            // Gözler düşen paraya kilitlenir: önce yukarı, para indikçe aşağı.
            if (p != null) bakis = Offset(0, -1 + 1.6 * p * p);
          }
          final u = ((_yeme.value - _sevincAni) / (1 - _sevincAni)).clamp(0.0, 1.0);
          if (u > 0) {
            zipla(u, 22);
            if (u > .1 && u < .9) gozKapali = true;
          }
        }

        // Hava: bulutluyken başın üstünde süzülen bulut; teselli anında güneş.
        double? gunes;
        if (widget.ruh == Ruh.bulutlu) {
          final t = _teselli.value;
          gunes = _gunesAcik
              ? 1
              : _teselli.isAnimating
                  ? Curves.easeOut.transform((t / .15).clamp(0.0, 1.0)) *
                      (1 - Curves.easeIn.transform(((t - .75) / .25).clamp(0.0, 1.0)))
                  : 0;
        }
        final karakter = Transform.translate(
          offset: Offset(0, y),
          child: Transform.rotate(
            angle: aci,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleX: sx,
              scaleY: sy,
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size.square(widget.boyut),
                painter: KarakterPainter(
                  tur: widget.tur,
                  // Güneş açınca karakter de gülümser (teselliye karşılık).
                  ruh: (gunes ?? 0) > .5 ? Ruh.mutlu : widget.ruh,
                  pulSayisi: widget.pulSayisi,
                  parlak: widget.parlak,
                  gozKapali: gozKapali,
                  agizAcik: agizAcik,
                  bakis: bakis,
                ),
              ),
            ),
          ),
        );
        if (!_yeme.isAnimating && gunes == null) return karakter;
        return Stack(clipBehavior: Clip.none, children: [
          karakter,
          if (gunes != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: HavaPainter(gunes: gunes, kayma: 3 * (_bob.value - .5))),
              ),
            ),
          if (_yeme.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParaYagmuru(
                  agiz: _agizMerkezi(widget.tur),
                  ilerlemeler: [for (var i = 0; i < _paraBasla.length; i++) _paraIlerleme(i)],
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Bulut ve güneş (110×110 alanında, sağ üst köşe). [gunes] 0 = yalnız bulut,
/// 1 = bulut çekilmiş, güneş açmış. Bulut gri-mavi ve yumuşak: fırtına, yağmur,
/// şimşek YOK; amaç "hava kapalı", korku değil.
class HavaPainter extends CustomPainter {
  HavaPainter({required this.gunes, this.kayma = 0});
  final double gunes;
  final double kayma;

  static const _bulut = Color(0xFFDDE3EE);
  static const _gunesRengi = Color(0xFFF7C948);

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 110;
    cv.save();
    cv.scale(s);
    final cizgi = Paint()
      ..color = DunyaRenkleri.murekkep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (gunes > 0) {
      cv.save();
      cv.translate(88, 12);
      cv.scale(.4 + .6 * gunes);
      final isin = Paint()
        ..color = _gunesRengi.withValues(alpha: gunes)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + gunes;
        cv.drawLine(Offset(math.cos(a) * 10, math.sin(a) * 10), Offset(math.cos(a) * 14, math.sin(a) * 14), isin);
      }
      cv.drawCircle(Offset.zero, 7.5, Paint()..color = _gunesRengi.withValues(alpha: gunes));
      cv.restore();
    }
    final b = 1 - gunes;
    if (b > 0) {
      // Bulut kenara kayarak çekilir.
      final x = 84 + kayma + 22 * gunes;
      // Parçalar tek kontura birleştirilir ki iç çizgiler görünmesin.
      final parcalar = [
        Path()..addOval(Rect.fromCircle(center: Offset(x - 8, 14), radius: 6.5)),
        Path()..addOval(Rect.fromCircle(center: Offset(x, 10), radius: 9)),
        Path()..addOval(Rect.fromCircle(center: Offset(x + 9, 14), radius: 6)),
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, 13, 29, 7.5), const Radius.circular(4))),
      ];
      final birlesik = parcalar.reduce((a, b) => Path.combine(PathOperation.union, a, b));
      cv.drawPath(birlesik, Paint()..color = _bulut.withValues(alpha: b));
      cv.drawPath(birlesik, cizgi..color = DunyaRenkleri.murekkep.withValues(alpha: b));
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(HavaPainter o) => o.gunes != gunes || o.kayma != kayma;
}

/// Besleme paraları: yukarıdan yerçekimiyle (p²) ağza düşer, dönerek gelir,
/// son %20'de ağza girerken küçülür. Logodaki halkalı altın paranın aynısı.
class _ParaYagmuru extends CustomPainter {
  _ParaYagmuru({required this.agiz, required this.ilerlemeler});
  final Offset agiz;
  final List<double?> ilerlemeler;

  static const _kaymalar = [-6.0, 7.0, 0.0];

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 110;
    cv.save();
    cv.scale(s);
    for (var i = 0; i < ilerlemeler.length; i++) {
      final p = ilerlemeler[i];
      if (p == null) continue;
      final bas = Offset(agiz.dx + _kaymalar[i], -34);
      final y = bas.dy + (agiz.dy - bas.dy) * p * p;
      final x = bas.dx + (agiz.dx - bas.dx) * p;
      final olcek = 1 - .6 * ((p - .8) / .2).clamp(0.0, 1.0);
      cv.save();
      cv.translate(x, y);
      // Dönüş: yatay basıklık (para kendi ekseninde döner gibi).
      cv.scale(olcek * (.55 + .45 * math.cos(p * math.pi * 3).abs()), olcek);
      cv.drawCircle(Offset.zero, 8.5, Paint()..color = const Color(0xFFF7D774));
      cv.drawCircle(
          Offset.zero,
          8.5,
          Paint()
            ..color = DunyaRenkleri.murekkep
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      cv.drawCircle(
          Offset.zero,
          5,
          Paint()
            ..color = const Color(0xFFE0A800)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      cv.restore();
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(_ParaYagmuru o) => true;
}
