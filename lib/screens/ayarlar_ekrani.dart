import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/l10n.dart';
import '../models/cocuk.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/depo.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/ortak.dart';

final _surumProvider = FutureProvider<String>((_) async {
  final p = await PackageInfo.fromPlatform();
  return '${p.version} (${p.buildNumber})';
});

/// Ayarlar: kamp yeri, yaş modu, para birimi, dil; veli köşesi PIN ardında.
class AyarlarEkrani extends ConsumerWidget {
  const AyarlarEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final n = ref.read(cocukProvider.notifier);
    final surum = ref.watch(_surumProvider).valueOrNull;
    final sesAcik = ref.watch(sesAcikProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.m, Bosluk.xl, Bosluk.dev),
      children: [
        Text(l.ayarlarBaslik, style: context.t.headlineMedium),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarDunya),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
          for (final d in Dunya.values)
            SecimCipi(
              metin: l.dunya(d),
              secili: cocuk.dunya == d,
              onTap: () {
                HapticFeedback.selectionClick();
                n.guncelle((c) => c.copyWith(dunya: d));
              },
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarYas),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          for (final y in YasModu.values)
            SecimCipi(
              metin: y == YasModu.kucuk ? l.yasKucuk : l.yasBuyuk,
              secili: cocuk.yas == y,
              onTap: () => n.guncelle((c) => c.copyWith(yas: y)),
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        // Sesler: sessiz anahtarı zaten susturur (ambient oturum); bu seçim
        // telefon sesi açıkken de kapatmak isteyen için.
        BolumBasligi(l.ayarlarSes),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          for (final v in const [true, false])
            SecimCipi(
              metin: v ? l.sesAcik : l.sesKapali,
              secili: sesAcik == v,
              onIkon: Icon(v ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  size: 18, color: sesAcik == v ? r.accInk : r.fg),
              onTap: () => ref.read(sesAcikProvider.notifier).ayarla(v),
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarDil),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          SecimCipi(metin: l.dilCihaz, secili: cocuk.dil == null, onTap: () => n.kaydet(_dilsiz(cocuk))),
          SecimCipi(metin: 'Türkçe', secili: cocuk.dil == 'tr', onTap: () => n.guncelle((c) => c.copyWith(dil: 'tr'))),
          SecimCipi(metin: 'English', secili: cocuk.dil == 'en', onTap: () => n.guncelle((c) => c.copyWith(dil: 'en'))),
        ]),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarPara),
        const SizedBox(height: Bosluk.s),
        Text(cocuk.para.kod, style: context.t.titleMedium),
        const SizedBox(height: Bosluk.xs),
        // Para birimi değişimi beslemelerin birimini de değiştirir (tutarlar ev
        // biriminde saklı). Bu yüzden yalnız veli köşesinden, hareket yokken.
        Text(l.ayarlarKaynak, style: context.t.bodySmall?.copyWith(color: r.sub)),
        const SizedBox(height: Bosluk.xl),
        Kart(
          onTap: () => _veliKosesi(context, ref),
          child: Row(children: [
            Icon(Icons.lock_outline_rounded, color: r.fg),
            const SizedBox(width: Bosluk.m),
            Expanded(child: Text(l.ayarlarVeli, style: context.t.titleMedium)),
            Icon(Icons.chevron_right_rounded, color: r.sub),
          ]),
        ),
        const SizedBox(height: Bosluk.xl),
        if (surum != null)
          Text(l.ayarlarSurum(surum), textAlign: TextAlign.center, style: context.t.bodySmall?.copyWith(color: r.sub)),
      ],
    );
  }

  Cocuk _dilsiz(Cocuk c) => Cocuk(
        ad: c.ad, yas: c.yas, dunya: c.dunya, pinOzeti: c.pinOzeti, olusturma: c.olusturma, para: c.para, dil: null);

  Future<void> _veliKosesi(BuildContext context, WidgetRef ref) async {
    final cocuk = ref.read(cocukProvider)!;
    if (cocuk.veliKilidiVar) {
      final gecti = await pinSor(context, cocuk.pinOzeti!);
      if (gecti != true || !context.mounted) return;
    }
    if (!context.mounted) return;
    await altSayfaGoster(context, const _VeliKosesi());
  }
}

