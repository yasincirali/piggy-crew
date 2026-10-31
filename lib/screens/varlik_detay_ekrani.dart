import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/cikartma.dart';
import '../models/ders.dart';
import '../models/hedef.dart';
import '../models/plan.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../services/ses_servisi.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/hedef_esyasi.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import 'besle_sayfasi.dart';
import 'hedef_sayfasi.dart';
import 'ikilem_sayfasi.dart';
import 'kumbaradan_al_sayfasi.dart';
import 'plan_sayfasi.dart';

/// Tekil karakter: büyük karakter, bugünkü değer, iki çubuk (Verdin / Bugün),
/// "neden" kartı (karakter konuşur), hedef eşyası, besleme listesi. Grafik yok.
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
                      kostum: ref.watch(cikartmalarProvider).contains(Cikartma.kostum(tur)),
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
                  const SizedBox(height: Bosluk.l),
                  _HedefKarti(tur: tur, durum: d),
                  _Ulastiklarim(tur: tur),
                  _PlanKarti(tur: tur, ad: ad),
                  _OgretilenRaf(tur: tur, ad: ad),
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
                            Icon(h.cikis ? Icons.waving_hand_rounded : (h.kaynak?.ikon ?? Icons.local_fire_department_rounded),
                                color: h.cikis ? r.sub : r.petal),
                            const SizedBox(width: Bosluk.m),
                            Expanded(
                              flex: 2,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(tarihF.format(h.tarih), style: context.t.titleMedium),
                                if (h.cikis) Text(l.cikisSatir, style: context.t.bodyMedium),
                                // Kaynak ikonla birlikte yazıyla da (yalnız ikona anlam yüklenmez).
                                if (h.kaynak != null) Text(l.kaynakAdi(h.kaynak!.name), style: context.t.bodyMedium),
                                if (!tur.nakitMi) Text(fmtMiktar(h.miktar.abs(), birim, cocuk.para), style: context.t.bodyMedium),
                              ]),
                            ),
                            // Sağa yaslı ayrı sütun: 3,1× yazıda tutar sığmazsa alt satıra iner, taşmaz.
                            Expanded(
                              child: Text(h.cikis ? fmtFark(h.tutarTl, cocuk.para) : fmtPara(h.tutarTl, cocuk.para),
                                  textAlign: TextAlign.end, style: context.t.titleMedium),
                            ),
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
                        if (tamam != true || !context.mounted) return;
                        bildir(context, l.cikisTamam(ad));
                        await ikilemGosterGerekirse(context, ref);
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

/// "Öğrettiklerin" rafı (Ar-Ge 26 Eki, "Tortu'ya öğret"): çocuğun bu
/// karaktere anlattığı dersler, başlıklarıyla. Sayı, sayaç, eksik listesi
/// yok; boşsa raf hiç görünmez (yokluk yüze vurulmaz). Dokununca ders
/// metni bir sayfada yeniden okunur — anlatılanı hatırlamak için.
class _OgretilenRaf extends ConsumerWidget {
  const _OgretilenRaf({required this.tur, required this.ad});
  final VarlikTuru tur;
  final String ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final dersler = ref.watch(derslerProvider(Localizations.localeOf(context).languageCode)).valueOrNull;
    final ogretilen = ref.watch(ogretilenProvider);
    // null: eski kurulum, Öğren sekmesi ilk açılışta tohumlar (orada).
    if (dersler == null || ogretilen == null) return const SizedBox.shrink();
    final raf = [
      for (final d in dersler)
        if (ogretilen.contains(d.id) && (d.karakter ?? VarlikTuru.euro) == tur) d,
    ];
    if (raf.isEmpty) return const SizedBox.shrink();
    String p(String s) => Ders.paraYerlestir(s, cocuk.para);

    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.l),
      child: Kart(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BolumBasligi(l.detayOgrettiklerin(ad)),
            const SizedBox(height: Bosluk.xs),
            for (final d in raf)
              InkWell(
                borderRadius: BorderRadius.circular(Kose.m),
                onTap: () => altSayfaGoster<void>(
                  context,
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.xl, Bosluk.xl, Bosluk.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p(d.baslik), style: context.t.titleLarge),
                        const SizedBox(height: Bosluk.m),
                        Text(p(d.metin(cocuk.yas)), style: context.t.bodyLarge),
                      ],
                    ),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: r.sub, size: 20),
                      const SizedBox(width: Bosluk.m),
                      Expanded(child: Text(p(d.baslik), style: context.t.titleMedium)),
                      Icon(Icons.chevron_right_rounded, color: r.sub),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Ulaştıklarım" (Ar-Ge 29 Eki 20:07 #3): dolmuş eski hedefler, en yenisi
