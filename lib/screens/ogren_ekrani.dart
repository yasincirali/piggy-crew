import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/ders.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import '../services/dokunsal.dart';

/// Öğren: günde bir kavram, tek soru, üç seçenek. Yanlışta ceza yok; ipucu.
///
/// Soruyu karakter sorar, çocuk ona öğretir (Ar-Ge 26 Eki, protégé etkisi:
/// Chase ve diğ. 2009, sanal bir karaktere öğreten çocuk öğrenmeye daha çok
/// emek verir; sınanan karakter olunca hata utandırmaz). Doğruda övgü çocuğa
/// değil, karakter "anladım" der ve ders onun rafına girer; yanlışta karakter
/// de karıştırdığını söyler. Puan, sayaç, ödül eklenmez.
class OgrenEkrani extends ConsumerStatefulWidget {
  const OgrenEkrani({super.key});
  @override
  ConsumerState<OgrenEkrani> createState() => _OgrenState();
}

class _OgrenState extends ConsumerState<OgrenEkrani> {
  int? _secim;
  bool _dogru = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final dersler = ref.watch(derslerProvider(Localizations.localeOf(context).languageCode)).valueOrNull;
    final ilerleme = ref.watch(dersIlerlemeProvider);
    if (dersler == null) return const Center(child: CircularProgressIndicator());
    // Bu özellikten önce ders geçmiş çocuk: geçtiği dersler (ilerleme yalnız
    // doğru cevapla artar) öğretilmiş sayılır. Sekmeler uygulama açılışında
    // kurulduğu için bu bir kez, karakter ekranı açılmadan önce olur.
    if (ref.watch(ogretilenProvider) == null) {
      Future.microtask(() => ref.read(ogretilenProvider.notifier).tohumla(dersler.take(ilerleme).map((d) => d.id)));
    }

    if (ilerleme >= dersler.length) return _Hatirla(dersler: dersler);

    final ders = dersler[ilerleme];
    String p(String s) => Ders.paraYerlestir(s, cocuk.para);
    final karakter = ders.karakter ?? VarlikTuru.euro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
      children: [
        // Sayaç ("3 / 10") yok: çocuğa eksiğini sayıyordu (Ar-Ge 31 Eki 11:07 #3).
        // Başlık zamansız: günlük kapı yok, "Bugünün" yanlış söz veriyordu.
        BolumBasligi(l.ogrenBaslik),
        const SizedBox(height: Bosluk.s),
        Kart(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Karakter(tur: karakter, ruh: Ruh.mutlu, boyut: 72),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.m, vertical: Bosluk.xs),
                    decoration: BoxDecoration(color: r.accSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text(p(ders.kavram), style: context.t.labelLarge?.copyWith(color: r.fg)),
                  ),
                  const SizedBox(height: Bosluk.s),
                  Text(p(ders.baslik), style: context.t.titleLarge),
                ]),
              ),
            ]),
            const SizedBox(height: Bosluk.l),
            Text(p(ders.metin(cocuk.yas)), style: context.t.bodyLarge),
          ]),
        ),
        const SizedBox(height: Bosluk.l),
        Row(children: [
          Karakter(tur: karakter, ruh: _dogru ? Ruh.mutlu : Ruh.duz, boyut: 44),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(l.ogrenKarakterSoruyor(l.karakter(karakter)), style: context.t.bodyLarge?.copyWith(color: r.sub)),
          ),
        ]),
        const SizedBox(height: Bosluk.s),
        Text(p(ders.soru), style: context.t.titleMedium),
        const SizedBox(height: Bosluk.m),
        for (final (i, s) in ders.secenekler.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Bosluk.s),
            child: _Secenek(
              metin: p(s),
              durum: _secim == null
                  ? _SecenekDurumu.bos
                  : (i == ders.dogru && _secim == i)
                      ? _SecenekDurumu.dogru
                      : (_secim == i ? _SecenekDurumu.yanlis : _SecenekDurumu.bos),
              onTap: _dogru
                  ? null
                  : () {
                      final dogru = i == ders.dogru;
                      ref.read(dokunsalProvider).cal(Dokunus.secim);
                      setState(() {
                        _secim = i;
                        _dogru = dogru;
                      });
                      if (dogru) {
                        final n = ref.read(ogretilenProvider.notifier);
                        // Önceki sürümde geçilen dersler kaybolmasın (ilk yazımda).
                        n.tohumla(dersler.take(ilerleme).map((d) => d.id)).then((_) => n.ekle(ders.id));
                      }
                    },
            ),
          ),
        const SizedBox(height: Bosluk.s),
        AnimatedSwitcher(
          duration: Devinim.sure(context, Devinim.normal),
          child: _secim == null
              ? const SizedBox(height: 24)
              : Text(
                  _dogru ? l.ogrenOgretti(l.karakter(karakter)) : l.ogrenBirlikte(l.karakter(karakter)),
                  key: ValueKey('$_secim$_dogru'),
                  style: context.t.titleMedium?.copyWith(color: _dogru ? r.acc : r.sub),
                ),
        ),
        const SizedBox(height: Bosluk.l),
        AnaDugme(
          metin: l.ogrenSonraki,
          onTap: _dogru
              ? () async {
                  await ref.read(dersIlerlemeProvider.notifier).ilerle(ilerleme + 1);
                  final cik = ref.read(cikartmalarProvider.notifier);
                  if (ilerleme + 1 >= 5) await cik.ac('ders_5');
                  if (ilerleme + 1 >= 10) await cik.ac('ders_10');
                  setState(() {
                    _secim = null;
                    _dogru = false;
                  });
                }
              : null,
        ),
      ],
    );
  }
}

