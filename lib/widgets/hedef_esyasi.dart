import 'package:flutter/material.dart';

import '../models/hedef.dart';
import '../theme/dunya.dart';

/// Alttan dolan eşya: ilerleme sayı değil, eşyanın dolması (yol haritası 2.1).
/// Boş kısım soluk iz, dolu kısım vurgu rengi; dolunca sıcak bir halka.
/// Doluluk değişince akarak dolar (hareketi azalt → anında).
class HedefEsyasi extends StatelessWidget {
  const HedefEsyasi({super.key, required this.esya, required this.doluluk, this.boyut = 72});

  final HedefEsya esya;
  final double doluluk;
  final double boyut;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: doluluk.clamp(0, 1)),
      duration: Devinim.sure(context, Devinim.yavas),
      curve: Devinim.cikis,
      builder: (_, v, _) => Container(
        width: boyut + 16,
        height: boyut + 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: r.accSoft,
          // Dolunca sıcak halka: gölge ikonu bulanıklaştırıyordu (önce/sonra sayfası).
          border: v >= 1 ? Border.all(color: r.warm, width: 3) : null,
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(esya.ikon, size: boyut, color: r.track),
          ClipRect(clipper: _AlttanKirp(v), child: Icon(esya.ikon, size: boyut, color: r.acc)),
        ]),
      ),
    );
  }
}

/// Alttan [oran] kadarını gösterir (su dolar gibi).
class _AlttanKirp extends CustomClipper<Rect> {
  const _AlttanKirp(this.oran);
  final double oran;

  @override
  Rect getClip(Size s) => Rect.fromLTRB(0, s.height * (1 - oran), s.width, s.height);

  @override
  bool shouldReclip(_AlttanKirp eski) => eski.oran != oran;
}
