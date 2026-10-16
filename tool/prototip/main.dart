// Denenebilir prototip: büyüme evreleri + 2,5D görünüm (yasin 2026-10-16).
//
// Uygulamanın GERÇEK karakter kodunu (`Karakter`, `KarakterPainter`, `Evre`)
// tarayıcıda çalıştırır; ayrı bir taklit değil. Uygulamaya girmez (yalnız
// `lib/main.dart` ağacı paketlenir). Derleme:
//   flutter create --platforms=web .   (geçici; web/ commit edilmez)
//   flutter build web -t tool/prototip/main.dart --no-web-resources-cdn
// Metin yalnız Türkçe: yasin için deneme yüzeyi, çocuk ekranı değil.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:harcliklarim/models/evre.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/theme/dunya.dart';
import 'package:harcliklarim/widgets/karakter.dart';

void main() => runApp(const PrototipUygulama());

class PrototipUygulama extends StatelessWidget {
  const PrototipUygulama({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Harçlıklarım prototip',
        // Uygulamanın dünya teması koyu zemin içindir; deneme yüzeyi açık zeminde.
        theme: ThemeData(colorSchemeSeed: const Color(0xFF3E8E4A), fontFamily: govdeFontu),
        home: const Prototip(),
      );
}

const _adlar = {
  VarlikTuru.altin: 'Tortu',
  VarlikTuru.dolar: 'Zıpzıp',
  VarlikTuru.euro: 'Baykuş',
  VarlikTuru.nakit: 'Sincap',
};

const _evreAdi = {
  Evre.minik: 'Minik',
  Evre.filiz: 'Filiz',
  Evre.cicek: 'Çiçek',
  Evre.yildiz: 'Yıldız',
};

class Prototip extends StatefulWidget {
  const Prototip({super.key});
  @override
  State<Prototip> createState() => _PrototipState();
}

class _PrototipState extends State<Prototip> {
  VarlikTuru _tur = VarlikTuru.dolar;
  final _gun = {for (final t in VarlikTuru.values) t: 1};
  final _enYuksek = {for (final t in VarlikTuru.values) t: Evre.minik};
  Ruh _ruh = Ruh.duz;
  int _yeme = 0, _tepki = 0, _sevinc = 0;
  bool _derinlik = true, _sesAcik = true, _hareketsiz = false;
  String _not = 'Besle düğmesine bas: her yeni gün karakteri büyütür.';

