import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../models/cocuk.dart';
import '../models/geri_bildirim.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/depo.dart';
import '../services/dokunsal.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/ortak.dart';

import 'gizlilik_sayfasi.dart';

final _surumProvider = FutureProvider<String>((_) async {
  final p = await PackageInfo.fromPlatform();
  return '${p.version} (${p.buildNumber})';
});

/// Ayarlar: çocuk tarafında yalnız zararsız seçimler (kamp yeri, ses,
/// titreşim, görünüm). Dil, yaş modu ve para birimi veli köşesinde, PIN
/// ardında (Ar-Ge 25 Eki): çocuk bir dokunuşla uygulamayı okuyamadığı bir
/// dile çevirip geri dönemiyordu; "Büyük" yaş modu yüzde gösterir, seçimi veliye ait.
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
    final titresimAcik = ref.watch(titresimAcikProvider);
    final ucBoyut = ref.watch(karakter3dProvider);

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
                ref.read(dokunsalProvider).cal(Dokunus.secim);
                n.guncelle((c) => c.copyWith(dunya: d));
              },
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
        // Titreşim ayrı seçim: sesi açık tutup titreşimi kapatmak isteyen
        // (ya da tersi) için. Açılınca bir kez tıklar ki farkı hissedilsin.
        BolumBasligi(l.ayarlarTitresim),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          for (final v in const [true, false])
            SecimCipi(
              metin: v ? l.sesAcik : l.sesKapali,
              secili: titresimAcik == v,
              onIkon: Icon(v ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                  size: 18, color: titresimAcik == v ? r.accInk : r.fg),
              onTap: () async {
                await ref.read(titresimAcikProvider.notifier).ayarla(v);
                if (v) ref.read(dokunsalProvider).cal(Dokunus.secim);
              },
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        // Karakter görünümü: 3D deneme; varsayılan klasik (2D).
        BolumBasligi(l.ayarlarGorunum),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
          for (final v in const [false, true])
            SecimCipi(
              metin: v ? l.gorunum3d : l.gorunumKlasik,
              secili: ucBoyut == v,
              onTap: () {
                ref.read(dokunsalProvider).cal(Dokunus.secim);
                ref.read(karakter3dProvider.notifier).ayarla(v);
              },
            ),
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
        const SizedBox(height: Bosluk.s),
        Kart(
          onTap: () => gizlilikGoster(context),
          child: Row(children: [
            Icon(Icons.privacy_tip_outlined, color: r.fg),
            const SizedBox(width: Bosluk.m),
            Expanded(child: Text(l.ayarlarGizlilik, style: context.t.titleMedium)),
            Icon(Icons.chevron_right_rounded, color: r.sub),
          ]),
        ),
        const SizedBox(height: Bosluk.xl),
        if (surum != null)
          Text(l.ayarlarSurum(surum), textAlign: TextAlign.center, style: context.t.bodySmall?.copyWith(color: r.sub)),
      ],
    );
  }

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

