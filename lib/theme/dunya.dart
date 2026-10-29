import 'package:flutter/material.dart';

/// Dünyalar — temalar cinsiyet değil, DÜNYA'dır (karar 2026-10-14).
///
/// Çocuk herhangi birini seçer, istediği an değiştirir. Kamp alanı değişir,
/// Kumbara Takımı (karakterler) aynı kalır: çocuğun bağ kurduğu şey tema
/// değil karakterdir. Token adları prototipteki `--p-*` ile birebir.
enum Dunya {
  bahce('bahce', 'Bahçe'),
  uzay('uzay', 'Uzay'),
  okyanus('okyanus', 'Okyanus'),
  neon('neon', 'Neon'),
  seker('seker', 'Şeker'),
  safari('safari', 'Safari');

  const Dunya(this.anahtar, this.ad);
  final String anahtar;
  final String ad;

  static Dunya fromAnahtar(String? a) =>
      Dunya.values.firstWhere((d) => d.anahtar == a, orElse: () => Dunya.bahce);
}

/// Bir dünyanın renk seti. Ekran kodu RENK LİTERALİ yazmaz; her şey buradan
/// gelir (sandık'taki `context.c` kuralının karşılığı).
class DunyaRenkleri extends ThemeExtension<DunyaRenkleri> {
  const DunyaRenkleri({
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.fg,
    required this.sub,
    required this.acc,
    required this.accInk,
    required this.accSoft,
    required this.warm,
    required this.warmInk,
    required this.petal,
    required this.soil,
    required this.soil2,
    required this.loss,
    required this.card,
    required this.line,
    required this.track,
    required this.koyu,
  });

  final Color bg1, bg2, bg3; // arka plan gradyanı
  final Color fg, sub; // metin / ikincil metin
  final Color acc, accInk, accSoft; // vurgu düğme, üstündeki metin, yumuşak zemin
  final Color warm, warmInk; // kamp ateşi parıltısı / sıcak rozet
  final Color petal; // alev ucu / yıldız tozu
  final Color soil, soil2; // odun / zemin
  final Color loss; // zarar vurgusu (yalnız renkle anlam verilmez; yüz de değişir)
  final Color card, line, track;
  final bool koyu;

  /// Kazanç rengi: vurgu rengi. Yüz ifadesi anlamı ayrıca taşır (renk körlüğü).
  Color get gain => acc;

  /// Mürekkep konturu — tüm karakterlerde sabit, tema değişse de aynı.
  static const Color murekkep = Color(0xFF2A1B14);

  /// Çizim boya kutusu ("Hedefini kendin çiz"): temadan bağımsız, çocuğun
  /// seçtiği renk her dünyada aynı kalır. Çizim hep [kagit] üstünde durur ki
  /// koyu temada da mürekkep görünsün. Sıra kayıtta saklanır: yalnız sona ekle.
  static const List<Color> boyalar = [
    murekkep,
    Color(0xFFE63946), // kırmızı
    Color(0xFFF4A300), // sarı (kâğıtta okunur koyulukta)
    Color(0xFF2A9D5C), // yeşil
    Color(0xFF2F6FED), // mavi
  ];
  static const Color kagit = Color(0xFFFFFBF2);

  /// Kâğıt üstünde, henüz dolmamış çizginin soluk izi.
  static const Color kagitIz = Color(0xFFDDD5C6);