/// Dersler bitince: "Hatırlıyor musun?" (Ar-Ge 31 Eki, yasin "yap"). Eskiden
/// yalnız "Baştan oku" vardı, aynı metin ve soru; sekme ilk haftadan sonra
/// boş kalıyordu. Karakter öğretilmiş bir dersi **metni göstermeden** yeni bir
/// soruyla sorar; yanlışta ders metni ipucu olarak açılır. Açılışta tek soru:
/// sıra durum kurulurken bir kez okunur, doğru cevapla bir sonrakine geçer ama
/// yeni soru ancak uygulama yeniden açılınca gelir (ardı ardına sorgu test
/// hissi verir). Puan, sayaç, çıkartma yok.
class _Hatirla extends ConsumerStatefulWidget {
  const _Hatirla({required this.dersler});
  final List<Ders> dersler;
  @override
  ConsumerState<_Hatirla> createState() => _HatirlaState();
}

class _HatirlaState extends ConsumerState<_Hatirla> {
  late final int _sira = ref.read(depoProvider).hatirlaSiraOku();
  int? _secim;
  bool _dogru = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final ogretilen = ref.watch(ogretilenProvider) ?? const <String>{};
    final adaylar = [
      for (final d in widget.dersler)
        if (d.hatirla != null && ogretilen.contains(d.id)) d,
    ];
    final ders = adaylar.isEmpty ? null : adaylar[_sira % adaylar.length];
    String p(String s) => Ders.paraYerlestir(s, cocuk.para);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
      children: [
        Text(l.ogrenBitti, style: context.t.titleLarge),
        const SizedBox(height: Bosluk.l),
        if (ders != null) ...[
          Builder(builder: (context) {
            final h = ders.hatirla!;
            final karakter = ders.karakter ?? VarlikTuru.euro;
            return Kart(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Karakter(tur: karakter, ruh: _dogru ? Ruh.mutlu : Ruh.duz, boyut: 56),
                  const SizedBox(width: Bosluk.m),
                  Expanded(child: BolumBasligi(l.hatirlaBaslik)),
                ]),
                const SizedBox(height: Bosluk.s),
                Text(l.hatirlaSoruyor(l.karakter(karakter), p(ders.kavram)), style: context.t.bodyLarge?.copyWith(color: r.sub)),
                const SizedBox(height: Bosluk.s),
                Text(p(h.soru), style: context.t.titleMedium),
                const SizedBox(height: Bosluk.m),
                for (final (i, s) in h.secenekler.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Bosluk.s),
                    child: _Secenek(
                      metin: p(s),
                      durum: _secim != i
                          ? _SecenekDurumu.bos
                          : (i == h.dogru ? _SecenekDurumu.dogru : _SecenekDurumu.yanlis),
                      onTap: _dogru
                          ? null
                          : () {
                              final dogru = i == h.dogru;
                              ref.read(dokunsalProvider).cal(dogru ? Dokunus.onay : Dokunus.secim);
                              setState(() {
                                _secim = i;
                                _dogru = dogru;
                              });
                              // Sıra yalnız doğruda ilerler: yanlışta aynı soru bir
                              // sonraki açılışta yine gelir, ceza değil tekrar.
                              if (dogru) ref.read(depoProvider).hatirlaSiraYaz(_sira + 1);
                            },
                    ),
                  ),
                AnimatedSwitcher(
                  duration: Devinim.sure(context, Devinim.normal),
                  child: _secim == null
                      ? const SizedBox.shrink()
                      : _dogru
                          ? Text(
                              l.hatirlaDogru(l.karakter(karakter)),
                              key: const ValueKey('dogru'),
                              style: context.t.titleMedium?.copyWith(color: r.acc),
                            )
                          // Rehberli geri getirme: yanlışta ders metni ipucu olur.
                          : Column(
                              key: ValueKey('ipucu$_secim'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(l.ogrenBirlikte(l.karakter(karakter)), style: context.t.titleMedium?.copyWith(color: r.sub)),
                                const SizedBox(height: Bosluk.s),
                                Text(p(ders.metin(cocuk.yas)), style: context.t.bodyLarge),
                              ],
                            ),
                ),
              ]),
            );
          }),
          const SizedBox(height: Bosluk.xl),
        ],
        AnaDugme(
          metin: l.ogrenBastan,
          ikincil: true,
          onTap: () async {
            // Sıfırlamadan önce: hiç tohumlanmamış eski kurulumda bütün
            // dersler öğretilmiş sayılır; ilerleme sıfırlanır, raf kalır.
            await ref.read(ogretilenProvider.notifier).tohumla(widget.dersler.map((d) => d.id));
            await ref.read(dersIlerlemeProvider.notifier).ilerleSifirla();
          },
        ),
      ],
    );
  }
}

