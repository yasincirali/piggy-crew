import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../models/evre.dart';
import '../models/varlik.dart';
import '../services/dokunsal.dart';
import '../services/ses_servisi.dart';
import '../theme/dunya.dart';

part 'besleme_efektleri.dart';
part 'besleme_sahnesi.dart';

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
    this.yuz,
    this.sembol = '₺',
    this.evre,
    this.evreOnceki,
    this.evreGecis = 1,
    this.derinlik = true,
    this.golgeCiz = true,
    this.yeme,
  });

  /// Besleme ritüelinin anı (bkz. [yemeSahnesi]): yiyecek ve karaktere özgü
  /// parçalar (Sincap'ın yanakları ve kuyruğu, Baykuş'un kanatları ve göz
  /// yıldızları, Zıpzıp'in kulakları, Tortu'nun kabuk ışığı). Null → yok.
  final YemeAni? yeme;

  /// Büyüme evresi: gövde ölçeği ve baştaki bitki. Null → evresiz çizim
  /// (karşılama, dersler: evre kavramı yok, ölçek 1).
  final Evre? evre;

  /// Atlama sahnesinde önceki evre; [evreGecis] 0'da onun, 1'de [evre]'nin
  /// görünümü. Yeni gelen parça (filiz, çiçek, yıldız) büyüyerek çıkar.
  final Evre? evreOnceki;
  final double evreGecis;

  /// 2,5D görünüm: yumuşak ışık–gölge, parıltı, bulanık zemin gölgesi ve
  /// bakışla kayan yüz (baş çevirme). Çizgi film dili korunur; mürekkep
  /// kontur ve desenler aynı, yalnız hacim eklenir.
  final bool derinlik;

  /// Zemin gölgesini painter mı çizsin. Canlı karakter 2,5D'de gölgeyi
  /// kendisi yerde sabit çizer (zıplayınca gölge küçülür), burada çizilmez.
  final bool golgeCiz;

  final VarlikTuru tur;
  final Ruh ruh;

  /// Sincap'ın madeni parasındaki simge: çocuğun ev para birimi (global).
  final String sembol;

  /// Sürekli yüz değerleri (canlı karakter). Null ise yüz [ruh], [gozKapali]
  /// ve [agizAcik]'tan türetilir (durağan çizimler: liste, albüm).
  final Yuz? yuz;

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
    _isik(cv, p);
    if (kontur > 0) cv.drawPath(p, _cizgi(kontur));
  }

  /// Hacim: biçimin içine sol üstten ışık, sağ alta yumuşak gölge. Mürekkep
  /// kontur ÜSTTE kalır ki çizgi film netliği bozulmasın. Küçük parçalara
  /// (burun, ağız) uygulanmaz: kalabalık ve "kirli" görünür.
  void _isik(Canvas cv, Path p) {
    if (!derinlik) return;
    final b = p.getBounds();
    if (b.shortestSide < 12) return;
    cv.save();
    cv.clipPath(p);
    cv.drawRect(
        b,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.45, -.6),
            radius: 1.05,
            colors: [Color(0x59FFFFFF), Color(0x00FFFFFF), Color(0x00000000), Color(0x38000000)],
            stops: [0, .4, .62, 1],
          ).createShader(b));
    cv.restore();
  }

  /// Parıltı: ışığın yüzeyde bıraktığı küçük yumuşak beyaz leke (hacim hissi).
  void _parilti(Canvas cv, Offset c, double w, double h) {
    if (!derinlik) return;
    cv.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        Paint()
          ..color = const Color(0x8CFFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
  }

  /// Baş çevirme: yüz bakış yönüne birkaç birim kayar, gövde yerinde kalır
  /// (paralaks). Gözbebeklerinin kayması bunun üstüne biner.
  double get _yuzKayma => derinlik ? bakis.dx * 2.6 : 0;

  void _yuzBasla(Canvas cv) {
    cv.save();
    cv.translate(_yuzKayma, 0);
  }

  void _yuzBitir(Canvas cv) => cv.restore();

  static const _golgeOlcu = {
    VarlikTuru.altin: (55.0, 40.0),
    VarlikTuru.dolar: (55.0, 34.0),
    VarlikTuru.euro: (55.0, 34.0),
    VarlikTuru.nakit: (52.0, 34.0),
  };

  void _golge(Canvas cv, double olcek) {
    final (cx, rx) = _golgeOlcu[tur]!;
    cv.drawOval(
        Rect.fromCenter(center: Offset(cx, 101), width: rx * 2 * olcek, height: 12 * olcek),
        derinlik
            ? (Paint()
              ..color = const Color(0x4D000000)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3))
            : _dolgu(const Color(0x47000000)));
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
    _isik(cv, sekil);
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
    _isik(cv, sekil);
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
    _isik(cv, sekil);
  }

  // ── Yüz parçaları ──────────────────────────────────────────────────────
  //
  // Neden sürekli değerler: eskiden yüz birkaç sabit hâl arasında atlıyordu
  // (açık göz ↔ kapalı kapak, düz ağız ↔ gülüş). Sevinç anında gözlerin
  // uykulu kapağa dönmesi çocuğa "yoruldu" diye okunuyordu. Artık her parça
  // 0–1 arası bir değerle biçim değiştirir ve sahneler bu değerleri yumuşak
  // zarflarla sürer: aynı duygu her yerde aynı yüzle, atlamadan gelir.
  Yuz get _y => yuz ?? Yuz.ruhtan(ruh, kapali: gozKapali, agizAcik: agizAcik);

  void _goz(Canvas cv, double cx, double cy, double r, {Color iris = _murekkep, double irisR = 3.9}) {
    final y = _y;
    final s = y.sevinc.clamp(0.0, 1.0);
    final k = y.kapak.clamp(0.0, 1.0);
    // Göz dikeyde basılarak çizgiye dönüşür; çizgi sevinçte ^ (gülen göz),
    // kırpma/esnemede ‿ (kapalı göz). İkisi de aynı basılmanın iki ucu.
    final acik = (1 - s) * (1 - k);
    // Kare: ara kareler kısa sürsün (yarı basık göz "şüpheli" okunuyor).
    final boy = acik * acik;
    if (boy > .03) {
      cv.save();
      cv.translate(cx, cy);
      cv.scale(1, boy);
      cv.translate(-cx, -cy);
      cv.drawCircle(Offset(cx, cy), r, _dolgu(const Color(0xFFFFFAF0)));
      cv.drawCircle(Offset(cx, cy), r, _cizgi(1.5));
      // Bebek göz içinde kalır: kayma payı (r − irisR) ile sınırlı.
      final pay = math.max(0.0, r - irisR - .8);
      final b = Offset(cx + 1 + bakis.dx * pay, cy + 1 + bakis.dy * pay);
      cv.drawCircle(b, irisR, _dolgu(iris));
      if (iris != _murekkep) cv.drawCircle(b, irisR * .55, _dolgu(_murekkep));
      final yil = (yeme?.gozYildiz ?? 0).clamp(0.0, 1.0);
      if (yil > .01) {
        // Göze giren yıldız: parıltı yıldız biçiminde büyür (Baykuş'un yemesi).
        cv.drawPath(_yildizYolu(1.8 + 2.8 * yil).shift(b + const Offset(2, -3)), _dolgu(const Color(0xFFFFF3B0)));
        cv.drawPath(_yildizYolu(1.8 + 2.8 * yil).shift(b + const Offset(2, -3)), _cizgi(.8));
      } else {
        cv.drawCircle(b + const Offset(2.5, -3.5), 1.8, _dolgu(Colors.white));
      }
      cv.restore();
    }
    final yay = 1 - acik;
    if (yay <= .03) return;
    // Yay, göz kapandıkça belirir; biçimi sevinç ile kapak oranına göre.
    final sevincPayi = (s + k) == 0 ? 0.0 : s / (s + k);
    final egim = r * (.85 * sevincPayi - .45 * (1 - sevincPayi));
    final taban = cy + r * .25 * sevincPayi;
    final yol = Path()
      ..moveTo(cx - r * .8, taban)
      ..quadraticBezierTo(cx, taban - 2 * egim, cx + r * .8, taban);
    cv.drawPath(yol, _cizgi(2.4, _murekkep.withValues(alpha: (yay * 2.5).clamp(0.0, 1.0))));
  }

  void _yanak(Canvas cv, double cx, double cy) {
    final kz = _y.kizarma.clamp(0.0, 1.0);
    cv.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 12 * (1 + .4 * kz), height: 7 * (1 + .4 * kz)),
        _dolgu(const Color(0xFFF28C8C).withValues(alpha: .75 + .25 * kz)));
  }

  /// Ağız tek biçimden türer: düz çizgi → gülümseme → açık "D" kahkaha;
  /// çiğneme ve esneme ise yuvarlak "O". Konum karaktere göre (x,y) kaydırılır.
  void _agiz(Canvas cv, double dx, double dy) {
    final y = _y;
    final g = y.gulus.clamp(0.0, 1.0);
    final s = y.kahkaha.clamp(0.0, 1.0);
    final o = y.agizO.clamp(0.0, 1.0);
    cv.save();
    cv.translate(dx, dy);
    if (o < .97) {
      final x0 = 48 - 2 * g - 2 * s, x1 = 62 + 2 * g + 2 * s, y0 = 45 - 3 * g;
      final alt = y0 + 9 * g + 13 * s, ust = y0 + 9 * g * (1 - s);
      final katman = o > 0;
      if (katman) cv.saveLayer(const Rect.fromLTWH(30, 25, 50, 40), Paint()..color = Color.fromRGBO(0, 0, 0, 1 - o));
      if (s < .02) {
        cv.drawPath(
            Path()
              ..moveTo(x0, y0)
              ..quadraticBezierTo(55, alt, x1, y0),
            _cizgi(2.6));
      } else {
        final d = Path()
          ..moveTo(x0, y0)
          ..quadraticBezierTo(55, alt, x1, y0)
          ..quadraticBezierTo(55, ust, x0, y0)
          ..close();
        cv.drawPath(d, _dolgu(_murekkep));
        cv.save();
        cv.clipPath(d);
        final dip = (y0 + alt) / 2;
        cv.drawOval(Rect.fromCenter(center: Offset(55, dip - 1), width: 11, height: 7), _dolgu(const Color(0xFFF28C8C)));
        cv.restore();
        cv.drawPath(d, _cizgi(2.2));
      }
      if (katman) cv.restore();
    }
    if (o > .02) {
      final r = Rect.fromCenter(center: const Offset(55, 45), width: 6 + 7 * o, height: 10 * o);
      cv.drawOval(r, _dolgu(_murekkep));
      cv.drawOval(Rect.fromCenter(center: Offset(55, 45 + 3 * o), width: 7 * o, height: 3.5 * o),
          _dolgu(const Color(0xFFF28C8C)));
    }
    cv.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 110;
    canvas.save();
    canvas.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    canvas.scale(s);
    final ev = evre;
    final hedef = ev?.olcek ?? 1.0;
    final g = Curves.easeInOut.transform(evreGecis.clamp(0.0, 1.0));
    final olcek = evreOnceki == null ? hedef : evreOnceki!.olcek + (hedef - evreOnceki!.olcek) * g;
    if (golgeCiz) _golge(canvas, olcek);
    // Evre ölçeği ayak tabanından: karakter yerinde büyür, havaya kalkmaz.
    canvas.translate(55, 100);
    canvas.scale(olcek);
    canvas.translate(-55, -100);
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
    if (ev != null) _bitki(canvas, ev);
    final y = yeme;
    if (y != null && y.yemek != null && y.yemekOlcek > 0) {
      final opak = y.yemekOpak.clamp(0.0, 1.0);
      if (opak < 1) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opak));
      yemekCiz(canvas, tur, y.yemek!, yemekYaricap * y.yemekOlcek, aci: y.yemekAci, sembol: sembol);
      if (opak < 1) canvas.restore();
    }
    canvas.restore();
  }

  // ── Büyüme: baştaki bitki ─────────────────────────────────────────────
  //
  // Neden bitki: büyümenin kendisini anlatır (filiz → çiçek → yıldız), kostüm
  // değildir (çıkartmalar kostüm) ve dört karakterde aynı dil. Tortu'da
  // kabuğun arkasında biter (kaplumbağanın sırtındaki küçük bahçe).
  static const _bitkiYeri = {
    VarlikTuru.altin: (Offset(85, 55), .75),
    VarlikTuru.dolar: (Offset(55, 37), 0.0),
    VarlikTuru.euro: (Offset(55, 25), 0.0),
    VarlikTuru.nakit: (Offset(46, 33), -.1),
  };

  static const _yaprak = Color(0xFF6CC56B);
  static const _tacYaprak = {
    VarlikTuru.altin: Color(0xFFF28C8C),
    VarlikTuru.dolar: Color(0xFFFFB3C7),
    VarlikTuru.euro: Color(0xFFFFFAF0),
    VarlikTuru.nakit: Color(0xFFB9A7FF),
  };
  static const _altinTac = Color(0xFFF7C948);

  /// Yeni gelen parçanın büyüme payı (0–1): önceki evrede yoksa [evreGecis]
  /// ile büyür, zaten varsa tam.
  double _yeni(Evre parca) {
    final o = evreOnceki;
    if (o != null && o.index < parca.index) {
      // Hafif aşma ile çıkar (çizgi film "pıt"): 0 → 1,15 → 1.
      final t = evreGecis.clamp(0.0, 1.0);
      return t < .7 ? Curves.easeOut.transform(t / .7) * 1.15 : 1.15 - .15 * Curves.easeInOut.transform(((t - .7) / .3).clamp(0.0, 1.0));
    }
    return 1;
  }

  void _bitki(Canvas cv, Evre e) {
    if (e.index < Evre.filiz.index) return;
    final (yer, aci) = _bitkiYeri[tur]!;
    cv.save();
    cv.translate(yer.dx, yer.dy);
    cv.rotate(aci);
    final f = _yeni(Evre.filiz);
    if (f <= 0) {
      cv.restore();
      return;
    }
    cv.scale(f);
    final cicek = e.index >= Evre.cicek.index ? _yeni(Evre.cicek) : 0.0;
    // Sap: çiçekte uzar.
    final boy = 8 + 4 * cicek.clamp(0.0, 1.0);
    cv.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-1.5, -boy * .5, 0, -boy),
        _cizgi(1.8, const Color(0xFF3E8E4A)));
    // İki yaprak.
    for (final (x, y, r) in [(-4.2, -5.5, -.6), (4.2, -7.5, .6)]) {
      cv.save();
      cv.translate(x, y);
      cv.rotate(r);
      final yp = Path()..addOval(Rect.fromCenter(center: Offset.zero, width: 8, height: 4.6));
      cv.drawPath(yp, _dolgu(_yaprak));
      _isik(cv, yp);
      cv.drawPath(yp, _cizgi(1.3));
      cv.restore();
    }
    if (cicek > 0) {
      cv.save();
      cv.translate(0, -boy - 3);
      cv.scale(cicek);
      final yil = e == Evre.yildiz ? _yeni(Evre.yildiz).clamp(0.0, 1.0) : 0.0;
      final tac = Color.lerp(_tacYaprak[tur]!, _altinTac, yil)!;
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        final c = Offset(math.cos(a) * 3.6, math.sin(a) * 3.6);
        cv.drawCircle(c, 3, _dolgu(tac));
        cv.drawCircle(c, 3, _cizgi(1.2));
      }
      if (yil > 0) {
        // Yıldız evresi: göbek yıldız olur, iki minik pırıltı.
        cv.drawPath(_yildizYolu(3.6 * (.6 + .4 * yil)), _dolgu(const Color(0xFFFFF3B0)));
        cv.drawPath(_yildizYolu(3.6 * (.6 + .4 * yil)), _cizgi(1.1));
        for (final (px, py, pr) in [(-9.0, -4.0, 1.9), (8.5, -7.0, 1.5)]) {
          cv.drawPath(_yildizYolu(pr * 1.6 * yil).shift(Offset(px, py)), _dolgu(const Color(0xFFFFF3B0)));
          cv.drawPath(_yildizYolu(pr * 1.6 * yil).shift(Offset(px, py)), _cizgi(.9));
        }
      } else {
        cv.drawCircle(Offset.zero, 2.4, _dolgu(const Color(0xFFF7D774)));
        cv.drawCircle(Offset.zero, 2.4, _cizgi(1.1));
      }
      cv.restore();
    }
    cv.restore();
  }

  static Path _yildizYolu(double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rr = i.isEven ? r : r * .42;
      final o = Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  void _tortu(Canvas cv) {
    _sekil(cv, _p('M14 86c0-30 18-50 41-50s41 20 41 50z'), const Color(0xFFE0A800));
    final kabuk = _p('M22 86c0-24 14-40 33-40s33 16 33 40z');
    _cini(cv, kabuk);
    final isilti = yeme?.kabukIsilti ?? 0;
    if (isilti > 0 && isilti < 1) {
      // Karo kabuğa oturunca kabukta soldan sağa eğik bir ışık dolaşır.
      cv.save();
      cv.clipPath(kabuk);
      final x = 6 + 98 * Curves.easeInOut.transform(isilti);
      cv.translate(x, 66);
      cv.rotate(.45);
      final bant = Rect.fromCenter(center: Offset.zero, width: 14, height: 60);
      cv.drawRect(
          bant,
          Paint()
            ..shader = const LinearGradient(colors: [Color(0x00FFFFFF), Color(0xB3FFF6D6), Color(0x00FFFFFF)])
                .createShader(bant));
      cv.restore();
    }
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
      _isik(cv, Path()..addRRect(r));
      cv.drawRRect(r, _cizgi(2));
    }
    // Baş: baş çevirmede baş da yüzün yarısı kadar kayar (boyun döner).
    cv.save();
    cv.translate(_yuzKayma * .5, 0);
    const ten = Color(0xFFF5C76A);
    final bas = Path()..addOval(Rect.fromCircle(center: const Offset(55, 34), radius: 22));
    cv.drawPath(bas, _dolgu(ten));
    _isik(cv, bas);
    cv.drawPath(bas, _cizgi(2));
    cv.drawPath(_p('M44 16q11-8 22 0'), _cizgi(2));
    _parilti(cv, const Offset(45, 21), 9, 5);
    cv.restore();
    _yuzBasla(cv);
    _goz(cv, 47, 32, 7);
    _goz(cv, 63, 32, 7);
    _yanak(cv, 40, 44);
    _yanak(cv, 70, 44);
    _agiz(cv, 0, 0);
    _yuzBitir(cv);
  }

  void _zipzip(Canvas cv) {
    const yesil = Color(0xFF4FCF80);
    // Kulaklar dibinden döner: yere inişte dışa sarkıp yaylanır.
    final sark = (yeme?.kulakSark ?? 0) * .45;
    for (final (dis, ic, dip, yon) in [
      ('M34 46c-6-24 0-44 7-44s13 20 7 44z', 'M38 40c-3-16 1-30 3-30s6 14 3 30z', const Offset(41, 46), -1.0),
      ('M62 46c-6-24 0-44 7-44s13 20 7 44z', 'M66 40c-3-16 1-30 3-30s6 14 3 30z', const Offset(69, 46), 1.0),
    ]) {
      cv.save();
      if (sark != 0) {
        cv.translate(dip.dx, dip.dy);
        cv.rotate(yon * sark);
        cv.translate(-dip.dx, -dip.dy);
      }
      _sekil(cv, _p(dis), yesil);
      cv.drawPath(_p(ic), _dolgu(const Color(0xFFF28C8C)));
      cv.restore();
    }
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(55, 68), width: 68, height: 64));
    _hasir(cv, govde);
    cv.drawPath(govde, _cizgi(2));
    final karin = Rect.fromCenter(center: const Offset(55, 84), width: 32, height: 24);
    cv.drawOval(karin, _dolgu(const Color(0xFFEAFBEA)));
    _isik(cv, Path()..addOval(karin));
    cv.drawOval(karin, _cizgi(1.5));
    _parilti(cv, const Offset(38, 46), 10, 5.5);
    _yuzBasla(cv);
    _goz(cv, 44, 60, 8, irisR: 4.4);
    _goz(cv, 66, 60, 8, irisR: 4.4);
    _yanak(cv, 37, 72);
    _yanak(cv, 73, 72);
    _sekil(cv, _p('M51 73l4 4 4-4z'), const Color(0xFFF28C8C), kontur: 1.2);
    _agiz(cv, 0, 36);
    _yuzBitir(cv);
    cv.drawPath(_p('M40 86l-4 8M70 86l4 8'), _cizgi(2));
  }

  void _baykus(Canvas cv) {
    const lacivert = Color(0xFF1F3B73);
    // Kanatlar gövdenin arkasında durur; yıldızı yiyince iki kez çırpılır.
    final kanat = (yeme?.kanat ?? 0).clamp(0.0, 1.0);
    if (kanat > .01) {
      for (final (dip, yon) in [(const Offset(27, 58), -1.0), (const Offset(83, 58), 1.0)]) {
        cv.save();
        cv.translate(dip.dx, dip.dy);
        cv.rotate(-yon * (.15 + 1.1 * kanat));
        final k = Path()..addOval(Rect.fromCenter(center: const Offset(0, 15), width: 17, height: 34));
        _sekil(cv, k, const Color(0xFF17305E));
        cv.restore();
      }
    }
    cv.drawPath(_p('M22 32l16 12M88 32l-16 12'), _cizgi(11));
    cv.drawPath(_p('M22 32l16 12M88 32l-16 12'), _cizgi(8, lacivert));
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(55, 62), width: 72, height: 76));
    _sekil(cv, govde, lacivert);
    final kusak = _p('M30 70q25-16 50 0v10q-25 16-50 0z');
    _kilim(cv, kusak);
    cv.drawPath(kusak, _cizgi(1.5));
    _parilti(cv, const Offset(36, 36), 10, 6);
    _yuzBasla(cv);
    final yuz = Rect.fromCenter(center: const Offset(55, 60), width: 48, height: 36);
    cv.drawOval(yuz, _dolgu(const Color(0xFFDBE7FF)));
    _isik(cv, Path()..addOval(yuz));
    cv.drawOval(yuz, _cizgi(1.5));
    // Nazar gözleri: açık mavi halka + beyaz + mavi iris + siyah göz bebeği.
    for (final cx in [42.0, 68.0]) {
      cv.drawCircle(Offset(cx, 56), 12, _dolgu(const Color(0xFF7FC8FF)));
      _goz(cv, cx, 56, 10, iris: const Color(0xFF2B6FD6), irisR: 6.2);
    }
    _yanak(cv, 35, 68);
    _yanak(cv, 75, 68);
    _sekil(cv, _p('M50 67l5 8 5-8z'), const Color(0xFFF5B82E));
    _agiz(cv, 0, 38);
    _yuzBitir(cv);
    cv.drawPath(_p('M44 99l-3 6M66 99l3 6M55 99v6'), _cizgi(3, const Color(0xFFF5B82E)));
  }

  void _sincap(Canvas cv) {
    const turuncu = Color(0xFFE8540E);
    final kuyruk = _p('M70 50c30-30 46-10 42 20-3 22-24 36-38 26z');
    final sal = yeme?.kuyruk ?? 0;
    cv.save();
    if (sal != 0) {
      // Kuyruk dibinden sallanır (sakladığını süpürür gibi).
      cv.translate(72, 80);
      cv.rotate(sal);
      cv.translate(-72, -80);
    }
    _kilim(cv, kuyruk);
    cv.drawPath(kuyruk, _cizgi(2));
    cv.restore();
    final govde = Path()..addOval(Rect.fromCenter(center: const Offset(46, 64), width: 60, height: 64));
    _sekil(cv, govde, turuncu);
    final sis = (yeme?.yanakSis ?? 0).clamp(0.0, 1.0);
    if (sis > .01) {
      // Yanak keseleri: palamut parayı yanaklarına doldurur.
      for (final cx in [24.0, 68.0]) {
        final y = Path()..addOval(Rect.fromCircle(center: Offset(cx, 69), radius: 4 + 9 * sis));
        _sekil(cv, y, turuncu);
      }
    }
    _sekil(cv, _p('M22 42l5-18 11 12M70 42l-5-18-11 12'), turuncu);
    final karin = Rect.fromCenter(center: const Offset(46, 78), width: 32, height: 24);
    cv.drawOval(karin, _dolgu(const Color(0xFFFFE3C2)));
    _isik(cv, Path()..addOval(karin));
    cv.drawOval(karin, _cizgi(1.5));
    _parilti(cv, const Offset(30, 44), 9, 5);
    _yuzBasla(cv);
    _goz(cv, 36, 58, 7);
    _goz(cv, 56, 58, 7);
    _yanak(cv, 29, 70);
    _yanak(cv, 63, 70);
    cv.drawPath(_p('M43 71l3 4 3-4z'), _dolgu(_murekkep));
    _agiz(cv, -9, 34);
    _yuzBitir(cv);
    final para = Path()..addOval(Rect.fromCircle(center: const Offset(46, 98), radius: 10));
    cv.drawPath(para, _dolgu(const Color(0xFFF7D774)));
    _isik(cv, para);
    cv.drawPath(para, _cizgi(2));
    final tp = TextPainter(
      text: TextSpan(
        text: sembol,
        style: const TextStyle(fontFamily: govdeFontu, fontSize: 12, fontWeight: FontWeight.w700, color: _murekkep),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(cv, Offset(46 - tp.width / 2, 98 - tp.height / 2));
  }

  @override
  bool shouldRepaint(KarakterPainter o) =>
      o.tur != tur || o.ruh != ruh || o.pulSayisi != pulSayisi || o.parlak != parlak || o.gozKapali != gozKapali || o.agizAcik != agizAcik || o.bakis != bakis || o.yuz != yuz || o.sembol != sembol ||
      o.evre != evre || o.evreOnceki != evreOnceki || o.evreGecis != evreGecis || o.derinlik != derinlik || o.golgeCiz != golgeCiz || o.yeme != yeme;
}

/// Yüzün sürekli değerleri (hepsi 0–1). Tek duygu sözlüğü:
/// - [gulus]: ağız uçları; 0 düz, 1 gülümseme. Ruh hâlinden gelir.
/// - [sevinc]: gözler ^ biçimine kapanır (gülen göz).
/// - [kahkaha]: gülümseme açık "D" ağza açılır, dil görünür.
/// - [kapak]: göz ‿ biçimine kapanır (kırpma, esneme). Uyku/yorgunluk dili;
///   sevinçte KULLANILMAZ.
/// - [agizO]: yuvarlak ağız (para yerken, esnerken).
/// - [kizarma]: yanaklar büyür ve koyulaşır (sevinç, mahcup keyif).
@immutable
class Yuz {
  const Yuz({this.gulus = 0, this.sevinc = 0, this.kahkaha = 0, this.kapak = 0, this.agizO = 0, this.kizarma = 0});

  factory Yuz.ruhtan(Ruh r, {bool kapali = false, bool agizAcik = false}) =>
      Yuz(gulus: ruhGulusu(r), kapak: kapali ? 1 : 0, agizO: agizAcik ? 1 : 0);

  /// Ruh hâlinin ağız eğrisi. Düz hâl hafif gülümser: 7–10 yaş düz çizgiyi
  /// "canı sıkkın" okur; nötr karakter de sıcak bakmalı. Bulutlu en sakin.
  static double ruhGulusu(Ruh r) => switch (r) {
        Ruh.mutlu => 1,
        Ruh.duz => .4,
        Ruh.bulutlu => .1,
      };

  final double gulus, sevinc, kahkaha, kapak, agizO, kizarma;

  /// Sahne katmanlarını birleştirir: her değer en güçlü katmandan gelir.
  Yuz ust(Yuz o) => Yuz(
        gulus: math.max(gulus, o.gulus),
        sevinc: math.max(sevinc, o.sevinc),
        kahkaha: math.max(kahkaha, o.kahkaha),
        kapak: math.max(kapak, o.kapak),
        agizO: math.max(agizO, o.agizO),
        kizarma: math.max(kizarma, o.kizarma),
      );

  List<double> get degerler => [gulus, sevinc, kahkaha, kapak, agizO, kizarma];

  @override
  bool operator ==(Object other) => other is Yuz && _esit(other);
  bool _esit(Yuz o) {
    final a = degerler, b = o.degerler;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(degerler);
}

/// Yumuşak zarf: 0'dan girer, 1'de durur, 0'a iner. Uçlarda eğim sıfır
/// (smoothstep) ki duygu "açılıp kapanırken" atlama olmasın.
double zarf(double t, {double gir = .15, double cik = .2}) {
  if (t <= 0 || t >= 1) return 0;
  double ss(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  return math.min(ss(t / gir), ss((1 - t) / cik));
}

/// Sevinç yüzü (gücü e): ^ gözler, açık gülüş, kızaran yanak. Besleme sonu,
/// değer artıya geçince ve dokunma kıkırdaması AYNI yüzü kullanır.
Yuz sevincYuzu(double e, {double kahkaha = 1}) =>
    Yuz(gulus: e, sevinc: e, kahkaha: e * kahkaha, kizarma: e);

/// Büyüme sahnesi zaman çizelgesi (0–1, 2,4 sn): hazırlık, büyüme, sevinç.
const evreBuyumeBasla = 0.22;
const evreBuyumeBitis = 0.5;
const evreSevincAni = 0.52;

/// Büyüme sahnesinin bir anı (saf fonksiyon, `karakter_buyume_test`).
/// [gecis]: eski evreden yeniye (0–1); [sx]/[sy]: çömelme ve aşmalı büyüme.
({double gecis, double sx, double sy, double bakisY, Yuz yuz}) evreSahnesi(double t) {
  double ss(double x) => x <= 0 ? 0 : x >= 1 ? 1 : x * x * (3 - 2 * x);
  // Hazırlık: çömelir (basılır, genişler), merakla yukarı bakar.
  final comel = t < .28 ? math.sin(math.pi * t / .28) : 0.0;
  // Büyüme: geçiş ilerler, üstüne sönen aşma ("pıt" diye oturma).
  final u = ((t - evreBuyumeBasla) / (evreBuyumeBitis - evreBuyumeBasla)).clamp(0.0, 1.0);
  final asma = (t > evreBuyumeBasla && t < .78) ? .07 * math.sin(math.pi * ((t - evreBuyumeBasla) / (.78 - evreBuyumeBasla))) * (1 - u * .5) : 0.0;
  final sx = 1 + .08 * comel + asma * .8;
  final sy = 1 - .1 * comel + asma;
  // Merak yüzü (hazırlıkta): yuvarlak "o" ağız; sevinç anında aynı sevinç yüzü.
  final merak = zarf(t / .32, gir: .3, cik: .3);
  final sevinc = zarf((t - .3) / .7, gir: .15, cik: .25);
  final bakisY = -ss(t / .12) * (1 - ss((t - .55) / .1));
  return (
    gecis: ss(u),
    sx: sx,
    sy: sy,
    bakisY: bakisY,
    yuz: Yuz(agizO: merak * .6).ust(sevincYuzu(sevinc, kahkaha: .9)),
  );
}

/// Geri dönüş karşılaması zaman çizelgesi (0–1, 1,5 sn): koşu, varış, sevinç.
const donusVarisAni = 0.6;

/// Karşılamanın bir anı (saf fonksiyon, `donus_karsilamasi_test`).
/// [uzaklik]: yerine kalan yol (1 = kenarda, 0 = yerinde; widget yönle ve
/// boyutla çarpar); [opaklik]: kenarda belirerek girer, ekranda "ışınlanma"
/// olmasın; [egim]: koşu yönüne öne eğilme (yön işaretsiz, widget çarpar).
/// Koşu dört küçük sekmeyle, varınca bir sevinç zıplaması; yüz baştan sona
/// gülümser, varışta aynı sevinç yüzüne açılır (duygu sözlüğü tek).
({double uzaklik, double opaklik, double y, double sx, double sy, double egim, Yuz yuz}) donusSahnesi(double t) {
  double ss(double x) => x <= 0 ? 0 : x >= 1 ? 1 : x * x * (3 - 2 * x);
  final p = (t / donusVarisAni).clamp(0.0, 1.0);
  // Güçlü yavaşlayan giriş (Devinim.cikis eğrisi): hızla gelir, yerinde yumuşak durur.
  final uzaklik = 1 - Devinim.cikis.transform(p);
  final opaklik = ss(t / .14);
  var y = 0.0, sx = 1.0, sy = 1.0;
  if (t < donusVarisAni) {
    // Koşu sekmeleri: yaklaştıkça alçalır.
    final z = ziplamaEgrisi((p * 4) % 1, 7 * (1 - .5 * p));
    y = z.y;
    sx = z.sx;
    sy = z.sy;
  } else {
    final z = ziplamaEgrisi((t - donusVarisAni) / (1 - donusVarisAni), 18);
    y = z.y;
    sx = z.sx;
    sy = z.sy;
  }
  final egim = .1 * zarf(p, gir: .1, cik: .45);
  final sevinc = zarf((t - donusVarisAni + .04) / (1 - donusVarisAni + .04), gir: .15, cik: .3);
  final gulus = zarf(t, gir: .08, cik: .12);
  return (
    uzaklik: uzaklik,
    opaklik: opaklik,
    y: y,
    sx: sx,
    sy: sy,
    egim: egim,
    yuz: Yuz(gulus: gulus, kizarma: .4 * gulus).ust(sevincYuzu(sevinc)),
  );
}

/// Gövdenin ortası (110×110): büyüme ışığının merkezi.
Offset _govdeMerkezi(VarlikTuru t) => switch (t) {
      VarlikTuru.altin => const Offset(55, 62),
      VarlikTuru.dolar => const Offset(55, 64),
      VarlikTuru.euro => const Offset(55, 60),
      VarlikTuru.nakit => const Offset(48, 64),
    };

/// Yerde sabit, yumuşak zemin gölgesi (2,5D). [yukseklik] 0 = yerde,
/// 1 = en yüksekte (gölge küçülür, solar).
class ZeminGolgesi extends CustomPainter {
  ZeminGolgesi({required this.tur, required this.yukseklik, this.olcek = 1});
  final VarlikTuru tur;
  final double yukseklik;
  final double olcek;

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 110;
    cv.save();
    cv.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    cv.scale(s);
    final (cx, rx) = KarakterPainter._golgeOlcu[tur]!;
    final k = olcek * (1 - .35 * yukseklik);
    cv.drawOval(
        Rect.fromCenter(center: Offset(cx, 101), width: rx * 2 * k, height: 12 * k),
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, .3 * (1 - .5 * yukseklik))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    cv.restore();
  }

  @override
  bool shouldRepaint(ZeminGolgesi o) => o.yukseklik != yukseklik || o.olcek != olcek || o.tur != tur;
}

/// Büyüme ışığı: arkada sıcak hâle (büyüme anında doruk), önde dışa saçılan
/// sekiz pırıltı. Konfeti değil: az, yumuşak, karakterin kendi ışığı.
class EvreIsigi extends CustomPainter {
  EvreIsigi({required this.t, required this.arka, required this.merkez});
  final double t;
  final bool arka;
  final Offset merkez;

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 110;
    cv.save();
    cv.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    cv.scale(s);
    if (arka) {
      final h = zarf(t / .85, gir: .3, cik: .5);
      if (h > 0) {
        final r = 34 + 22 * h;
        cv.drawCircle(
            merkez,
            r,
            Paint()
              ..shader = RadialGradient(colors: [
                Color.fromRGBO(255, 236, 160, .75 * h),
                Color.fromRGBO(255, 214, 102, .35 * h),
                const Color(0x00FFD666),
              ], stops: const [0, .55, 1])
                  .createShader(Rect.fromCircle(center: merkez, radius: r)));
      }
    } else {
      final p = ((t - evreBuyumeBasla) / .55).clamp(0.0, 1.0);
      if (p > 0 && p < 1) {
        final e = Curves.easeOut.transform(p);
        final gorunur = 1 - Curves.easeIn.transform(p);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + .35;
          final d = 22 + 34 * e + (i.isEven ? 4 : 0);
          final c = merkez + Offset(math.cos(a) * d, math.sin(a) * d * .85);
          final r = (i.isEven ? 4.2 : 3.0) * (.4 + .6 * math.sin(math.pi * math.min(1, p * 1.4)));
          cv.save();
          cv.translate(c.dx, c.dy);
          cv.rotate(p * 1.5);
          final yol = KarakterPainter._yildizYolu(r);
          cv.drawPath(yol, Paint()..color = Color.fromRGBO(255, 243, 176, gorunur));
          cv.drawPath(
              yol,
              Paint()
                ..color = DunyaRenkleri.murekkep.withValues(alpha: gorunur * .8)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .9
                ..strokeJoin = StrokeJoin.round);
          cv.restore();
        }
      }
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(EvreIsigi o) => o.t != t || o.arka != arka;
}

/// Ev para biriminin simgesi ağaçta bir kez verilir (main); her Karakter
/// çağrısına parametre taşımamak için. Yoksa '₺' (testler, önizleme).
class ParaSembolu extends InheritedWidget {
  const ParaSembolu({super.key, required this.sembol, required super.child});
  final String sembol;

  static String of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<ParaSembolu>()?.sembol ?? '₺';

  @override
  bool updateShouldNotify(ParaSembolu o) => o.sembol != sembol;
}

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
/// - Tepki (`tepkiTetik`): dokununca zıplar, kıkırdar, kendi sesini çıkarır.
/// - Yeme (`yemeTetik`): karakterin kendi besleme ritüeli (~1,8 sn, bkz.
///   `besleme_sahnesi.dart`): yiyecek karaktere ulaşınca "tık" ve hafif
///   titreşim, keyif anında "yum", sonda aynı sevinç zıplaması ve arpej.
///   Konfeti yok (ürün kararı): ödül karakterin kendi sevinci.
/// - Avuç (`avuc`): çocuğun elindeki yiyeceğin ekran konumu. Karakter ona
///   bakar, yaklaştıkça ona doğru eğilip ağzını hafifçe açar (bekleyiş,
///   talep değil: ses yok, metin yok).
/// - Sevinç (`sevincTetik`): değeri artıya geçince bir kez, iki zıplama ve
///   besleme sonundaki sevinç yüzünün aynısı.
///
/// - Büyüme (`evre` artınca, `evreKutla` açıksa): bir kez ~2,4 sn'lik sahne.
///   Hazırlık (çömelir, merakla yukarı bakar, "o" ağız), büyüme (arkada sıcak
///   ışık, gövde yeni ölçeğe aşmayla oturur, yeni bitki parçası "pıt" diye
///   çıkar, pırıltılar dışa saçılır), sevinç (aynı sevinç yüzü + zıplama).
///   Beslemeyle aynı anda gelirse yeme sahnesi bitince başlar. Uygulama
///   açılışında oynamaz (yalnız ekrandayken artış).
/// - Geri dönüş (`donusTetik`): birkaç gün sonra açılışta, haftada en çok bir
///   kez (karar `models/donus.dart`'ta). [donusYon] tarafındaki kenardan
///   belirerek koşar, yerine varınca sevinçle zıplar; ~1,5 sn. İlk karede
///   tetik zaten artmışsa (soğuk açılış) sahne ilk kareden başlar ki
///   karakter önce yerinde görünüp sonra kenara "ışınlanmasın".
///
/// Duygu sözlüğü tektir ([Yuz]): sevinç = ^ gözler + açık gülüş + kızaran
/// yanak (besleme sonu, artıya geçiş, dokunma kıkırdaması, keyif); kapalı ‿
/// göz yalnız kırpma ve esnemede. Ruh hâli değişince gülüş 600 ms'de kayar.
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
    this.sevincTetik = 0,
    this.bosta = false,
    this.ses,
    this.dokun,
    this.evre,
    this.evreKutla = false,
    this.derinlik = true,
    this.donusTetik = 0,
    this.donusYon = -1,
    this.donusGecikme = Duration.zero,
    this.avuc,
  });

  /// Elde bekleyen yiyeceğin global konumu (null → yok). Bkz. `AvucParasi`.
  final ValueListenable<Offset?>? avuc;

  /// Her artışta geri dönüş karşılaması oynar (azalış oynatmaz: üst widget
  /// sahneden sonra sayacı sıfırlayabilir).
  final int donusTetik;

  /// Koşarak geldiği kenar: −1 soldan, +1 sağdan.
  final double donusYon;

  /// Takım sırayla gelsin diye karaktere özgü kısa bekleme; bu sürede
  /// karakter görünmez (kenarda bekliyor).
  final Duration donusGecikme;

  /// Büyüme evresi (null → evresiz çizim). Bkz. [Evre].
  final Evre? evre;

  /// Evre artınca büyüme sahnesi oynasın mı (kamp, detay). Kapalıysa yeni
  /// evre doğrudan görünür.
  final bool evreKutla;

  /// 2,5D görünüm (bkz. [KarakterPainter.derinlik]).
  final bool derinlik;

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

  /// Her artışta "artıya geçti" sevinci oynar.
  final int sevincTetik;

  /// Kendiliğinden ara sıra hareket etsin mi (kamp).
  final bool bosta;

  /// Ses çalıcı; null ise sessiz (sayfalar, testler).
  final void Function(Ses)? ses;

  /// Titreşim: sahne anları sesle aynı zaman çizelgesinden çalar
  /// (bkz. [yemeIpuclari]). Null → titreşim yok.
  final void Function(Dokunus)? dokun;

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
  // Kırpma 180 ms: göz ‿'ya kapanıp açılır (eskiden 140 ms'lik anlık takas).
  late final AnimationController _kirp =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  // Teselli: bulutluyken dokununca bulut çekilir, güneş açar, sonra bulut
  // yavaşça geri gelir (fiyat değişmedi; yalan söylemeyiz, ama karakter
  // çocuğun ilgisine sevinir).
  late final AnimationController _teselli =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  // Artıya geçiş sevinci: iki zıplama, ~1,5 sn. Nadir an, sevinç bütçesi burada.
  late final AnimationController _sevincC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  // Ruh değişince gülüş eğrisi yumuşak kayar (ani yüz değişimi yok).
  late final AnimationController _gulusC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600), value: 1);
  late double _gulusBas = Yuz.ruhGulusu(widget.ruh);
  late double _gulusHedef = _gulusBas;
  Timer? _gunesSabit;
  bool _gunesAcik = false;
  late final AnimationController _yeme =
      AnimationController(vsync: this, duration: yemeSuresi)
        ..addListener(_yemeSesleri)
        ..addStatusListener(_yemeBitti);
  // Büyüme sahnesi: nadir ve ilk kez olan an; sevinç bütçesinin en büyüğü.
  // Geri dönüş karşılaması: koşu + varış sevinci, ~1,5 sn. Nadir (haftada en
  // çok bir) an; sevinç bütçesi burada harcanabilir.
  late final AnimationController _donusC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  Timer? _donusZaman;
  // Bekleyiş gücü (0–1) ve yönü: avuç konumundan, yumuşatılarak.
  late final AnimationController _istekC = AnimationController(vsync: this);
  Offset _istekYon = Offset.zero;
  bool _donusBekliyor = false;
  bool _ilkBagimlilik = true;
  late final AnimationController _evreC =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..addListener(_evreSesleri);
  late Evre? _evreGorunen = widget.evre;
  Evre? _evreOnceki;
  bool _evreBekliyor = false;
  bool _evreIsikCalindi = false;
  bool _evreSevincCalindi = false;
  _Bosta _bostaTur = _Bosta.kipir;
  final _rnd = math.Random();
  // Zamanlayıcılar alanda tutulur ve dispose'da iptal edilir; aksi hâlde
  // widget ağacı kalktıktan sonra sarkan timer kalır (testler yakalar).
  Timer? _bobGecikme;
  Timer? _kirpma;
  Timer? _bostaZaman;
  Timer? _sessizSevinc;

  // Besleme ipuçlarından kaçıncısına gelindi (ses + titreşim).
  int _ipucuSira = 0;

  bool get _hareketsiz => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _bobGecikme = Timer(widget.gecikme, () {
      if (mounted && !_hareketsiz) _bob.repeat(reverse: true);
    });
    _kirpmaPlanla();
    if (widget.bosta) _bostaPlanla();
    // Soğuk açılış: tetik ilk karede gelmişse karakter kenarda (görünmez)
    // başlar; hareketi azalt bilgisi ancak didChangeDependencies'te okunur.
    _donusBekliyor = widget.donusTetik > 0;
    widget.avuc?.addListener(_avucDegisti);
  }

  void _avucDegisti() {
    final g = widget.avuc?.value;
    final kutu = context.findRenderObject();
    if (g == null || kutu is! RenderBox || !kutu.hasSize) {
      _istekC.animateTo(0, duration: const Duration(milliseconds: 220));
      return;
    }
    final yerel = kutu.globalToLocal(g) - kutu.size.center(Offset.zero);
    final uzak = yerel.distance;
    if (uzak > 0) _istekYon = yerel / math.max(uzak, widget.boyut * .6);
    // Uzaktayken yalnız bakar; yaklaştıkça eğilip ağzını açar.
    final yakin = 1 - ((uzak - widget.boyut * .5) / (widget.boyut * 2)).clamp(0.0, 1.0);
    _istekC.animateTo(.25 + .75 * yakin, duration: const Duration(milliseconds: 120));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ilkBagimlilik) {
      _ilkBagimlilik = false;
      if (_donusBekliyor) _donusBaslat();
    }
  }

  void _donusBaslat() {
    _donusZaman?.cancel();
    if (_hareketsiz) {
      // Hareket yok: karakter yerinde kalır; ses ve mesajı kamp verir.
      _donusBekliyor = false;
      return;
    }
    _donusBekliyor = true;
    _donusZaman = Timer(widget.donusGecikme, () {
      if (!mounted) return;
      _donusBekliyor = false;
      _bostaC.stop();
      _donusC.forward(from: 0);
    });
  }

  void _kirpmaPlanla() {
    _kirpma = Timer(Duration(milliseconds: 2500 + _rnd.nextInt(3500)), () {
      if (!mounted) return;
      if (!_hareketsiz) _kirp.forward(from: 0);
      _kirpmaPlanla();
    });
  }

  void _bostaPlanla() {
    _bostaZaman?.cancel();
    _bostaZaman = Timer(Duration(milliseconds: 6000 + _rnd.nextInt(7000)), () {
      if (!mounted || !widget.bosta) return;
      final mesgul =
          _hop.isAnimating || _yeme.isAnimating || _kipir.isAnimating || _sevincC.isAnimating || _evreC.isAnimating || _donusC.isAnimating || widget.avuc?.value != null;
      if (!_hareketsiz && !mesgul) {
        _bostaTur = _Bosta.values[_rnd.nextInt(_Bosta.values.length)];
        _bostaC.forward(from: 0);
      }
      _bostaPlanla();
    });
  }

  void _yemeSesleri() {
    final t = _yeme.value;
    final liste = yemeIpuclari(widget.tur);
    while (_ipucuSira < liste.length && t >= liste[_ipucuSira].t) {
      final ip = liste[_ipucuSira++];
      if (ip.ses != null) widget.ses?.call(ip.ses!);
      if (ip.dokunus != null) widget.dokun?.call(ip.dokunus!);
    }
  }

  void _evreSesleri() {
    final t = _evreC.value;
    if (!_evreIsikCalindi && t >= evreBuyumeBasla) {
      _evreIsikCalindi = true;
      widget.ses?.call(Ses.cikartma);
      widget.dokun?.call(Dokunus.buyume);
    }
    if (!_evreSevincCalindi && t >= evreSevincAni) {
      _evreSevincCalindi = true;
      widget.ses?.call(Ses.yasasin);
      widget.dokun?.call(Dokunus.sevinc);
    }
  }

  void _evreBaslat() {
    _evreBekliyor = false;
    _evreIsikCalindi = false;
    _evreSevincCalindi = false;
    _bostaC.stop();
    _sevincC.stop();
    _evreC.forward(from: 0);
  }

  void _yemeBitti(AnimationStatus d) {
    if (d == AnimationStatus.completed && _evreBekliyor && mounted) _evreBaslat();
  }

  double get _gulus => _gulusBas + (_gulusHedef - _gulusBas) * Curves.easeInOut.transform(_gulusC.value);

  @override
  void didUpdateWidget(Karakter o) {
    super.didUpdateWidget(o);
    final yeniEvre = widget.evre;
    if (yeniEvre != _evreGorunen) {
      final artti = yeniEvre != null && _evreGorunen != null && yeniEvre.index > _evreGorunen!.index;
      if (artti && widget.evreKutla) {
        _evreOnceki = _evreGorunen;
        _evreGorunen = yeniEvre;
        if (_hareketsiz) {
          // Hareket yok: yeni evre hemen görünür, sevinç sesle gelir.
          _evreOnceki = null;
          widget.ses?.call(Ses.cikartma);
        } else if (_yeme.isAnimating || o.yemeTetik != widget.yemeTetik) {
          // Yeme bu karede başlıyor ya da sürüyor: sahne onun ardından.
          _evreBekliyor = true;
        } else {
          _evreBaslat();
        }
      } else {
        _evreGorunen = yeniEvre;
        _evreOnceki = null;
      }
    }
    if (o.ruh != widget.ruh) {
      _gulusBas = _gulus;
      _gulusHedef = Yuz.ruhGulusu(widget.ruh);
      _hareketsiz ? _gulusC.value = 1 : _gulusC.forward(from: 0);
    }
    if (o.tepkiTetik != widget.tepkiTetik) {
      widget.ses?.call(widget.tur.ses);
      widget.dokun?.call(widget.tur.sesDokunusu);
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
        // Hareket yok, sevinç sesle (ve titreşimle) gelir: yakalama, sonra yaşasın.
        widget.ses?.call(yakalamaSesi(widget.tur));
        widget.dokun?.call(Dokunus.yakalama);
        _sessizSevinc?.cancel();
        _sessizSevinc = Timer(const Duration(milliseconds: 280), () {
          if (!mounted) return;
          widget.ses?.call(Ses.yasasin);
          widget.dokun?.call(Dokunus.sevinc);
        });
      } else {
        _ipucuSira = 0;
        _bostaC.stop();
        _sevincC.stop();
        _yeme.forward(from: 0);
      }
    }
    if (o.sevincTetik != widget.sevincTetik) {
      widget.ses?.call(Ses.yasasin);
      if (!_hareketsiz && !_yeme.isAnimating && !_donusC.isAnimating) {
        widget.dokun?.call(Dokunus.sevinc);
        _bostaC.stop();
        _sevincC.forward(from: 0);
      }
    }
    if (o.bosta != widget.bosta) {
      widget.bosta ? _bostaPlanla() : _bostaZaman?.cancel();
    }
    if (widget.donusTetik > o.donusTetik) {
      _donusBaslat();
    }
    if (o.avuc != widget.avuc) {
      o.avuc?.removeListener(_avucDegisti);
      widget.avuc?.addListener(_avucDegisti);
      _avucDegisti();
    }
  }

  @override
  void dispose() {
    _bobGecikme?.cancel();
    _kirpma?.cancel();
    _bostaZaman?.cancel();
    _sessizSevinc?.cancel();
    _gunesSabit?.cancel();
    _donusZaman?.cancel();
    _donusC.dispose();
    widget.avuc?.removeListener(_avucDegisti);
    _istekC.dispose();
    _teselli.dispose();
    _bob.dispose();
    _hop.dispose();
    _kipir.dispose();
    _bostaC.dispose();
    _kirp.dispose();
    _sevincC.dispose();
    _gulusC.dispose();
    _yeme.dispose();
    _evreC.dispose();
    super.dispose();
  }

  /// Sahne beklerken (yeme sürüyor) eski evre çizilir: büyüme sahnesiz görünmesin.
  Evre? get _evreCizilen => _evreBekliyor ? _evreOnceki : _evreGorunen;

  double _evreOlcegi(double gecis) {
    final e = _evreCizilen;
    if (e == null) return 1;
    final o = _evreOnceki;
    if (o == null || gecis >= 1 || _evreBekliyor) return e.olcek;
    return o.olcek + (e.olcek - o.olcek) * Curves.easeInOut.transform(gecis);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _hop, _kipir, _bostaC, _yeme, _teselli, _kirp, _sevincC, _gulusC, _evreC, _donusC, _istekC]),
      builder: (context, _) {
        // Salınım = nefes: hafif yükselme + göğüs şişmesi.
        final nefes = Curves.easeInOut.transform(_bob.value);
        var y = -4 * nefes;
        var sx = 1.0 - .012 * nefes, sy = 1.0 + .02 * nefes, aci = 0.0;
        var bakis = Offset.zero;
        var yuz = Yuz(kapak: _kirp.isAnimating ? math.sin(_kirp.value * math.pi) : 0);

        void zipla(double t, double yukseklik) {
          final z = ziplamaEgrisi(t, yukseklik);
          y += z.y;
          sx *= z.sx;
          sy *= z.sy;
        }

        // Dokunma: çömel–zıpla–yaylan, üstüne sönen kıpırtı ve kıkırdama
        // (gülen göz, yarı açık gülüş): "dokundun, hoşuma gitti".
        if (_hop.isAnimating) zipla(_hop.value, 16);
        final k = _kipir.value;
        aci += .09 * math.sin(k * math.pi * 4) * (1 - k);
        if (_kipir.isAnimating) yuz = yuz.ust(sevincYuzu(zarf(k, gir: .12, cik: .35), kahkaha: .7));

        // Boşta.
        if (_bostaC.isAnimating) {
          final b = _bostaC.value;
          switch (_bostaTur) {
            case _Bosta.kipir:
              aci += .06 * math.sin(b * math.pi * 4) * (1 - b);
            case _Bosta.ziplama:
              zipla(b, 9);
            case _Bosta.gerinme:
              // Yavaş uzan, tepede esne (‿ göz + O ağız), bırak.
              final g = math.sin(math.pi * Curves.easeInOut.transform(b));
              sy += .09 * g;
              sx -= .05 * g;
              final e = zarf(b, gir: .3, cik: .3);
              yuz = yuz.ust(Yuz(kapak: e, agizO: e * .9));
            case _Bosta.keyif:
              // Keyif: gülen gözler, kapalı gülüş, hafif pembe yanak; yana
              // yaslanıp mırlanır gibi sallanma. Uykulu göz değil (eski hâl
              // "yoruldu" okunuyordu).
              final e = zarf(b, gir: .2, cik: .25);
              yuz = yuz.ust(Yuz(gulus: e, sevinc: e, kizarma: .5 * e));
              aci += .07 * math.sin(b * math.pi) * math.sin(b * math.pi * 3);
            case _Bosta.etrafaBak:
              // Önce sola, sonra sağa bakar; baş bakışla aynı yana eğilir.
              final d = b < .5 ? -math.sin(b * 2 * math.pi) : math.sin((b - .5) * 2 * math.pi);
              bakis = Offset(d, -.2 * d.abs());
              aci += .05 * d;
            case _Bosta.dans:
              // İki küçük sekme, her birinde başka yana eğilerek; gülümser.
              final yarim = b < .5 ? b * 2 : (b - .5) * 2;
              zipla(yarim, 6);
              aci += (b < .5 ? -.08 : .08) * math.sin(yarim * math.pi);
              yuz = yuz.ust(Yuz(gulus: zarf(b)));
          }
        }

        // Bekleyiş: elde yiyecek varken ona bakar, yaklaştıkça eğilir ve ağzını açar.
        final istek = _istekC.value;
        if (istek > 0) {
          bakis = Offset(_istekYon.dx.clamp(-1.0, 1.0), _istekYon.dy.clamp(-1.0, 1.0)) * istek;
          aci += .07 * _istekYon.dx.clamp(-1.0, 1.0) * istek;
          final a = ((istek - .25) / .75).clamp(0.0, 1.0);
          yuz = yuz.ust(Yuz(agizO: .35 * a, gulus: istek, kizarma: .3 * a));
        }

        // Yeme: karakterin kendi ritüeli (bkz. [yemeSahnesi]); sonda sevinç.
        YemeAni? yemeAni;
        if (_yeme.isAnimating) {
          final a = yemeAni = yemeSahnesi(widget.tur, _yeme.value);
          y += a.y;
          sx *= a.sx * a.donus;
          sy *= a.sy;
          aci += a.aci;
          bakis = a.bakis;
          yuz = yuz.ust(a.yuz);
        }

        // Artıya geçiş: iki zıplama (büyük + küçük), aynı sevinç yüzü.
        if (_sevincC.isAnimating) {
          final v = _sevincC.value;
          v < .55 ? zipla(v / .55, 20) : zipla((v - .55) / .45, 10);
          yuz = yuz.ust(sevincYuzu(zarf(v, gir: .1, cik: .25)));
        }

        // Büyüme: hazırlık (çömel, yukarı bak, "o"), büyüme (aşmalı ölçek),
        // sevinç (aynı yüz + zıplama). Bkz. [evreSahnesi].
        var evreGecis = 1.0;
        double? evreT;
        if (_evreC.isAnimating && _evreOnceki != null) {
          final t = evreT = _evreC.value;
          final e = evreSahnesi(t);
          evreGecis = e.gecis;
          sx *= e.sx;
          sy *= e.sy;
          bakis = Offset(bakis.dx, math.min(bakis.dy, e.bakisY));
          yuz = yuz.ust(e.yuz);
          final u = (t - evreSevincAni) / (.92 - evreSevincAni);
          if (u > 0 && u < 1) zipla(u, 14);
        }

        // Geri dönüş: kenardan koşarak gelir, varınca sevinçle zıplar.
        var dx = 0.0, opaklik = 1.0;
        if (_donusBekliyor) {
          opaklik = 0;
        } else if (_donusC.isAnimating) {
          final d = donusSahnesi(_donusC.value);
          dx = widget.donusYon * widget.boyut * 1.3 * d.uzaklik;
          opaklik = d.opaklik;
          y += d.y;
          sx *= d.sx;
          sy *= d.sy;
          // Koşu yönü −yön: soldan gelen sağa koşar, sağa eğilir; gözler de
          // gittiği yere (takımın ortasına) bakar.
          aci -= widget.donusYon * d.egim;
          bakis = Offset(-widget.donusYon * .6 * d.uzaklik, bakis.dy);
          yuz = yuz.ust(d.yuz);
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
        // Güneş açtıkça karakter de gülümser (teselliye karşılık), kayarak.
        final taban = _gulus + (1 - _gulus) * (gunes ?? 0);
        yuz = Yuz(gulus: taban).ust(yuz);

        final karakter = Transform.translate(
          offset: Offset(dx, y),
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
                  ruh: widget.ruh,
                  pulSayisi: widget.pulSayisi,
                  parlak: widget.parlak,
                  bakis: bakis,
                  yuz: yuz,
                  sembol: ParaSembolu.of(context),
                  evre: _evreCizilen,
                  evreOnceki: evreT == null ? null : _evreOnceki,
                  evreGecis: evreGecis,
                  derinlik: widget.derinlik,
                  golgeCiz: !widget.derinlik,
                  yeme: yemeAni,
                ),
              ),
            ),
          ),
        );
        // 2,5D: gölge yerde sabit kalır; karakter yükseldikçe küçülür ve
        // solar (havada olduğu okunur). Eskiden gölge karakterle zıplıyordu.
        final zemin = widget.derinlik
            ? Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: CustomPaint(
                      painter: ZeminGolgesi(
                        tur: widget.tur,
                        yukseklik: (-y / 24).clamp(0.0, 1.0),
                        olcek: _evreOlcegi(evreGecis),
                      ),
                    ),
                  ),
                ),
              )
            : null;
        final efektler = _yeme.isAnimating ? yemeEfektleri(widget.tur, _yeme.value) : const <Parcacik>[];
        final efekt = efektler.isEmpty
            ? null
            : Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: CustomPaint(painter: EfektPainter(parcaciklar: efektler, olcek: _evreOlcegi(evreGecis))),
                  ),
                ),
              );
        if (gunes == null && evreT == null && zemin == null && efekt == null && opaklik == 1) return karakter;
        final yigin = Stack(clipBehavior: Clip.none, children: [
          ?zemin,
          if (evreT != null)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: EvreIsigi(t: evreT, arka: true, merkez: _govdeMerkezi(widget.tur)))),
            ),
          karakter,
          ?efekt,
          if (evreT != null)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: EvreIsigi(t: evreT, arka: false, merkez: _govdeMerkezi(widget.tur)))),
            ),
          if (gunes != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: HavaPainter(gunes: gunes, kayma: 3 * (_bob.value - .5))),
              ),
            ),
        ]);
        // Kenarda beklerken ve belirirken saydam; gölge de karakterle gelir.
        return opaklik >= 1 ? yigin : Opacity(opacity: opaklik, child: yigin);
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
