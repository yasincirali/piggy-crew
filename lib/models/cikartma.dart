import 'package:flutter/foundation.dart';
import 'varlik.dart';

/// Çıkartmalar — rozet değil, karakterin KOSTÜMÜ. Her biri bir davranışı
/// ödüllendirir (ilk besleme, düzenlilik, eşik), piyasa şansını değil:
/// "altın yükseldi" diye çıkartma YOK, çocuk fiyatı kontrol edemez.
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
}
