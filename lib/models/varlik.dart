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

  /// Çocuğun elinde en sık olan banknot ve bozuk paralar ("Elindekini say",
  /// Ar-Ge 30 Eki): Besle'de her dokunuş tutara eklenir. Kuruş/cent yok; o
  /// klavyeyle yazılır. TR'ye özgü varsayım yalnız burada ve `bicim.dart`'ta
  /// (global kuralı). Kaynak: TCMB E9 serisi (5–200 ₺), Fed ($1–20 banknot),
  /// ECB (€5–50 banknot), Bank of England + Royal Mint (£1, £2 madeni; £5–20).
  List<int> get kupurler => switch (this) {
        ParaBirimi.tryy => const [5, 10, 20, 50, 100, 200],
        ParaBirimi.usd => const [1, 5, 10, 20],
        ParaBirimi.eur => const [5, 10, 20, 50],
        ParaBirimi.gbp => const [1, 2, 5, 10, 20],
      };

  /// Kupürün baskın rengi (Besle'de banknot görünümü, Ar-Ge 1 Kas 11:07).
  /// Çocuk ekrandaki düğmeyi cebindeki kâğıtla eşlesin diye. Renk tek başına
  /// anlam taşımaz: değer her zaman yazılı. Kaynak: TCMB "Paralarımızı tanıyor
  /// musun" (5 mor, 10 kırmızı, 20 yeşil, 50 turuncu, 100 mavi, 200 pembe);
  /// ECB Europa serisi (5 gri, 10 kırmızı, 20 mavi, 50 turuncu); ABD
  /// banknotları yeşil; BoE polimer (5 yeşil-turkuaz, 10 turuncu, 20 mor),
  /// £1/£2 madeni (altın/gümüş). Tonlar kâğıdın baskın rengine yakın, birebir değil.
  Color kupurRengi(int v) => Color(switch ((this, v)) {
        (ParaBirimi.tryy, 5) => 0xFF8E6BB0,
        (ParaBirimi.tryy, 10) => 0xFFD9534F,
        (ParaBirimi.tryy, 20) => 0xFF3FA36B,
        (ParaBirimi.tryy, 50) => 0xFFE8893A,
        (ParaBirimi.tryy, 100) => 0xFF3C7BD6,
        (ParaBirimi.tryy, 200) => 0xFFD06FA8,
        (ParaBirimi.eur, 5) => 0xFF9AA0A6,
        (ParaBirimi.eur, 10) => 0xFFD9534F,
        (ParaBirimi.eur, 20) => 0xFF3C7BD6,
        (ParaBirimi.eur, 50) => 0xFFE8893A,
        (ParaBirimi.gbp, 1) => 0xFFD9B44A,
        (ParaBirimi.gbp, 2) => 0xFFB8BCC2,
        (ParaBirimi.gbp, 5) => 0xFF3AA99F,
        (ParaBirimi.gbp, 10) => 0xFFE8893A,
        (ParaBirimi.gbp, 20) => 0xFF8E6BB0,
        _ => 0xFF6E9B6A, // USD: bütün banknotlar yeşil
      });

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

/// Paranın nereden geldiği (yol haritası 2.3 "bayram / hediye harçlığı",
/// Ar-Ge 23 Eki "Nereden geldi?"). İsteğe bağlı: seçilmezse etiket yok.
///
/// Neden ayrı bir bayram akışı değil: harçlık, hediye ve kendi emeği aynı
/// "Besle" ile yazılıyordu; tek satır etiket hem bayramı hem emeği kapsar,
/// yeni ekran açmaz. Etiket yalnız anlatır: ödül, sayaç, çıkartma ve
/// kaynaklara göre toplam/kıyas YOK (tutar değil davranış; iki sayı kuralı).
enum HareketKaynagi {
  harclik(Icons.savings_rounded),
  hediye(Icons.card_giftcard_rounded),
  emek(Icons.handyman_rounded);

  const HareketKaynagi(this.ikon);
  final IconData ikon;
}

/// Bir besleme (yatırma) ya da kumbaradan alma. Fiyat o gün alınan birim
/// fiyattır; sonradan değişmez. Çocuk tutarı EV para biriminde yazar,
/// miktar = tutar / birimFiyat. Alan adlarındaki "Tl" tarihsel: "ev para
/// birimi" okunur (TR ilk pazar).
///
/// Kumbaradan alma (2026-10-23, Ar-Ge raporu `harcliklarim/arge/raporlar/
/// 2026-10-23_0150.md` #1): gerçek kumbaradan para çıkınca uygulama gerçeği
/// bırakmasın diye. Ayrı tür alanı yerine EKSİ tutar: kayıt biçimi aynı kalır,
/// eski kayıtlar olduğu gibi okunur. Alma besleme SAYILMAZ: evre, odun ve
/// çıkartmalar yalnız [beslemeler]'den hesaplanır (harcamak cezalandırılmaz,
/// ama ödül de vermez).
@immutable
class Hareket {
  const Hareket({
    required this.id,
    required this.tur,
    required this.tarih,
    required this.tutarTl,
    required this.birimFiyat,
    this.kaynak,
  });

  final String id;
  final VarlikTuru tur;
  final DateTime tarih;
  final double tutarTl;
  final double birimFiyat;

  /// Yalnız beslemede; eski kayıtlarda ve seçilmeyince null.
  final HareketKaynagi? kaynak;

