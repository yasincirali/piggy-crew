import 'package:flutter/foundation.dart';
import 'varlik.dart';

/// Çıkartmalar — rozet değil, karakterin KOSTÜMÜ. Her biri bir davranışı
/// ödüllendirir (ilk besleme, düzenlilik, eşik), piyasa şansını değil:
/// "altın yükseldi" diye çıkartma YOK, çocuk fiyatı kontrol edemez.
@immutable
class Cikartma {
  const Cikartma(this.id, this.ad, this.aciklama, this.tur);
  final String id;
  final String ad;
  final String aciklama;
  final VarlikTuru? tur;

  static const hepsi = <Cikartma>[
    Cikartma('ilk_besleme', 'İlk kıvılcım', 'Kamp ateşini ilk kez yaktın.', null),
    Cikartma('tortu_sapka', 'Tortu\'nun şapkası', 'Tortu\'yu üç kez besledin.', VarlikTuru.altin),
    Cikartma('zipzip_atki', 'Zıpzıp\'ın atkısı', 'Zıpzıp\'ı üç kez besledin.', VarlikTuru.dolar),
    Cikartma('baykus_gozluk', 'Baykuş\'un gözlüğü', 'Baykuş\'u üç kez besledin.', VarlikTuru.euro),
    Cikartma('sincap_fular', 'Sincap\'ın fuları', 'Sincap\'ı üç kez besledin.', VarlikTuru.nakit),
    Cikartma('takim_tam', 'Takım tamam', 'Dört karakteri de besledin.', null),
    Cikartma('ates_1000', 'Büyük ateş', 'Kamp ateşin ilk kez 1.000 ₺\'yi geçti.', null),
    Cikartma('ates_5000', 'Şenlik ateşi', 'Kamp ateşin ilk kez 5.000 ₺\'yi geçti.', null),
    Cikartma('ders_5', 'Meraklı', 'Beş dersi bitirdin.', null),
    Cikartma('ders_10', 'Bilge', 'On dersi bitirdin.', null),
    Cikartma('sabir_30', 'Sabırlı', 'İlk beslemenden 30 gün geçti ve hâlâ buradasın.', null),
    Cikartma('tortu_parlak', 'Parlayan Tortu', 'Tortu\'nun değeri 1.500 ₺\'yi geçti.', VarlikTuru.altin),
  ];

  static Cikartma? bul(String id) => hepsi.where((c) => c.id == id).firstOrNull;
}
