import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

/// Kumbaradan aldım (Ar-Ge raporu 2026-10-23 #1): gerçek kumbaradan para
/// çıkınca çocuk yazar, uygulama gerçeği bırakmaz.
///
/// Karakter dili: harcamak kötü değil. Karakter sevinçle uğurlar ("iyi
/// kullan"), sebep sormaz, üzülmez; ateş ve evre küçülmez (bkz. [Hareket],
/// `Odun`). Tutar bugünkü fiyatla miktara çevrilir; fiyat yoksa düğme
/// kapalı (uydurma sayı yasağı, besleme ile aynı kural). Kumbaradakinden
/// fazlası alınamaz.
///
/// Kaydedildiyse true döner.
Future<bool?> kumbaradanAlGoster(BuildContext context, VarlikTuru tur) =>
    altSayfaGoster<bool>(context, _AlSayfasi(tur: tur));

class _AlSayfasi extends ConsumerStatefulWidget {
  const _AlSayfasi({required this.tur});
  final VarlikTuru tur;
  @override
  ConsumerState<_AlSayfasi> createState() => _AlState();
}

class _AlState extends ConsumerState<_AlSayfasi> {
  final _tutar = TextEditingController();
  bool _hepsi = false;
  bool _gonderiliyor = false;

  @override
  void dispose() {
    _tutar.dispose();
    super.dispose();
  }

  Future<void> _al(double fiyat, KarakterDurumu d) async {
    final v = parseSayi(_tutar.text);
    if (v == null || v <= 0 || _gonderiliyor) return;
    setState(() => _gonderiliyor = true);
    // "Hepsi": miktarın tamamı çıkar ki yuvarlanmış tutardan kırıntı kalmasın.
    final tutar = _hepsi ? d.miktar * fiyat : v;
    await ref.read(hareketlerProvider.notifier).ekle(Hareket(
          id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
          tur: widget.tur,
          tarih: DateTime.now(),
          tutarTl: -tutar,
          birimFiyat: fiyat,
        ));
    ref.read(dokunsalProvider).cal(Dokunus.onay);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final d = ref.watch(karakterlerProvider)[widget.tur]!;
    final fiyat = ref.watch(fiyatProvider).valueOrNull?.fiyat(widget.tur, cocuk.para);
    final deger = fiyat == null ? null : d.miktar * fiyat;
    final ad = l.karakter(widget.tur);
    final tutar = parseSayi(_tutar.text);
    // Kuruş yuvarlaması "hepsi"yi "fazla" saydırmasın.
    final fazla = tutar != null && deger != null && tutar > deger + 0.005;
    final gecerli = tutar != null && tutar > 0 && !fazla && fiyat != null;

    // Kaydırılır: büyük yazıda (3,1×) klavyeyle birlikte sığmaz.
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
          Row(children: [
            Karakter(tur: widget.tur, ruh: Ruh.mutlu, boyut: 64),
            const SizedBox(width: Bosluk.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.cikisBaslik, style: context.t.titleLarge),
                Text(l.cikisAlt(ad), style: context.t.bodyMedium),
              ]),
            ),
          ]),
          const SizedBox(height: Bosluk.l),
          if (deger != null)
            Text(l.cikisKumbarada(fmtPara(deger, cocuk.para)), style: context.t.titleMedium)
          else
            Text(l.besleFiyatYok, style: context.t.bodyMedium?.copyWith(color: r.loss)),
          const SizedBox(height: Bosluk.s),
          TextField(
            controller: _tutar,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: context.t.displaySmall,
            onChanged: (_) => setState(() => _hepsi = false),
            onSubmitted: (_) => gecerli ? _al(fiyat, d) : null,
            decoration: InputDecoration(
              prefixText: '${cocuk.para.sembol} ',
              prefixStyle: context.t.displaySmall?.copyWith(color: r.sub),
              hintText: '0',
              errorText: fazla ? l.cikisFazla : null,
              filled: true,
              fillColor: r.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.acc, width: 2)),
            ),
          ),
          const SizedBox(height: Bosluk.s),
          if (deger != null)
            Wrap(spacing: Bosluk.s, children: [
              SecimCipi(
                metin: l.cikisHepsi,
                secili: _hepsi,
                onTap: () => setState(() {
                  _tutar.text = _yazi(deger, cocuk.para);
                  _hepsi = true;
                }),
              ),
            ]),
          const SizedBox(height: Bosluk.xl),
          AnaDugme(
            metin: l.cikisDugme,
            onTap: (gecerli && !_gonderiliyor) ? () => _al(fiyat, d) : null,
          ),
        ],
      ),
    );
  }

  /// Alana yazılacak tutar: kuruşa yuvarlanmış, aşağı (fazla görünmesin).
  /// Binlik ayırıcı yok ki [parseSayi] ondalığı karıştırmasın.
  String _yazi(double v, ParaBirimi p) => NumberFormat('0.##', p.yerel).format((v * 100).floor() / 100);
}
