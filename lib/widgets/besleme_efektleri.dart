part of 'karakter.dart';

// ── Besleme efektleri ───────────────────────────────────────────────────
//
// Neden (yasin 2026-10-17, "titreşim ve efektleri profesyonel"): yakalama,
// ısırık, sekme gibi anlar yalnız gövde hareketiyle anlatılıyordu; el ve
// kulak bir şey duyarken göz boştu. Küçük, kısa ve az parçacık: yakalamada
// yiyeceğin renginde yedi kıvılcım, Zıpzıp'ın her ısırığında iki yaprak
// kırıntısı, Tortu'nun kabuğunda halka, Baykuş'un yıldızının ardında toz,
// Sincap'ın sekişinde toz bulutu ve dönüşünde iki hız çizgisi, sevinçte
// başın çevresinde üç pırıltı. Konfeti YOK (tutara bağlı şölen değil,
// davranışa küçük bir "aferin"). Hareketi azalt açıkken hiç çizilmez
// (sahne de oynamaz).
//
// Saf fonksiyon: aynı t aynı kareyi verir (rastgelelik yok, test edilebilir).

enum ParcacikBicim { kivilcim, kirinti, toz, halka, cizgi }

/// Tek parçacık (110×110 alanında). [govdeY]: parçacığın doğduğu andaki
/// gövde yüksekliği (piksel, `YemeAni.y`); havada kapılan yaprağın kıvılcımı
/// karakterle değil, kapıldığı yerde kalır.
@immutable
class Parcacik {
  const Parcacik(this.bicim, this.p, this.r, this.renk, this.opak, {this.aci = 0, this.yay = 0, this.govdeY = 0});
  final ParcacikBicim bicim;
  final Offset p;
  final double r, opak, aci, yay, govdeY;
  final Color renk;
}

/// Yakalama anında yiyeceğin bulunduğu nokta (kıvılcımların doğduğu yer).
const _yakalamaNoktasi = {
  VarlikTuru.altin: Offset(78, 64),
  VarlikTuru.dolar: Offset(55, 80),
  VarlikTuru.euro: Offset(55, 60),
  VarlikTuru.nakit: Offset(46, 80),
};

const _kivilcimRenkleri = {
  VarlikTuru.altin: [Color(0xFFF7C948), Color(0xFF2B6FD6)],
  VarlikTuru.dolar: [Color(0xFF6CC56B), Color(0xFFF7C948)],
  VarlikTuru.euro: [Color(0xFFFFF3B0), Color(0xFFFFFFFF)],
  VarlikTuru.nakit: [Color(0xFFF7D774), Color(0xFF8B5A2B)],
};

/// Bir efektin yerel ilerlemesi: [bas]'tan [sure] boyunca 0–1, dışında null.
double? _yerel(double t, double bas, double sure) {
  final u = (t - bas) / sure;
  return u < 0 || u > 1 ? null : u;
}

