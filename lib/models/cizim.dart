import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// "Hedefini kendin çiz" (2026-10-29): çocuk listede olmayan hedefini
/// parmağıyla çizer; çizim hedef eşyası olur ve kartta alttan dolar.
///
/// Noktalar 0..1 arasında saklanır: kart 72 pt, çizim alanı tam genişlik;
/// aynı çizim her boyutta aynı görünsün. Üst sınırlar kaydı küçük tutar
/// (shared_preferences; en kötü durumda ~150 KB) ve uzun bir karalamanın
/// her karede yeniden çizilmesini sınırlar.
///
/// Çizim değerlendirilmez: "güzel" ya da "eksik" denmez, puan yok
/// (karakter dili kuralı; çocuğun kendi işi).
@immutable
class Cizgi {
  const Cizgi({required this.renk, required this.noktalar});

  /// [Cizim.renkSayisi] içinde boya sırası; renk değeri temada değil
  /// boya kutusunda (kırmızı bisiklet tema değişince kırmızı kalsın).
  final int renk;
  final List<Offset> noktalar;

  Cizgi ekle(Offset p) => Cizgi(renk: renk, noktalar: [...noktalar, p]);

  @override
  bool operator ==(Object other) => other is Cizgi && other.renk == renk && listEquals(other.noktalar, noktalar);
  @override
  int get hashCode => Object.hash(renk, Object.hashAll(noktalar));
}

@immutable
class Cizim {
  const Cizim(this.cizgiler);

  static const renkSayisi = 5;
  static const enFazlaCizgi = 60;
  static const enFazlaNokta = 240;

  /// Bundan yakın nokta eklenmez (normalize); titreyen parmak kaydı şişirmesin.
  static const enKisaAdim = .008;

  final List<Cizgi> cizgiler;

  bool get bos => cizgiler.isEmpty;

  List<Map<String, dynamic>> toJson() => [
        for (final c in cizgiler)
          {
            'r': c.renk,
            // Düz liste, üç basamak: 240 nokta × 60 çizgi sınırında bile kayıt küçük kalır.
            'p': [
              for (final p in c.noktalar) ...[yuvarla(p.dx), yuvarla(p.dy)],
            ],
          },
      ];

  /// Çizerken de uygulanır ki bellekteki çizim kaydedilenle aynı olsun.
  static double yuvarla(double v) => (v.clamp(0.0, 1.0) * 1000).roundToDouble() / 1000;

  /// Bozuk parça atlanır; hiç geçerli çizgi kalmazsa null.
  static Cizim? fromJson(Object? j) {
    if (j is! List) return null;
    final cizgiler = <Cizgi>[];
    for (final c in j.take(enFazlaCizgi)) {
      if (c is! Map) continue;
      final r = c['r'];
      final p = c['p'];
      if (r is! int || r < 0 || r >= renkSayisi || p is! List || p.length < 2 || p.any((v) => v is! num)) continue;
      final noktalar = <Offset>[
        for (var i = 0; i + 1 < p.length && i < enFazlaNokta * 2; i += 2)
          Offset((p[i] as num).toDouble().clamp(0.0, 1.0), (p[i + 1] as num).toDouble().clamp(0.0, 1.0)),
      ];
      cizgiler.add(Cizgi(renk: r, noktalar: noktalar));
    }
    return cizgiler.isEmpty ? null : Cizim(cizgiler);
  }

  @override
  bool operator ==(Object other) => other is Cizim && listEquals(other.cizgiler, cizgiler);
  @override
  int get hashCode => Object.hashAll(cizgiler);
}
