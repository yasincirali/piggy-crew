import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import 'ortak.dart';

/// Öğren "Dokunarak dene": enflasyon dondurması (Ar-Ge 1 Kas 11:07 #1).
///
/// Çocuk yılı değiştirir; aynı madeni para durur, dondurma topu küçülür.
/// Neden sayı yok: ders metni zaten iki fiyat söylüyor; kart kavramı nesneyle
/// gösterir (somuttan soyuta, Carbonneau ve diğ. 2013). Para üstünde yalnız
/// birim simgesi var, tutar yok (ekranda iki sayı kuralı). Yanlış yapılamaz,
/// sayaç ve ödül yok; soru kartın ardından yine gelir.
///
/// Durum yalnız boyutla verilmez: seçili çipte onay işareti ve altında cümle
/// var (renk/şekil körlüğü, ekran okuyucu). Hareketi azalt açıkken boyut
/// anında değişir.
class DeneDondurma extends ConsumerStatefulWidget {
  const DeneDondurma({super.key, required this.para});
  final ParaBirimi para;

  @override
  ConsumerState<DeneDondurma> createState() => _DeneDondurmaState();
}

class _DeneDondurmaState extends ConsumerState<DeneDondurma> {
  bool _gelecek = false;

  void _sec(bool gelecek) {
    if (gelecek == _gelecek) return;
    ref.read(dokunsalProvider).cal(Dokunus.secim);
    setState(() => _gelecek = gelecek);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final sure = Devinim.sure(context, Devinim.yavas);
    return Kart(
      key: const ValueKey('dene-dondurma'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.touch_app_rounded, color: r.acc, size: 22),
          const SizedBox(width: Bosluk.s),
          Expanded(child: Text(l.ogrenDeneBaslik, style: context.t.titleMedium)),
        ]),
        const SizedBox(height: Bosluk.xs),
        Text(l.ogrenDeneIpucu, style: context.t.bodyMedium?.copyWith(color: r.sub)),
        const SizedBox(height: Bosluk.m),
        // Görsel süs değil, anlamı cümle taşır: ekran okuyucu cümleyi okur.
        ExcludeSemantics(
          child: SizedBox(
            height: 150,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              _Para(simge: widget.para.sembol),
              const SizedBox(width: Bosluk.l),
              Icon(Icons.arrow_forward_rounded, color: r.sub),
              const SizedBox(width: Bosluk.l),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _gelecek ? 0.6 : 1.0),
                duration: sure,
                curve: Devinim.cikis,
                builder: (context, top, _) => CustomPaint(
                  size: const Size(96, 150),
                  painter: _DondurmaPainter(top: top, kulah: r.soil, kulahCizgi: r.soil2, topRenk: r.petal, kenar: r.fg),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: Bosluk.m),
        Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
          SecimCipi(metin: l.ogrenDeneBuYil, secili: !_gelecek, onTap: () => _sec(false)),
          SecimCipi(metin: l.ogrenDeneGelecekYil, secili: _gelecek, onTap: () => _sec(true)),
        ]),
        const SizedBox(height: Bosluk.m),
        Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: Devinim.sure(context, Devinim.normal),
            child: Text(
              _gelecek ? l.ogrenDeneDondurmaSonra : l.ogrenDeneDondurmaSimdi,
              key: ValueKey(_gelecek),
              style: context.t.bodyLarge,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Madeni para: iki yılda da aynı boyut (anlatılan şey bu).
class _Para extends StatelessWidget {
  const _Para({required this.simge});
  final String simge;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: r.warm,
        shape: BoxShape.circle,
        border: Border.all(color: r.warmInk, width: 3),
      ),
      child: Text(simge, style: context.t.titleLarge?.copyWith(color: r.warmInk)),
    );
  }
}

/// Külah sabit, top [top] oranında (1 = bu yıl, 0,6 = gelecek yıl). Top külahın
/// ağzına oturur; küçülünce boşluk kalır ki fark ilk bakışta görünsün.
class _DondurmaPainter extends CustomPainter {
  _DondurmaPainter({required this.top, required this.kulah, required this.kulahCizgi, required this.topRenk, required this.kenar});
  final double top;
  final Color kulah, kulahCizgi, topRenk, kenar;

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final agiz = s.height * 0.52;
    final kenarKalem = Paint()
      ..color = kenar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final kulahYol = Path()
      ..moveTo(cx - s.width * 0.34, agiz)
      ..lineTo(cx + s.width * 0.34, agiz)
      ..lineTo(cx, s.height - 2)
      ..close();
    canvas.drawPath(kulahYol, Paint()..color = kulah);
    canvas.save();
    canvas.clipPath(kulahYol);
    final desen = Paint()
      ..color = kulahCizgi
      ..strokeWidth = 2;
    for (var i = -4; i <= 4; i++) {
      final x = cx + i * 14.0;
      canvas.drawLine(Offset(x - 40, agiz), Offset(x + 40, s.height), desen);
      canvas.drawLine(Offset(x + 40, agiz), Offset(x - 40, s.height), desen);
    }
    canvas.restore();
    canvas.drawPath(kulahYol, kenarKalem);

    final yaricap = s.width * 0.42 * top;
    final merkez = Offset(cx, agiz - yaricap * 0.75);
    canvas.drawCircle(merkez, yaricap, Paint()..color = topRenk);
    canvas.drawCircle(merkez, yaricap, kenarKalem);
  }

  @override
  bool shouldRepaint(_DondurmaPainter o) =>
      o.top != top || o.kulah != kulah || o.topRenk != topRenk || o.kenar != kenar || o.kulahCizgi != kulahCizgi;
}
