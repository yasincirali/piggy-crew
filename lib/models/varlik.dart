import 'package:flutter/material.dart';

/// Kumbara Takımı: her varlık bir karakterdir (karar 2026-10-14).
///
/// Çocuk "dolar" değil "Zıpzıp" biriktirir; kâr/zarar yüz ifadesiyle anlatılır.
/// Fiyat anahtarları truncgil v4 (`finans.truncgil.com/v4/today.json`) ile
/// aynıdır: GRA = 24 ayar gram altın ("gram altın" Türkiye'de 24 ayar demektir,
/// sandık `FiyatKaynagi.gramAltin24` ile aynı karar), USD, EUR. TL'nin fiyatı 1.
enum VarlikTuru {
  altin('altin', 'GRA'),
  dolar('dolar', 'USD'),
  euro('euro', 'EUR'),
  /// Ev para birimindeki nakit (TR'de lira, ABD'de dolar…). Fiyatı her zaman 1.
  nakit('nakit', null);

  const VarlikTuru(this.anahtar, this.fiyatAnahtari);
  final String anahtar;

  /// Kaynak anahtarı (TRY cinsinden kotasyon). Nakit için yok.
  final String? fiyatAnahtari;

  bool get nakitMi => this == VarlikTuru.nakit;

  /// Uygulama GLOBAL (yasin 2026-10-14): ev para birimi dolar olan çocukta
  /// "dolar" karakteri nakitle aynı şeydir, gizlenir; euro için de öyle.
  bool gorunur(ParaBirimi ev) => switch (this) {
        VarlikTuru.dolar => ev != ParaBirimi.usd,
        VarlikTuru.euro => ev != ParaBirimi.eur,
        _ => true,
      };

  static VarlikTuru fromAnahtar(String a) => VarlikTuru.values.firstWhere(
        (v) => v.anahtar == a || (a == 'tl' && v == VarlikTuru.nakit),
        orElse: () => VarlikTuru.nakit,
      );
}

/// Ev para birimi — çocuğun "parası". Varsayılan cihaz yereline göre seçilir,
/// karşılamada değiştirilebilir. Tüm değerler bu birimde gösterilir; kaynak
/// TRY kote ettiği için çevrim `Fiyatlar.evKuru` ile yapılır (sabit yok).
enum ParaBirimi {
  tryy('TRY', '₺', 'tr_TR'),
  usd('USD', r'$', 'en_US'),
  eur('EUR', '€', 'de_DE'),
  gbp('GBP', '£', 'en_GB');

  const ParaBirimi(this.kod, this.sembol, this.yerel);
  final String kod;
  final String sembol;
  final String yerel;

  static ParaBirimi fromKod(String? k) =>
      ParaBirimi.values.firstWhere((p) => p.kod == k, orElse: () => ParaBirimi.tryy);

  /// Cihaz yerelinden tahmin: ülke kodu → birim; bilinmeyen → USD (global varsayılan).
  static ParaBirimi yerelden(String? ulke) => switch (ulke) {
        'TR' => ParaBirimi.tryy,
        'US' => ParaBirimi.usd,
        'GB' => ParaBirimi.gbp,
        'DE' || 'FR' || 'IT' || 'ES' || 'NL' || 'AT' || 'BE' || 'PT' || 'IE' || 'FI' || 'GR' => ParaBirimi.eur,
        _ => ParaBirimi.usd,
      };
}

/// Karakterin hâli — anlam yalnız renkle değil yüz ve sahneyle de verilir
/// (renk körlüğü, HIG).
///
/// Neden "üzgün" yok (yasin kararı 2026-10-15, araştırma
/// `harcliklarim/arastirma/02` ve `03`): değer düşüşü çocuğun kontrol
/// edemediği piyasadan gelir. Üzgün yüz 7–10 yaşta güçlü kayıptan kaçınmayı
/// tetikler; çocuk kendini suçlar ya da "boz" der. Yerine `bulutlu`: yüz
/// sakin, başının üstünde bulut; dokununca güneş açar (teselli çocuktan
/// gelir, suçluluk değil).
enum Ruh { mutlu, duz, bulutlu }

/// Bir besleme (yatırma). Fiyat o gün alınan birim fiyattır; sonradan değişmez.
/// Çocuk tutarı EV para biriminde yazar, miktar = tutar / birimFiyat.
/// Alan adlarındaki "Tl" tarihsel: "ev para birimi" okunur (TR ilk pazar).
@immutable
class Hareket {
  const Hareket({
    required this.id,
    required this.tur,
    required this.tarih,
    required this.tutarTl,
    required this.birimFiyat,
  });

  final String id;
  final VarlikTuru tur;
  final DateTime tarih;
  final double tutarTl;
  final double birimFiyat;

  double get miktar => birimFiyat > 0 ? tutarTl / birimFiyat : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tur': tur.anahtar,
        'tarih': tarih.toIso8601String(),
        'tutarTl': tutarTl,
        'birimFiyat': birimFiyat,
      };

  static Hareket fromJson(Map<String, dynamic> j) => Hareket(
        id: j['id'] as String,
        tur: VarlikTuru.fromAnahtar(j['tur'] as String),
        tarih: DateTime.parse(j['tarih'] as String),
        tutarTl: (j['tutarTl'] as num).toDouble(),
        birimFiyat: (j['birimFiyat'] as num).toDouble(),
      );
}

/// Bir karakterin bugünkü durumu (hesap model katmanında, build() içinde değil).
@immutable
class KarakterDurumu {
  const KarakterDurumu({
    required this.tur,
    required this.miktar,
    required this.maliyetTl,
    required this.fiyat,
  });

  final VarlikTuru tur;
  final double miktar;
  final double maliyetTl;

  /// Bugünkü birim fiyat; bilinmiyorsa null → değer gösterilmez, UYDURULMAZ.
  final double? fiyat;

  bool get bos => miktar <= 0;
  double? get degerTl => tur.nakitMi ? miktar : (fiyat == null ? null : miktar * fiyat!);
  double? get farkTl => degerTl == null ? null : degerTl! - maliyetTl;
  double? get farkYuzde =>
      (farkTl == null || maliyetTl <= 0) ? null : farkTl! / maliyetTl * 100;

  /// Hâl: +%0,5 üstü gülümser; bulut ancak −%5'in altında gelir ki günlük
  /// kur oynaması karakteri bulutlandırmasın (eskiden ±%0,5'te üzülüyordu).
  /// Araştırmanın önerdiği "7 günlük pencere" fiyat geçmişi ister; v1 yalnız
  /// bugünkü fiyatı tutuyor, geçmiş gelince pencere eklenir.
  /// Nakit her zaman düz bakar: TL'nin kârı/zararı yoktur, enflasyon dersi ayrı.
  static const mutluEsik = .5, bulutEsik = -5.0;

  Ruh get ruh {
    final y = farkYuzde;
    if (y == null || bos || tur.nakitMi) return Ruh.duz;
    if (y > mutluEsik) return Ruh.mutlu;
    if (y < bulutEsik) return Ruh.bulutlu;
    return Ruh.duz;
  }
}
