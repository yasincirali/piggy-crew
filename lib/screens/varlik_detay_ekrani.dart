import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import 'besle_sayfasi.dart';
import 'kumbaradan_al_sayfasi.dart';

/// Tekil karakter: büyük karakter, bugünkü değer, iki çubuk (Verdin / Bugün),
/// "neden" kartı (karakter konuşur), besleme listesi. Grafik yok.
class VarlikDetayEkrani extends ConsumerWidget {
  const VarlikDetayEkrani({super.key, required this.tur});
  final VarlikTuru tur;

  /// iOS geçişi (sandık `adaptiveRoute` karşılığı): her iki platformda Cupertino
  /// kaydırmalı geri; Material'de de doğal hissettirir, geri kaydırma çalışır.
  static Route<void> rota(VarlikTuru t) => CupertinoPageRoute(builder: (_) => VarlikDetayEkrani(tur: t));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final d = ref.watch(karakterlerProvider)[tur];
    final hareketler = ref.watch(hareketlerProvider).where((h) => h.tur == tur).toList()
      ..sort((a, b) => b.tarih.compareTo(a.tarih));
    final ad = l.karakter(tur);
    final birim = l.birim(tur, cocuk.para);
    final tarihF = DateFormat.MMMd(Localizations.localeOf(context).toString());

    if (d == null) return const SizedBox.shrink();

    final degerOrani = (d.degerTl != null && d.maliyetTl > 0)
        ? (d.degerTl! / (d.degerTl! > d.maliyetTl ? d.degerTl! : d.maliyetTl))
        : 0.0;
    final maliyetOrani = (d.degerTl != null && d.degerTl! > d.maliyetTl && d.degerTl! > 0)
        ? d.maliyetTl / d.degerTl!
        : (d.maliyetTl > 0 ? 1.0 : 0.0);

    String neden() {
      if (tur.nakitMi) return l.detayNedenNakit;
      final f = d.farkTl;
      if (f == null || d.bos) return l.huy(tur);
      if (d.ruh == Ruh.mutlu) return l.detayNedenMutlu(l.varlik(tur), fmtFark(f, cocuk.para));
      if (d.ruh == Ruh.bulutlu) return l.detayNedenUzgun(l.varlik(tur), fmtFark(f, cocuk.para));
      return l.huy(tur);
    }

