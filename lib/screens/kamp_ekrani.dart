import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/donus.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/dokunsal.dart';
import '../services/ses_servisi.dart';
import '../theme/dunya.dart';
import '../utils/bicim.dart';
import '../widgets/avuc_parasi.dart';
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

class _KampState extends ConsumerState<KampEkrani> with WidgetsBindingObserver {
  final _yeme = <VarlikTuru, int>{};
  final _tepki = <VarlikTuru, int>{};
  final _sevinc = <VarlikTuru, int>{};
  bool _aciliyor = false;
  bool _ruhBakiliyor = false;

  /// Geri dönüş karşılaması (karar [donusKarsilamasiGerekli]). [_donus] dört
  /// karakterin ortak tetiği; [_donusSirada]: karar verildi ama kamp o an
  /// görünmüyor (başka sekme ya da üstte sayfa), görününce oynar.
  int _donus = 0;
  bool _donusSirada = false;

  /// Besleme ritüeli: yiyecek avuçta bekler (bkz. [AvucParasi]). Kayıt
  /// "Ver"de yapılmıştır; avuç yalnız sahneyi başlatır.
  final _anahtar = {for (final t in VarlikTuru.values) t: GlobalKey()};
  final _avuc = ValueNotifier<Offset?>(null);
  final _avucAnahtar = GlobalKey<AvucParasiState>();
  final _kaydirma = ScrollController();
  OverlayEntry? _avucGiris;
  VarlikTuru? _avucTur;
  Timer? _donusSesi;
  Timer? _donusSifirla;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _donusDenetle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _donusSesi?.cancel();
    _donusSifirla?.cancel();
    _avucGiris?.remove();
    _avuc.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sekme ya da üstteki sayfa değişince de buraya gelinir (TickerMode ve
    // ModalRoute bağımlılığı): sıradaki karşılama kamp görününce oynar.
    // Görünürlük her seferinde okunur ki sekme/ModalRoute bağımlılığı
    // kaydolsun (okunmazsa sekme değişince buraya hiç gelinmez).
    final gorunur = _gorunur;
    // Soğuk açılışta ilk kareden önce çalışır: karakterler kenarda başlar.
    _donusOynat();
    // Avuçta yiyecek varken kamp gizlendiyse (sekme, üstte sayfa) bekletme: ver.
    if (_avucGiris != null && !gorunur) _avucAnahtar.currentState?.hemenVer();
  }

