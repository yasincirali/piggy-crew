import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/cocuk.dart';
import '../models/varlik.dart';
import '../providers/saglayicilar.dart';
import '../services/depo.dart';
import '../theme/dunya.dart';
import '../widgets/karakter.dart';
import '../widgets/ortak.dart';
import '../services/dokunsal.dart';

/// Karşılama: 5 adım, e-posta yok, şifre yok. Ad → yaş → para → kamp yeri →
/// veli PIN (atlanabilir). Tema seçimi anında arka planı değiştirir ki çocuk
/// "seçmek" yerine "denemek" hissetsin.
class KarsilamaEkrani extends ConsumerStatefulWidget {
  const KarsilamaEkrani({super.key});
  @override
  ConsumerState<KarsilamaEkrani> createState() => _KarsilamaState();
}

class _KarsilamaState extends ConsumerState<KarsilamaEkrani> {
  int _adim = 0;
  final _ad = TextEditingController();
  YasModu _yas = YasModu.kucuk;
  late ParaBirimi _para;
  Dunya _dunya = Dunya.bahce;
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _pinHata;

  @override
  void initState() {
    super.initState();
    _para = ParaBirimi.yerelden(WidgetsBinding.instance.platformDispatcher.locale.countryCode);
  }

  @override
  void dispose() {
    _ad.dispose();
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  void _ileri() => setState(() => _adim++);
  void _geri() => setState(() => _adim--);

  Future<void> _bitir({bool pinli = true}) async {
    String? ozet;
    if (pinli) {
      if (_pin1.text.length != 4) return;
      if (_pin1.text != _pin2.text) {
        setState(() => _pinHata = context.l10n.veliPinUyusmaz);
        return;
      }
      ozet = Depo.pinOzeti(_pin1.text);
    }
    await ref.read(cocukProvider.notifier).kaydet(Cocuk(
          ad: _ad.text.trim(),
          yas: _yas,
          dunya: _dunya,
          pinOzeti: ozet,
          olusturma: DateTime.now(),
          para: _para,
        ));
  }

  @override
  Widget build(BuildContext context) {
    // Tema seçimi anında uygulanır: Theme'i burada sarıyoruz.
    return Theme(
      data: dunyaTemasi(_dunya),
      child: Builder(builder: (context) {
        final l = context.l10n;
        final r = context.r;
        return Scaffold(
          body: DunyaZemini(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Bosluk.xl, Bosluk.l, Bosluk.xl, Bosluk.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      if (_adim > 0)
                        IconButton(
                          onPressed: _geri,
                          icon: Icon(Icons.arrow_back_rounded, color: r.fg),
                          tooltip: l.geri,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                      const Spacer(),
                      _Noktalar(adim: _adim, toplam: 5),
                      const Spacer(),
                      if (_adim > 0) const SizedBox(width: 44),
                    ]),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Devinim.sure(context, Devinim.normal),
                        switchInCurve: Devinim.cikis,
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a),
                            child: c,
                          ),
                        ),
                        child: KeyedSubtree(key: ValueKey(_adim), child: _kaydirilabilir(_govde(l, r))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Adımlar Spacer'la dikeyde dağılır; büyük yazıda (Dynamic Type) ya da
  /// küçük ekranda sığmazsa kaydırılır. Sığdığında yerleşim birebir aynı kalır:
  /// en az ekran yüksekliği + IntrinsicHeight, Spacer'ları korur.
  Widget _kaydirilabilir(Widget govde) => LayoutBuilder(
        builder: (context, k) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: k.maxHeight),
            child: IntrinsicHeight(child: govde),
          ),
        ),
      );

  Widget _govde(AppLocalizations l, DunyaRenkleri r) => switch (_adim) {
        0 => _adimGiris(l, r),
        1 => _adimAd(l, r),
        2 => _adimPara(l, r),
        3 => _adimDunya(l, r),
        _ => _adimVeli(l, r),
      };

  Widget _adimGiris(AppLocalizations l, DunyaRenkleri r) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, t) in VarlikTuru.values.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i.isOdd ? 24 : 0),
                  child: Karakter(tur: t, ruh: Ruh.mutlu, boyut: 78, gecikme: Duration(milliseconds: 300 * i)),
                ),
            ],
          ),
          const SizedBox(height: Bosluk.xxl),
          Text(l.karsilamaBaslik, textAlign: TextAlign.center, style: context.t.headlineMedium),
          const SizedBox(height: Bosluk.m),
          Text(l.karsilamaAlt, textAlign: TextAlign.center, style: context.t.bodyLarge?.copyWith(color: r.sub)),
          const Spacer(),
          AnaDugme(metin: l.karsilamaBasla, onTap: _ileri),
        ],
      );

  Widget _adimAd(AppLocalizations l, DunyaRenkleri r) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Bosluk.dev),
          Text(l.adSoru, style: context.t.headlineMedium),
          const SizedBox(height: Bosluk.xl),
          TextField(
            controller: _ad,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 20,
            style: context.t.titleLarge,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _ad.text.trim().isNotEmpty ? _ileri() : null,
            decoration: InputDecoration(
              hintText: l.adIpucu,
              counterText: '',
              filled: true,
              fillColor: r.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.acc, width: 2)),
            ),
          ),
          const SizedBox(height: Bosluk.xxl),
          Text(l.yasSoru, style: context.t.titleLarge),
          const SizedBox(height: Bosluk.m),
          // Wrap: büyük yazıda iki yaş çipi yan yana sığmazsa alt alta iner.
          Wrap(spacing: Bosluk.s, runSpacing: Bosluk.s, children: [
            for (final y in YasModu.values)
              SecimCipi(metin: y == YasModu.kucuk ? l.yasKucuk : l.yasBuyuk, secili: _yas == y, onTap: () => setState(() => _yas = y)),
          ]),
          const Spacer(),
          AnaDugme(metin: l.devam, onTap: _ad.text.trim().isEmpty ? null : _ileri),
        ],
      );

  Widget _adimPara(AppLocalizations l, DunyaRenkleri r) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Bosluk.dev),
          Text(l.paraSoru, style: context.t.headlineMedium),
          const SizedBox(height: Bosluk.xl),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            children: [
              for (final p in ParaBirimi.values)
                SecimCipi(metin: '${p.sembol}  ${p.kod}', secili: _para == p, onTap: () => setState(() => _para = p)),
            ],
          ),
          const Spacer(),
          AnaDugme(metin: l.devam, onTap: _ileri),
        ],
      );

  Widget _adimDunya(AppLocalizations l, DunyaRenkleri r) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Bosluk.dev),
          Text(l.dunyaSoru, style: context.t.headlineMedium),
          const SizedBox(height: Bosluk.s),
          Text(l.dunyaAlt, style: context.t.bodyLarge?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.xl),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            children: [
              for (final d in Dunya.values)
                SecimCipi(
                  metin: l.dunya(d),
                  secili: _dunya == d,
                  onIkon: _DunyaNoktasi(d),
                  onTap: () {
                    ref.read(dokunsalProvider).cal(Dokunus.secim);
                    setState(() => _dunya = d);
                  },
                ),
            ],
          ),
          const Spacer(),
          Center(child: Karakter(tur: VarlikTuru.altin, ruh: Ruh.mutlu, boyut: 120)),
          const Spacer(),
          AnaDugme(metin: l.devam, onTap: _ileri),
        ],
      );

  Widget _adimVeli(AppLocalizations l, DunyaRenkleri r) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Bosluk.dev),
          Text(l.veliBaslik, style: context.t.headlineMedium),
          const SizedBox(height: Bosluk.s),
          Text(l.veliAciklama, style: context.t.bodyLarge?.copyWith(color: r.sub)),
          const SizedBox(height: Bosluk.xl),
          _PinAlani(controller: _pin1, ipucu: l.veliPinIpucu, onChanged: () => setState(() => _pinHata = null)),
          const SizedBox(height: Bosluk.m),
          _PinAlani(controller: _pin2, ipucu: l.veliPinTekrar, onChanged: () => setState(() => _pinHata = null)),
          if (_pinHata != null) ...[
            const SizedBox(height: Bosluk.s),
            Text(_pinHata!, style: context.t.bodyMedium?.copyWith(color: r.loss, fontWeight: FontWeight.w700)),
          ],
          const Spacer(),
          AnaDugme(metin: l.hazir, onTap: (_pin1.text.length == 4 && _pin2.text.length == 4) ? _bitir : null),
          const SizedBox(height: Bosluk.s),
          AnaDugme(metin: l.veliPinSonra, ikincil: true, onTap: () => _bitir(pinli: false)),
        ],
      );
}

