import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/hedef.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/hedef_esyasi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Hedef = karakterin taşıdığı eşya (yol haritası 2.1). İlerleme sayı değil
/// eşyanın dolması; kumbaraya konandan ölçülür (fiyat düşünce boşalmaz);
/// bir kez dolunca dolu kalır ve sevinç bir kez oynar.
void main() {
  Hareket h(String id, VarlikTuru t, double tutar, double fiyat, {int gun = 0}) =>
      Hareket(id: id, tur: t, tarih: DateTime(2026, 10, 19 + gun), tutarTl: tutar, birimFiyat: fiyat);

  group('model', () {
    test('doluluk kumbaraya konandan; fiyat düşünce eşya boşalmaz', () {
      const hd = Hedef(esya: HedefEsya.bisiklet, fiyatTl: 1000);
      final pahali = KarakterDurumu.hesapla(VarlikTuru.dolar, [h('a', VarlikTuru.dolar, 400, 40)], 40);
      final ucuz = KarakterDurumu.hesapla(VarlikTuru.dolar, [h('a', VarlikTuru.dolar, 400, 40)], 20);
      expect(hd.doluluk(pahali), closeTo(.4, 1e-9));
      expect(hd.doluluk(ucuz), closeTo(.4, 1e-9), reason: 'piyasa eşyayı boşaltmaz');
      expect(hd.doluluk(KarakterDurumu.hesapla(VarlikTuru.dolar, [h('a', VarlikTuru.dolar, 4000, 40)], 40)), 1, reason: '1\'i aşmaz');
    });

    test('bir kez dolunca dolu kalır; kumbaradan almak geri almaz', () {
      const hd = Hedef(esya: HedefEsya.top, fiyatTl: 100);
      final dolu = KarakterDurumu.hesapla(VarlikTuru.nakit, [h('a', VarlikTuru.nakit, 100, 1)], 1);
      expect(hd.simdiDoldu(dolu), isTrue);
      final ulasti = hd.ulas(DateTime(2026, 10, 20));
      expect(ulasti.simdiDoldu(dolu), isFalse, reason: 'ikinci kez sevinmez');
      final alindi = KarakterDurumu.hesapla(VarlikTuru.nakit, [h('a', VarlikTuru.nakit, 100, 1), h('b', VarlikTuru.nakit, -100, 1, gun: 1)], 1);
      expect(hd.doluluk(alindi), 0);
      expect(ulasti.doluluk(alindi), 1);
    });

    test('kuruş yuvarlaması dolmayı engellemez', () {
      const hd = Hedef(esya: HedefEsya.kitap, fiyatTl: 100);
      expect(hd.simdiDoldu(KarakterDurumu.hesapla(VarlikTuru.nakit, [h('a', VarlikTuru.nakit, 99.996, 1)], 1)), isTrue);
      expect(hd.simdiDoldu(KarakterDurumu.hesapla(VarlikTuru.nakit, [h('a', VarlikTuru.nakit, 99, 1)], 1)), isFalse);
    });

    test('kademe kelimeleri', () {
      expect(hedefKademe(0), HedefKademe.basladi);
      expect(hedefKademe(.49), HedefKademe.basladi);
      expect(hedefKademe(.5), HedefKademe.yarim);
      expect(hedefKademe(.8), HedefKademe.neredeyse);
      expect(hedefKademe(1), HedefKademe.hazir);
    });

    test('JSON gidiş-dönüş; bozuk kayıt yok sayılır, silinince gider', () async {
      SharedPreferences.setMockInitialValues({
        'hedefler_v1': '{"dolar":{"esya":"kaykay","fiyatTl":750,"ulasildi":"2026-10-20T10:00:00.000"},'
            '"euro":{"esya":"uzay_gemisi","fiyatTl":5},"altin":{"esya":"top","fiyatTl":-3},"yok":{"esya":"top","fiyatTl":5}}',
      });
      final depo = Depo(await SharedPreferences.getInstance());
      final m = depo.hedefleriOku();
      expect(m.keys, [VarlikTuru.dolar]);
      expect(m[VarlikTuru.dolar], Hedef(esya: HedefEsya.kaykay, fiyatTl: 750, ulasildi: DateTime(2026, 10, 20, 10)));
      await depo.hedefleriYaz({VarlikTuru.nakit: const Hedef(esya: HedefEsya.oyun, fiyatTl: 12.5)});
      expect(depo.hedefleriOku(), {VarlikTuru.nakit: const Hedef(esya: HedefEsya.oyun, fiyatTl: 12.5)});
      await depo.hepsiniSil();
      expect(depo.hedefleriOku(), isEmpty);
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
      for (final d in ['Devam', 'Devam', 'Devam', 'Şimdilik geç']) {
        await t.tap(find.text(d));
        await bekle(t);
      }
      t.platformDispatcher.textScaleFactorTestValue = yazi;
      await bekle(t);
      return sp;
    }

    // HIG: Dynamic Type 3,1×'e kadar taşma yok (taşma test hatasıdır).
    for (final yazi in [1.0, 3.1]) {
      testWidgets('hedef seç, eşya dolar, dolunca bir kez sevinir (yazı $yazi×)', (t) async {
        final sp = await kampaGel(t, yazi: yazi);
        await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"2026-10-19T10:00:00.000","tutarTl":120,"birimFiyat":1}]');
        final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
        kap.invalidate(hareketlerProvider);
        await bekle(t);
        Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
        await bekle(t);

        // Liste önbelleği kartı ekran dışında da kurar: kaydırıp göster.
        await t.scrollUntilVisible(find.text('Hedef seç'), 200, scrollable: find.byType(Scrollable).last);
        await t.ensureVisible(find.text('Hedef seç'));
        await bekle(t);
        await t.tap(find.text('Hedef seç'));
        await bekle(t);
        expect(find.text('Sincap ne için biriktirsin?'), findsOneWidget);
        await t.ensureVisible(find.text('Top'));
        await t.tap(find.text('Top'));
        await bekle(t);
        await t.enterText(find.byType(TextField), '200');
        await bekle(t);
        await t.ensureVisible(find.text('Hedefi koy'));
        await t.tap(find.text('Hedefi koy'));
        await bekle(t);

        // Detay listesi tembel kurar: baştan aşağı kaydırıp göster.
        Future<void> goster(Finder f) async {
          final liste = find.descendant(of: find.byType(VarlikDetayEkrani), matching: find.byType(Scrollable)).first;
          await t.drag(liste, const Offset(0, 6000));
          await bekle(t);
          await t.scrollUntilVisible(f, 200, scrollable: liste);
          await t.ensureVisible(f);
          await bekle(t);
        }

        await goster(find.byType(HedefEsyasi));
        expect(find.text('Sincap top için biriktiriyor'), findsOneWidget);
        expect(find.text('Yarısı doldu'), findsOneWidget);
        expect(t.widget<HedefEsyasi>(find.byType(HedefEsyasi)).doluluk, closeTo(.6, 1e-9));
        expect(find.textContaining('200'), findsNothing, reason: 'fiyat ekranda görünmez');

        // Fiyatı düşür: hemen dolar, bir kez sevinir.
        await goster(find.text('Değiştir'));
        await t.tap(find.text('Değiştir'));
        await bekle(t);
        await t.enterText(find.byType(TextField), '100');
        await bekle(t);
        await t.ensureVisible(find.text('Hedefi koy'));
        await t.tap(find.text('Hedefi koy'));
        await bekle(t);
        expect(find.text('Top hazır! Sincap çok sevindi.'), findsWidgets, reason: 'bildirim');
        await goster(find.byType(HedefEsyasi));
        expect(find.text('Top hazır! Sincap çok sevindi.'), findsWidgets, reason: 'kart');
        expect(find.text('Doldu!'), findsOneWidget);
        expect(kap.read(hedeflerProvider)[VarlikTuru.nakit]!.ulasildi, isNotNull);
        expect(sp.getString('hedefler_v1'), contains('ulasildi'));

        // Yeni hedef boş başlar; kaldırılabilir.
        await t.pump(const Duration(seconds: 3));
        await goster(find.text('Yeni hedef'));
        await t.tap(find.text('Yeni hedef'));
        await bekle(t);
        await t.ensureVisible(find.text('Hedefi kaldır'));
        await t.tap(find.text('Hedefi kaldır'));
        await bekle(t);
        expect(kap.read(hedeflerProvider), isEmpty);
        await goster(find.text('Hedef seç'));
        expect(find.text('Hedef seç'), findsOneWidget);
      });
    }
  });
}