  // Sekme gizliliği Visibility.of'tan gelir (IndexedStack TickerMode'u kapatmaz).
  bool get _gorunur =>
      TickerMode.valuesOf(context).enabled && Visibility.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _donusDenetle();
      setState(_donusOynat);
    } else if (s == AppLifecycleState.paused) {
      // Yokluk, son ön planda olunan andan ölçülür (açılış anından değil).
      // Yalnız paused: dönüşte de hidden'dan geçilir, orada yazmak yokluğu silerdi.
      ref.read(depoProvider).sonGorulmeYaz(DateTime.now());
    }
  }

  void _donusDenetle() {
    final depo = ref.read(depoProvider);
    final simdi = DateTime.now();
    if (donusKarsilamasiGerekli(sonGorulme: depo.sonGorulmeOku(), sonDonus: depo.sonDonusOku(), simdi: simdi)) {
      _donusSirada = true;
    }
    depo.sonGorulmeYaz(simdi);
  }

  void _donusOynat() {
    if (!_donusSirada || !mounted) return;
    if (!_gorunur) return;
    _donusSirada = false;
    // "Haftada bir" sayacı karşılama gerçekten görününce işler.
    ref.read(depoProvider).sonDonusYaz(DateTime.now());
    _donus++;
    final hareketsiz = MediaQuery.of(context).disableAnimations;
    // Tek ses ve tek mesaj, takımın varış anında (karakter başına değil).
    // Mesaj yokluğu anmaz: yalnız "seni görmek güzel" (karakter dili tüzüğü).
    _donusSesi?.cancel();
    _donusSesi = Timer(hareketsiz ? Duration.zero : const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      ref.read(sesProvider).cal(Ses.yasasin);
      ref.read(dokunsalProvider).cal(Dokunus.sevinc);
      bildir(context, context.l10n.donusKarsilama);
    });
    // Sahne bitince tetik sıfırlanır: yerleşim değişip bir karakter yeniden
    // kurulursa karşılamayı tekrar oynamasın (azalış oynatmaz).
    _donusSifirla?.cancel();
    _donusSifirla = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _donus = 0);
    });
  }

  /// Değeri artıya geçen karakter bir kez sevinir. Önceki hâl cihazda
  /// saklanır; fiyat yüklenmeden önceki hâl sayılmaz (bkz. [bilinenRuhlar]).
  void _artiyaGecisiDenetle(Map<VarlikTuru, KarakterDurumu> k) {
    final simdi = bilinenRuhlar(k.values);
    if (simdi.isEmpty || _ruhBakiliyor) return;
    final depo = ref.read(depoProvider);
    final onceki = depo.sonRuhOku();
    final degisti = simdi.entries.any((e) => onceki[e.key] != e.value);
    if (!degisti) return;
    _ruhBakiliyor = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gecen = artiyaGecenler(onceki, simdi);
      await depo.sonRuhYaz({...onceki, ...simdi});
      _ruhBakiliyor = false;
      if (!mounted || gecen.isEmpty) return;
      setState(() {
        for (final t in gecen) {
          _sevinc[t] = (_sevinc[t] ?? 0) + 1;
        }
      });
    });
  }

  Future<void> _besle(VarlikTuru t) async {
    _avucAnahtar.currentState?.hemenVer();
    final sonuc = await besleGoster(context, ref, t);
    if (sonuc == null || !mounted) return;
    // Hareketi azalt: avuç yok, sahne sesle gelir (bkz. Karakter).
    if (MediaQuery.of(context).disableAnimations) return _beslendi(t, sonuc);
    await _avucaKoy(t, sonuc);
  }

  /// Yiyeceği avuca koyar: alt kenardan yükselir, karakterin yanında bekler.
  Future<void> _avucaKoy(VarlikTuru t, BeslemeSonucu sonuc) async {
    // Sahne görünsün: liste aşağı kaymışsa başa döner.
    if (_kaydirma.hasClients && _kaydirma.offset > 0) {
      await _kaydirma.animateTo(0, duration: Devinim.normal, curve: Devinim.cikis);
    }
    if (!mounted) return;
    final kutu = _anahtar[t]!.currentContext?.findRenderObject();
    if (kutu is! RenderBox || !kutu.hasSize || !_gorunur) return _beslendi(t, sonuc);
    final ekran = MediaQuery.sizeOf(context);
    final olcek = ref.read(evrelerProvider)[t]?.olcek ?? 1;

    // Karakterin çizim alanındaki bir noktanın global yeri (sahne ölçeği ve
    // evre büyüklüğü dahil, ayak tabanından ölçeklenir).
    Rect alan() => Rect.fromPoints(kutu.localToGlobal(Offset.zero), kutu.localToGlobal(kutu.size.bottomRight(Offset.zero)));
    Offset hedef() {
      final a = alan();
      final g = yemekGirisNoktasi[t]!;
      final q = Offset(55 + (g.dx - 55) * olcek, 100 + (g.dy - 100) * olcek);
      return a.topLeft + q * (a.width / 110);
    }

    final a = alan();
    // Avuç karakterin ekran ortasına bakan yanında, kenara taşmadan.
    final yon = ekran.width / 2 >= a.center.dx ? 1.0 : -1.0;
    final bekleme = Offset(
      (a.center.dx + yon * a.width * .95).clamp(AvucParasi.dokunma, ekran.width - AvucParasi.dokunma),
      a.center.dy - a.height * .05,
    );
    final hedefOlcek = yemekYaricap * (a.width / 110) * olcek / (AvucParasi.boyut / 2 * .8);
    final l = context.l10n;
    late final OverlayEntry giris;
    giris = OverlayEntry(
      builder: (_) => AvucParasi(
        key: _avucAnahtar,
        tur: t,
        sembol: ref.read(cocukProvider)!.para.sembol,
        baslangic: Offset(ekran.width / 2, ekran.height + 30),
        bekleme: bekleme,
        hedef: hedef,
        hedefOlcek: hedefOlcek,
        konum: _avuc,
        ses: ref.read(sesProvider).cal,
        dokunsal: ref.read(dokunsalProvider),
        halka: () {
          final g = alan();
          // Gövdenin ortası (ayaklar altta, baş üstte): çizim alanının biraz altı.
          return (g.center + Offset(0, g.height * .06), g.width * .5 * olcek);
        },
        etiket: l.besleVer(l.karakter(t)),
        onVerildi: () => _sonra(() {
          giris.remove();
          if (_avucGiris == giris) _avucGiris = null;
          if (!mounted) return;
          setState(() => _avucTur = null);
          _beslendi(t, sonuc);
        }),
      ),
    );
    _avucGiris = giris;
    setState(() => _avucTur = t);
    Overlay.of(context, rootOverlay: true).insert(giris);
  }

  /// Kare çizilirken ağaç değiştirilmez: o anda gelen çağrı kare sonuna kalır.
  void _sonra(VoidCallback f) {
    final faz = SchedulerBinding.instance.schedulerPhase;
    if (faz == SchedulerPhase.idle || faz == SchedulerPhase.postFrameCallbacks) {
      f();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => f());
    }
  }

  void _beslendi(VarlikTuru t, BeslemeSonucu sonuc) {
    setState(() => _yeme[t] = (_yeme[t] ?? 0) + 1);
    if (sonuc.yeniCikartma != null) {
      // Çıkartma sesi yeme sahnesinin arpejinden sonra gelsin, üst üste binmesin.
      Future.delayed(yemeSuresi + const Duration(milliseconds: 100), () {
        ref.read(sesProvider).cal(Ses.cikartma);
        ref.read(dokunsalProvider).cal(Dokunus.cikartma);
      });
    }
    bildir(context, sonuc.mesaj(context.l10n, t));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.r;
    final cocuk = ref.watch(cocukProvider)!;
    final k = ref.watch(karakterlerProvider);
    final toplam = ref.watch(toplamProvider);
    final fiyat = ref.watch(fiyatProvider);
    _artiyaGecisiDenetle(k);
    final gorunur = k.keys.toList();
    final bos = toplam.maliyetTl <= 0;

    final sol = gorunur.where((t) => t != VarlikTuru.altin).toList();
    // Yerleşim: üst satır (Baykuş · ateş · Zıpzıp), alt satır (Tortu büyük · Sincap).
    // Ev birimi dolar/euro ise bir karakter eksik; kalanlar sırayla doldurur.
    // Geri dönüşte her karakter kendi yakın kenarından, sırayla (60 ms ara) gelir.
    final ust = sol.take(2).toList();
    final alt = sol.skip(2).toList();

    Widget karakter(
      VarlikTuru t, {
      double boyut = 92,
      Duration gecikme = Duration.zero,
      double donusYon = -1,
      Duration donusGecikme = Duration.zero,
    }) {
      final d = k[t]!;
      final cik = ref.watch(cikartmalarProvider);
      return Basilabilir(
        semantik: '${l.karakter(t)}, ${l.varlik(t)}',
        // Dokununca önce karakter tepki verir (ses + zıplama), detay ardından
        // açılır: tepki görünsün diye kısa bekleme. Çift dokunma iki sayfa
        // açmasın diye bekleme sırasında yeni dokunma yalnız tepki verir.
        onTap: () {
          // Avuçta bu karakterin yiyeceği varken karaktere dokunmak = ver.
          if (_avucTur == t) return _avucAnahtar.currentState?.ver();
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
            key: _anahtar[t],
            tur: t,
            ruh: d.ruh,
            boyut: boyut,
            gecikme: gecikme,
            yemeTetik: _yeme[t] ?? 0,
            tepkiTetik: _tepki[t] ?? 0,
            sevincTetik: _sevinc[t] ?? 0,
            bosta: true,
            ses: ref.read(sesProvider).cal,
            dokun: ref.read(dokunsalProvider).cal,
            pulSayisi: t == VarlikTuru.altin ? (d.verilenTl / 250).floor().clamp(0, 3) : 0,
            parlak: t == VarlikTuru.altin && cik.contains('tortu_parlak'),
            evre: ref.watch(evrelerProvider)[t],
            evreKutla: true,
            donusTetik: _donus,
            donusYon: donusYon,
            donusGecikme: donusGecikme,
            avuc: _avucTur == t ? _avuc : null,
          ),
          // Karakterin kendi farkı burada yazılmaz (Ar-Ge 24 Eki 11:07 #2): ekranda
          // en fazla iki sayı, toplam ve fark. Değişimi yüz ve hava durumu anlatır;
          // tutar karakter ekranında.
          Text(l.karakter(t), style: context.t.labelLarge),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fiyatProvider.notifier).yenile(),
      color: r.acc,
      child: ListView(
        controller: _kaydirma,
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
                        // Ateş odunla büyür, tutarla değil: piyasa düşüşü de
                        // kumbaradan alma da onu küçültmez (bkz. [Odun]).
                        odun: ref.watch(odunProvider),
                        etiket: l.kampOdunEtiket(ref.watch(odunProvider)),
                        boyut: 140,
                        parlamaTetik: _yeme.values.fold(0, (a, b) => a + b),
                      )),
                  _sigdir(92, ust.length > 1 ? karakter(ust[1], gecikme: const Duration(milliseconds: 1400), donusYon: 1, donusGecikme: const Duration(milliseconds: 60)) : const SizedBox(width: 92)),
                ],
              ),
              const SizedBox(height: Bosluk.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sigdir(120, karakter(VarlikTuru.altin, boyut: 120, donusGecikme: const Duration(milliseconds: 120))),
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
                  _sigdir(92, alt.isNotEmpty ? karakter(alt[0], gecikme: const Duration(milliseconds: 2100), donusYon: 1, donusGecikme: const Duration(milliseconds: 180)) : const SizedBox(width: 92)),
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
                  semantik: l.besleBaslik(l.karakter(t), t.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: Bosluk.xs),
                    child: Row(children: [
                      SizedBox.square(dimension: 44, child: CustomPaint(painter: KarakterPainter(tur: t, ruh: k[t]!.ruh, sembol: cocuk.para.sembol))),
                      const SizedBox(width: Bosluk.m),
                      Expanded(
                        // Miktar karakter ekranında ("Elinde …"); burada yalnız ad.
                        child: Text('${l.karakter(t)} · ${l.varlik(t)}', style: context.t.titleMedium),
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
