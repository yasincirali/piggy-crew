import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/varlik.dart';
import '../services/dokunsal.dart';
import '../services/ses_servisi.dart';
import '../theme/dunya.dart';
import 'karakter.dart';

/// Avuç parası: besledikten sonra yiyecek çocuğun "avucunda" belirir; çocuk
/// onu sürükleyip karaktere uzatır ya da dokunur, yiyecek uçup karakterin
/// sahnesine geçer (bkz. `besleme_sahnesi.dart`).
///
/// Neden bir adım daha (yasin 2026-10-17, "besleme sanatsal ve özgün"):
/// davranışı değiştiren şey gerçek eylem (araştırma `02_pedagoji`); "Ver"
/// düğmesi bir form gönderimiydi. Yiyeceği kendi eliyle uzatmak beslemeyi
/// ritüele çevirir ve karakterle bağı elden kurar. Zorlama değil: süre yok,
/// sayaç yok, uyarı yok; dokunmak da yeter (ince motor becerisi gerekmez,
/// ekran okuyucuda tek düğme). Çocuk uzatmadan ayrılırsa (sekme, sayfa)
/// yiyecek kendiliğinden verilir: kayıt zaten yapılmıştır, sahne kaybolmaz.
///
/// Dokunuş dili (2026-10-17, "titreşim ve efektler profesyonel"): avuçta
/// belirince hafif bir damla sesi; tutunca "pıt" ve tık; sürüklerken
/// karaktere yaklaştıkça artan, çok hafif bir titreşim dokusu (iPhone) ve
/// karakterin etrafında bir halka; yakalama alanına girince tek bir "çentik"
/// (bırakabilirsin); atınca yumuşak "vuş"; uzakta bırakınca avuca
/// "damla" ile döner. Yiyeceğin arkasında kısa bir iz kalır (hız okunur).
/// Hiçbiri metin değil, hiçbiri süre ya da baskı kurmaz.
///
/// Konumlar global (kök Overlay ekranın tamamını kaplar).
class AvucParasi extends StatefulWidget {
  const AvucParasi({
    super.key,
    required this.tur,
    required this.sembol,
    required this.baslangic,
    required this.bekleme,
    required this.hedef,
    required this.hedefOlcek,
    required this.konum,
    required this.etiket,
    required this.onVerildi,
    this.ses,
    this.dokunsal,
    this.halka,
  });

  final VarlikTuru tur;
  final String sembol;

  /// Çıktığı yer (alt sayfanın kapandığı alt kenar) ve beklediği yer.
  final Offset baslangic, bekleme;

  /// Sahnenin yiyeceği devraldığı nokta; uçuş başlarken okunur.
  final Offset Function() hedef;

  /// Uçuş sonunda yiyeceğin ölçeği (sahnedeki boyuna eşit olsun diye).
  final double hedefOlcek;

  /// Yiyeceğin anlık konumu: karakter ona bakar (`Karakter.avuc`).
  final ValueNotifier<Offset?> konum;

  /// Ekran okuyucu etiketi ("Tortu'ya ver").
  final String etiket;
  final VoidCallback onVerildi;
  final void Function(Ses)? ses;
  final DokunsalServisi? dokunsal;

  /// Yakalama halkası: karakterin gövdesi (merkez + yarıçap, global).
  /// Null → halka çizilmez.
  final (Offset, double) Function()? halka;

  /// Bırakınca verildiği yarıçap (karakterin yiyecek noktasına uzaklık).
  static const yakalamaYaricapi = 90.0;

  /// Avuçtaki çizim çapı; dokunma alanı 56 (≥44 pt).
  static const boyut = 40.0;
  static const dokunma = 56.0;

  @override
  State<AvucParasi> createState() => AvucParasiState();
}

