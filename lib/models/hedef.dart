import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

import 'cizim.dart';
import 'varlik.dart';

/// Hedef = karakterin taşıdığı eşya (yol haritası 2.1; araştırma Rapor 1 #2,
/// Rapor 2 Öneri 1): "Zıpzıp bisiklet için biriktiriyor".
///
/// Neden eşya, sayı değil: 7–12 yaş "kaç kaldı" yüzdesini değil, somut bir
/// şeyin dolduğunu izler; ekranda en fazla iki sayı kuralı da korunur. Fiyatı
/// çocuk (ya da veli) seçerken bir kez yazar, sonra ekranda görünmez.
///
/// İlerleme kumbaraya KONAN paradan ölçülür (`maliyetTl`), bugünkü değerden
/// değil: fiyat düşünce eşya boşalmaz (kayıptan kaçınma; evre kuralıyla aynı).
/// Kumbaradan almak ise çocuğun kendi işi, eşya ona göre azalır — ama hedefe
/// bir kez ulaşıldıysa ulaşılmış kalır (belki o eşyayı almak için çıkarıldı).
///
/// Ödül değil: ulaşınca çıkartma açılmaz (çıkartma davranışı ödüllendirir,
/// tutarı değil); karakter yalnız bir kez sevinir.
enum HedefEsya {
  bisiklet(Icons.pedal_bike_rounded),
  top(Icons.sports_soccer_rounded),
  kitap(Icons.menu_book_rounded),
  kulaklik(Icons.headphones_rounded),
  oyuncak(Icons.toys_rounded),
  kaykay(Icons.skateboarding_rounded),
  oyun(Icons.sports_esports_rounded),
  hediye(Icons.card_giftcard_rounded),

  /// Listede olmayan hedef: çocuk çizer ([Hedef.cizim]). Sonda: seçicide
  /// hazır eşyalardan sonra gelir.
  cizim(Icons.brush_rounded);

  const HedefEsya(this.ikon);
  final IconData ikon;
}

@immutable
class Hedef {
  const Hedef({required this.esya, required this.fiyatTl, this.ulasildi, this.cizim});

  final HedefEsya esya;

  /// Yalnız [HedefEsya.cizim] için; diğer eşyalarda null.
  final Cizim? cizim;

  /// Ev para biriminde (adı sandık geleneği: `tutarTl` gibi).
  final double fiyatTl;

  /// Ulaşıldığı an; null → henüz değil. Bir kez dolunca geri alınmaz.
  final DateTime? ulasildi;

  /// 0..1; kumbaraya konan paranın fiyata oranı. Ulaşıldıysa hep 1.
  double doluluk(KarakterDurumu d) {
    if (ulasildi != null) return 1;
    if (fiyatTl <= 0) return 0;
    return (d.maliyetTl / fiyatTl).clamp(0.0, 1.0);
  }

  /// Bu durumla hedef ilk kez doluyor mu (sevinç bir kez oynasın diye).
  /// Kuruş yuvarlaması "dolmadı" saydırmasın.
  bool simdiDoldu(KarakterDurumu d) => ulasildi == null && d.maliyetTl + 0.005 >= fiyatTl;

  Hedef ulas(DateTime t) => Hedef(esya: esya, fiyatTl: fiyatTl, ulasildi: t, cizim: cizim);

  Map<String, dynamic> toJson() => {
        'esya': esya.name,
        'fiyatTl': fiyatTl,
        if (ulasildi != null) 'ulasildi': ulasildi!.toIso8601String(),
        if (cizim != null) 'cizim': cizim!.toJson(),
      };

  /// Bozuk ya da bilinmeyen eşya → null (o hedef yok sayılır, uygulama düşmez).
  static Hedef? fromJson(Map<String, dynamic> j) {
    final e = j['esya'];
    final f = j['fiyatTl'];
    if (e is! String || !HedefEsya.values.any((v) => v.name == e) || f is! num || f <= 0) return null;
    final u = j['ulasildi'];
    var esya = HedefEsya.values.byName(e);
    final cizim = esya == HedefEsya.cizim ? Cizim.fromJson(j['cizim']) : null;
    // Çizimi okunamayan hedef silinmez, hediyeye döner: fiyat ve doluluk
    // çocuğun emeği, bozuk bir çizgi yüzünden kaybolmasın.
    if (esya == HedefEsya.cizim && cizim == null) esya = HedefEsya.hediye;
    return Hedef(
      esya: esya,
      fiyatTl: f.toDouble(),
      ulasildi: u is String ? DateTime.tryParse(u) : null,
      cizim: cizim,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Hedef && other.esya == esya && other.fiyatTl == fiyatTl && other.ulasildi == ulasildi && other.cizim == cizim;
  @override
  int get hashCode => Object.hash(esya, fiyatTl, ulasildi, cizim);
}

/// Söz dizimi için doluluk kademesi: ekranda sayı yerine kelime
/// (renk körlüğü ve ekran okuyucu için de; HIG "yalnız renkle anlam yok").
enum HedefKademe { basladi, yarim, neredeyse, hazir }

HedefKademe hedefKademe(double v) {
  if (v >= 1) return HedefKademe.hazir;
  if (v >= .8) return HedefKademe.neredeyse;
  if (v >= .5) return HedefKademe.yarim;
  return HedefKademe.basladi;
}