  static const _bahce = DunyaRenkleri(
    bg1: Color(0xFF0E2A22), bg2: Color(0xFF15382C), bg3: Color(0xFF1B4A36),
    fg: Color(0xFFF2F7EE), sub: Color(0xFFA9C9A2),
    acc: Color(0xFFD6F26B), accInk: Color(0xFF163018), accSoft: Color(0x2ED6F26B),
    warm: Color(0xFFF7E7A1), warmInk: Color(0xFF3B2A00), petal: Color(0xFFF5B82E),
    soil: Color(0xFF5B3A22), soil2: Color(0xFF6E4A2C), loss: Color(0xFFFFB4A2),
    card: Color(0x14FFFFFF), line: Color(0x38FFFFFF), track: Color(0x40000000),
    koyu: true,
  );
  static const _uzay = DunyaRenkleri(
    bg1: Color(0xFF120E3A), bg2: Color(0xFF1B1552), bg3: Color(0xFF261C6B),
    fg: Color(0xFFF1EEFF), sub: Color(0xFFB3A9E6),
    acc: Color(0xFF7EF0FF), accInk: Color(0xFF0B1030), accSoft: Color(0x2E7EF0FF),
    warm: Color(0xFFFFD166), warmInk: Color(0xFF2B1A00), petal: Color(0xFFFFD166),
    soil: Color(0xFF2A2350), soil2: Color(0xFF3A3170), loss: Color(0xFFFF9EC2),
    card: Color(0x14FFFFFF), line: Color(0x38FFFFFF), track: Color(0x40000000),
    koyu: true,
  );
  static const _okyanus = DunyaRenkleri(
    bg1: Color(0xFF062A44), bg2: Color(0xFF083B5C), bg3: Color(0xFF0B4F74),
    fg: Color(0xFFEAF7FF), sub: Color(0xFF9CC8E0),
    acc: Color(0xFFFF8A5B), accInk: Color(0xFF2A1105), accSoft: Color(0x33FF8A5B),
    warm: Color(0xFFFFE3A3), warmInk: Color(0xFF3A2300), petal: Color(0xFFFFD166),
    soil: Color(0xFFC9B27E), soil2: Color(0xFFDCC896), loss: Color(0xFFFFB4A2),
    card: Color(0x14FFFFFF), line: Color(0x38FFFFFF), track: Color(0x4D000000),
    koyu: true,
  );
  static const _neon = DunyaRenkleri(
    bg1: Color(0xFF0B0B12), bg2: Color(0xFF11111C), bg3: Color(0xFF171726),
    fg: Color(0xFFF4F4F8), sub: Color(0xFF9A9AB3),
    acc: Color(0xFFC6FF3D), accInk: Color(0xFF101400), accSoft: Color(0x29C6FF3D),
    warm: Color(0xFFFFE066), warmInk: Color(0xFF1A1400), petal: Color(0xFFFF3DB8),
    soil: Color(0xFF23233A), soil2: Color(0xFF2F2F4D), loss: Color(0xFFFF6B8A),
    card: Color(0x14FFFFFF), line: Color(0x38FFFFFF), track: Color(0x40000000),
    koyu: true,
  );
  static const _seker = DunyaRenkleri(
    bg1: Color(0xFFFFF3F7), bg2: Color(0xFFFFE9F0), bg3: Color(0xFFFFE0EA),
    fg: Color(0xFF4A1631), sub: Color(0xFF8A5A70),
    acc: Color(0xFFFF5D8F), accInk: Color(0xFFFFFFFF), accSoft: Color(0x29FF5D8F),
    warm: Color(0xFFFFE9A3), warmInk: Color(0xFF4A3200), petal: Color(0xFFFF8FB3),
    soil: Color(0xFFC79B6B), soil2: Color(0xFFD8AE80), loss: Color(0xFFD6336C),
    card: Color(0x0F4A1631), line: Color(0x384A1631), track: Color(0x1F4A1631),
    koyu: false,
  );
  static const _safari = DunyaRenkleri(
    bg1: Color(0xFFF7E9C9), bg2: Color(0xFFF3DFB6), bg3: Color(0xFFEAD29F),
    fg: Color(0xFF3B2A12), sub: Color(0xFF7A6340),
    acc: Color(0xFFE8540E), accInk: Color(0xFFFFFFFF), accSoft: Color(0x29E8540E),
    warm: Color(0xFFFFD27A), warmInk: Color(0xFF3B2500), petal: Color(0xFFE63946),
    soil: Color(0xFF8A5A2B), soil2: Color(0xFFA06A35), loss: Color(0xFFB3261E),
    card: Color(0x123B2A12), line: Color(0x383B2A12), track: Color(0x243B2A12),
    koyu: false,
  );