/// solda. Ustalık deneyimini hatırlatır (Bandura), ödül değildir: sayı,
/// rozet, "hepsini topla" yok; boşken görünmez. Hücre altında yalnız ay.
class _Ulastiklarim extends ConsumerWidget {
  const _Ulastiklarim({required this.tur});
  final VarlikTuru tur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final liste = ref.watch(ulasilanlarProvider)[tur];
    if (liste == null || liste.isEmpty) return const SizedBox.shrink();
    final yerel = Localizations.localeOf(context).toString();
    String ad(Hedef h) => h.esya == HedefEsya.cizim ? l.cizimEtiket : l.hedefEsyaAdi(h.esya.name);

    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.l),
      child: Kart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BolumBasligi(l.ulastiklarimBaslik),
          const SizedBox(height: Bosluk.m),
          Wrap(spacing: Bosluk.m, runSpacing: Bosluk.m, children: [
            for (final h in liste.reversed)
              Basilabilir(
                semantik: '${ad(h)}, ${DateFormat.yMMMM(yerel).format(h.ulasildi!)}',
                onTap: () => altSayfaGoster<void>(
                  context,
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.xl, Bosluk.xl, Bosluk.xxl),
                    // stretch: alt sayfa içerik kadar daralmasın, tam genişlik açılsın.
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Center(child: HedefEsyasi(esya: h.esya, doluluk: 1, boyut: 120, cizim: h.cizim)),
                      const SizedBox(height: Bosluk.l),
                      Text(
                        l.ulasilanCumle(DateFormat.yMMMM(yerel).format(h.ulasildi!)),
                        style: context.t.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ),
                child: ExcludeSemantics(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    HedefEsyasi(esya: h.esya, doluluk: 1, boyut: 40, cizim: h.cizim),
                    const SizedBox(height: Bosluk.xs),
                    Text(DateFormat.MMMM(yerel).format(h.ulasildi!), style: context.t.labelMedium?.copyWith(color: r.sub)),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

/// "Benim planım" (bkz. [PlanSablon]): hedefin hemen altında, çünkü plan
/// hedefe giden yolu söyler. Kampa kart eklenmedi (inceleme 26 Eki 20:07):
/// kamp bir sahne, kart onu kalabalıklaştırır. Sayı yok, denetim yok.
class _PlanKarti extends ConsumerWidget {
  const _PlanKarti({required this.tur, required this.ad});
  final VarlikTuru tur;
  final String ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final PlanSablon? p = ref.watch(planlarProvider)[tur];
    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.l),
      child: Kart(
        onTap: p == null ? null : () => planGoster(context, tur),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
            BolumBasligi(l.planBaslik),
            if (p != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, size: 18, color: r.sub),
                const SizedBox(width: Bosluk.xs),
                Flexible(child: Text(l.hedefDegistir, style: context.t.labelLarge?.copyWith(color: r.sub))),
              ]),
          ]),
          const SizedBox(height: Bosluk.s),
          if (p != null)
            Text(l.planCumle(p.name, ad), style: context.t.titleMedium)
          else ...[
            Text(l.planYok, style: context.t.bodyLarge),
            const SizedBox(height: Bosluk.m),
            AnaDugme(metin: l.planSec, ikincil: true, onTap: () => planGoster(context, tur)),
          ],
        ]),
      ),
    );
  }
}