class AvucParasiState extends State<AvucParasi> with TickerProviderStateMixin {
  // Giriş: alt kenardan yükselir, beklediği yere yumuşak oturur.
  late final AnimationController _giris =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 480))..forward();
  late final AnimationController _salinim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  // İpucu: bir süre dokunulmazsa avuçtan karaktere noktalı yay (metin yok).
  late final AnimationController _ipucu =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _ucus = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _bitir();
    });
  late final AnimationController _geri = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && !verildi) {
        widget.ses?.call(Ses.don);
        widget.dokunsal?.cal(Dokunus.avucaDonus);
      }
    });
  // Yakalama alanına girince karakterin etrafında bir kez açılan halka.
  late final AnimationController _halka =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  // Sürükleme ve uçuşta yiyeceğin arkasındaki kısa iz (son konumlar).
  final _iz = <Offset>[];
  bool _icerde = false;
  double _yakinlik = 0, _gonderilen = -1;
  Timer? _ipucuZaman;

  Offset? _surukle;
  Offset _tutmaFark = Offset.zero;
  Offset _geriBas = Offset.zero;
  Offset _ucusBas = Offset.zero, _ucusKontrol = Offset.zero, _ucusSon = Offset.zero;
  bool _ucuyor = false, _bitti = false;

  bool get verildi => _ucuyor || _bitti;

  @override
  void initState() {
    super.initState();
    _ipucuZaman = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _surukle == null && !_ucuyor) _ipucu.repeat();
    });
    for (final c in [_giris, _salinim, _ucus, _geri]) {
      c.addListener(_yayinla);
    }
    _giris.addStatusListener((s) {
      if (s == AnimationStatus.completed && !verildi) widget.ses?.call(Ses.belir);
    });
    _ucus.addListener(_izEkle);
  }

  void _yayinla() {
    if (!_bitti) widget.konum.value = _merkez;
  }

  @override
  void dispose() {
    _ipucuZaman?.cancel();
    widget.dokunsal?.surekliDur();
    for (final c in [_giris, _salinim, _ipucu, _ucus, _geri, _halka]) {
      c.dispose();
    }
    super.dispose();
  }

  Offset get _bekleyis {
    final g = Devinim.cikis.transform(_giris.value);
    final bas = Offset.lerp(widget.baslangic, widget.bekleme, g)!;
    // Avuçta hafifçe süzülür (canlı ama sakin).
    return bas + Offset(0, 3 * math.sin(2 * math.pi * _salinim.value) * g);
  }

  Offset get _merkez {
    if (_ucuyor) {
      final t = Curves.easeOutCubic.transform(_ucus.value);
      final a = Offset.lerp(_ucusBas, _ucusKontrol, t)!;
      final b = Offset.lerp(_ucusKontrol, _ucusSon, t)!;
      return Offset.lerp(a, b, t)!;
    }
    if (_surukle != null) return _surukle!;
    if (_geri.isAnimating) return Offset.lerp(_geriBas, _bekleyis, Curves.easeOutCubic.transform(_geri.value))!;
    return _bekleyis;
  }

  double get _olcek {
    if (!_ucuyor) return _surukle != null ? 1.08 + .08 * _yakinlik : 1;
    return 1 + (widget.hedefOlcek - 1) * Curves.easeOutCubic.transform(_ucus.value);
  }

  void _ipucuDur() {
    _ipucuZaman?.cancel();
    _ipucu
      ..stop()
      ..value = 0;
  }

  /// Yiyeceği karaktere uçurur (dokunma, bırakma ya da karaktere dokunma).
  void ver() {
    if (verildi || !mounted) return;
    _ipucuDur();
    final bas = _merkez;
    final son = widget.hedef();
    final yol = (son - bas).distance;
    // Yay: ortanın üstünden geçer (atılmış gibi), kısa mesafede alçak.
    final orta = Offset.lerp(bas, son, .5)!;
    setState(() {
      _ucuyor = true;
      _surukle = null;
      _ucusBas = bas;
      _ucusSon = son;
      _ucusKontrol = orta - Offset(0, math.min(90, yol * .35));
    });
    widget.dokunsal?.surekliDur();
    widget.ses?.call(Ses.firlat);
    widget.dokunsal?.cal(Dokunus.firlatma);
    _ucus.duration = Duration(milliseconds: (220 + yol * .45).clamp(260, 520).round());
    _ucus.forward(from: 0);
  }

  /// Hemen ver, uçuşsuz (sekme değişti, sayfa açıldı, yeni besleme).
  void hemenVer() {
    if (_bitti) return;
    _bitir();
  }

  void _bitir() {
    if (_bitti) return;
    widget.dokunsal?.surekliDur();
    _bitti = true;
    _ucuyor = false;
    widget.konum.value = null;
    widget.onVerildi();
  }

  void _basla(DragStartDetails d) {
    if (verildi) return;
    _ipucuDur();
    _geri.stop();
    _tutmaFark = d.globalPosition - _merkez;
    _iz.clear();
    _icerde = false;
    _gonderilen = -1;
    setState(() => _surukle = d.globalPosition - _tutmaFark);
    widget.ses?.call(Ses.al);
    widget.dokunsal?.cal(Dokunus.tutma);
    widget.dokunsal?.surekliBasla();
    _yaklasmaGuncelle();
  }

  /// Karaktere yakınlık (0 uzak – 1 yakalama alanında): doku şiddeti,
  /// yiyeceğin büyümesi ve halka buna bağlı.
  void _yaklasmaGuncelle() {
    final s = _surukle;
    if (s == null) return;
    final d = (widget.hedef() - s).distance;
    const r = AvucParasi.yakalamaYaricapi;
    _yakinlik = (1 - (d - r) / (3 * r)).clamp(0.0, 1.0);
    final icerde = d < r;
    if (icerde && !_icerde) {
      widget.dokunsal?.cal(Dokunus.yaklasma);
      _halka.forward(from: 0);
    }
    _icerde = icerde;
    // Doku: uzakta neredeyse yok, yaklaştıkça artar; yalnız belirgin
    // değişimde gönderilir (kanalı her karede yormamak için).
    final siddet = icerde ? .42 : .04 + .3 * _yakinlik * _yakinlik;
    if ((siddet - _gonderilen).abs() > .03) {
      _gonderilen = siddet;
      widget.dokunsal?.surekliAyarla(siddet, .2 + .4 * _yakinlik);
    }
  }

  void _izEkle() {
    _iz.add(_merkez);
    if (_iz.length > 4) _iz.removeAt(0);
  }

  void _guncelle(DragUpdateDetails d) {
    if (verildi) return;
    setState(() => _surukle = d.globalPosition - _tutmaFark);
    _izEkle();
    _yaklasmaGuncelle();
    _yayinla();
  }

  void _birak(DragEndDetails d) {
    final s = _surukle;
    if (verildi || s == null) return;
    final hedef = widget.hedef();
    final yon = hedef - s;
    widget.dokunsal?.surekliDur();
    final hiz = d.velocity.pixelsPerSecond;
    final dogru = yon.distance == 0 ? 0.0 : (hiz.dx * yon.dx + hiz.dy * yon.dy) / yon.distance;
    // Karaktere yakın bırakıldı ya da ona doğru fırlatıldı → ver; değilse avuca döner.
    if (yon.distance < AvucParasi.yakalamaYaricapi || dogru > 600) {
      ver();
    } else {
      setState(() {
        _geriBas = s;
        _surukle = null;
        _yakinlik = 0;
        _icerde = false;
        _iz.clear();
      });
      _geri.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bitti) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge([_giris, _salinim, _ipucu, _ucus, _geri, _halka]),
      builder: (context, _) {
        final m = _merkez;
        const d = AvucParasi.dokunma;
        final suruklenir = _surukle != null;
        return Stack(children: [
          if (widget.halka != null && (suruklenir || _halka.isAnimating))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: YakalamaHalkasi(
                    govde: widget.halka!(),
                    yakinlik: suruklenir ? _yakinlik : 0,
                    acilis: _halka.isAnimating ? _halka.value : null,
                  ),
                ),
              ),
            ),
          if ((suruklenir || _ucuyor) && _iz.length > 1)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _IzCizimi(tur: widget.tur, sembol: widget.sembol, noktalar: List.of(_iz), olcek: _olcek),
                ),
              ),
            ),
          if (_ipucu.isAnimating)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: IpucuYayi(bas: m, son: widget.hedef(), t: _ipucu.value))),
            ),
          // Anahtar: üstteki katmanlar sürükleme başlarken eklenir; anahtarsız
          // olursa yiyeceğin elementi yeniden kurulur ve parmak hareketi kopar.
          Positioned(
            key: const ValueKey('yiyecek'),
            left: m.dx - d / 2,
            top: m.dy - d / 2,
            width: d,
            height: d,
            child: Semantics(
              button: true,
              label: widget.etiket,
              onTap: ver,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ver,
                onPanStart: _basla,
                onPanUpdate: _guncelle,
                onPanEnd: _birak,
                child: CustomPaint(
                  painter: _AvucCizimi(
                    tur: widget.tur,
                    sembol: widget.sembol,
                    olcek: _olcek,
                    aci: _ucuyor ? .4 * math.sin(math.pi * _ucus.value) : 0,
                    hale: _ucuyor ? 1 - _ucus.value : 1,
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _AvucCizimi extends CustomPainter {
  _AvucCizimi({required this.tur, required this.sembol, required this.olcek, required this.aci, required this.hale});
  final VarlikTuru tur;
  final String sembol;
  final double olcek, aci, hale;

  @override
  void paint(Canvas cv, Size size) {
    final c = size.center(Offset.zero);
    final r = AvucParasi.boyut / 2 * .8 * olcek;
    // Sıcak hâle: "elde, verilmeyi bekliyor".
    if (hale > 0) {
      cv.drawCircle(
          c,
          AvucParasi.boyut * .62,
          Paint()
            ..color = Color.fromRGBO(255, 226, 150, .35 * hale)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    yemekCiz(cv, tur, c, r, aci: aci, sembol: sembol);
  }

  @override
  bool shouldRepaint(_AvucCizimi o) => o.olcek != olcek || o.aci != aci || o.hale != hale || o.tur != tur || o.sembol != sembol;
}

/// Yiyeceğin arkasındaki iz: son konumlarda küçülen, solan kopyalar
/// (hız ve yön okunur, bulanıklık yok).
class _IzCizimi extends CustomPainter {
  _IzCizimi({required this.tur, required this.sembol, required this.noktalar, required this.olcek});
  final VarlikTuru tur;
  final String sembol;
  final List<Offset> noktalar;
  final double olcek;

  @override
  void paint(Canvas cv, Size size) {
    final n = noktalar.length;
    // En eski en solgun; sonuncusu yiyeceğin kendisi, çizilmez.
    for (var i = 0; i < n - 1; i++) {
      final k = (i + 1) / n;
      if ((noktalar[i] - noktalar.last).distance < 6) continue;
      cv.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, .2 * k));
      yemekCiz(cv, tur, noktalar[i], AvucParasi.boyut / 2 * .8 * olcek * (.7 + .25 * k), sembol: sembol);
      cv.restore();
    }
  }

  @override
  bool shouldRepaint(_IzCizimi o) => true;
}

/// Karakterin etrafında yakalama halkası: sürüklerken yaklaştıkça belirir;
/// alana girince bir kez dışa açılır ("bırakabilirsin").
class YakalamaHalkasi extends CustomPainter {
  YakalamaHalkasi({required this.govde, required this.yakinlik, this.acilis});
  final (Offset, double) govde;
  final double yakinlik;
  final double? acilis;

  @override
  void paint(Canvas cv, Size size) {
    const renk = Color(0xFFFFE296);
    final (merkez, r) = govde;
    if (yakinlik > 0) {
      cv.drawCircle(
          merkez,
          r * (1 + .06 * yakinlik),
          Paint()
            ..color = renk.withValues(alpha: .5 * yakinlik * yakinlik)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
    final a = acilis;
    if (a != null) {
      final e = Curves.easeOutCubic.transform(a);
      cv.drawCircle(
          merkez,
          r * (1 + .35 * e),
          Paint()
            ..color = renk.withValues(alpha: .7 * (1 - a))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - e) + 1);
    }
  }

  @override
  bool shouldRepaint(YakalamaHalkasi o) => o.govde != govde || o.yakinlik != yakinlik || o.acilis != acilis;
}

/// İpucu: avuçtan karaktere noktalı yay, üstünde ilerleyen parlak bir nokta.
/// Metin yok; okuma bilmeyen 7 yaş da "oraya" diye okur.
class IpucuYayi extends CustomPainter {
  IpucuYayi({required this.bas, required this.son, required this.t});
  final Offset bas, son;
  final double t;

  Offset _nokta(double u) {
    final yol = (son - bas).distance;
    final k = Offset.lerp(bas, son, .5)! - Offset(0, math.min(90, yol * .35));
    final a = Offset.lerp(bas, k, u)!;
    final b = Offset.lerp(k, son, u)!;
    return Offset.lerp(a, b, u)!;
  }

  @override
  void paint(Canvas cv, Size size) {
    final gorunur = zarf(t, gir: .15, cik: .25);
    if (gorunur <= 0) return;
    final p = Paint()..color = Color.fromRGBO(255, 246, 214, .55 * gorunur);
    for (var i = 2; i < 18; i++) {
      cv.drawCircle(_nokta(i / 18), 2.2, p);
    }
    cv.drawCircle(_nokta(Curves.easeInOut.transform(t)), 4, Paint()..color = Color.fromRGBO(255, 226, 150, .9 * gorunur));
  }

  @override
  bool shouldRepaint(IpucuYayi o) => o.t != t || o.bas != bas || o.son != son;
}
