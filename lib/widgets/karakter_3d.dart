part of 'karakter.dart';

// ── 3D görünüm (deneme) ─────────────────────────────────────────────────
//
// Neden (yasin 2026-10-17, "bu kısmı gönder bakalım"): Kumbara Takımı'nın
// Blender'da modellenen 3D hâli telefonda denensin. Veli köşesinde
// varsayılanı kapalı bir seçim; kapalıyken bugünkü 2D birebir aynı.
//
// Kararlar:
// - Önceden render (canlı 3D değil): Kids uygulamasında 3D motoru ve
//   gölgelendirici derlemesi yok, pil dostu; kareler Blender'da
//   `tool/karakter3d/` ile üretilir.
// - Zaman çizelgesi 2D ile tek: hareket (zıplama, eğilme, nefes, yeme)
//   bugünkü denetleyicilerden gelir; 3D yalnız "deri"dir. Ses, titreşim,
//   parçacık, gölge değişmez.
// - İki tür kare: (1) ifade atlası (13 durağan yüz × evre), yüz değerleri
//   (Yuz) opaklıkla karıştırılır, gövde hareketini Flutter dönüşümü verir;
//   (2) hareketi pişmiş sahneler (dokunma, artı, boşta zıplama/keyif/etrafa
//   bakış/dans): kulak ve bitki fiziği, baş takibi, dönüş karede. Pişmiş
//   sahnede Flutter yalnız nefesi ekler.
// - Bellek: atlas evre başına bir kez çözülür ve paylaşılır; sahne kareleri
//   sahne başlayınca sırayla çözülür, bitince bırakılır. Kare henüz
//   çözülmediyse atlas gösterilir (takılma yerine yumuşak düşüş).
// - Besleme ritüelinin karaktere özgü parçaları (Sincap'ın yanakları,
//   Baykuş'un kanatları…) bu denemede 3D'de yok: yiyecek 2D çizilir, gövde
//   atlastan ağız açarak yer. Sonraki adım: yeme sahnelerinin 3D'si.

/// 3D görünüm açık mı (uygulama kökünde, ayardan).
class UcBoyut extends InheritedWidget {
  const UcBoyut({super.key, required this.acik, required super.child});
  final bool acik;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<UcBoyut>()?.acik ?? false;

  @override
  bool updateShouldNotify(UcBoyut o) => o.acik != acik;
}

/// Atlas sırası (`tool/karakter3d/kumbara.py` ATLAS ile aynı; dosya adları
/// `mutlu_sol` gibi, burada camelCase).
enum AtlasIfade { mutlu, duz, bulutlu, mutluSol, mutluSag, mutluYukari, o, oSol, oSag, oYukari, sevinc, kirp, esne }

/// Asset'teki animasyonlu WebP'yi sırayla çözer. [kareler] çözüldükçe dolar.
class _Film {
  _Film(this.anahtar) {
    _yukle();
  }

  final String anahtar;
  final kareler = <ui.Image>[];
  final hazir = ValueNotifier<int>(0);

  /// Toplam kare (çözücü açılınca bilinir; 0 = henüz bilinmiyor).
  int toplam = 0;
  bool _birakildi = false;
  bool hata = false;

  Future<void> _yukle() async {
    ui.Codec? codec;
    try {
      final veri = await rootBundle.load('assets/karakter3d/$anahtar.webp');
      final tampon = await ui.ImmutableBuffer.fromUint8List(veri.buffer.asUint8List(veri.offsetInBytes, veri.lengthInBytes));
      final tanim = await ui.ImageDescriptor.encoded(tampon);
      codec = await tanim.instantiateCodec();
      toplam = codec.frameCount;
      for (var i = 0; i < codec.frameCount; i++) {
        final k = await codec.getNextFrame();
        if (_birakildi) {
          k.image.dispose();
          break;
        }
        kareler.add(k.image);
        hazir.value = kareler.length;
      }
    } catch (_) {
      // Asset yoksa ya da çözülemezse 2D'ye düşülür (süs; uygulama durmaz).
      hata = true;
      hazir.value = -1;
    } finally {
      codec?.dispose();
    }
  }

  /// İlerleme [t] (0–1) için kare sırası.
  int sira(double t) => toplam <= 1 ? 0 : (t.clamp(0.0, 1.0) * (toplam - 1)).round();

  /// [i]. kare; henüz çözülmediyse en son çözülen, hiç yoksa null.
  ui.Image? kare(int i) => kareler.isEmpty ? null : kareler[math.min(i, kareler.length - 1)];

