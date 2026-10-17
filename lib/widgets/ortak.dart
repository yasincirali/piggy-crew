import 'package:flutter/material.dart';

import '../theme/dunya.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';

/// Ortak bileşenler — "bir iş = bir bileşen" (sandık tasarım dili).
/// Dokunma alanı ≥ 44 pt her yerde; basışta .97 ölçek, 120 ms.

/// Yumuşak kart: dünyanın `card` rengi + ince çizgi.
class Kart extends StatelessWidget {
  const Kart({super.key, required this.child, this.padding = const EdgeInsets.all(Bosluk.l), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final govde = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: r.card,
        borderRadius: BorderRadius.circular(Kose.l),
        border: Border.all(color: r.line),
      ),
      child: child,
    );
    if (onTap == null) return govde;
    return Basilabilir(onTap: onTap!, child: govde);
  }
}

/// Basınca hafif küçülen sarmalayıcı (hareketi azalt → ölçek yok).
class Basilabilir extends StatefulWidget {
  const Basilabilir({super.key, required this.child, required this.onTap, this.semantik});
  final Widget child;
  final VoidCallback onTap;
  final String? semantik;

  @override
  State<Basilabilir> createState() => _BasilabilirState();
}

class _BasilabilirState extends State<Basilabilir> {
  bool _basili = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semantik,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _basili = true),
        onTapCancel: () => setState(() => _basili = false),
        onTapUp: (_) => setState(() => _basili = false),
        onTap: () {
          dokunsalCal(context, Dokunus.dokunma);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _basili ? .97 : 1,
          duration: Devinim.sure(context, Devinim.hizli),
          curve: Devinim.cikis,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Ana eylem düğmesi: vurgu rengi, 56 pt, tam genişlik.
class AnaDugme extends StatelessWidget {
  const AnaDugme({super.key, required this.metin, required this.onTap, this.ikincil = false});
  final String metin;
  final VoidCallback? onTap;
  final bool ikincil;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final aktif = onTap != null;
    return Basilabilir(
      onTap: onTap ?? () {},
      child: AnimatedOpacity(
        opacity: aktif ? 1 : .45,
        duration: Devinim.sure(context, Devinim.normal),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ikincil ? r.card : r.acc,
            borderRadius: BorderRadius.circular(Kose.m),
            border: ikincil ? Border.all(color: r.line) : null,
          ),
          child: Text(
            metin,
            style: context.t.titleMedium?.copyWith(color: ikincil ? r.fg : r.accInk),
          ),
        ),
      ),
    );
  }
}

/// Seçim çipi (filtre/seçenek): 44 pt, seçiliyse vurgu zemin + onay işareti
/// (yalnız renkle anlam yok).
class SecimCipi extends StatelessWidget {
  const SecimCipi({super.key, required this.metin, required this.secili, required this.onTap, this.onIkon});
  final String metin;
  final bool secili;
  final VoidCallback onTap;
  final Widget? onIkon;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Basilabilir(
      onTap: onTap,
      semantik: metin,
      child: Semantics(
        selected: secili,
        child: AnimatedContainer(
          duration: Devinim.sure(context, Devinim.normal),
          curve: Devinim.cikis,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: Bosluk.s),
          decoration: BoxDecoration(
            color: secili ? r.acc : r.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: secili ? r.acc : r.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onIkon != null) ...[onIkon!, const SizedBox(width: Bosluk.s)],
              if (secili) Icon(Icons.check_rounded, size: 18, color: r.accInk),
              if (secili) const SizedBox(width: Bosluk.xs),
              // Flexible: büyük yazıda çip satıra sığmazsa metin alt satıra iner.
              Flexible(child: Text(metin, style: context.t.labelLarge?.copyWith(color: secili ? r.accInk : r.fg))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alt sayfa: tek davranış (sandık `showSandikSheet` karşılığı).
Future<T?> altSayfaGoster<T>(BuildContext context, Widget child) {
  final r = context.r;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: r.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Kose.xl))),
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
      child: child,
    ),
  );
}

/// Bölüm başlığı — küçük, ikincil renk. Büyük harf YAPILMAZ: Dart
/// `toUpperCase` yerel bilmez, "ateşim" → "ATEŞIM" (noktasız I) olur.
class BolumBasligi extends StatelessWidget {
  const BolumBasligi(this.metin, {super.key});
  final String metin;
  @override
  Widget build(BuildContext context) => Text(
        metin,
        style: context.t.labelLarge?.copyWith(color: context.r.sub, fontWeight: FontWeight.w800),
      );
}

/// Kısa bildirim (toast): alttan, 2,2 sn.
void bildir(BuildContext context, String metin) {
  final r = context.r;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(metin, style: context.t.bodyLarge?.copyWith(color: r.warmInk, fontWeight: FontWeight.w700)),
      backgroundColor: r.warm,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Kose.m)),
    ));
}

/// Dünya gradyanlı zemin.
class DunyaZemini extends StatelessWidget {
  const DunyaZemini({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AnimatedContainer(
      duration: Devinim.sure(context, Devinim.yavas),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [r.bg1, r.bg2, r.bg3],
          stops: const [0, .55, 1],
        ),
      ),
      child: child,
    );
  }
}