/// Hedef eşyası kartı (yol haritası 2.1): sayı yok; eşya dolar, bir cümle
/// ve doluluk kelimesi. Hedef ilk kez dolduğunda burada bir kez sevinilir
/// (kampta beslenip dolduysa da burada, ilk açılışta); işaret saklanır,
/// ikinci kez oynamaz.
class _HedefKarti extends ConsumerStatefulWidget {
  const _HedefKarti({required this.tur, required this.durum});
  final VarlikTuru tur;
  final KarakterDurumu durum;
  @override
  ConsumerState<_HedefKarti> createState() => _HedefKartiState();
}

class _HedefKartiState extends ConsumerState<_HedefKarti> {
  bool _bakiliyor = false;

  void _dolduMuDenetle(Hedef? h) {
    if (h == null || _bakiliyor || !h.simdiDoldu(widget.durum)) return;
    _bakiliyor = true;
    // Kayıt build dışında: sağlayıcı build sırasında değiştirilmez.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final oldu = await ref.read(hedeflerProvider.notifier).ulastiysaIsaretle(widget.tur, widget.durum);
      _bakiliyor = false;
      if (!oldu || !mounted) return;
      ref.read(sesProvider).cal(Ses.yasasin);
      ref.read(dokunsalProvider).cal(Dokunus.sevinc);
      bildir(context, context.l10n.hedefHazir(context.l10n.karakter(widget.tur), h.esya.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final h = ref.watch(hedeflerProvider)[widget.tur];
    final ad = l.karakter(widget.tur);
    _dolduMuDenetle(h);

    if (h == null) {
      return Kart(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BolumBasligi(l.hedefBaslik),
          const SizedBox(height: Bosluk.s),
          Text(l.hedefYok(ad), style: context.t.bodyLarge),
          const SizedBox(height: Bosluk.m),
          AnaDugme(metin: l.hedefSec, ikincil: true, onTap: () => hedefGoster(context, widget.tur)),
        ]),
      );
    }

    final v = h.doluluk(widget.durum);
    final hazir = h.ulasildi != null;
    final esya = HedefEsyasi(esya: h.esya, doluluk: v, cizim: h.cizim);
    final metin = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(hazir ? l.hedefHazir(ad, h.esya.name) : l.hedefCumle(ad, h.esya.name), style: context.t.titleMedium),
      const SizedBox(height: Bosluk.xs),
      Text(
        l.hedefKademe(widget.durum.maliyetTl <= 0 && !hazir ? 'yeni' : hedefKademe(v).name),
        style: context.t.bodyMedium?.copyWith(color: hazir ? r.acc : r.sub, fontWeight: FontWeight.w700),
      ),
    ]);
    // Büyük yazıda (≥1,6×) eşya metnin üstüne çıkar: yan yanayken kelimeler
    // dar sütunda harf harf bölünür.
    final buyukYazi = MediaQuery.textScalerOf(context).scale(10) > 16;
    return Kart(
      onTap: hazir ? null : () => hedefGoster(context, widget.tur),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Wrap: büyük yazıda "Değiştir" başlığın altına iner, taşmaz.
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          BolumBasligi(l.hedefBaslik),
          if (!hazir)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit_rounded, size: 18, color: r.sub),
              const SizedBox(width: Bosluk.xs),
              Flexible(child: Text(l.hedefDegistir, style: context.t.labelLarge?.copyWith(color: r.sub))),
            ]),
        ]),
        const SizedBox(height: Bosluk.m),
        if (buyukYazi)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [esya, const SizedBox(height: Bosluk.m), metin])
        else
          Row(children: [esya, const SizedBox(width: Bosluk.l), Expanded(child: metin)]),
        if (hazir) ...[
          const SizedBox(height: Bosluk.m),
          AnaDugme(metin: l.hedefYeni, ikincil: true, onTap: () => hedefGoster(context, widget.tur)),
        ],
      ]),
    );
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