  void birak() {
    _birakildi = true;
    for (final k in kareler) {
      k.dispose();
    }
    kareler.clear();
    hazir.dispose();
  }
}

/// Atlaslar uygulama boyunca paylaşılır (karakter × evre başına bir).
final _atlaslar = <String, _Film>{};

_Film _atlas(VarlikTuru t, Evre? e) {
  final a = '${t.name}/atlas_${(e ?? Evre.minik).name}';
  return _atlaslar.putIfAbsent(a, () => _Film(a));
}

/// Bir katman: film, kare ve opaklık.
typedef _Katman = ({_Film film, int kare, double opak});

/// Yüz ve bakıştan atlas karışımı (alttan üste). Taban: ruh gülüşü
/// (mutlu/düz/bulutlu arası); üstüne bakış, "o", esneme, sevinç, kırpma.
List<(AtlasIfade, double)> atlasKarisimi(Yuz y, Offset bakis) {
  final out = <(AtlasIfade, double)>[];
  final g = y.gulus.clamp(0.0, 1.0);
  if (g >= .4) {
    out.add((AtlasIfade.duz, 1));
    out.add((AtlasIfade.mutlu, (g - .4) / .6));
  } else {
    out.add((AtlasIfade.bulutlu, 1));
    out.add((AtlasIfade.duz, ((g - .1) / .3).clamp(0.0, 1.0)));
  }
  // Bakış: yön kareleri başı da çevirir; yarı opak karışım iki baş gösterir
  // (hayalet). Bu yüzden yön, eşikte kısa bir geçişle tam olarak değişir.
  double esik(double x) {
    final u = ((x - .45) / .15).clamp(0.0, 1.0);
    return u * u * (3 - 2 * u);
  }

  final yatay = esik(bakis.dx.abs());
  final yukari = esik(-bakis.dy) * (1 - yatay);
  void yon(AtlasIfade sol, AtlasIfade sag, AtlasIfade ust, double w) {
    if (w <= 0) return;
    if (yatay > .01) out.add((bakis.dx < 0 ? sol : sag, yatay * w));
    if (yukari > .01) out.add((ust, yukari * w));
  }

  yon(AtlasIfade.mutluSol, AtlasIfade.mutluSag, AtlasIfade.mutluYukari, ((g - .4) / .6).clamp(0.0, 1.0));
  final esne = math.min(y.kapak, y.agizO / .9).clamp(0.0, 1.0);
  final o = (y.agizO - esne).clamp(0.0, 1.0);
  if (o > .01) {
    out.add((AtlasIfade.o, o));
    yon(AtlasIfade.oSol, AtlasIfade.oSag, AtlasIfade.oYukari, o);
  }
  if (esne > .01) out.add((AtlasIfade.esne, esne));
  final s = math.max(y.sevinc, y.kahkaha).clamp(0.0, 1.0);
  if (s > .01) out.add((AtlasIfade.sevinc, s));
  final k = ((y.kapak - esne) * (1 - s)).clamp(0.0, 1.0);
  if (k > .01) out.add((AtlasIfade.kirp, k));
  return [for (final e in out) if (e.$2 > .01) e];
}

/// 3D katmanları 110'luk kutuya çizer (KarakterPainter ile aynı ölçek).
class _UcBoyutPainter extends CustomPainter {
  _UcBoyutPainter({required this.tur, required this.katmanlar, required this.olcek, super.repaint});
  final VarlikTuru tur;
  final List<_Katman> katmanlar;

  /// Evre ölçeği (ayak tabanından).
  final double olcek;

  @override
  void paint(Canvas cv, Size size) {
    final s = size.shortestSide / 110;
    final (ox, oy, k) = _yerlesim3d[tur]!;
    cv.save();
    cv.translate((size.width - 110 * s) / 2, (size.height - 110 * s) / 2);
    cv.scale(s);
    cv.translate(55, 100);
    cv.scale(olcek);
    cv.translate(-55, -100);
    for (final l in katmanlar) {
      final im = l.film.kare(l.kare);
      final kutu = _kirpim3d[l.film.anahtar];
      if (im == null || kutu == null || l.opak <= 0) continue;
      final (x0, y0, x1, y1) = kutu;
      final hedef = Rect.fromLTRB(ox + x0 * k, oy + y0 * k, ox + x1 * k, oy + y1 * k);
      cv.drawImageRect(
          im,
          Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
          hedef,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Color.fromRGBO(0, 0, 0, l.opak.clamp(0.0, 1.0)));
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(_UcBoyutPainter o) => true;
}
