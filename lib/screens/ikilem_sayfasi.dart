import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/ders.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

/// Sincap'ın ikilemi (Ar-Ge raporu 2026-10-23 11:07, yol haritası 3.6'nın
/// ilk adımı): ilk kumbaradan almadan hemen sonra, bir kez.
///
/// Gerçek harcama anı "ihtiyaç ve istek" dersinin en çok işe yaradığı an.
/// Ama soru çocuğun harcaması hakkında DEĞİL — "aldığın şey istek miydi?"
/// sorgu gibi gelir (rapordaki çocuk ve veli gözü). Soruyu karakter kendine
/// sorar; iki seçenek de sıcak karşılanır, yanlış cevap yok, puan yok.
/// Ardından o ders (id `ihtiyac`) sırası beklenmeden burada okunur; Öğren
/// sekmesindeki sıra sayacına dokunulmaz, ders orada yine yerinde gelir.
///
/// Tekrar etmez: sayaç değil, yalnız "gösterildi" bilgisi ([Depo]). Bayrak
/// gösterimden ÖNCE yazılır ki sayfa yarıda kapansa da ikinci kez çıkmasın.
Future<void> ikilemGosterGerekirse(BuildContext context, WidgetRef ref) async {
  final depo = ref.read(depoProvider);
  if (depo.ikilemGosterildiOku()) return;
  await depo.ikilemGosterildiYaz();
  if (!context.mounted) return;
  await altSayfaGoster<void>(context, const _IkilemSayfasi());
}

class _IkilemSayfasi extends ConsumerStatefulWidget {
  const _IkilemSayfasi();
  @override
  ConsumerState<_IkilemSayfasi> createState() => _IkilemState();
}

class _IkilemState extends ConsumerState<_IkilemSayfasi> {
  /// null: henüz seçilmedi; true: istek (palamut); false: ihtiyaç (tahta).
  bool? _istek;
  Ders? _ders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ders != null) return;
    final dil = Localizations.localeOf(context).languageCode;
    Ders.yukle(dil).then((liste) {
      final d = liste.where((x) => x.id == 'ihtiyac').firstOrNull;
      if (mounted && d != null) setState(() => _ders = d);
    }).catchError((_) {
      // Ders dosyası okunamazsa sayfa dersiz de anlamlı: sessiz geç.
    });
  }

  void _sec(bool istek) {
    ref.read(dokunsalProvider).cal(Dokunus.secim);
    setState(() => _istek = istek);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final ad = l.karakter(VarlikTuru.nakit);
    final ders = _ders;

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
            Karakter(tur: VarlikTuru.nakit, ruh: Ruh.mutlu, boyut: 64),
            const SizedBox(width: Bosluk.m),
            Expanded(child: Text(l.ikilemBaslik(ad), style: context.t.titleLarge)),
          ]),
          const SizedBox(height: Bosluk.l),
          Text(l.ikilemSoru(ad), style: context.t.bodyLarge),
          const SizedBox(height: Bosluk.l),
          if (_istek == null) ...[
            AnaDugme(metin: l.ikilemIstek, ikincil: true, onTap: () => _sec(true)),
            const SizedBox(height: Bosluk.s),
            AnaDugme(metin: l.ikilemIhtiyac, ikincil: true, onTap: () => _sec(false)),
          ] else ...[
            Kart(
              child: Text(_istek! ? l.ikilemIstekCevap : l.ikilemIhtiyacCevap, style: context.t.titleMedium),
            ),
            if (ders != null) ...[
              const SizedBox(height: Bosluk.l),
              Text(Ders.paraYerlestir(ders.baslik, cocuk.para), style: context.t.titleLarge),
              const SizedBox(height: Bosluk.s),
              Text(Ders.paraYerlestir(ders.metin(cocuk.yas), cocuk.para), style: context.t.bodyLarge),
            ],
            const SizedBox(height: Bosluk.xl),
            AnaDugme(metin: l.ikilemTamam, onTap: () => Navigator.of(context).pop()),
          ],
        ],
      ),
    );
  }
}