Cocuk _dilsiz(Cocuk c) => Cocuk(
    ad: c.ad, yas: c.yas, dunya: c.dunya, pinOzeti: c.pinOzeti, olusturma: c.olusturma, para: c.para, dil: null);

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
    return SingleChildScrollView(
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
                dokunsalCal(context, Dokunus.hata);
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
    // Kaydırılır: büyük yazıda (Dynamic Type 2×+) sayfa ekrana sığmıyordu.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Bosluk.xl),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.veliBaslik, style: context.t.titleLarge),
        const SizedBox(height: Bosluk.s),
        Text(
          l.veliOzet(cocuk.ad, hareketler.beslemeler.length, fmtPara(toplam.degerTl ?? toplam.maliyetTl, cocuk.para)),
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
        if (hareketler.isNotEmpty) ...[
          const SizedBox(height: Bosluk.xs),
          Text(l.karsilamaParaNot, style: context.t.bodySmall?.copyWith(color: r.sub)),
        ],
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarYas),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          for (final y in YasModu.values)
            SecimCipi(
              metin: y == YasModu.kucuk ? l.yasKucuk : l.yasBuyuk,
              secili: cocuk.yas == y,
              onTap: () => ref.read(cocukProvider.notifier).guncelle((c) => c.copyWith(yas: y)),
            ),
        ]),
        const SizedBox(height: Bosluk.xl),
        BolumBasligi(l.ayarlarDil),
        const SizedBox(height: Bosluk.s),
        Wrap(spacing: Bosluk.s, children: [
          SecimCipi(metin: l.dilCihaz, secili: cocuk.dil == null, onTap: () => ref.read(cocukProvider.notifier).kaydet(_dilsiz(cocuk))),
          // Liste desteklenen dillerden üretilir: yeni .arb eklenince seçenek
          // kendiliğinden gelir.
          for (final d in AppLocalizations.supportedLocales)
            SecimCipi(
              metin: dilAdlari[d.languageCode] ?? d.languageCode,
              secili: cocuk.dil == d.languageCode,
              onTap: () => ref.read(cocukProvider.notifier).guncelle((c) => c.copyWith(dil: d.languageCode)),
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
        // Paylaşım uygulama dışına çıkar: Apple Kids ebeveyn kapısı ister.
        // PIN yoksa önce kurdurulur (veli köşesi PIN'siz de açılabiliyor).
        AnaDugme(
          metin: l.geriBildirim,
          ikincil: true,
          onTap: () async {
            if (!cocuk.veliKilidiVar) {
              bildir(context, l.geriBildirimKilitGerek);
              return;
            }
            await altSayfaGoster(context, const _GeriBildirimSayfasi());
          },
        ),
        const SizedBox(height: Bosluk.l),
        // Veri nerede durur: gizlilik politikası madde 1 ile aynı bilgi, silme
        // düğmesinin hemen üstünde (veli "her şey silindi mi?" diye sorar).
        Text(l.veliYedekNot, style: context.t.bodyMedium?.copyWith(color: r.sub)),
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

/// Veli onaylı geri bildirim: gönderilecek metin olduğu gibi görünür, üç
/// isteğe bağlı soru, sistem paylaşım sayfası (alıcıyı veli seçer). Metin
/// [geriBildirimMetni]'nden gelir; ad ve tutar içermez.
class _GeriBildirimSayfasi extends ConsumerStatefulWidget {
  const _GeriBildirimSayfasi();
  @override
  ConsumerState<_GeriBildirimSayfasi> createState() => _GeriBildirimState();
}

class _GeriBildirimState extends ConsumerState<_GeriBildirimSayfasi> {
  final _cevaplar = List.generate(3, (_) => TextEditingController());
  final _paylasAnahtar = GlobalKey();

  @override
  void dispose() {
    for (final c in _cevaplar) {
      c.dispose();
    }
    super.dispose();
  }

  String _metin(AppLocalizations l, {bool cevapli = true}) {
    final cocuk = ref.read(cocukProvider)!;
    return geriBildirimMetni(
      l: l,
      cocuk: cocuk,
      hareketler: ref.read(hareketlerProvider),
      odun: ref.read(odunProvider),
      ders: ref.read(dersIlerlemeProvider),
      cikartma: ref.read(cikartmalarProvider).length,
      ucBoyut: ref.read(karakter3dProvider),
      surum: ref.read(_surumProvider).valueOrNull,
      dil: Localizations.localeOf(context).languageCode,
      simdi: DateTime.now(),
      cevaplar: cevapli ? [for (final c in _cevaplar) c.text] : const [],
    );
  }

  Future<void> _paylas(AppLocalizations l) async {
    final kutu = _paylasAnahtar.currentContext?.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: _metin(l),
      subject: l.geriBildirimKonu,
      // iPad'de paylaşım balonu düğmeden çıkar.
      sharePositionOrigin: kutu == null ? null : kutu.localToGlobal(Offset.zero) & kutu.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    // Özet sayfa açıkken değişmez; yalnız cevaplar değişir (onlar alanlarda).
    ref.watch(_surumProvider);
    final ozet = _metin(l, cevapli: false);
    InputDecoration alan(String ipucu) => InputDecoration(
          labelText: ipucu,
          filled: true,
          fillColor: r.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Bosluk.xl),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.geriBildirim, style: context.t.titleLarge),
        const SizedBox(height: Bosluk.s),
        Text(l.geriBildirimAciklama, style: context.t.bodyMedium),
        const SizedBox(height: Bosluk.l),
        BolumBasligi(l.geriBildirimOzet),
        const SizedBox(height: Bosluk.s),
        Kart(child: Text(ozet, style: context.t.bodyMedium)),
        const SizedBox(height: Bosluk.l),
        for (final (i, soru) in [l.geriBildirimSoru1, l.geriBildirimSoru2, l.geriBildirimSoru3].indexed) ...[
          TextField(controller: _cevaplar[i], maxLines: null, textCapitalization: TextCapitalization.sentences, decoration: alan(soru)),
          const SizedBox(height: Bosluk.m),
        ],
        const SizedBox(height: Bosluk.s),
        KeyedSubtree(
          key: _paylasAnahtar,
          child: AnaDugme(metin: l.geriBildirimPaylas, onTap: () => _paylas(l)),
        ),
      ]),
    );
  }
}
