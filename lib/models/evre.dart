import 'varlik.dart';

/// Büyüme evresi: karakter beslendikçe büyür (yasin 2026-10-16, "varlık
/// büyüdükçe bir reaksiyon").
///
/// Neden tutara değil besleme GÜNÜNE bağlı (araştırma `harcliklarim/arastirma/02`):
/// tutar eşiği ailenin harçlık miktarını ödüllendirir, çocuğun davranışını
/// değil; harçlığı az olan çocuk geride kalır. Aynı gün on küçük besleme de
/// bir gün sayılır ki "çok dokunarak büyütme" olmasın. Tutar yalnız küçük süs
/// verir (Tortu'nun pulları), evre vermez.
///
/// Evre GERİ GİTMEZ: besleme silinse de, fiyat düşse de karakter küçülmez
/// (kayıptan kaçınma; çocuk "küçüldü" görmez). Ulaşılan en yüksek evre
/// cihazda saklanır (`Depo.evreOku`). Atlama sahnesini `Karakter` kendisi
/// oynatır: ekrandayken evresi artarsa (besleme sonrası) bir kez; uygulama
/// açılışında oynamaz.
///
/// Görünüm: başındaki bitki büyür (filiz → çiçek → yıldızlı çiçek) ve gövde
/// hafifçe irileşir. Kostüm değil (çıkartmalar kostümdür), büyümenin kendisi.
enum Evre {
  minik(0, .90),
  filiz(2, .94),
  cicek(5, .97),
  yildiz(10, 1.0);

  const Evre(this.esikGun, this.olcek);

  /// Bu evre için gereken farklı besleme günü sayısı.
  final int esikGun;

  /// Gövde ölçeği (110×110 alanında, ayak tabanından).
  final double olcek;

  static Evre gunden(int gun) => Evre.values.lastWhere((e) => gun >= e.esikGun);

  /// Sonraki evre (en üstteyse null).
  Evre? get sonraki => index + 1 < Evre.values.length ? Evre.values[index + 1] : null;
}

/// Bir karakterin kaç FARKLI günde beslendiği (yerel takvim günü).
int beslemeGunu(Iterable<Hareket> h, VarlikTuru t) =>
    h.where((e) => e.tur == t).map((e) => DateTime(e.tarih.year, e.tarih.month, e.tarih.day)).toSet().length;

/// Hesaplanan evreler (yalnız en az bir kez beslenmiş karakterler).
Map<VarlikTuru, Evre> evreler(Iterable<Hareket> h) => {
      for (final t in VarlikTuru.values)
        if (h.any((e) => e.tur == t)) t: Evre.gunden(beslemeGunu(h, t)),
    };

/// Gösterilen evre: hesaplanan ile saklanan en yükseğin büyüğü (geri gitmez).
Evre gosterilenEvre(Evre? hesap, Evre? kayitli) {
  if (hesap == null) return kayitli ?? Evre.minik;
  if (kayitli == null) return hesap;
  return hesap.index >= kayitli.index ? hesap : kayitli;
}
