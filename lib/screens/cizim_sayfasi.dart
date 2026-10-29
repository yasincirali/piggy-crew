import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/cizim.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../widgets/cizim_boyaci.dart';
import '../widgets/ortak.dart';

/// "Hedefini kendin çiz" (2026-10-29): listede olmayan hedefi çocuk çizer.
/// Bitti → çizim döner; Kapat, dışına dokunma, aşağı çekme ya da geri tuşu
/// → null (hedef değişmez).
///
/// Yarım çizim kaybolmaz (Ar-Ge 29 Eki 20:07 #2): her değişiklik
/// [onDegisti] ile çağırana gider, çağıran onu taslak olarak tutar ve bir
/// sonraki açılışta [eski] olarak geri verir. Yanlış bir dokunuşla bir
/// dakikalık emek gitmesin; yalnız "Temizle" siler. Taslak kalıcı kayda
/// yazılmaz (hedef sayfası kapanınca gider).
///
/// Bilerek az araç: beş boya, tek kalınlık, geri al, temizle. Silgi, kalınlık,
/// şekil yok: 7 yaşın bir dakikada bitireceği bir şey; araç kutusu çizimin
/// önüne geçmesin. Çizim değerlendirilmez ("güzel olmuş" yok).
Future<Cizim?> cizimGoster(BuildContext context, {Cizim? eski, ValueChanged<Cizim>? onDegisti}) =>
    altSayfaGoster<Cizim>(context, _CizimSayfasi(eski: eski, onDegisti: onDegisti));

class _CizimSayfasi extends ConsumerStatefulWidget {
  const _CizimSayfasi({this.eski, this.onDegisti});
  final Cizim? eski;
  final ValueChanged<Cizim>? onDegisti;
  @override
  ConsumerState<_CizimSayfasi> createState() => _CizimState();
}

class _CizimState extends ConsumerState<_CizimSayfasi> {
  late List<Cizgi> _cizgiler = [...?widget.eski?.cizgiler];
  int _renk = 0;
  int? _parmak;

  Cizim get _cizim => Cizim(List.unmodifiable(_cizgiler));

  Offset _normalize(Offset yerel, Size s) => Offset(
        Cizim.yuvarla(yerel.dx / s.width),
        Cizim.yuvarla(yerel.dy / s.height),
      );

  Drag? _basla(Offset genel, BuildContext alan) {
    // Tek parmak: ikinci parmak (avuç, öteki el) çizgi açmaz.
    if (_parmak != null || _cizgiler.length >= Cizim.enFazlaCizgi) return null;
    final kutu = alan.findRenderObject()! as RenderBox;
    final p = _normalize(kutu.globalToLocal(genel), kutu.size);
    setState(() => _cizgiler.add(Cizgi(renk: _renk, noktalar: [p])));
    _parmak = _cizgiler.length - 1;
    return _Surukle(
      guncelle: (g) {
        final i = _parmak;
        if (i == null) return;
        final q = _normalize(kutu.globalToLocal(g), kutu.size);
        final c = _cizgiler[i];
        if (c.noktalar.length >= Cizim.enFazlaNokta || (q - c.noktalar.last).distance < Cizim.enKisaAdim) return;
        setState(() => _cizgiler[i] = c.ekle(q));
      },
      bitir: () {
        _parmak = null;
        _bildir();
      },
    );
  }

  /// Çizgi bitince (her nokta değil): taslak çağıranda güncel kalsın.
  void _bildir() => widget.onDegisti?.call(_cizim);

  void _geriAl() {
    if (_cizgiler.isEmpty) return;
    setState(() => _cizgiler.removeLast());
    _bildir();
  }