  double get miktar => birimFiyat > 0 ? tutarTl / birimFiyat : 0;

  /// Kumbaradan alma mı (eksi tutar).
  bool get cikis => tutarTl < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tur': tur.anahtar,
        'tarih': tarih.toIso8601String(),
        'tutarTl': tutarTl,
        'birimFiyat': birimFiyat,
        if (kaynak != null) 'kaynak': kaynak!.name,
      };

  static Hareket fromJson(Map<String, dynamic> j) => Hareket(
        id: j['id'] as String,
        tur: VarlikTuru.fromAnahtar(j['tur'] as String),
        tarih: DateTime.parse(j['tarih'] as String),
        tutarTl: (j['tutarTl'] as num).toDouble(),
        birimFiyat: (j['birimFiyat'] as num).toDouble(),
        // Bilinmeyen etiket (ileriki sürümden) yok sayılır, kayıt düşmez.
        kaynak: HareketKaynagi.values.where((k) => k.name == j['kaynak']).firstOrNull,
      );
}

extension Beslemeler on Iterable<Hareket> {
  /// Yalnız beslemeler (kumbaradan almalar hariç): ödül hesapları bunu kullanır.
  Iterable<Hareket> get beslemeler => where((h) => !h.cikis);

  /// Son 30 günde "Kendim kazandım" etiketli besleme sayısı (Veli köşesi,
  /// Ar-Ge 1 Kas 11:07 #5). Yalnız veliye bir cümle; çocuğa gösterilmez,
  /// ödül/eşik bağlanmaz. 30 gün kayan pencere: takvim ayı başında sıfırlanan
  /// bir sayaç "bu ay az" kıyası kurardı.
  int kendiKazandigiSon30Gun(DateTime simdi) {
    final sinir = simdi.subtract(const Duration(days: 30));
    return beslemeler.where((h) => h.kaynak == HareketKaynagi.emek && h.tarih.isAfter(sinir)).length;
  }
}

/// Bir karakterin bugünkü durumu (hesap model katmanında, build() içinde değil).
@immutable
class KarakterDurumu {
  const KarakterDurumu({
    required this.tur,
    required this.miktar,
    required this.maliyetTl,
    required this.fiyat,
    double? verilenTl,
  }) : verilenTl = verilenTl ?? maliyetTl;

  /// Hareketlerden durum. Kumbaradan almada maliyet ORTALAMA maliyetle düşer:
  /// 10 doları 300'e alıp 5'ini 200 ederken alan çocukta kalan 5 doların
  /// maliyeti 150'dir. Alınan tutar (200) düşülseydi kalan kâr şişerdi.
  factory KarakterDurumu.hesapla(VarlikTuru tur, Iterable<Hareket> hareketler, double? fiyat) {
    final sirali = hareketler.where((h) => h.tur == tur).toList()..sort((a, b) => a.tarih.compareTo(b.tarih));
    var miktar = 0.0, maliyet = 0.0, verilen = 0.0;
    for (final h in sirali) {
      if (h.cikis) {
        final oran = miktar > 0 ? (-h.miktar / miktar).clamp(0.0, 1.0) : 1.0;
        maliyet -= maliyet * oran;
      } else {
        maliyet += h.tutarTl;
        verilen += h.tutarTl;
      }
      miktar += h.miktar;
    }
    // Hepsi alındıysa kayan nokta artığı "boş değil" saydırmasın.
    if (miktar <= bosEsik) {
      miktar = 0;
      maliyet = 0;
    }
    return KarakterDurumu(tur: tur, miktar: miktar, maliyetTl: maliyet, fiyat: fiyat, verilenTl: verilen);
  }

  static const bosEsik = 1e-9;

  final VarlikTuru tur;
  final double miktar;

  /// Elde kalanın maliyeti (alınan kısım ortalama maliyetle düşülmüş).
  final double maliyetTl;

  /// Bugüne kadar verilen toplam (almalar düşülmez). Tutara bağlı küçük süs
  /// (Tortu'nun pulları) bunu kullanır ki harcayınca süs kaybolmasın.
  final double verilenTl;

  /// Bugünkü birim fiyat; bilinmiyorsa null → değer gösterilmez, UYDURULMAZ.
  final double? fiyat;

  bool get bos => miktar <= bosEsik;
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

/// Bilinen hâl: fiyatı bilinen, boş olmayan, nakit olmayan karakterin ruhu.
/// Fiyat yüklenmeden önceki "düz" hâl bilinmeyen sayılır ki uygulama her
/// açılışta sevinç oynatmasın.
Map<VarlikTuru, Ruh> bilinenRuhlar(Iterable<KarakterDurumu> k) => {
      for (final d in k)
        if (d.farkYuzde != null && !d.bos && !d.tur.nakitMi) d.tur: d.ruh,
    };

/// Değeri artıya geçenler: önceki BİLİNEN hâli mutlu değildi, şimdi mutlu.
/// İlk kez görülen karakter (önceki yok) kutlanmaz; düşüşte hiçbir şey olmaz.
Set<VarlikTuru> artiyaGecenler(Map<VarlikTuru, Ruh> onceki, Map<VarlikTuru, Ruh> simdi) => {
      for (final e in simdi.entries)
        if (e.value == Ruh.mutlu && onceki[e.key] != null && onceki[e.key] != Ruh.mutlu) e.key,
    };
