part of 'karakter.dart';

// ── Besleme ritüeli ─────────────────────────────────────────────────────
//
// Neden her karakter kendi yolunda yer (yasin 2026-10-17, "besleme
// mekaniğine sanatsal ve özgün şekilde çalış"): eskiden dördü de aynı üç
// parayı yukarıdan ağzına düşürüyordu; karakter yalnız rengiyle ayrılıyordu.
// Artık yiyeceği ve yeme biçimi karakterin kendisinden, deseninden ve
// hayvanın gerçek huyundan gelir:
// - Tortu (altın, çini): altın bir çini karo kabuğunun omzuna oturur, kabukta ışık
//   dolaşır; Tortu yavaşça, keyifle başını sallar. Kaplumbağa altını yemez,
//   kabuğuna işler (pullar da aynı fikrin süsü).
// - Zıpzıp (dolar, hasır): yaprak düşer, Zıpzıp havada kapar, hızlı hızlı
//   kemirir; yere inince kulakları sallanır.
// - Baykuş (euro, nazar): yıldız gece gibi yavaş, salınarak süzülür; Baykuş
//   başını yıldızla birlikte yana yatırır, yıldız gözlerine girer ve
//   gözlerinde parlar, kanat çırpar.
// - Sincap (nakit, kilim): palamut para yuvarlanarak gelir, Sincap kapar,
//   yanakları şişer, bir tur döner ve kuyruğunu sallayarak saklar.
// Duygu sözlüğü yine tek: hepsi aynı sevinç yüzü ve zıplamayla biter.
// Para sayısı yok (eskiden üç para "tatmin bu sayımdan gelir" diye vardı):
// tutardan bağımsız tek bir yiyecek, çünkü ödül davranıştır, tutar değil.

/// Besleme sahnesinin süresi (dört karakterde aynı ki ses ve çıkartma
/// zamanlaması tek olsun).
const yemeSuresi = Duration(milliseconds: 1800);

/// Sahne anları (0–1): yiyeceğin karaktere ulaştığı an ("tık" ve hafif
/// titreşim), keyif sesi ("yum") ve sevinç (aynı sevinç yüzü + zıplama).
typedef YemeZamani = ({double tutma, double yum, double sevinc});

YemeZamani yemeZamani(VarlikTuru t) => switch (t) {
      VarlikTuru.altin => (tutma: .22, yum: .45, sevinc: .68),
      VarlikTuru.dolar => (tutma: .19, yum: .5, sevinc: .68),
      VarlikTuru.euro => (tutma: .5, yum: .62, sevinc: .74),
      VarlikTuru.nakit => (tutma: .2, yum: .6, sevinc: .7),
    };

/// Yiyeceğin sahneye girdiği nokta (110×110 çizim alanında). Kamp'taki avuç
/// parası buraya uçar; sahne yiyeceği tam buradan devralır, ekranda atlama
/// olmaz. Tortu'da kabuğun üstü, Zıpzıp ve Baykuş'ta başın üstü (düşer,
/// süzülür), Sincap'ta önündeki yer (yuvarlanır).
const yemekGirisNoktasi = {
  VarlikTuru.altin: Offset(84, 30),
  VarlikTuru.dolar: Offset(55, -10),
  VarlikTuru.euro: Offset(55, -16),
  VarlikTuru.nakit: Offset(14, 86),
};

/// Yiyeceğin çizim alanındaki yarıçapı (avuç parasının küçülme hedefi).
const yemekYaricap = 8.5;

/// Besleme sahnesinin bir anı. Hepsi gövde dönüşümleri ve çizim
/// parametreleri; [yemek] null ise yiyecek görünmez.
@immutable
class YemeAni {
  const YemeAni({
    this.y = 0,
    this.sx = 1,
    this.sy = 1,
    this.aci = 0,
    this.donus = 1,
    this.bakis = Offset.zero,
    this.yuz = const Yuz(),
    this.yemek,
    this.yemekOlcek = 1,
    this.yemekOpak = 1,
    this.yemekAci = 0,
    this.yanakSis = 0,
    this.kuyruk = 0,
    this.kanat = 0,
    this.gozYildiz = 0,
    this.kulakSark = 0,
    this.kabukIsilti = 0,
  });

  final double y, sx, sy, aci;

  /// Sincap'ın dönüşü: yatay ölçek çarpanı (1 → −1 → 1, bir tur).
  final double donus;
  final Offset bakis;
  final Yuz yuz;
  final Offset? yemek;
  final double yemekOlcek, yemekOpak, yemekAci;
  final double yanakSis, kuyruk, kanat, gozYildiz, kulakSark, kabukIsilti;

