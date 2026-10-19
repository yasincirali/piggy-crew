part of 'karakter.dart';

// ── Açılış: hazine sandığı (para yuvası) ─────────────────────────────────
//
// Neden (yasin 2026-10-19): açılışta Kumbara Takımı'nın sandığı açılsın ve
// içine girelim; hayvanlar ve para net görünsün. Üç demodan "C · para
// yuvası" seçildi: Sincap parayı fırlatır, para kapaktaki kumbara yuvasına
// düşer, sandık açılır, Zıpzıp ve Baykuş paraların üstünde belirir, takım
// sevinir, kamera sandığın ışığına dalar ve uygulama o ışıktan açılır.
//
// Kararlar:
// - Sandık önceden render (Blender, `tool/karakter3d/sandik.py`), iki katman:
//   arka (iç, kapak, paralar) ve ön duvar. İçteki karakterler aradan çizilir,
//   ön duvar ayaklarını örter. Kapak açıklığı kare sırasıdır; zamanlama burada.
// - Karakterler her zaman 3D kareleriyle (veli köşesindeki görünüm seçiminden
//   bağımsız): açılış sabit bir film, sandıkla aynı ışık ve tarzda olmalı.
//   Evre bitkisi yok (minik); kampta evre görünmeye devam eder.
// - Para çocuğun para birimi simgesini taşır (ParaSembolu), Sincap'ınki gibi.
// - Süre: tam hâli günün ilk açılışında 3,4 sn; aynı gün sonraki açılışlarda
//   para atışı atlanır (kısa). Dokununca hemen kapanır. Hareketi azalt:
//   sandık açık belirir, takım yerinde, yumuşak geçiş. VoiceOver/TalkBack
//   açıkken hiç oynamaz (doğrudan uygulama).
// - Ödül değil karşılama: konfeti, parıltı patlaması, sayı yok.

/// Sahne koordinatı: 720 × 1560 (ekran genişliğine sığdırılır, dikeyde ortalanır).
const _sahneG = 720.0, _sahneY = 1560.0;

/// Sandık katmanlarının render kadrajındaki (720²) kırpım kutuları ve sahnedeki üst kenarı.
const _sandikArka = Rect.fromLTRB(134, 96, 582, 602), _sandikOn = Rect.fromLTRB(136, 349, 559, 602);
const _sandikUst = 560.0;
const _sandikAdim = 36; // açıklık 0 → 1,1 (kare 35)

/// Karakter ölçeği (110'luk kutu → sahne pikseli) ve son duruşlar: Zıpzıp ve
/// Baykuş sandığın içinde, Tortu ile Sincap iki yanında yerde.
const _acilisOlcek = 2.4;
const _acilisPoz = <VarlikTuru, (double x, double y, bool ic, double olc)>{
  VarlikTuru.altin: (118, 1235, false, 1),
  VarlikTuru.dolar: (292, 985, true, .9),
  VarlikTuru.euro: (432, 985, true, .9),
  VarlikTuru.nakit: (600, 1235, false, 1),
};

/// Dalış merkezi (sandığın ağzı) ve yuvanın yeri.
const _dalisMerkez = Offset(355, 900), _yuva = Offset(346, 872);

