import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/cikartma.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import '../services/dokunsal.dart';

/// Besleme sonucu: hareket eklendi; varsa yeni açılan çıkartmanın adı.
class BeslemeSonucu {
  const BeslemeSonucu(this.yeniCikartma);
  final String? yeniCikartma;
}

/// Besle alt sayfası: tutar yaz → bugünkü fiyatla miktar görünür → ver.
/// Fiyat yoksa düğme kapalı; sabit fiyatla alım YAPILMAZ (uydurma sayı yasağı).
Future<BeslemeSonucu?> besleGoster(BuildContext context, WidgetRef ref, VarlikTuru tur) =>
    altSayfaGoster<BeslemeSonucu>(context, _BesleSayfasi(tur: tur));

class _BesleSayfasi extends ConsumerStatefulWidget {
  const _BesleSayfasi({required this.tur});
  final VarlikTuru tur;
  @override
  ConsumerState<_BesleSayfasi> createState() => _BesleState();
}

class _BesleState extends ConsumerState<_BesleSayfasi> {
  final _tutar = TextEditingController();
  bool _gonderiliyor = false;

  @override
  void dispose() {
    _tutar.dispose();
    super.dispose();
  }

  Future<void> _ver(double fiyat) async {
    final v = parseSayi(_tutar.text);
    if (v == null || _gonderiliyor) return;
    setState(() => _gonderiliyor = true);
    final h = Hareket(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      tur: widget.tur,
      tarih: DateTime.now(),
      tutarTl: v,
      birimFiyat: fiyat,
    );
    await ref.read(hareketlerProvider.notifier).ekle(h);
    final yeni = await _cikartmalariKontrolEt();
    ref.read(dokunsalProvider).cal(Dokunus.onay);
    if (mounted) Navigator.of(context).pop(BeslemeSonucu(yeni));
  }

  /// Davranış çıkartmaları — tek yerden, besleme sonrası. İlk yeni açılanın
  /// adını döner (birden fazlası aynı anda açılırsa diğerleri sessizce açılır,
  /// listede görünür).
  Future<String?> _cikartmalariKontrolEt() async {
    final l = context.l10n;
    final hareketler = ref.read(hareketlerProvider);
    final k = ref.read(karakterlerProvider);
    final cik = ref.read(cikartmalarProvider.notifier);
    String? ilk;
    Future<void> dene(String id, bool kosul) async {
      if (!kosul) return;
      if (await cik.ac(id)) {
        final c = Cikartma.bul(id);
        if (c != null) ilk ??= l.cikartmaAd(c);
      }
    }

    int sayi(VarlikTuru t) => hareketler.where((h) => h.tur == t).length;
    await dene('ilk_besleme', hareketler.isNotEmpty);
    await dene('tortu_sapka', sayi(VarlikTuru.altin) >= 3);
    await dene('zipzip_atki', sayi(VarlikTuru.dolar) >= 3);
    await dene('baykus_gozluk', sayi(VarlikTuru.euro) >= 3);
    await dene('sincap_fular', sayi(VarlikTuru.nakit) >= 3);
    await dene('takim_tam', k.values.every((d) => !d.bos));
    // Düzenlilik: tutar değil, kaç farklı haftada beslendi (bkz. Cikartma).
    final haftalar = Cikartma.farkliHaftalar(hareketler.map((h) => h.tarih));
    await dene('ates_1000', haftalar >= Cikartma.atesHafta);
    await dene('ates_5000', haftalar >= Cikartma.senlikHafta);
    final tortuHaftalar = Cikartma.farkliHaftalar(
        hareketler.where((h) => h.tur == VarlikTuru.altin).map((h) => h.tarih));
    await dene('tortu_parlak', tortuHaftalar >= Cikartma.tortuHafta);
    final ilkTarih = hareketler.isEmpty ? null : hareketler.map((h) => h.tarih).reduce((a, b) => a.isBefore(b) ? a : b);
    await dene('sabir_30', ilkTarih != null && DateTime.now().difference(ilkTarih).inDays >= 30);
    return ilk;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final fiyatlar = ref.watch(fiyatProvider).valueOrNull;
    final fiyat = fiyatlar?.fiyat(widget.tur, cocuk.para);
    final ad = l.karakter(widget.tur);
    final tutar = parseSayi(_tutar.text);
    final birim = l.birim(widget.tur, cocuk.para);

    return Padding(
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
          Row(children: [
            Karakter(tur: widget.tur, ruh: Ruh.mutlu, boyut: 64),
            const SizedBox(width: Bosluk.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.besleBaslik(ad, widget.tur.name), style: context.t.titleLarge),
                if (fiyat != null && !widget.tur.nakitMi)
                  Text(l.besleBugunFiyat(birim, fmtPara(fiyat, cocuk.para)), style: context.t.bodyMedium),
                if (fiyat == null) Text(l.besleFiyatYok, style: context.t.bodyMedium?.copyWith(color: r.loss)),
              ]),
            ),
          ]),
          const SizedBox(height: Bosluk.xl),
          Text(l.besleTutar, style: context.t.titleMedium),
          const SizedBox(height: Bosluk.s),
          TextField(
            controller: _tutar,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: context.t.displaySmall,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => fiyat != null ? _ver(fiyat) : null,
            decoration: InputDecoration(
              prefixText: '${cocuk.para.sembol} ',
              prefixStyle: context.t.displaySmall?.copyWith(color: r.sub),
              hintText: '0',
              filled: true,
              fillColor: r.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.acc, width: 2)),
            ),
          ),
          const SizedBox(height: Bosluk.s),
          Wrap(
            spacing: Bosluk.s,
            children: [
              for (final v in _hizliTutarlar(cocuk.para))
                SecimCipi(
                  metin: fmtPara(v, cocuk.para),
                  secili: tutar == v,
                  onTap: () => setState(() => _tutar.text = v.toInt().toString()),
                ),
            ],
          ),
          const SizedBox(height: Bosluk.l),
          AnimatedSwitcher(
            duration: Devinim.sure(context, Devinim.normal),
            child: (tutar != null && fiyat != null && !widget.tur.nakitMi)
                ? Text(
                    l.besleAlir(fmtPara(tutar, cocuk.para), fmtMiktar(tutar / fiyat, birim, cocuk.para)),
                    key: ValueKey(tutar),
                    style: context.t.titleMedium?.copyWith(color: r.acc),
                  )
                : const SizedBox(height: 24),
          ),
          const SizedBox(height: Bosluk.l),
          AnaDugme(
            metin: l.besleVer(ad),
            onTap: (tutar != null && fiyat != null && !_gonderiliyor) ? () => _ver(fiyat) : null,
          ),
        ],
      ),
    );
  }

  /// Hızlı tutarlar ev birimine göre: TRY için 50/100/250/500, diğerleri 5/10/25/50.
  List<double> _hizliTutarlar(ParaBirimi p) =>
      p == ParaBirimi.tryy ? const [50, 100, 250, 500] : const [5, 10, 25, 50];
}