  /// Süreklilik testi için düz liste (yiyecek konumu hariç).
  List<double> get degerler =>
      [y, sx, sy, aci, donus, bakis.dx, bakis.dy, ...yuz.degerler, yanakSis, kuyruk, kanat, gozYildiz, kulakSark];
}

double _ss(double x) => x <= 0 ? 0 : x >= 1 ? 1 : x * x * (3 - 2 * x);
double _ara(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Besleme sahnesinin bir anı (t: 0–1). Saf fonksiyon: sürekliliği ve
/// sonda nötr bitişi `karakter_duygu_test` dört karakter için tarar.
YemeAni yemeSahnesi(VarlikTuru tur, double t) {
  final z = yemeZamani(tur);
  // Ortak bitiş: aynı sevinç yüzü + zıplama (duygu sözlüğü tek).
  final su = _ara(t, z.sevinc, 1);
  final sevinc = sevincYuzu(zarf(su, gir: .15, cik: .3));
  final sz = ziplamaEgrisi(su, 16);
  return switch (tur) {
    VarlikTuru.altin => _tortuYer(t, z, sevinc, sz),
    VarlikTuru.dolar => _zipzipYer(t, z, sevinc, sz),
    VarlikTuru.euro => _baykusYer(t, z, sevinc, sz),
    VarlikTuru.nakit => _sincapYer(t, z, sevinc, sz),
  };
}

typedef _Zipla = ({double y, double sx, double sy});

YemeAni _tortuYer(double t, YemeZamani z, Yuz sevinc, _Zipla sz) {
  // Karo yerçekimiyle kabuğa iner, minik sekip oturur, kabuğa karışır.
  final d = _ara(t, 0, z.tutma);
  final sek = 3 * math.sin(math.pi * _ara(t, z.tutma, z.tutma + .08));
  final karisma = _ss(_ara(t, .26, .36));
  final g = yemekGirisNoktasi[VarlikTuru.altin]!;
  // Kabuğun sağ omzuna (başın yanına, yüzü kapatmadan) iner.
  final yemek = karisma >= 1 ? null : Offset(g.dx - 6 * d, g.dy + 34 * d * d - sek);
  // Yukarı bakar (merak "o"), karo inince keyifle gözlerini kısar, iki yavaş baş sallama.
  final merak = zarf(_ara(t, 0, .3), gir: .3, cik: .4);
  final keyif = zarf(_ara(t, .26, z.sevinc), gir: .25, cik: .25);
  final nu = _ara(t, .3, .64);
  final bas = 2.5 * math.sin(2 * math.pi * 2 * nu) * zarf(nu, gir: .2, cik: .2);
  final oturma = math.sin(math.pi * _ara(t, z.tutma - .02, z.tutma + .08));
  return YemeAni(
    y: bas + sz.y,
    sx: (1 + .04 * oturma) * sz.sx,
    sy: (1 - .05 * oturma) * sz.sy,
    bakis: Offset(0, -.8 * (1 - _ss(_ara(t, .14, .3)))),
    yuz: Yuz(agizO: .45 * merak, gulus: keyif, sevinc: keyif, kizarma: .6 * keyif).ust(sevinc),
    yemek: yemek,
    yemekOlcek: 1 - .25 * karisma,
    yemekOpak: 1 - karisma,
    yemekAci: .3 * (1 - d) * math.sin(d * 9),
    kabukIsilti: _ara(t, .24, .62),
  );
}

YemeAni _zipzipYer(double t, YemeZamani z, Yuz sevinc, _Zipla sz) {
  // Havada kapma: zıplamanın tepesi yaprağın ağza vardığı ana denk gelir.
  final hop = ziplamaEgrisi(_ara(t, 0, .42), 18);
  final p = _ara(t, 0, z.tutma);
  final g = yemekGirisNoktasi[VarlikTuru.dolar]!;
  final yemek = t >= z.tutma
      ? null
      : Offset(g.dx + 8 * math.sin(p * math.pi * 2) * (1 - p), g.dy + 90 * math.pow(p, 1.6).toDouble());
  final kap = _ss(_ara(t, .08, .17)) * (1 - _ss(_ara(t, z.tutma, z.tutma + .04)));
  // Kemirme: beş hızlı ısırık, yanaklar oynar.
  final ku = _ara(t, .3, .62);
  final isirik = math.sin(5 * math.pi * ku).abs() * zarf(ku, gir: .1, cik: .2);
  // İnişte kulaklar sarkıp yaylanır (gecikmeli, sönen).
  final ki = _ara(t, .3, .62);
  final kulak = math.sin(ki * math.pi * 3) * math.pow(1 - ki, 2).toDouble();
  final keyif = zarf(_ara(t, .2, z.sevinc), gir: .15, cik: .25);
  return YemeAni(
    y: hop.y + sz.y,
    sx: hop.sx * (1 + .04 * isirik) * sz.sx,
    sy: hop.sy * (1 - .04 * isirik) * sz.sy,
    bakis: Offset(0, -1 + _ss(_ara(t, .14, .22))),
    yuz: Yuz(agizO: math.max(kap, .55 * isirik), gulus: .9 * keyif, kizarma: .5 * keyif).ust(sevinc),
    yemek: yemek,
    yemekOlcek: 1 - .4 * _ss(_ara(p, .8, 1)),
    yemekAci: .5 * math.sin(p * 6) * (1 - p),
    kulakSark: kulak,
  );
}

YemeAni _baykusYer(double t, YemeZamani z, Yuz sevinc, _Zipla sz) {
  // Yıldız salınarak süzülür; baş onunla birlikte yana yatar (baykuş huyu).
  final p = _ara(t, 0, z.tutma);
  final g = yemekGirisNoktasi[VarlikTuru.euro]!;
  final x = g.dx + 20 * math.sin(p * math.pi * 2.5) * (1 - p);
  final y = g.dy + 76 * _ss(p);
  final kucul = 1 - _ss(_ara(t, z.tutma - .04, z.tutma + .04));
  final takip = 1 - _ss(_ara(t, z.tutma - .08, z.tutma));
  final yan = (x - g.dx) / 20;
  final ku = _ara(t, z.tutma + .02, z.tutma + .28);
  final keyif = zarf(_ara(t, .45, .8), gir: .2, cik: .3);
  return YemeAni(
    y: sz.y,
    sx: sz.sx,
    sy: sz.sy,
    aci: .16 * yan * takip,
    bakis: Offset(.9 * yan * takip, (-1 + _ss(p)) * takip),
    yuz: Yuz(agizO: .5 * zarf(_ara(t, .3, .6)), gulus: keyif, kizarma: .5 * keyif).ust(sevinc),
    yemek: kucul <= 0 ? null : Offset(x, y),
    yemekOlcek: kucul,
    yemekAci: .6 * math.sin(p * math.pi * 3),
    gozYildiz: zarf(_ara(t, z.tutma, .86), gir: .2, cik: .35),
    // İki kanat çırpışı (|sin| iki tümsek, uçlarda sıfır).
    kanat: .9 * math.sin(2 * math.pi * ku).abs(),
  );
}

YemeAni _sincapYer(double t, YemeZamani z, Yuz sevinc, _Zipla sz) {
  // Palamut para sekerek yuvarlanır, ağza girer; yanaklar şişer, bir tur
  // döner, kuyruk sallanır, yanaklar iner (sakladı).
  final p = _ara(t, 0, z.tutma);
  final g = yemekGirisNoktasi[VarlikTuru.nakit]!;
  final x = g.dx + 32 * _ss(p);
  final y = g.dy - 6 * p - 6 * math.sin(p * math.pi * 2).abs();
  final yut = 1 - _ss(_ara(t, z.tutma, z.tutma + .1));
  final egil = zarf(_ara(t, 0, .3), gir: .3, cik: .35);
  final sis = _ss(_ara(t, .22, .32)) * (1 - _ss(_ara(t, .56, .66)));
  final ku = _ara(t, .3, .7);
  final keyif = zarf(_ara(t, .2, z.sevinc), gir: .15, cik: .25);
  return YemeAni(
    y: sz.y,
    sx: sz.sx,
    sy: sz.sy,
    aci: -.1 * egil,
    donus: math.cos(2 * math.pi * _ss(_ara(t, .34, .56))),
    bakis: Offset((x - 46) / 32 * .9, .5) * (1 - _ss(_ara(t, .16, .26))),
    // Yarım kısık göz "şüpheli" okunur (bkz. _goz): sevinç gözü tam kapanır.
    yuz: Yuz(gulus: keyif, sevinc: zarf(_ara(t, .26, .62), gir: .2, cik: .25), kizarma: .6 * keyif).ust(sevinc),
    yemek: yut <= 0 ? null : Offset(x, y),
    yemekOlcek: yut,
    yemekAci: p * math.pi * 3,
    yanakSis: sis,
    kuyruk: .35 * math.sin(ku * math.pi * 4) * (1 - ku),
  );
}

/// Yiyecek çizimi (110×110 alanında, merkez [c], yarıçap [r]): karakterin
/// kendi deseninden. Kamp'taki avuç parası da aynı çizimi kullanır ki elden
/// sahneye geçişte yiyecek değişmesin.
void yemekCiz(Canvas cv, VarlikTuru tur, Offset c, double r, {double aci = 0, String sembol = '₺'}) {
  final murekkep = Paint()
    ..color = DunyaRenkleri.murekkep
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * .22
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  cv.save();
  cv.translate(c.dx, c.dy);
  cv.rotate(aci);
  switch (tur) {
    case VarlikTuru.altin:
      // Altın çini karo: yuvarlak köşeli kare, ortada lacivert sekiz kollu yıldız.
      final karo = RRect.fromRectAndRadius(Rect.fromCircle(center: Offset.zero, radius: r), Radius.circular(r * .35));
      cv.drawRRect(karo, Paint()..color = const Color(0xFFF7C948));
      final yildiz = Path();
      for (var i = 0; i < 16; i++) {
        final a = i * math.pi / 8;
        final rr = i.isEven ? r * .72 : r * .34;
        final o = Offset(math.cos(a) * rr, math.sin(a) * rr);
        i == 0 ? yildiz.moveTo(o.dx, o.dy) : yildiz.lineTo(o.dx, o.dy);
      }
      yildiz.close();
      cv.drawPath(yildiz, Paint()..color = const Color(0xFF2B6FD6));
      cv.drawCircle(Offset.zero, r * .2, Paint()..color = const Color(0xFFFFFAF0));
      cv.drawRRect(karo, murekkep);
    case VarlikTuru.dolar:
      // Hasır yaprağı: badem biçimi, ortada damar, iki yan damar.
      final yaprak = Path()
        ..moveTo(0, -r * 1.1)
        ..quadraticBezierTo(r * 1.05, 0, 0, r * 1.1)
        ..quadraticBezierTo(-r * 1.05, 0, 0, -r * 1.1)
        ..close();
      cv.drawPath(yaprak, Paint()..color = const Color(0xFF6CC56B));
      final damar = Paint()
        ..color = const Color(0xFF2F9E5A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .14
        ..strokeCap = StrokeCap.round;
      cv.drawLine(Offset(0, -r * .8), Offset(0, r * .9), damar);
      cv.drawLine(Offset(0, -r * .1), Offset(r * .42, -r * .45), damar);
      cv.drawLine(Offset(0, r * .3), Offset(-r * .42, -r * .05), damar);
      cv.drawPath(yaprak, murekkep);
    case VarlikTuru.euro:
      // Gece yıldızı: yumuşak hâle + beş kollu yıldız.
      cv.drawCircle(
          Offset.zero,
          r * 1.5,
          Paint()
            ..color = const Color(0x66FFF3B0)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .5));
      final yildiz = KarakterPainter._yildizYolu(r * 1.05);
      cv.drawPath(yildiz, Paint()..color = const Color(0xFFFFF3B0));
      cv.drawPath(yildiz, murekkep);
    case VarlikTuru.nakit:
      // Palamut para: sarı para, üstünde kahverengi palamut şapkası ve sapı.
      cv.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFF7D774));
      cv.drawCircle(Offset.zero, r, murekkep);
      final sapka = Path()
        ..moveTo(-r * 1.02, -r * .38)
        ..quadraticBezierTo(0, -r * 1.55, r * 1.02, -r * .38)
        ..quadraticBezierTo(0, -r * .62, -r * 1.02, -r * .38)
        ..close();
      cv.drawPath(sapka, Paint()..color = const Color(0xFF8B5A2B));
      cv.drawPath(sapka, murekkep);
      cv.drawLine(Offset(0, -r * 1.05), Offset(r * .18, -r * 1.42), murekkep);
      final tp = TextPainter(
        text: TextSpan(
          text: sembol,
          style: TextStyle(fontFamily: govdeFontu, fontSize: r * 1.15, fontWeight: FontWeight.w800, color: DunyaRenkleri.murekkep),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(cv, Offset(-tp.width / 2, -tp.height / 2 + r * .18));
  }
  cv.restore();
}