double _kl(double x, [double a = 0, double b = 1]) => x < a ? a : (x > b ? b : x);
double _dilim(double t, double a, double b) => _kl((t - a) / (b - a));
double _eOut(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _eIn(double x) => x * x * x;
double _eIO(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
double _eBack(double x) {
  const c = 1.9;
  return 1 + (c + 1) * math.pow(x - 1, 3) + c * math.pow(x - 1, 2);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Açılışın zaman çizelgesi (saniye). Saf: test ve çizim aynı değerleri okur.
class AcilisAni {
  const AcilisAni(this.t);
  final double t;

  static const toplam = 3.4;
  static const kisaBaslangic = .95; // kısa sürüm: para atışı atlanır
  static const dalis = 2.25;

  /// Kapak açıklığı (0–1,1): 1,1'e taşar, 1'e oturur.
  double get kapak => t < 1.1 ? 0 : _lerp(0, 1.1, _eOut(_dilim(t, 1.1, 1.42))) - .1 * _eIO(_dilim(t, 1.42, 1.65));

  /// Para yutulunca sandığın ezilmesi (en, boy).
  (double, double) get ezilme {
    final s = math.sin(_dilim(t, .85, 1.1) * math.pi);
    return (1 + .05 * s, 1 - .08 * s);
  }

  /// Para: konum, en ölçeği (dönüş), boy ölçeği (yuvaya girerken), görünür mü.
  ({Offset konum, double en, double boy, bool gorunur}) get para {
    final (sx0, sy0, _, _) = _acilisPoz[VarlikTuru.nakit]!;
    final el = Offset(sx0 - 40, sy0 - 190);
    if (t < .25) return (konum: el.translate(0, 40 * _dilim(t, 0, .25)), en: 1, boy: 1, gorunur: true);
    if (t >= .95) return (konum: _yuva, en: 1, boy: 0, gorunur: false);
    final u = _dilim(t, .25, .85), yut = _dilim(t, .85, .95);
    final x = _lerp(el.dx + 0, _yuva.dx, u);
    final y = _lerp(el.dy + 40, _yuva.dy, u) - 330 * math.sin(u * math.pi) + 26 * yut;
    return (konum: Offset(x, y), en: math.max(.2, math.cos(t * 7).abs()), boy: 1 - .85 * yut, gorunur: true);
  }

  /// Karakter: atlas ifadesi ya da dokunma sahnesi karesi, konum, opaklık.
  ({AtlasIfade yuz, double? sahne, Offset ayak, bool ic, double olc, double opak}) karakter(VarlikTuru tur) {
    final (x, y, ic, olc) = _acilisPoz[tur]!;
    final yuz = t < 1.65 ? (t < .9 ? AtlasIfade.mutlu : AtlasIfade.o) : (t > 2.05 && t < 2.12 ? AtlasIfade.kirp : AtlasIfade.sevinc);
    if (ic) {
      final g = tur == VarlikTuru.dolar ? 0.0 : .07;
      final u = _dilim(t, 1.25 + g, 1.55 + g);
      return (yuz: yuz, sahne: null, ayak: Offset(x, _lerp(y + 260, y, _eBack(u))), ic: true, olc: olc, opak: u > 0 ? 1 : 0);
    }
    // Sincap atışta zıplar; ikisi de sevinçte bir kez hoplar.
    final at = tur == VarlikTuru.nakit ? t - .05 : -1.0;
    final sev = t - (1.62 + (tur == VarlikTuru.nakit ? .02 : 0));
    final sahne = (at >= 0 && at < .73) ? at * 30 : ((sev >= 0 && sev < .73) ? sev * 30 : null);
    return (yuz: yuz, sahne: sahne, ayak: Offset(x, y), ic: false, olc: olc, opak: 1);
  }

  /// Kamera: yakınlaşma ve dikey kayma (sandığın ağzı ortaya gelir).
  (double, double) get kamera {
    final u = _dilim(t, dalis, dalis + .7);
    return (1 + 7 * _eIn(u), -120 * _eIO(u));
  }

  /// Altın parlama (dalışın sonunda ekranı doldurur, sonra söner).
  double get parlama => _dilim(t, dalis + .3, dalis + .6) * (1 - _dilim(t, dalis + .75, dalis + 1.15));

  /// Sahnenin kendisinin görünürlüğü (parlamanın arkasında söner; uygulama açılır).
  double get sahne => 1 - _dilim(t, dalis + .6, dalis + .75);
}

/// Açılış sahnesi. [bitti] sahne kapanınca (sonunda ya da dokununca) çağrılır.
class AcilisSahnesi extends StatefulWidget {
  const AcilisSahnesi({super.key, required this.bitti, this.kisa = false, this.ses, this.titresim});

  final VoidCallback bitti;

  /// Aynı gün ikinci açılış: para atışı atlanır.
  final bool kisa;
  final void Function(Ses)? ses;
  final void Function(Dokunus)? titresim;

  @override
  State<AcilisSahnesi> createState() => _AcilisSahnesiState();
}

class _AcilisSahnesiState extends State<AcilisSahnesi> with TickerProviderStateMixin {
  late final AnimationController _c;
  final _arka = _Film('acilis/sandik_arka'), _on = _Film('acilis/sandik_on');
  final _dokunma = {for (final t in VarlikTuru.values) t: _Film('${t.name}/dokunma_beden')};
  final _anlar = <double>{};
  double _atla = -1; // dokunulduğu an (sahne saniyesi); -1 = dokunulmadı
  bool _sakin = false;

  double get _t0 => widget.kisa ? AcilisAni.kisaBaslangic : 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
      ..addListener(_anKontrol)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.bitti();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    final mq = MediaQuery.of(context);
    if (mq.accessibleNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.bitti());
      return;
    }
    _sakin = mq.disableAnimations;
    if (_sakin) {
      _c.duration = const Duration(milliseconds: 1700);
      _c.forward();
    } else {
      final kalan = AcilisAni.toplam - _t0;
      _c.duration = Duration(milliseconds: (kalan * 1000).round());
      _c.forward();
    }
  }

  double get _t => _sakin ? _c.value * 1.7 : _t0 + _c.value * (AcilisAni.toplam - _t0);

  // Ses ve titreşim anları (bir kez).
  void _anKontrol() {
    if (_sakin || _atla >= 0) return;
    final t = _t;
    void an(double s, void Function() f) {
      if (t >= s && _anlar.add(s)) f();
    }

    if (!widget.kisa) {
      an(.08, () {
        widget.ses?.call(Ses.firlat);
        widget.titresim?.call(Dokunus.firlatma);
      });
      an(.86, () {
        widget.ses?.call(Ses.para);
        widget.titresim?.call(Dokunus.sekme);
      });
    }
    an(1.12, () => widget.ses?.call(Ses.belir));
    an(1.62, () {
      widget.ses?.call(Ses.yasasin);
      widget.titresim?.call(Dokunus.sevinc);
    });
  }

  // Dokununca hızlı kapanış: sahne 200 ms'de söner.
  late final _kapanis = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.bitti();
    });

  void _dokun() {
    if (_atla >= 0) return;
    _atla = _t;
    _c.stop();
    _kapanis.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _kapanis.dispose();
    _arka.birak();
    _on.birak();
    for (final f in _dokunma.values) {
      f.birak();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dokun,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final a = AcilisAni(_t);
            final gorunur = (_sakin ? 1 - _dilim(_t, 1.2, 1.7) : a.sahne) * (1 - _kapanis.value);
            return Opacity(
              opacity: _kl(gorunur),
              child: CustomPaint(
                size: Size.infinite,
                painter: _AcilisPainter(
                  ani: a,
                  sakin: _sakin,
                  arka: _arka,
                  on: _on,
                  dokunma: _dokunma,
                  sembol: ParaSembolu.of(context),
                  // Açılış ekranının düz zemininden yumuşak giriş.
                  giris: _dilim(_c.value * _c.duration!.inMilliseconds / 1000, 0, .2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AcilisPainter extends CustomPainter {
  _AcilisPainter({required this.ani, required this.sakin, required this.arka, required this.on, required this.dokunma, required this.sembol, this.giris = 1});

  final AcilisAni ani;
  final bool sakin;
  final _Film arka, on;
  final Map<VarlikTuru, _Film> dokunma;
  final String sembol;
  final double giris;

  static const _zemin = [Color(0xFF1F5440), Color(0xFF15382C), Color(0xFF0E2A22)];

  @override
  void paint(Canvas cv, Size size) {
    final ekran = Offset.zero & size;
    cv.drawRect(
        ekran,
        Paint()
          ..shader = RadialGradient(center: const Alignment(0, .16), radius: .9, colors: _zemin, stops: const [0, .45, 1])
              .createShader(ekran));
    final s = size.width / _sahneG;
    final oy = (size.height - _sahneY * s) / 2;
    final kapak = sakin ? 1.0 : ani.kapak;
    final (kz, ky) = sakin ? (1.0, 0.0) : ani.kamera;

    if (giris < 1) {
      cv.saveLayer(ekran, Paint()..color = Color.fromRGBO(0, 0, 0, giris));
    } else {
      cv.save();
    }
    cv.translate(0, oy);
    cv.scale(s);
    cv.translate(_dalisMerkez.dx, _dalisMerkez.dy + ky);
    cv.scale(kz);
    cv.translate(-_dalisMerkez.dx, -_dalisMerkez.dy);

    // Yer gölgesi
    final yg = Rect.fromCenter(center: const Offset(360, 1155), width: 420, height: 70);
    cv.drawOval(yg, Paint()..shader = const RadialGradient(colors: [Color(0x73000000), Color(0x00000000)]).createShader(yg));

    final (ex, eb) = sakin ? (1.0, 1.0) : ani.ezilme;
    final kare = (kapak.clamp(0.0, 1.1) / 1.1 * (_sandikAdim - 1)).round();

    void sandik(_Film f, Rect kutu) {
      final im = f.kare(kare);
      if (im == null) return;
      cv.save();
      cv.translate(350, _sandikUst + 600);
      cv.scale(ex, eb);
      cv.translate(-350, -(_sandikUst + 600));
      cv.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), kutu.shift(const Offset(0, _sandikUst)),
          Paint()..filterQuality = FilterQuality.medium);
      cv.restore();
    }

    sandik(arka, _sandikArka);
    // İçten gelen ışık (karakterlerin arkasında; onları soldurmasın).
    if (kapak > 0) {
      final r = Rect.fromCenter(center: const Offset(350, 850), width: 480, height: 420);
      cv.drawOval(
          r,
          Paint()
            ..blendMode = BlendMode.screen
            ..shader = RadialGradient(colors: [
              const Color(0xD9FFDE8C).withValues(alpha: .85 * .6 * _kl(kapak)),
              const Color(0x59FFBE46).withValues(alpha: .35 * .6 * _kl(kapak)),
              const Color(0x00FFBE46),
            ], stops: const [0, .55, 1])
                .createShader(r));
    }
    for (final t in VarlikTuru.values) {
      if (_acilisPoz[t]!.$3) _karakter(cv, t);
    }
    sandik(on, _sandikOn);
    for (final t in VarlikTuru.values) {
      if (!_acilisPoz[t]!.$3) _karakter(cv, t);
    }
    if (!sakin) _para(cv);
    cv.restore();

    final p = sakin ? 0.0 : ani.parlama;
    if (p > 0) {
      cv.drawRect(
          ekran,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.04, .2),
              colors: [const Color(0xFFFFF8DC), const Color(0xFFFFE08A), const Color(0xFFF5B82E)].map((c) => c.withValues(alpha: p)).toList(),
              stops: const [0, .4, 1],
            ).createShader(ekran));
    }
  }

  void _karakter(Canvas cv, VarlikTuru tur) {
    final k = ani.karakter(tur);
    final opak = sakin ? 1.0 : k.opak;
    if (opak <= 0) return;
    final (x, y, ic, olc) = _acilisPoz[tur]!;
    final ayak = sakin ? Offset(x, y) : k.ayak;
    final sahne = sakin ? null : k.sahne;
    final ol = _acilisOlcek * olc;
    if (!ic) {
      final g = Rect.fromCenter(center: ayak, width: 140 * olc, height: 30 * olc);
      cv.drawOval(g, Paint()..shader = const RadialGradient(colors: [Color(0x66000000), Color(0x00000000)]).createShader(g));
    }
    _Film film;
    int sira;
    String anahtar;
    final dk = dokunma[tur]!;
    if (sahne != null && dk.kareler.isNotEmpty) {
      film = dk;
      sira = sahne.round();
      anahtar = '${tur.name}/dokunma_beden';
    } else {
      film = _atlas(tur, Evre.minik);
      sira = (sakin ? AtlasIfade.mutlu : k.yuz).index;
      anahtar = '${tur.name}/atlas_minik';
    }
    final im = film.kare(sira);
    final kutu = _kirpim3d[anahtar];
    if (im == null || kutu == null) return;
    final (ox, oy, kk) = _yerlesim3d[tur]!;
    final (l, t, r, b) = kutu;
    Offset p(double u, double v) => Offset(ayak.dx + (u - 55) * ol, ayak.dy + (v - 100) * ol);
    final hedef = Rect.fromPoints(p(ox + l * kk, oy + t * kk), p(ox + r * kk, oy + b * kk));
    cv.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), hedef,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, opak));
  }

  void _para(Canvas cv) {
    final p = ani.para;
    if (!p.gorunur) return;
    cv.save();
    cv.translate(p.konum.dx, p.konum.dy);
    cv.scale(p.en, p.boy);
    const r = 60.0;
    final daire = Rect.fromCircle(center: Offset.zero, radius: r);
    cv.drawCircle(Offset.zero, r + 22, Paint()..shader = const RadialGradient(colors: [Color(0x99FFD65A), Color(0x00FFD65A)]).createShader(daire.inflate(22)));
    cv.drawCircle(Offset.zero, r,
        Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFFF6C2), Color(0xFFFFD34D), Color(0xFFD9970F)], stops: [0, .5, 1]).createShader(daire));
    cv.drawCircle(Offset.zero, r - 17, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0x997A4520));
    cv.drawCircle(Offset.zero, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = DunyaRenkleri.murekkep);
    final tp = TextPainter(
      text: TextSpan(text: sembol, style: const TextStyle(fontFamily: 'Baloo2', fontSize: 56, fontWeight: FontWeight.w800, color: Color(0xFFA8650A), height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(cv, Offset(-tp.width / 2, -tp.height / 2 + 2));
    cv.restore();
  }

  @override
  bool shouldRepaint(_AcilisPainter o) => true;
}
