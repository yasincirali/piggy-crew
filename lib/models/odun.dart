import 'cikartma.dart';
import 'varlik.dart';

/// Kamp odunu (yol haritası 2.2, Ar-Ge raporu 2026-10-23 #1): beslenen her
/// FARKLI takvim haftası ateşe bir odun ekler. Ateşin boyu artık tutara değil
/// odun sayısına bağlı.
///
/// Neden tutar değil (araştırma `harcliklarim/arastirma/03` Öneri 6): ateş
/// toplamla büyüyordu (6.000'de tam boy); bu ailenin harçlık miktarını
/// ödüllendiriyordu ve kumbaradan alma gelince harcamak ateşi küçültürdü,
/// çocuk "harcamak kötü" öğrenirdi. Odun yalnız düzenliliği ödüllendirir.
///
/// Odun EKSİLMEZ, kırılmaz: haftalar ardışık olmak zorunda değil (seri yok),
/// besleme silinse ya da para alınsa da sayı düşmez (ulaşılan en yüksek
/// değer cihazda saklanır, bkz. `Depo.odunOku`).
class Odun {
  Odun._();

  /// Bu kadar odunda ateş tam boy (Şenlik ateşi çıkartmasıyla aynı eşik).
  /// Üstü yığında görünmeye devam etmez, ekran taşmasın.
  static const tamBoy = Cikartma.senlikHafta;

  /// Hareketlerden hesaplanan odun: kaç farklı haftada beslendi.
  static int say(Iterable<Hareket> h) => Cikartma.farkliHaftalar(h.beslemeler.map((e) => e.tarih));

  /// Gösterilen: hesaplanan ile saklananın büyüğü (geri gitmez).
  static int gosterilen(int hesap, int kayitli) => hesap > kayitli ? hesap : kayitli;
}
