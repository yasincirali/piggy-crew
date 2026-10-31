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

/// Besleme sonucu: hareket eklendi; varsa yeni açılan çıkartmanın adı ve
/// haftanın ilk beslemesiyle ateşe odun gelip gelmediği.
class BeslemeSonucu {
  const BeslemeSonucu(this.yeniCikartma, {this.yeniOdun = false, this.kaynak});
  final String? yeniCikartma;
  final bool yeniOdun;
  final HareketKaynagi? kaynak;

  /// Gösterilecek tek mesaj: çıkartma > odun > kaynak cümlesi > doydu (üst
  /// üste mesaj yok). Kaynak cümlesi sıcak bir söz, ödül değil.
  String mesaj(AppLocalizations l, VarlikTuru t) {
    if (yeniCikartma != null) return l.cikartmaAcildi(yeniCikartma!);
    if (yeniOdun) return l.odunEklendi;
    final ad = l.karakter(t);
    return switch (kaynak) {
      HareketKaynagi.emek => l.besleEmek(ad),
      HareketKaynagi.hediye => l.besleHediye(ad),
      _ => l.besleDoydu(ad),
    };
  }
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

  /// Dokunulan kupürler, sırayla: "Geri al" sonuncuyu çıkarır. Çocuk elle
  /// yazınca liste silinir (artık yazdığı sayı geçerli).
  final _kupurler = <int>[];
  bool _gonderiliyor = false;
  HareketKaynagi? _kaynak;

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
      kaynak: _kaynak,
    );
    final odunOnce = ref.read(odunProvider);
    await ref.read(hareketlerProvider.notifier).ekle(h);
    final yeni = await _cikartmalariKontrolEt();
    final yeniOdun = ref.read(odunProvider) > odunOnce;
    ref.read(dokunsalProvider).cal(Dokunus.onay);
    if (mounted) Navigator.of(context).pop(BeslemeSonucu(yeni, yeniOdun: yeniOdun, kaynak: _kaynak));
  }

  /// Davranış çıkartmaları — tek yerden, besleme sonrası. İlk yeni açılanın
  /// adını döner (birden fazlası aynı anda açılırsa diğerleri sessizce açılır,
  /// listede görünür).
  Future<String?> _cikartmalariKontrolEt() async {
    final l = context.l10n;
    // Kumbaradan almalar ödül hesabına girmez (bkz. [Hareket]).
    final hareketler = ref.read(hareketlerProvider).beslemeler.toList();
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

    // Kaydırılır: "Nereden geldi?" satırıyla büyük yazıda klavyeyle sığmaz.
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
                Text(l.besleBaslik(ad, widget.tur.name), style: context.t.titleLarge),
                if (fiyat != null && !widget.tur.nakitMi)
                  Text(l.besleBugunFiyat(birim, fmtPara(fiyat, cocuk.para)), style: context.t.bodyMedium),
                if (fiyat == null) Text(l.besleFiyatYok, style: context.t.bodyMedium?.copyWith(color: r.loss)),
              ]),
            ),
          ]),
          const SizedBox(height: Bosluk.xl),
          Text(l.besleTutar, style: context.t.titleMedium),
          Text(l.kupurIpucu, style: context.t.bodyMedium?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.s),
          TextField(
            controller: _tutar,
            // Klavye kendiliğinden açılmaz: açılınca kupürleri örtüyordu
            // (küçük ekran). Yazmak isteyen alana dokunur.
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            style: context.t.displaySmall,
            onChanged: (_) => setState(_kupurler.clear),
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
          // "Elindekini say" (Ar-Ge 30 Eki, yasin "yap" 31 Eki): elindeki
          // banknot ve bozuk paraların eşine dokun, her dokunuş EKLER. 7 yaş
          // 145'i yazamaz ama 100'ü ve 20'yi tanır (somut → temsil → soyut).
          // Eski dört hızlı tutar (50/100/250/500) tutarı değiştiriyordu ve
          // 250 diye banknot yoktu. Ödül, sayaç, süre yok.
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            children: [
              for (final v in cocuk.para.kupurler)
                _Kupur(
                  key: ValueKey('kupur-$v'),
                  metin: fmtPara(v.toDouble(), cocuk.para),
                  semantik: l.kupurEkle(fmtPara(v.toDouble(), cocuk.para)),
                  onTap: () => _kupurEkle(v),
                ),
              if (_kupurler.isNotEmpty)
                SecimCipi(
                  key: const ValueKey('kupur-geri'),
                  metin: l.kupurGeriAl,
                  secili: false,
                  onIkon: Icon(Icons.undo_rounded, size: 18, color: r.fg),
                  onTap: _kupurGeriAl,
                ),
            ],
          ),
          const SizedBox(height: Bosluk.l),
          // İsteğe bağlı: seçilmezse akış eskisi gibi. Seçili çipe yeniden
          // dokunmak etiketi kaldırır.
          Text(l.besleNereden, style: context.t.titleMedium),
          const SizedBox(height: Bosluk.s),
          Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
            for (final k in HareketKaynagi.values)
              SecimCipi(
                metin: l.kaynakAdi(k.name),
                secili: _kaynak == k,
                onIkon: _kaynak == k ? null : Icon(k.ikon, size: 20, color: r.fg),
                onTap: () => setState(() => _kaynak = _kaynak == k ? null : k),
              ),
          ]),
          const SizedBox(height: Bosluk.l),
          AnimatedSwitcher(
            duration: Devinim.sure(context, Devinim.normal),
            child: (tutar != null && fiyat != null && !widget.tur.nakitMi)
                ? Text(
                    l.besleAlir(fmtPara(tutar, cocuk.para), fmtMiktar(tutar / fiyat, birim, cocuk.para)),
                    key: ValueKey(tutar),
                    style: context.t.titleMedium?.copyWith(color: r.acc),
                  )
                // Nakitte miktar satırı yok; büyük tutar yine biçimli yankılanır
                // ki fazladan sıfır ya da "1.500" yanlış okunmuşsa görünsün.
                : (tutar != null && tutar >= 1000)
                    ? Text(
                        fmtPara(tutar, cocuk.para),
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

  /// Kupürden önce elle yazılmış tutar (varsa); kupürler bunun üstüne eklenir.
  double _taban = 0;

  void _kupurEkle(int v) {
    if (_kupurler.isEmpty) _taban = parseSayi(_tutar.text) ?? 0;
    setState(() {
      _kupurler.add(v);
      _tutar.text = _yaz(_taban + _kupurler.fold(0, (a, b) => a + b));
    });
    ref.read(dokunsalProvider).cal(Dokunus.secim);
  }

  void _kupurGeriAl() {
    if (_kupurler.isEmpty) return;
    setState(() {
      _kupurler.removeLast();
      final t = _taban + _kupurler.fold(0, (a, b) => a + b);
      _tutar.text = t > 0 ? _yaz(t) : '';
    });
  }

  /// Alan ham sayı tutar (binlik ayırıcı yok): parseSayi "1.500"ü de okur ama
  /// ham yazım ondalıkla karışmaz.
  String _yaz(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Kupür: elindeki paranın eşi. Banknot gibi köşeli kart, üstte artı; en az
/// 44 pt. Ekran okuyucu "20 ₺ ekle" okur.
class _Kupur extends StatelessWidget {
  const _Kupur({super.key, required this.metin, required this.semantik, required this.onTap});
  final String metin;
  final String semantik;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Basilabilir(
      onTap: onTap,
      semantik: semantik,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: Bosluk.m, vertical: Bosluk.s),
        decoration: BoxDecoration(
          color: r.card,
          borderRadius: BorderRadius.circular(Kose.s),
          border: Border.all(color: r.acc.withValues(alpha: .6), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 16, color: r.acc),
          const SizedBox(width: Bosluk.xs),
          Text(metin, style: context.t.titleMedium),
        ]),
      ),
    );
  }
}
