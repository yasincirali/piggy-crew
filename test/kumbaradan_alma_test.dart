import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/evre.dart';
import 'package:harcliklarim/models/odun.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/kamp_atesi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Kumbaradan alma + kamp odunu (Ar-Ge raporu 2026-10-23 #1). Harcamak
/// cezalandırılmaz: ateş, evre ve çıkartmalar yalnız beslemelerden; ateş
/// odunla büyür, odun eksilmez. Maliyet ortalama maliyetle düşer.
void main() {
  Hareket h(String id, VarlikTuru t, DateTime tarih, double tutar, double fiyat) => Hareket(id: id, tur: t, tarih: tarih, tutarTl: tutar, birimFiyat: fiyat);
  final pzt = DateTime(2026, 10, 19);

  group('model', () {
    test('alma ortalama maliyetle düşer, kalan kâr şişmez', () {
      final d = KarakterDurumu.hesapla(VarlikTuru.dolar, [
        h('a', VarlikTuru.dolar, pzt, 300, 30), // 10 $
        h('b', VarlikTuru.dolar, pzt.add(const Duration(days: 1)), -200, 40), // 5 $ alındı
      ], 40);
      expect(d.miktar, closeTo(5, 1e-9));
      expect(d.maliyetTl, closeTo(150, 1e-9));
      expect(d.degerTl, closeTo(200, 1e-9));
      expect(d.farkTl, closeTo(50, 1e-9));
      expect(d.verilenTl, 300, reason: 'verilen toplam almayla düşmez (süs kaybolmasın)');
    });

    test('hepsi alınınca boş; kayan nokta artığı boş sayılır', () {
      const f = 41.2;
      final d = KarakterDurumu.hesapla(VarlikTuru.dolar, [
        h('a', VarlikTuru.dolar, pzt, 100, f),
        h('b', VarlikTuru.dolar, pzt, 33.3, f),
        h('c', VarlikTuru.dolar, pzt.add(const Duration(hours: 1)), -(133.3 / f) * f, f),
      ], f);
      expect(d.bos, isTrue);
      expect(d.maliyetTl, 0);
    });

    test('alma evre ve odun saymaz', () {
      final hs = [h('a', VarlikTuru.nakit, pzt, 50, 1), h('b', VarlikTuru.nakit, pzt.add(const Duration(days: 8)), -20, 1), h('c', VarlikTuru.nakit, pzt.add(const Duration(days: 15)), -10, 1)];
      expect(beslemeGunu(hs, VarlikTuru.nakit), 1);
      expect(Odun.say(hs), 1);
    });

    test('odun = farklı hafta; ardışık olması gerekmez; geri gitmez', () {
      final hs = [
        h('a', VarlikTuru.nakit, pzt, 10, 1),
        h('b', VarlikTuru.nakit, pzt.add(const Duration(days: 2)), 10, 1), // aynı hafta
        h('c', VarlikTuru.altin, pzt.add(const Duration(days: 21)), 10, 5000), // 3 hafta ara
      ];
      expect(Odun.say(hs), 2);
      expect(Odun.gosterilen(1, 2), 2);
      expect(Odun.gosterilen(3, 2), 3);
    });

    test('ateş odunla büyür, tutar ateşi değiştirmez', () {
      expect(KampAtesi.olcek(0), .5);
      expect(KampAtesi.olcek(Odun.tamBoy), closeTo(1.15, 1e-9));
      expect(KampAtesi.olcek(Odun.tamBoy + 20), closeTo(1.15, 1e-9), reason: 'sonsuz büyümez');
      expect(KampAtesi.olcek(4), greaterThan(KampAtesi.olcek(3)));
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
      // Önbellekteki varlık okuması önceki testin sahte saatinde kalmış olabilir.
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
      // Büyük yazı karşılamadan sonra: karşılamanın kendisi dynamic_type_test'te.
      t.platformDispatcher.textScaleFactorTestValue = yazi;
      await bekle(t);
      return sp;
    }

    testWidgets('haftanın ilk beslemesi ateşe odun ekler ve söyler', (t) async {
      final sp = await kampaGel(t);
      // Geçen ay bir besleme ve ilk çıkartma zaten var: bu besleme yeni hafta.
      await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"2026-09-01T10:00:00.000","tutarTl":20,"birimFiyat":1}]');
      await sp.setStringList('cikartmalar_v1', ['ilk_besleme', 'sabir_30']);
      final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
      kap.invalidate(hareketlerProvider);
      kap.invalidate(cikartmalarProvider);
      await bekle(t);
      expect(kap.read(odunProvider), 1);
      await t.tap(find.byKey(const ValueKey('besle-nakit')));
      await bekle(t);
      await t.enterText(find.byType(TextField), '10');
      await bekle(t);
      await t.tap(find.text("Sincap'a ver"));
      await bekle(t);
      expect(find.text('Bu hafta ateşe bir odun eklendi!'), findsOneWidget);
      expect(kap.read(odunProvider), 2);
      expect(t.widget<KampAtesi>(find.byType(KampAtesi)).odun, 2);
    });

    // HIG: Dynamic Type 3,1×'e kadar taşma yok (taşma test hatasıdır).
    for (final yazi in [1.0, 3.1]) {
      testWidgets('varlık ekranında kumbaradan alma (yazı $yazi×)', (t) async {
        final sp = await kampaGel(t, yazi: yazi);
        await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"2026-10-19T10:00:00.000","tutarTl":120,"birimFiyat":1}]');
        // Depo okuması provider kurulurken yapıldı; yeniden kur.
        final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
        kap.invalidate(hareketlerProvider);
        await bekle(t);
        final odunOnce = kap.read(odunProvider);
        expect(odunOnce, 1);

        // Büyük yazıda sahne aşağı iner; detay doğrudan açılır.
        Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
        await bekle(t);
        await t.scrollUntilVisible(find.text('Kumbaradan aldım'), 200, scrollable: find.byType(Scrollable).last);
        await t.ensureVisible(find.text('Kumbaradan aldım'));
        await t.pump();
        await t.tap(find.text('Kumbaradan aldım'));
        await bekle(t);
        // Fazlası alınamaz.
        await t.enterText(find.byType(TextField), '500');
        await bekle(t);
        expect(find.text('Bu, kumbaradakinden fazla.'), findsOneWidget);
        await t.ensureVisible(find.text('Hepsi'));
        await t.tap(find.text('Hepsi'));
        await bekle(t);
        await t.ensureVisible(find.text('Aldım'));
        await t.tap(find.text('Aldım'));
        await bekle(t);
        expect(find.text('Sincap: İyi kullan!'), findsOneWidget);
        final d = kap.read(karakterlerProvider)[VarlikTuru.nakit]!;
        expect(d.bos, isTrue);
        expect(kap.read(odunProvider), odunOnce, reason: 'alma odunu eksiltmez');
        expect(kap.read(hareketlerProvider).last.cikis, isTrue);

        // İlk almadan sonra Sincap'ın ikilemi (bir kez). Büyük yazıda da sığar.
        expect(find.text('Sincap düşünüyor'), findsOneWidget);
        // Ders dosyası gerçek G/Ç ile okunur; sahte saat onu ilerletmez.
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.ensureVisible(find.text('Yuvaya tahta'));
        await t.tap(find.text('Yuvaya tahta'));
        await bekle(t);
        expect(find.text('Kışın sıcak bir yuva lazım! Bu bir ihtiyaç. Önce ihtiyaç, sonra istek.'), findsOneWidget);
        expect(find.text('Lazım mı, canın mı çekti?'), findsOneWidget, reason: 'ders sırası beklenmeden açılır');
        expect(kap.read(dersIlerlemeProvider), 0, reason: 'Öğren sırası değişmez');
        await t.ensureVisible(find.text('Tamam'));
        await t.tap(find.text('Tamam'));
        await bekle(t);
        expect(find.text('Sincap düşünüyor'), findsNothing);
        expect(sp.getBool('ikilem_gosterildi_v1'), isTrue);
      });
    }

    testWidgets('ikilem yalnız ilk almadan sonra; istek de sıcak karşılanır', (t) async {
      final sp = await kampaGel(t);
      await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"2026-10-19T10:00:00.000","tutarTl":120,"birimFiyat":1}]');
      final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
      kap.invalidate(hareketlerProvider);
      await bekle(t);
      Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
      await bekle(t);

      Future<void> al() async {
        await t.scrollUntilVisible(find.text('Kumbaradan aldım'), 200, scrollable: find.byType(Scrollable).last);
        await t.ensureVisible(find.text('Kumbaradan aldım'));
        await t.pump();
        await t.tap(find.text('Kumbaradan aldım'));
        await bekle(t);
        await t.enterText(find.byType(TextField), '10');
        await bekle(t);
        await t.tap(find.text('Aldım'));
        await bekle(t);
      }

      await al();
      expect(find.text('Sincap düşünüyor'), findsOneWidget);
      await t.tap(find.text('Yeni palamut'));
      await bekle(t);
      expect(find.text('Canının çektiği bir şey! Bu bir istek. İstekler de güzel, sırası gelince.'), findsOneWidget);
      await t.tap(find.text('Tamam'));
      await bekle(t);

      await al();
      expect(find.text('Sincap düşünüyor'), findsNothing, reason: 'ikinci almada tekrar etmez');
      expect(kap.read(hareketlerProvider).where((h) => h.cikis).length, 2);
    });
  });
}