  void _temizle() {
    if (_cizgiler.isEmpty) return;
    setState(() => _cizgiler = []);
    _bildir();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final bos = _cizgiler.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: r.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: Bosluk.l),
          Text(l.cizimBaslik, style: context.t.titleLarge),
          const SizedBox(height: Bosluk.xs),
          Text(l.cizimAlt, style: context.t.bodyMedium?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.l),
          // Kare ve en fazla 360 pt: iPad'de de bir elle çizilir boyut.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                aspectRatio: 1,
                child: Semantics(
                  label: l.cizimAlani,
                  image: true,
                  child: Builder(
                    builder: (alan) => RawGestureDetector(
                      // Hemen kazanan sürükleme: sayfa kaydırması ve alt sayfayı
                      // aşağı çekme dikey çizgiyi yutmasın.
                      gestures: {
                        ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
                          ImmediateMultiDragGestureRecognizer.new,
                          (g) => g.onStart = (p) => _basla(p, alan),
                        ),
                      },
                      child: Container(
                        key: const ValueKey('cizim-alani'),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: DunyaRenkleri.kagit,
                          borderRadius: BorderRadius.circular(Kose.l),
                          border: Border.all(color: r.line, width: 2),
                        ),
                        child: CustomPaint(painter: CizimBoyaci(_cizim), size: Size.infinite),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Bosluk.l),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            children: [
              for (var i = 0; i < Cizim.renkSayisi; i++) _Boya(sira: i, secili: _renk == i, onTap: () => _sec(i)),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          // Wrap: büyük yazıda iki düğme alt alta iner, taşmaz.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            children: [
              _Arac(ikon: Icons.undo_rounded, metin: l.cizimGeriAl, onTap: bos ? null : _geriAl),
              _Arac(ikon: Icons.delete_outline_rounded, metin: l.cizimTemizle, onTap: bos ? null : _temizle),
            ],
          ),
          const SizedBox(height: Bosluk.xl),
          AnaDugme(
            metin: l.cizimBitti,
            onTap: bos
                ? null
                : () {
                    ref.read(dokunsalProvider).cal(Dokunus.onay);
                    Navigator.of(context).pop(_cizim);
                  },
          ),
          const SizedBox(height: Bosluk.s),
          AnaDugme(metin: l.cizimVazgec, ikincil: true, onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  void _sec(int i) {
    if (i == _renk) return;
    setState(() => _renk = i);
  }
}

class _Surukle extends Drag {
  _Surukle({required this.guncelle, required this.bitir});
  final void Function(Offset genel) guncelle;
  final VoidCallback bitir;

  @override
  void update(DragUpdateDetails d) => guncelle(d.globalPosition);
  @override
  void end(DragEndDetails d) => bitir();
  @override
  void cancel() => bitir();
}

/// Boya düğmesi: 48 pt daire. Seçili olan onay işareti ve kalın halka
/// taşır (yalnız renkle anlam yok); ekran okuyucu renk adını okur.
class _Boya extends StatelessWidget {
  const _Boya({required this.sira, required this.secili, required this.onTap});
  final int sira;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final renk = DunyaRenkleri.boyalar[sira];
    return Basilabilir(
      onTap: onTap,
      semantik: context.l10n.cizimRenk('r$sira'),
      child: Semantics(
        selected: secili,
        child: AnimatedContainer(
          duration: Devinim.sure(context, Devinim.normal),
          curve: Devinim.cikis,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: renk,
            border: Border.all(color: secili ? r.fg : r.line, width: secili ? 4 : 2),
          ),
          child: secili ? const Icon(Icons.check_rounded, color: DunyaRenkleri.kagit, size: 24) : null,
        ),
      ),
    );
  }
}

/// Geri al / Temizle: ikonlu küçük düğme, en az 44 pt.
class _Arac extends StatelessWidget {
  const _Arac({required this.ikon, required this.metin, required this.onTap});
  final IconData ikon;
  final String metin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Basilabilir(
      onTap: onTap ?? () {},
      semantik: metin,
      child: AnimatedOpacity(
        opacity: onTap == null ? .45 : 1,
        duration: Devinim.sure(context, Devinim.normal),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: Bosluk.s),
          decoration: BoxDecoration(
            color: r.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: r.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ikon, size: 20, color: r.fg),
            const SizedBox(width: Bosluk.s),
            Flexible(child: Text(metin, style: context.t.labelLarge?.copyWith(color: r.fg))),
          ]),
        ),
      ),
    );
  }
}
