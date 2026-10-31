import 'package:flutter/foundation.dart';
import 'varlik.dart';

/// Çıkartmalar — rozet değil, karakterin KOSTÜMÜ. Her biri bir davranışı
/// ödüllendirir (ilk besleme, düzenlilik), piyasa şansını değil:
/// "altın yükseldi" diye çıkartma YOK, çocuk fiyatı kontrol edemez.
///
/// Tutar eşiği de YOK (2026-10-15, araştırma `harcliklarim/arastirma/02` ve
/// `03`): "ateş 1.000'i geçti" ailenin harçlık miktarını ödüllendiriyordu,
/// çocuğun davranışını değil. `ates_1000`, `ates_5000` ve `tortu_parlak`
/// aynı id ile düzenliliğe bağlandı: kaç FARKLI haftada beslendiği. Hafta
/// sayısı eksilmez (seri değil, kırılmaz); açılmış çıkartma asla geri alınmaz.
@immutable
class Cikartma {
  const Cikartma(this.id, this.tur);
  final String id;

  /// Ad ve açıklama .arb'da (`ckXAd`, `ckXAciklama`): global uygulama, metin kodda değil.
  final VarlikTuru? tur;

  static const hepsi = <Cikartma>[
    Cikartma('ilk_besleme', null),
    Cikartma('tortu_sapka', VarlikTuru.altin),
    Cikartma('zipzip_atki', VarlikTuru.dolar),
    Cikartma('baykus_gozluk', VarlikTuru.euro),
    Cikartma('sincap_fular', VarlikTuru.nakit),
    Cikartma('takim_tam', null),
    Cikartma('ates_1000', null),
    Cikartma('ates_5000', null),
    Cikartma('ders_5', null),
    Cikartma('ders_10', null),
    Cikartma('sabir_30', null),
    Cikartma('tortu_parlak', VarlikTuru.altin),
  ];

  static Cikartma? bul(String id) => hepsi.where((c) => c.id == id).firstOrNull;

  /// Karakterin giyilebilir kostümü (çıkartma id'si). Açılınca karakter onu
  /// her yerde giyer (kamp, detay, çıkartma kartı); geri alınmaz.
  static String kostum(VarlikTuru t) => switch (t) {
        VarlikTuru.altin => 'tortu_sapka',
        VarlikTuru.dolar => 'zipzip_atki',
        VarlikTuru.euro => 'baykus_gozluk',
        VarlikTuru.nakit => 'sincap_fular',
      };

  /// Düzenlilik eşikleri (farklı hafta sayısı).
  static const atesHafta = 4, senlikHafta = 12, tortuHafta = 5;

  /// Kaç farklı takvim haftasında (Pazartesi başlangıçlı) hareket var.
  /// Ardışık olması gerekmez: ara vermek kazanılanı silmez.
  static int farkliHaftalar(Iterable<DateTime> tarihler) => tarihler.map((t) {
        final gun = DateTime.utc(t.year, t.month, t.day);
        return gun.subtract(Duration(days: gun.weekday - 1)).millisecondsSinceEpoch;
      }).toSet().length;
}