class _PinAlani extends StatelessWidget {
  const _PinAlani({required this.controller, required this.ipucu, required this.onChanged});
  final TextEditingController controller;
  final String ipucu;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: context.t.titleLarge?.copyWith(letterSpacing: 8),
      textAlign: TextAlign.center,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: ipucu,
        hintStyle: context.t.bodyLarge?.copyWith(color: r.sub, letterSpacing: 0),
        counterText: '',
        filled: true,
        fillColor: r.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Kose.m), borderSide: BorderSide(color: r.acc, width: 2)),
      ),
    );
  }
}

class _Noktalar extends StatelessWidget {
  const _Noktalar({required this.adim, required this.toplam});
  final int adim, toplam;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < toplam; i++)
          AnimatedContainer(
            duration: Devinim.sure(context, Devinim.normal),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == adim ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(color: i <= adim ? r.acc : r.line, borderRadius: BorderRadius.circular(4)),
          ),
      ],
    );
  }
}

/// Tema çipindeki küçük renk örneği.
class _DunyaNoktasi extends StatelessWidget {
  const _DunyaNoktasi(this.d);
  final Dunya d;
  @override
  Widget build(BuildContext context) {
    final r = DunyaRenkleri.of(d);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [r.bg1, r.acc]),
        border: Border.all(color: DunyaRenkleri.murekkep.withValues(alpha: .4)),
      ),
    );
  }
}