  static DunyaRenkleri of(Dunya d) => switch (d) {
        Dunya.bahce => _bahce,
        Dunya.uzay => _uzay,
        Dunya.okyanus => _okyanus,
        Dunya.neon => _neon,
        Dunya.seker => _seker,
        Dunya.safari => _safari,
      };

  @override
  DunyaRenkleri copyWith() => this;

  @override
  DunyaRenkleri lerp(DunyaRenkleri? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DunyaRenkleri(
      bg1: l(bg1, other.bg1), bg2: l(bg2, other.bg2), bg3: l(bg3, other.bg3),
      fg: l(fg, other.fg), sub: l(sub, other.sub),
      acc: l(acc, other.acc), accInk: l(accInk, other.accInk), accSoft: l(accSoft, other.accSoft),
      warm: l(warm, other.warm), warmInk: l(warmInk, other.warmInk), petal: l(petal, other.petal),
      soil: l(soil, other.soil), soil2: l(soil2, other.soil2), loss: l(loss, other.loss),
      card: l(card, other.card), line: l(line, other.line), track: l(track, other.track),
      koyu: t < .5 ? koyu : other.koyu,
    );
  }
}

/// Boşluk ölçeği (4'ün katları). Ham sayı yazma.
abstract final class Bosluk {
  static const double xs = 4, s = 8, m = 12, l = 16, xl = 20, xxl = 28, dev = 40;
}

/// Köşe ölçeği.
abstract final class Kose {
  static const double s = 12, m = 16, l = 22, xl = 28;
}

/// Hareket: ease-out çıkış, "pop" için hafif aşım. Konfeti yok (sandık kuralı);
/// kutlama karakterin kendi ışığıdır.
abstract final class Devinim {
  static const Duration hizli = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration yavas = Duration(milliseconds: 600);
  static const Curve cikis = Cubic(.23, 1, .32, 1);
  static const Curve pop = Cubic(.34, 1.4, .64, 1);

  /// Hareketi azalt açıksa süre sıfır: animasyonlar anında biter.
  static Duration sure(BuildContext c, Duration d) =>
      MediaQuery.of(c).disableAnimations ? Duration.zero : d;
}

extension DunyaContext on BuildContext {
  DunyaRenkleri get r => Theme.of(this).extension<DunyaRenkleri>()!;
  TextTheme get t => Theme.of(this).textTheme;
}

const baslikFontu = 'Baloo2';
const govdeFontu = 'Nunito';

/// Dünyaya göre ThemeData. Tipografi pakete gömülü iki aile: başlıklar Baloo 2
/// (yuvarlak, kalın, logodaki tombul kavanozla aynı dil), gövde Nunito (yuvarlak
/// uçlu, küçük boyutta okunaklı). google_fonts kullanılmaz: çalışma zamanında
/// ağdan çeker, Kids kategorisinde istenmez. Boyutlar Material ölçeğinden gelir,
/// Dynamic Type (textScaler) olduğu gibi uygulanır.
ThemeData dunyaTemasi(Dunya d) {
  final r = DunyaRenkleri.of(d);
  final base = r.koyu ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final tt = base.textTheme.apply(bodyColor: r.fg, displayColor: r.fg, fontFamily: govdeFontu);
  TextStyle? baslik(TextStyle? s) => s?.copyWith(fontFamily: baslikFontu);
  return base.copyWith(
    scaffoldBackgroundColor: r.bg2,
    colorScheme: base.colorScheme.copyWith(
      primary: r.acc,
      onPrimary: r.accInk,
      surface: r.bg2,
      onSurface: r.fg,
      error: r.loss,
    ),
    textTheme: tt.copyWith(
      displayLarge: baslik(tt.displayLarge)?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      displayMedium: baslik(tt.displayMedium)?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: baslik(tt.displaySmall)?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: baslik(tt.headlineLarge)?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: baslik(tt.headlineMedium)?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.25),
      headlineSmall: baslik(tt.headlineSmall)?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: baslik(tt.titleLarge)?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: tt.bodyLarge?.copyWith(height: 1.4),
      bodyMedium: tt.bodyMedium?.copyWith(height: 1.4, color: r.sub),
      labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    splashFactory: NoSplash.splashFactory,
    extensions: [r],
  );
}
