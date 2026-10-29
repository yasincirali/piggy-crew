import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/cizim.dart';
import 'package:harcliklarim/models/hedef.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/cizim_boyaci.dart';
import 'package:harcliklarim/widgets/hedef_esyasi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// "Hedefini kendin çiz": listede olmayan hedefi çocuk çizer; çizim hedef
/// eşyası olur, kartta alttan dolar, kayıtta kalır, "tüm veriyi sil" ile gider.
void main() {
  group('model', () {
    const ev = Cizim([
      Cizgi(renk: 1, noktalar: [Offset(.1, .2), Offset(.5, .5)]),
      Cizgi(renk: 0, noktalar: [Offset(.9, .9)]),
    ]);

    test('JSON gidiş-dönüş; eski kayıt ve diğer eşyalar etkilenmez', () {
      const hd = Hedef(esya: HedefEsya.cizim, fiyatTl: 300, cizim: ev);
      final geri = Hedef.fromJson(jsonDecode(jsonEncode(hd.toJson())) as Map<String, dynamic>);
      expect(geri, hd);
      expect(geri!.ulas(DateTime(2026, 10, 29)).cizim, ev, reason: 'ulaşınca çizim kalır');
      expect(const Hedef(esya: HedefEsya.top, fiyatTl: 5).toJson().containsKey('cizim'), isFalse);
      expect(Hedef.fromJson({'esya': 'top', 'fiyatTl': 5}), const Hedef(esya: HedefEsya.top, fiyatTl: 5));
    });

    test('okunamayan çizim hedefi silmez, hediyeye döner', () {
      for (final bozuk in [null, 'x', [], [{'r': 9, 'p': [0, 0]}], [{'r': 0, 'p': ['a', 1]}]]) {
        final h = Hedef.fromJson({'esya': 'cizim', 'fiyatTl': 40, 'cizim': bozuk});
        expect(h, const Hedef(esya: HedefEsya.hediye, fiyatTl: 40), reason: '$bozuk');
      }
    });

    test('sınırlar: en fazla 60 çizgi, çizgi başına 240 nokta, 0..1 içinde', () {
      final cok = [
        for (var i = 0; i < 80; i++) {'r': 0, 'p': List<num>.generate(600, (k) => k.isEven ? 2 : -1)},
      ];
      final c = Cizim.fromJson(cok)!;
      expect(c.cizgiler.length, Cizim.enFazlaCizgi);
      expect(c.cizgiler.first.noktalar.length, Cizim.enFazlaNokta);
      expect(c.cizgiler.first.noktalar.first, const Offset(1, 0));
    });
  });

  group('akış', () {
    Future<SharedPreferences> kampaGel(WidgetTester t, {double yazi = 1}) async {
      t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
      t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.platformDispatcher.clearAllTestValues);
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      rootBundle.clear();
      final sp = await SharedPreferences.getInstance();
      final sahteHttp = MockClient(
        (_) async => http.Response('{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200, headers: {'content-type': 'application/json; charset=utf-8'}),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            depoProvider.overrideWithValue(Depo(sp)),
            fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
          ],
          child: const HarcliklarimApp(),
        ),
      );
      await bekle(t);
      await t.tap(find.text('Başla'));
      await bekle(t);
      await t.enterText(find.byType(TextField), 'Deniz');
      await bekle(t);
      for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
        await t.tap(find.text(d));
        await bekle(t);
      }
      t.platformDispatcher.textScaleFactorTestValue = yazi;
      await bekle(t);
      return sp;
    }

    // HIG: Dynamic Type 3,1×'e kadar taşma yok (taşma test hatasıdır).
    for (final yazi in [1.0, 3.1]) {
      testWidgets('çiz, geri al, hedef yap; kartta dolar, silinince gider (yazı $yazi×)', (t) async {
        final sp = await kampaGel(t, yazi: yazi);
        await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"2026-10-19T10:00:00.000","tutarTl":50,"birimFiyat":1}]');
        final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
        kap.invalidate(hareketlerProvider);
        await bekle(t);
        Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
        await bekle(t);
        await t.scrollUntilVisible(find.text('Hedef seç'), 200, scrollable: find.byType(Scrollable).last);
        await t.ensureVisible(find.text('Hedef seç'));
        await bekle(t);
        await t.tap(find.text('Hedef seç'));
        await bekle(t);

        // Yarım çizim kaybolmaz: "Kapat" ve dışına dokunma taslağı bırakır,
        // hedef seçilmez.
        Cizim? cizimde() => t.widgetList<CustomPaint>(find.descendant(of: find.byKey(const ValueKey('cizim-alani')), matching: find.byType(CustomPaint)))
            .map((p) => p.painter).whereType<CizimBoyaci>().first.cizim;
        Future<void> cizimiAc() async {
          await t.ensureVisible(find.text('Kendin çiz'));
          await t.tap(find.text('Kendin çiz'));
          await bekle(t);
        }

        await cizimiAc();
        expect(find.text('Hedefini çiz'), findsOneWidget);
        expect(find.bySemanticsLabel('Çizim alanı. Parmağınla çiz.'), findsOneWidget);
        final alan = find.byKey(const ValueKey('cizim-alani'));
        await t.ensureVisible(alan);
        await bekle(t);
        // Dikey çizgi: sayfa kaydırması ya da alt sayfanın aşağı çekilmesi yutmamalı.
        await t.timedDragFrom(t.getTopLeft(alan) + const Offset(40, 40), const Offset(0, 150), const Duration(milliseconds: 300));
        await bekle(t);
        await t.ensureVisible(find.text('Kapat'));
        await t.tap(find.text('Kapat'));
        await bekle(t);
        expect(find.text('Hedefini çiz'), findsNothing);
        expect(find.text('Yeniden çiz'), findsNothing, reason: 'Bitti denmeden hedef seçilmez');

        await cizimiAc();
        expect(cizimde()!.cizgiler.length, 1, reason: 'Kapat taslağı bıraktı');
        await t.ensureVisible(find.bySemanticsLabel('Kırmızı'));
        await t.tap(find.bySemanticsLabel('Kırmızı'));
        await bekle(t);
        await t.ensureVisible(alan);
        await t.dragFrom(t.getTopLeft(alan) + const Offset(60, 60), const Offset(120, 30));
        await bekle(t);
        // Geri tuşu (dışına dokunma ve aşağı çekmeyle aynı yol: sonuçsuz kapanış) da taslağı bırakır.
        await t.binding.handlePopRoute();
        await bekle(t);
        expect(find.text('Hedefini çiz'), findsNothing);
        await cizimiAc();
        expect(cizimde()!.cizgiler.map((c) => c.renk), [0, 1], reason: 'geri tuşu taslağı bıraktı');
        await t.ensureVisible(alan);
        await t.dragFrom(t.getTopLeft(alan) + const Offset(30, 200), const Offset(90, 0));
        await bekle(t);
        await t.ensureVisible(find.text('Geri al'));
        await t.tap(find.text('Geri al'));
        await bekle(t);
        await t.ensureVisible(find.text('Bitti'));
        await t.tap(find.text('Bitti'));
        await bekle(t);

        expect(find.text('Hedefini çiz'), findsNothing);
        expect(find.text('Yeniden çiz'), findsOneWidget, reason: 'önizleme ve yeniden çiz');
        await t.enterText(find.byType(TextField), '200');
        await bekle(t);
        await t.ensureVisible(find.text('Hedefi koy'));
        await t.tap(find.text('Hedefi koy'));
        await bekle(t);

        final h = kap.read(hedeflerProvider)[VarlikTuru.nakit]!;
        expect(h.esya, HedefEsya.cizim);
        expect(h.cizim!.cizgiler.map((c) => c.renk), [0, 1], reason: 'geri al son çizgiyi kaldırdı');
        expect(h.cizim!.cizgiler.first.noktalar.length, greaterThan(3), reason: 'dikey çizgi çizildi');
        expect(h.cizim!.cizgiler.first.noktalar.first.dy, lessThan(h.cizim!.cizgiler.first.noktalar.last.dy));

        final liste = find.descendant(of: find.byType(VarlikDetayEkrani), matching: find.byType(Scrollable)).first;
        await t.drag(liste, const Offset(0, 6000));
        await bekle(t);
        await t.scrollUntilVisible(find.byType(HedefEsyasi), 200, scrollable: liste);
        await t.ensureVisible(find.byType(HedefEsyasi));
        await bekle(t);
        expect(find.text('Sincap senin çizdiğin şey için biriktiriyor'), findsOneWidget);
        // Kart dokunulabilir: etiket kartın okunan cümlesine katılır.
        expect(find.bySemanticsLabel(RegExp('Senin çizimin')), findsWidgets);
        expect(t.widget<HedefEsyasi>(find.byType(HedefEsyasi)).doluluk, closeTo(.25, 1e-9));

        // Kayıtta kalır, yeniden okununca aynı; "tüm veriyi sil" götürür.
        expect(sp.getString('hedefler_v1'), contains('cizim'));
        expect(Depo(sp).hedefleriOku()[VarlikTuru.nakit], h);
        await Depo(sp).hepsiniSil();
        expect(sp.getString('hedefler_v1'), isNull);
      });
    }
  });
}