List<Parcacik> yemeEfektleri(VarlikTuru tur, double t) {
  final z = yemeZamani(tur);
  final ps = <Parcacik>[];

  // Yakalama kıvılcımları (ortak): yedi kıvılcım dışa açılıp söner.
  final uk = _yerel(t, z.tutma, .1);
  if (uk != null) {
    final e = Curves.easeOutCubic.transform(uk);
    final govde = yemeSahnesi(tur, z.tutma).y;
    final renk = _kivilcimRenkleri[tur]!;
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7 + .4;
      ps.add(Parcacik(
        ParcacikBicim.kivilcim,
        _yakalamaNoktasi[tur]! + Offset(math.cos(a), math.sin(a)) * (6 + 16 * e),
        3.6 * (1 - uk) + .5,
        renk[i % 2],
        math.pow(1 - uk, 1.5).toDouble(),
        aci: a,
        govdeY: govde,
      ));
    }
  }

  switch (tur) {
    case VarlikTuru.altin:
      // Karo kabuğa oturunca omuzdan açılan ince halka.
      final u = _yerel(t, z.tutma, .14);
      if (u != null) {
        ps.add(Parcacik(ParcacikBicim.halka, _yakalamaNoktasi[tur]!, 4 + 18 * Curves.easeOutCubic.transform(u),
            const Color(0xFFF7C948), .9 * (1 - u)));
      }
    case VarlikTuru.dolar:
      // Her ısırıkta iki yaprak kırıntısı ağızdan düşer.
      for (final k in zipzipIsirikAnlari) {
        final tb = .3 + .32 * k;
        final u = _yerel(t, tb, .12);
        if (u == null) continue;
        for (final yon in const [-1.0, 1.0]) {
          ps.add(Parcacik(
            ParcacikBicim.kirinti,
            Offset(55 + yon * (3 + 9 * u), 82 - 4 * u + 26 * u * u),
            2.4,
            yon < 0 ? const Color(0xFF6CC56B) : const Color(0xFF2F9E5A),
            1 - u * u,
            aci: yon * (1 + 4 * u),
          ));
        }
      }
    case VarlikTuru.euro:
      // Süzülen yıldızın ardında altı toz noktası.
      if (t < z.tutma) {
        for (var k = 1; k <= 6; k++) {
          final tk = t - .025 * k;
          if (tk < 0) break;
          final y = yemeSahnesi(tur, tk).yemek;
          if (y == null) continue;
          final g = 1 - k / 7;
          ps.add(Parcacik(ParcacikBicim.toz, y, 1.8 * g + .3, const Color(0xFFFFF3B0), .6 * g));
        }
      }
    case VarlikTuru.nakit:
      // Para yere değince minik toz bulutu.
      final u = _yerel(t, .1, .1);
      if (u != null) {
        for (final yon in const [-1.0, 0.0, 1.0]) {
          ps.add(Parcacik(ParcacikBicim.toz, Offset(30 + yon * (2 + 6 * u), 93 - 3 * u - (yon == 0 ? 2 * u : 0)),
              1.5 + 2.5 * u, const Color(0xFFD9C6A5), .5 * (1 - u)));
        }
      }
      // Dönüşte gövdenin iki yanında hız çizgileri.
      final d = _yerel(t, .34, .22);
      if (d != null) {
        final o = zarf(d, gir: .25, cik: .35);
        for (final bas in const [math.pi * .85, -math.pi * .15]) {
          ps.add(Parcacik(ParcacikBicim.cizgi, const Offset(46, 66), 36, const Color(0xFFB9A7FF), .7 * o,
              aci: bas + d * 1.2, yay: .9));
        }
      }
  }

  // Sevinç: başın çevresinde üç pırıltı (sırayla belirir, yükselip söner).
  final su = t > z.sevinc ? _ara(t, z.sevinc, 1) : -1.0;
  const yerler = [Offset(20, 28), Offset(90, 22), Offset(60, 2)];
  for (var i = 0; i < 3; i++) {
    final u = _yerel(su, .06 * i, .42);
    if (u == null) continue;
    ps.add(Parcacik(ParcacikBicim.kivilcim, yerler[i] - Offset(0, 8 * u), 3.6 * zarf(u, gir: .3, cik: .5),
        const Color(0xFFFFE296), zarf(u, gir: .15, cik: .5),
        aci: .3 * i));
  }
  return ps;
}

/// Parçacıkları karakterle aynı ölçekte çizer (gövde dönüşümlerinin
/// dışında: parçacık doğduğu yerde kalır).
class EfektPainter extends CustomPainter {
  EfektPainter({required this.parcaciklar, this.olcek = 1});
  final List<Parcacik> parcaciklar;

  /// Evre büyüklüğü (ayak tabanından, karakterle aynı).
  final double olcek;

  @override
  void paint(Canvas cv, Size size) {
    if (parcaciklar.isEmpty) return;
    final s = size.shortestSide / 110;
    cv.save();
    cv.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    cv.scale(s);
    cv.translate(55, 100);
    cv.scale(olcek);
    cv.translate(-55, -100);
    for (final p in parcaciklar) {
      if (p.opak <= 0 || p.r <= 0) continue;
      final renk = p.renk.withValues(alpha: p.renk.a * p.opak.clamp(0.0, 1.0));
      final merkez = p.p + Offset(0, p.govdeY / s / olcek);
      switch (p.bicim) {
        case ParcacikBicim.kivilcim:
          final yol = Path();
          for (var i = 0; i < 8; i++) {
            final a = p.aci + i * math.pi / 4;
            final rr = i.isEven ? p.r : p.r * .38;
            final o = merkez + Offset(math.cos(a), math.sin(a)) * rr;
            i == 0 ? yol.moveTo(o.dx, o.dy) : yol.lineTo(o.dx, o.dy);
          }
          cv.drawPath(yol..close(), Paint()..color = renk);
        case ParcacikBicim.kirinti:
          cv.save();
          cv.translate(merkez.dx, merkez.dy);
          cv.rotate(p.aci);
          cv.drawOval(Rect.fromCenter(center: Offset.zero, width: p.r * 2, height: p.r * 1.1), Paint()..color = renk);
          cv.restore();
        case ParcacikBicim.toz:
          cv.drawCircle(merkez, p.r, Paint()..color = renk);
        case ParcacikBicim.halka:
          cv.drawCircle(
              merkez,
              p.r,
              Paint()
                ..color = renk
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6);
        case ParcacikBicim.cizgi:
          cv.drawArc(
              Rect.fromCircle(center: merkez, radius: p.r),
              p.aci,
              p.yay,
              false,
              Paint()
                ..color = renk
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round);
      }
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(EfektPainter o) => true;
}