enum _SecenekDurumu { bos, dogru, yanlis }

class _Secenek extends StatelessWidget {
  const _Secenek({required this.metin, required this.durum, required this.onTap});
  final String metin;
  final _SecenekDurumu durum;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final (zemin, ikon) = switch (durum) {
      _SecenekDurumu.bos => (r.card, null),
      _SecenekDurumu.dogru => (r.acc, Icons.check_rounded),
      _SecenekDurumu.yanlis => (r.loss.withValues(alpha: .25), Icons.refresh_rounded),
    };
    final fg = durum == _SecenekDurumu.dogru ? r.accInk : r.fg;
    return Basilabilir(
      onTap: onTap ?? () {},
      semantik: metin,
      child: AnimatedContainer(
        duration: Devinim.sure(context, Devinim.normal),
        curve: Devinim.cikis,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: Bosluk.m),
        decoration: BoxDecoration(
          color: zemin,
          borderRadius: BorderRadius.circular(Kose.m),
          border: Border.all(color: durum == _SecenekDurumu.bos ? r.line : zemin),
        ),
        child: Row(children: [
          Expanded(child: Text(metin, style: context.t.titleMedium?.copyWith(color: fg))),
          if (ikon != null) Icon(ikon, color: fg),
        ]),
      ),
    );
  }
}