    return Scaffold(
      body: DunyaZemini(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Bosluk.s),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_rounded, color: r.fg),
                  tooltip: l.geri,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                Expanded(child: Text('$ad · ${l.varlik(tur)}', textAlign: TextAlign.center, style: context.t.titleLarge)),
                const SizedBox(width: 44),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.s, Bosluk.xl, Bosluk.dev),
                children: [
                  Center(
                    child: Karakter(
                      tur: tur,
                      ruh: d.ruh,
                      boyut: 170,
                      pulSayisi: tur == VarlikTuru.altin ? (d.verilenTl / 250).floor().clamp(0, 3) : 0,
                      parlak: tur == VarlikTuru.altin && ref.watch(cikartmalarProvider).contains('tortu_parlak'),
                      // Buradan beslenip evre atlarsa büyüme sahnesi burada oynar.
                      evre: ref.watch(evrelerProvider)[tur],
                      evreKutla: true,
                      ses: ref.read(sesProvider).cal,
                      dokun: ref.read(dokunsalProvider).cal,
                    ),
                  ),
                  const SizedBox(height: Bosluk.s),
                  if (d.bos)
                    Text(l.detayBos(ad), textAlign: TextAlign.center, style: context.t.bodyLarge?.copyWith(color: r.sub))
                  else ...[
                    Center(
                      child: Text(
                        d.degerTl == null ? l.kampFiyatYok : fmtPara(d.degerTl!, cocuk.para),
                        style: d.degerTl == null ? context.t.bodyLarge : context.t.displayMedium,
                      ),
                    ),
                    Center(child: Text(l.detayMiktar(fmtMiktar(d.miktar, birim, cocuk.para)), style: context.t.bodyMedium)),
                    const SizedBox(height: Bosluk.xl),
                    if (!tur.nakitMi && d.degerTl != null)
                      Kart(
                        child: Column(children: [
                          _Cubuk(etiket: l.detayVerdin, oran: maliyetOrani, deger: fmtPara(d.maliyetTl, cocuk.para), renk: r.soil),
                          const SizedBox(height: Bosluk.m),
                          _Cubuk(
                            etiket: l.detayBugun,
                            oran: degerOrani,
                            deger: fmtPara(d.degerTl!, cocuk.para),
                            renk: r.acc,
                          ),
                          if (d.farkYuzde != null && cocuk.yas.anahtar == 'buyuk') ...[
                            const SizedBox(height: Bosluk.m),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${fmtFark(d.farkTl!, cocuk.para)} · ${fmtYuzde(d.farkYuzde!, cocuk.para)}',
                                style: context.t.titleMedium?.copyWith(color: r.acc),
                              ),
                            ),
                          ],
                        ]),
                      ),
                  ],
                  const SizedBox(height: Bosluk.l),
                  Kart(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      BolumBasligi(l.detayNedenBaslik(ad)),
                      const SizedBox(height: Bosluk.s),
                      Text(neden(), style: context.t.bodyLarge),
                    ]),
                  ),
                  if (hareketler.isNotEmpty) ...[
                    const SizedBox(height: Bosluk.xl),
                    BolumBasligi(l.detayBeslemeler),
                    const SizedBox(height: Bosluk.s),
                    for (final h in hareketler)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Bosluk.s),
                        child: Kart(
                          padding: const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: Bosluk.m),
                          onTap: () => _silSor(context, ref, h),
                          // Alma satırı ikon + yazıyla ayrılır, yalnız renkle değil.
                          child: Row(children: [
                            Icon(h.cikis ? Icons.waving_hand_rounded : Icons.local_fire_department_rounded,
                                color: h.cikis ? r.sub : r.petal),
                            const SizedBox(width: Bosluk.m),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(tarihF.format(h.tarih), style: context.t.titleMedium),
                                if (h.cikis) Text(l.cikisSatir, style: context.t.bodyMedium),
                                if (!tur.nakitMi) Text(fmtMiktar(h.miktar.abs(), birim, cocuk.para), style: context.t.bodyMedium),
                              ]),
                            ),
                            Text(h.cikis ? fmtFark(h.tutarTl, cocuk.para) : fmtPara(h.tutarTl, cocuk.para),
                                style: context.t.titleMedium),
                          ]),
                        ),
                      ),
                  ],
                  const SizedBox(height: Bosluk.xl),
                  AnaDugme(
                    metin: l.detayBirazDaha,
                    onTap: () async {
                      final s = await besleGoster(context, ref, tur);
                      if (s != null && context.mounted) bildir(context, s.mesaj(l, tur));
                    },
                  ),
                  if (!d.bos) ...[
                    const SizedBox(height: Bosluk.s),
                    AnaDugme(
                      metin: l.cikisBaslik,
                      ikincil: true,
                      onTap: () async {
                        final tamam = await kumbaradanAlGoster(context, tur);
                        if (tamam == true && context.mounted) bildir(context, l.cikisTamam(ad));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _silSor(BuildContext context, WidgetRef ref, Hareket h) async {
    final l = context.l10n;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(h.cikis ? l.cikisSil : l.detaySil),
        content: Text(h.cikis ? l.cikisSilOnay : l.detaySilOnay),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.iptal)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.sil)),
        ],
      ),
    );
    if (onay == true) await ref.read(hareketlerProvider.notifier).sil(h.id);
  }
}

class _Cubuk extends StatelessWidget {
  const _Cubuk({required this.etiket, required this.oran, required this.deger, required this.renk});
  final String etiket;
  final double oran;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(children: [
      SizedBox(width: 64, child: Text(etiket, style: context.t.labelLarge?.copyWith(color: r.sub))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 20, color: r.track),
            TweenAnimationBuilder<double>(
              tween: Tween(end: oran.clamp(0, 1)),
              duration: Devinim.sure(context, Devinim.yavas),
              curve: Devinim.cikis,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(height: 20, decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: Bosluk.s),
      SizedBox(width: 84, child: Text(deger, textAlign: TextAlign.end, style: context.t.labelLarge)),
    ]);
  }
}
