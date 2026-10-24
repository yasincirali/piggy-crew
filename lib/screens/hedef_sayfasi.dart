import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/hedef.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';

/// Hedef seç (yol haritası 2.1): eşya + yaklaşık fiyat. Fiyat yalnız burada
/// görünür; kartta eşya dolar (bkz. [Hedef]). Var olan hedef açılırsa
/// değiştirilir ya da kaldırılır. Fiyat değişirse "ulaşıldı" sıfırlanır ki
/// yeni hedef yeniden sevinsin; aynı kalırsa korunur.
Future<void> hedefGoster(BuildContext context, VarlikTuru tur) => altSayfaGoster<void>(context, _HedefSayfasi(tur: tur));

class _HedefSayfasi extends ConsumerStatefulWidget {
  const _HedefSayfasi({required this.tur});
  final VarlikTuru tur;
  @override
  ConsumerState<_HedefSayfasi> createState() => _HedefState();
}

class _HedefState extends ConsumerState<_HedefSayfasi> {
  final _fiyat = TextEditingController();
  HedefEsya? _esya;
  Hedef? _eski;

  @override
  void initState() {
    super.initState();
    _eski = ref.read(hedeflerProvider)[widget.tur];
    // Ulaşılmış hedef "Yeni hedef" ile açılır: boş başlar.
    if (_eski != null && _eski!.ulasildi == null) {
      _esya = _eski!.esya;
      _fiyat.text = NumberFormat('0.##', ref.read(cocukProvider)!.para.yerel).format(_eski!.fiyatTl);
    }
  }

  @override
  void dispose() {
    _fiyat.dispose();
    super.dispose();
  }

  Future<void> _kaydet(double fiyat) async {
    final esya = _esya!;
    final eski = _eski;
    final ayni = eski != null && eski.esya == esya && eski.fiyatTl == fiyat;
    await ref.read(hedeflerProvider.notifier).koy(widget.tur, ayni ? eski : Hedef(esya: esya, fiyatTl: fiyat));
    ref.read(dokunsalProvider).cal(Dokunus.onay);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _kaldir() async {
    await ref.read(hedeflerProvider.notifier).kaldir(widget.tur);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final fiyat = parseSayi(_fiyat.text);
    final gecerli = _esya != null && fiyat != null;

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
            Expanded(child: Text(l.hedefSayfaBaslik(l.karakter(widget.tur)), style: context.t.titleLarge)),
          ]),
          const SizedBox(height: Bosluk.l),
          Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
            for (final e in HedefEsya.values)
              SecimCipi(
                metin: l.hedefEsyaAdi(e.name),
                secili: _esya == e,
                onIkon: _esya == e ? null : Icon(e.ikon, size: 20, color: r.fg),
                onTap: () => setState(() => _esya = e),
              ),
          ]),
          const SizedBox(height: Bosluk.xl),
          Text(l.hedefFiyat, style: context.t.titleMedium),
          const SizedBox(height: Bosluk.s),
          TextField(
            controller: _fiyat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: context.t.displaySmall,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => gecerli ? _kaydet(fiyat) : null,
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
          Text(l.hedefFiyatNot, style: context.t.bodyMedium?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.xl),
          AnaDugme(metin: l.hedefKaydet, onTap: gecerli ? () => _kaydet(fiyat) : null),
          if (_eski != null) ...[
            const SizedBox(height: Bosluk.s),
            AnaDugme(metin: l.hedefKaldir, ikincil: true, onTap: _kaldir),
          ],
        ],
      ),
    );
  }
}