/// PIN sorgusu: 4 hane, yanlışta titreme yok (çocuk görebilir), kısa mesaj.
Future<bool?> pinSor(BuildContext context, String ozet) {
  return altSayfaGoster<bool>(context, _PinSayfasi(ozet: ozet));
}

class _PinSayfasi extends StatefulWidget {
  const _PinSayfasi({required this.ozet});
  final String ozet;
  @override
  State<_PinSayfasi> createState() => _PinSayfasiState();
}

class _PinSayfasiState extends State<_PinSayfasi> {
  final _c = TextEditingController();
  bool _hata = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.all(Bosluk.xl),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.kilitBaslik, style: context.t.titleLarge),
        const SizedBox(height: Bosluk.l),
        TextField(
          controller: _c,
          autofocus: true,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: context.t.headlineMedium?.copyWith(letterSpacing: 10),
          decoration: InputDecoration(
            counterText: '',
            errorText: _hata ? l.kilitYanlis : null,
            filled: true,
            fillColor: r.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
          ),
          onChanged: (v) {
            if (v.length == 4) {
              if (Depo.pinOzeti(v) == widget.ozet) {
                Navigator.of(context).pop(true);
              } else {
                HapticFeedback.heavyImpact();
                setState(() {
                  _hata = true;
                  _c.clear();
                });
              }
            } else if (_hata) {
              setState(() => _hata = false);
            }
          },
        ),
        const SizedBox(height: Bosluk.l),
      ]),
    );
  }
}

class _VeliKosesi extends ConsumerWidget {
  const _VeliKosesi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider);
    if (cocuk == null) return const SizedBox.shrink();
    final hareketler = ref.watch(hareketlerProvider);
    final toplam = ref.watch(toplamProvider);
    return Padding(
      padding: const EdgeInsets.all(Bosluk.xl),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.veliBaslik, style: context.t.titleLarge),
        const SizedBox(height: Bosluk.s),
        Text(
          l.veliOzet(cocuk.ad, hareketler.length, fmtPara(toplam.degerTl ?? toplam.maliyetTl, cocuk.para)),
          style: context.t.bodyLarge,
        ),
        const SizedBox(height: Bosluk.s),
        Text(l.veliNot, style: context.t.bodyMedium),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarPara),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
          for (final p in ParaBirimi.values)
            SecimCipi(
              metin: '${p.sembol} ${p.kod}',
              secili: cocuk.para == p,
              // Hareket varken birim değişmez: eski tutarlar başka birimde kalırdı.
              onTap: hareketler.isEmpty ? () => ref.read(cocukProvider.notifier).guncelle((c) => c.copyWith(para: p)) : () {},
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        AnaDugme(
          metin: cocuk.veliKilidiVar ? l.veliPinDegistir : l.kilitKur,
          ikincil: true,
          onTap: () async {
            final yeni = await _pinOlustur(context);
            if (yeni != null) {
              await ref.read(cocukProvider.notifier).guncelle((c) => c.copyWith(pinOzeti: Depo.pinOzeti(yeni)));
            }
          },
        ),
        const SizedBox(height: Bosluk.s),
        Basilabilir(
          onTap: () async {
            final onay = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(l.veliSil),
                content: Text(l.veliSilOnay),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.iptal)),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.veliSilOnayDugme)),
                ],
              ),
            );
            if (onay == true && context.mounted) {
              Navigator.of(context).pop();
              await ref.read(cocukProvider.notifier).hepsiniSil();
            }
          },
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Kose.m),
              border: Border.all(color: r.loss),
            ),
            child: Text(l.veliSil, style: context.t.titleMedium?.copyWith(color: r.loss)),
          ),
        ),
      ]),
    );
  }

  Future<String?> _pinOlustur(BuildContext context) async {
    final l = context.l10n;
    final c = TextEditingController();
    final sonuc = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.kilitKur),
        content: TextField(
          controller: c,
          autofocus: true,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: l.veliPinIpucu, counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.iptal)),
          TextButton(onPressed: () => Navigator.pop(d, c.text.length == 4 ? c.text : null), child: Text(l.devam)),
        ],
      ),
    );
    c.dispose();
    return sonuc;
  }
}