  // Web'de her ses kendi oyuncusuyla, düşük gecikme modu olmadan çalar.
  final _oyuncular = <Ses, AudioPlayer>{};
  void _cal(Ses s) {
    if (!_sesAcik) return;
    final o = _oyuncular.putIfAbsent(s, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    o.stop().then((_) => o.play(AssetSource('sesler/${s.name}.wav'))).catchError((_) {});
  }

  Evre get _evre => _enYuksek[_tur]!;

  void _evreGuncelle() {
    final h = Evre.gunden(_gun[_tur]!);
    if (h.index > _enYuksek[_tur]!.index) _enYuksek[_tur] = h;
  }

  void _besle({required bool yeniGun}) {
    setState(() {
      _yeme++;
      final once = _evre;
      if (yeniGun) _gun[_tur] = _gun[_tur]! + 1;
      _evreGuncelle();
      final sonraki = _evre.sonraki;
      _not = _evre != once
          ? '${_adlar[_tur]} büyüdü: ${_evreAdi[_evre]}! Yeme bitince büyüme sahnesi oynar.'
          : yeniGun
              ? (sonraki == null
                  ? 'En büyük evrede. Beslemeye devam: sevinç sahnesi her seferinde.'
                  : 'Yeni gün sayıldı. ${_evreAdi[sonraki]} için ${sonraki.esikGun - _gun[_tur]!} gün daha.')
              : 'Aynı gün tekrar besledin: sevinir ama gün sayısı artmaz (çok dokunarak büyütme yok).';
    });
  }

  void _sil() {
    setState(() {
      if (_gun[_tur]! > 0) _gun[_tur] = _gun[_tur]! - 1;
      _not = 'Bir besleme silindi: gün azaldı ama karakter KÜÇÜLMEZ, evre geri gitmez.';
    });
  }

  void _atla() {
    final s = _evre.sonraki;
    if (s == null) return;
    setState(() {
      _gun[_tur] = s.esikGun;
      _enYuksek[_tur] = s;
      _not = 'Doğrudan ${_evreAdi[s]} evresine geçti.';
    });
  }

  void _bastan() => setState(() {
        _gun[_tur] = 1;
        _enYuksek[_tur] = Evre.minik;
        _ruh = Ruh.duz;
        _not = 'Baştan: Minik evre, 1 besleme günü.';
      });

  @override
  void dispose() {
    for (final o in _oyuncular.values) {
      o.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sonraki = _evre.sonraki;
    final ilerleme = sonraki == null
        ? 1.0
        : ((_gun[_tur]! - _evre.esikGun) / (sonraki.esikGun - _evre.esikGun)).clamp(0.0, 1.0);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: _hareketsiz),
      child: ParaSembolu(
        sembol: '₺',
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF4DF),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
                  Text('Büyüme ve 2,5D', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Uygulamanın gerçek karakter kodu. Karaktere dokunabilirsin.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in VarlikTuru.values)
                      ChoiceChip(
                        label: Text(_adlar[t]!),
                        selected: _tur == t,
                        onSelected: (_) => setState(() {
                          _tur = t;
                          _not = '${_adlar[t]}: ${_evreAdi[_evre]} evresinde.';
                        }),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  _sahne(),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('${_evreAdi[_evre]}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: ilerleme, minHeight: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(sonraki == null ? 'en büyük' : '${_gun[_tur]}/${sonraki.esikGun} gün',
                        style: Theme.of(context).textTheme.labelLarge),
                  ]),
                  const SizedBox(height: 6),
                  Text(_not, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  _baslik('Büyüme'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(
                      onPressed: () => _besle(yeniGun: true),
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Besle (yeni gün)'),
                    ),
                    OutlinedButton(onPressed: () => _besle(yeniGun: false), child: const Text('Aynı gün tekrar besle')),
                    OutlinedButton(onPressed: sonraki == null ? null : _atla, child: const Text('Sonraki evreye atla')),
                    OutlinedButton(onPressed: _sil, child: const Text('Bir beslemeyi sil')),
                    TextButton(onPressed: _bastan, child: const Text('Baştan')),
                  ]),
                  const SizedBox(height: 12),
                  _baslik('Değer'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        final once = _ruh;
                        _ruh = Ruh.mutlu;
                        if (once != Ruh.mutlu) _sevinc++;
                        _not = once == Ruh.mutlu ? 'Zaten artıda.' : 'Değer artıya geçti: bir kez sevinir.';
                      }),
                      child: const Text('Artıya geçti'),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _ruh = Ruh.duz;
                        _not = 'Değer yatay: hafif gülümser.';
                      }),
                      child: const Text('Yatay'),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _ruh = Ruh.bulutlu;
                        _not = 'Değer %5\'ten çok düştü: bulut gelir, karakter küçülmez. Dokununca güneş açar.';
                      }),
                      child: const Text('Düştü (bulut)'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _baslik('Görünüm'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('2,5D (ışık, gölge, baş çevirme)'),
                    value: _derinlik,
                    onChanged: (v) => setState(() => _derinlik = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ses'),
                    value: _sesAcik,
                    onChanged: (v) => setState(() => _sesAcik = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hareketi azalt (erişilebilirlik)'),
                    value: _hareketsiz,
                    onChanged: (v) => setState(() => _hareketsiz = v),
                  ),
                  const SizedBox(height: 8),
                  _baslik('Dört evre yan yana'),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final e in Evre.values)
                      Column(children: [
                        SizedBox.square(
                          dimension: 92,
                          child: CustomPaint(
                            painter: KarakterPainter(tur: _tur, ruh: Ruh.mutlu, evre: e, derinlik: _derinlik),
                          ),
                        ),
                        Text('${_evreAdi[e]}', style: Theme.of(context).textTheme.labelLarge),
                        Text('${e.esikGun} gün', style: Theme.of(context).textTheme.labelSmall),
                      ]),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _baslik(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _sahne() => GestureDetector(
        onTap: () => setState(() {
          _tepki++;
          _not = _ruh == Ruh.bulutlu ? 'Dokundun: bulut çekilir, güneş açar.' : 'Dokundun: zıplar ve kıkırdar.';
        }),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBFE6FF), Color(0xFFE9F7FF), Color(0xFFBDE6A8), Color(0xFF8FCF7A)],
              stops: [0, .6, .61, 1],
            ),
          ),
          alignment: const Alignment(0, .55),
          child: Karakter(
            key: ValueKey(_tur),
            tur: _tur,
            ruh: _ruh,
            boyut: 220,
            evre: _evre,
            evreKutla: true,
            derinlik: _derinlik,
            yemeTetik: _yeme,
            tepkiTetik: _tepki,
            sevincTetik: _sevinc,
            bosta: true,
            pulSayisi: _tur == VarlikTuru.altin ? (_gun[_tur]! ~/ 3).clamp(0, 3) : 0,
            ses: _cal,
          ),
        ),
      );
}
