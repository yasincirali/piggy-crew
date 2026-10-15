import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/ses_servisi.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/kamp_atesi.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import 'besle_sayfasi.dart';
import 'varlik_detay_ekrani.dart';

/// Kamp: ana ekran. Ortada ateş (toplam), çevresinde takım. Karaktere dokun →
/// detay. Sayı az: toplam ve fark. Analiz, grafik, yüzde listesi yok (karar).
class KampEkrani extends ConsumerStatefulWidget {
  const KampEkrani({super.key});
  @override
  ConsumerState<KampEkrani> createState() => _KampState();
}

class _KampState extends ConsumerState<KampEkrani> {
  final _yeme = <VarlikTuru, int>{};
  final _tepki = <VarlikTuru, int>{};
  bool _aciliyor = false;

  Future<void> _besle(VarlikTuru t) async {
    final sonuc = await besleGoster(context, ref, t);
    if (sonuc == null || !mounted) return;
    setState(() => _yeme[t] = (_yeme[t] ?? 0) + 1);
    if (sonuc.yeniCikartma != null) {
      // Çıkartma sesi yeme sahnesinin arpejinden sonra gelsin, üst üste binmesin.
      Future.delayed(const Duration(milliseconds: 1500), () => ref.read(sesProvider).cal(Ses.cikartma));
    }
    final l = context.l10n;
    final mesaj = sonuc.yeniCikartma == null
        ? l.besleDoydu(l.karakter(t))
        : l.cikartmaAcildi(sonuc.yeniCikartma!);
    bildir(context, mesaj);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final k = ref.watch(karakterlerProvider);
    final toplam = ref.watch(toplamProvider);
    final fiyat = ref.watch(fiyatProvider);
    final gorunur = k.keys.toList();
    final bos = toplam.maliyetTl <= 0;

    final sol = gorunur.where((t) => t != VarlikTuru.altin).toList();
    // Yerleşim: üst satır (Baykuş · ateş · Zıpzıp), alt satır (Tortu büyük · Sincap).
    // Ev birimi dolar/euro ise bir karakter eksik; kalanlar sırayla doldurur.
    final ust = sol.take(2).toList();
    final alt = sol.skip(2).toList();

    Widget karakter(VarlikTuru t, {double boyut = 92, Duration gecikme = Duration.zero}) {
      final d = k[t]!;
      final cik = ref.watch(cikartmalarProvider);
      return Basilabilir(
        semantik: '${l.karakter(t)}, ${l.varlik(t)}',
        // Dokununca önce karakter tepki verir (ses + zıplama), detay ardından
        // açılır: tepki görünsün diye kısa bekleme. Çift dokunma iki sayfa
        // açmasın diye bekleme sırasında yeni dokunma yalnız tepki verir.
        onTap: () {
          setState(() => _tepki[t] = (_tepki[t] ?? 0) + 1);
          if (_aciliyor) return;
          _aciliyor = true;
          final nav = Navigator.of(context);
          Future.delayed(Devinim.sure(context, const Duration(milliseconds: 420)), () async {
            if (!mounted) return;
            await nav.push(VarlikDetayEkrani.rota(t));
            _aciliyor = false;
          });
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Karakter(
            tur: t,
            ruh: d.ruh,
            boyut: boyut,
            gecikme: gecikme,
            yemeTetik: _yeme[t] ?? 0,
            tepkiTetik: _tepki[t] ?? 0,
            bosta: true,
            ses: ref.read(sesProvider).cal,
            pulSayisi: t == VarlikTuru.altin ? (d.maliyetTl / 250).floor().clamp(0, 3) : 0,
            parlak: t == VarlikTuru.altin && cik.contains('tortu_parlak'),
          ),
          Text(l.karakter(t), style: context.t.labelLarge),
          if (!d.bos && d.farkTl != null)
            Text(
              fmtFark(d.farkTl!, cocuk.para),
              style: context.t.labelMedium?.copyWith(
                color: d.ruh == Ruh.mutlu ? r.gain : r.sub,
                fontWeight: FontWeight.w800,
              ),
            ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fiyatProvider.notifier).yenile(),
      color: r.acc,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
        children: [
          Text(l.kampSelam(cocuk.ad), style: context.t.titleMedium?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.xs),
          BolumBasligi(l.kampAtesim),
          const SizedBox(height: Bosluk.xs),
          if (toplam.degerTl != null)
            Text(fmtPara(toplam.degerTl!, cocuk.para), style: context.t.displayMedium)
          else if (!bos)
            Text(l.kampFiyatYok, style: context.t.bodyLarge?.copyWith(color: r.sub))
          else
            Text(fmtPara(0, cocuk.para), style: context.t.displayMedium),
          if (toplam.farkTl != null && !bos)
            Text(
              '${l.fark}: ${fmtFark(toplam.farkTl!, cocuk.para)}',
              style: context.t.titleMedium?.copyWith(
                color: toplam.farkTl! > 0 ? r.gain : r.sub,
              ),
            ),
          const SizedBox(height: Bosluk.l),
          // Kamp sahnesi. Karakterler ve ateş sabit boyutlu bir sahne; altındaki
          // ad/fark etiketleri en fazla 1,5× büyür ki sahne dar ekranda taşmasın.
          // Aynı bilgi aşağıdaki besleme listesinde tam Dynamic Type ile var.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sigdir(92, ust.isNotEmpty ? karakter(ust[0], gecikme: const Duration(milliseconds: 700)) : const SizedBox(width: 92)),
                  _sigdir(140, KampAtesi(
                        // Ateş piyasa düşüşünde küçülmez: en az verilen kadar
                        // yanar (çocuğun emeği sönmez), kazançla büyür.
                        toplamTl: math.max(toplam.degerTl ?? 0, toplam.maliyetTl),
                        boyut: 140,
                        parlamaTetik: _yeme.values.fold(0, (a, b) => a + b),
                      )),
                  _sigdir(92, ust.length > 1 ? karakter(ust[1], gecikme: const Duration(milliseconds: 1400)) : const SizedBox(width: 92)),
                ],
              ),
              const SizedBox(height: Bosluk.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sigdir(120, karakter(VarlikTuru.altin, boyut: 120)),
                  // Flex = kalan doğal genişlik (335 − 120 − 92); sahne öğeleriyle aynı ölçekte.
                  Expanded(
                    flex: 123,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Bosluk.m),
                      child: Text(
                        bos ? l.kampBos : _fiyatNotu(l, fiyat.valueOrNull?.zaman),
                        textAlign: TextAlign.center,
                        style: context.t.bodySmall?.copyWith(color: r.sub),
                      ),
                    ),
                  ),
                  _sigdir(92, alt.isNotEmpty ? karakter(alt[0], gecikme: const Duration(milliseconds: 2100)) : const SizedBox(width: 92)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: Bosluk.xl),
          // Besle düğmeleri: her karakter için bir satır (44 pt+).
          Kart(
            padding: const EdgeInsets.all(Bosluk.s),
            child: Column(children: [
              for (final t in gorunur)
                Basilabilir(
                  onTap: () => _besle(t),
                  semantik: l.besleBaslik(l.karakter(t)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: Bosluk.xs),
                    child: Row(children: [
                      SizedBox.square(dimension: 44, child: CustomPaint(painter: KarakterPainter(tur: t, ruh: k[t]!.ruh))),
                      const SizedBox(width: Bosluk.m),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${l.karakter(t)} · ${l.varlik(t)}', style: context.t.titleMedium),
                          if (!k[t]!.bos)
                            Text(fmtMiktar(k[t]!.miktar, l.birim(t, cocuk.para), cocuk.para),
                                style: context.t.bodyMedium),
                        ]),
                      ),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: r.acc, borderRadius: BorderRadius.circular(999)),
                        child: Text(l.besle, style: context.t.labelLarge?.copyWith(color: r.accInk)),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  String _fiyatNotu(AppLocalizations l, DateTime? z) {
    if (z == null || z.millisecondsSinceEpoch == 0) return l.kampFiyatYok;
    final f = DateFormat.Hm(Localizations.localeOf(context).toString());
    final bugun = DateTime.now().difference(z).inHours < 20;
    return l.kampFiyatEski(bugun ? f.format(z) : DateFormat.MMMd(Localizations.localeOf(context).toString()).format(z));
  }
}

/// Sahne öğesi dar ekranda sığmazsa orantılı küçülür, sığıyorsa boyutu aynen kalır.
/// [en] öğenin doğal genişliği: satırdaki pay buna oranla dağılır, böylece
/// normal ekranda hiçbir öğe küçülmez (eşit pay ateşi 140'tan küçültüyordu).
Widget _sigdir(int en, Widget w) => Flexible(flex: en, child: FittedBox(fit: BoxFit.scaleDown, child: w));
