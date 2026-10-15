import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/ders.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

final _derslerProvider = FutureProvider.family<List<Ders>, String>((_, dil) => Ders.yukle(dil));

/// Öğren: günde bir kavram, tek soru, üç seçenek. Yanlışta ceza yok; ipucu.
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
    final dersler = ref.watch(_derslerProvider(Localizations.localeOf(context).languageCode)).valueOrNull;
    final ilerleme = ref.watch(dersIlerlemeProvider);
    if (dersler == null) return const Center(child: CircularProgressIndicator());

    if (ilerleme >= dersler.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Bosluk.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Karakter(tur: VarlikTuru.euro, ruh: Ruh.mutlu, boyut: 140),
            const SizedBox(height: Bosluk.l),
            Text(l.ogrenBitti, textAlign: TextAlign.center, style: context.t.titleLarge),
            const SizedBox(height: Bosluk.l),
            AnaDugme(metin: l.ogrenBastan, ikincil: true, onTap: () => ref.read(dersIlerlemeProvider.notifier).ilerleSifirla()),
          ]),
        ),
      );
    }

    final ders = dersler[ilerleme];
    String p(String s) => Ders.paraYerlestir(s, cocuk.para);
    final karakter = ders.karakter ?? VarlikTuru.euro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
      children: [
        // Wrap: büyük yazıda başlık ile sayaç yan yana sığmazsa alt alta iner.
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: Bosluk.s, runSpacing: Bosluk.xs, children: [
          BolumBasligi(l.ogrenBaslik),
          Text(l.ogrenSayac(ilerleme + 1, dersler.length), style: context.t.labelLarge?.copyWith(color: r.sub)),
        ]),
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
        BolumBasligi(l.ogrenSoru),
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
                      HapticFeedback.lightImpact();
                      setState(() {
                        _secim = i;
                        _dogru = dogru;
                      });
                    },
            ),
          ),
        const SizedBox(height: Bosluk.s),
        AnimatedSwitcher(
          duration: Devinim.sure(context, Devinim.normal),
          child: _secim == null
              ? const SizedBox(height: 24)
              : Text(
                  _dogru ? l.ogrenDogru(l.karakter(karakter)) : l.ogrenYanlis,
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
