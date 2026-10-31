import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// "Nereden geldi?" (yol haritası 2.3, bayram / hediye harçlığı): isteğe
/// bağlı etiket; eski kayıtlar bozulmadan okunur; etiket ödül ya da sayı
/// getirmez, yalnız karakterin sıcak bir cümlesi ve satırda ikon + yazı.
void main() {
  group('model', () {
    test('eski kayıt etiketsiz okunur; etiket gidiş-dönüş', () {
      final eski = Hareket.fromJson({'id': 'a', 'tur': 'nakit', 'tarih': '2026-10-19T10:00:00.000', 'tutarTl': 20, 'birimFiyat': 1});
      expect(eski.kaynak, isNull);
      expect(eski.toJson().containsKey('kaynak'), isFalse, reason: 'etiketsiz kayıt biçimi değişmez');
      final h = Hareket(id: 'b', tur: VarlikTuru.altin, tarih: DateTime(2026, 10, 31), tutarTl: 500, birimFiyat: 5000, kaynak: HareketKaynagi.hediye);
      expect(Hareket.fromJson(h.toJson()).kaynak, HareketKaynagi.hediye);
    });

    test('bilinmeyen etiket kaydı düşürmez', () {
      final h = Hareket.fromJson({'id': 'a', 'tur': 'nakit', 'tarih': '2026-10-19T10:00:00.000', 'tutarTl': 20, 'birimFiyat': 1, 'kaynak': 'piyango'});
      expect(h.kaynak, isNull);
      expect(h.tutarTl, 20);
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
      await t.pumpWidget(ProviderScope(overrides: [
        depoProvider.overrideWithValue(Depo(sp)),
        fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
      ], child: const HarcliklarimApp()));
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
      testWidgets('kendim kazandım etiketiyle besle; satırda ikon + yazı (yazı $yazi×)', (t) async {
        final sp = await kampaGel(t, yazi: yazi);
        // Bu haftanın beslemesi: yeni besleme odun getirmesin ki mesaj kaynak cümlesi olsun.
        await sp.setString('hareketler_v1', '[{"id":"a","tur":"nakit","tarih":"${DateTime.now().toIso8601String()}","tutarTl":20,"birimFiyat":1}]');
        await sp.setStringList('cikartmalar_v1', ['ilk_besleme']);
        final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
        kap.invalidate(hareketlerProvider);
        kap.invalidate(cikartmalarProvider);
        await bekle(t);
        Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
        await bekle(t);

        final besle = find.text('Biraz daha besle');
        await t.scrollUntilVisible(besle, 200, scrollable: find.byType(Scrollable).last);
        await t.ensureVisible(besle);
        await t.pump();
        await t.tap(besle);
        await bekle(t);
        await t.enterText(find.byType(TextField), '30');
        await bekle(t);
        expect(find.text('Nereden geldi? (istersen)'), findsOneWidget);
        await t.ensureVisible(find.text('Kendim kazandım'));
        await t.tap(find.text('Kendim kazandım'));
        await bekle(t);
        await t.ensureVisible(find.text("Sincap'a ver"));
        await t.tap(find.text("Sincap'a ver"));
        await bekle(t);

        expect(kap.read(hareketlerProvider).last.kaynak, HareketKaynagi.emek);
        expect(sp.getString('hareketler_v1'), contains('"kaynak":"emek"'));
        expect(find.text('Sincap: Bunu sen kazandın, özenle saklıyorum!'), findsOneWidget);
        // Etiket ödül vermez: çıkartma kümesi aynı.
        expect(kap.read(cikartmalarProvider), {'ilk_besleme'});

        final satir = find.text('Kendim kazandım');
        await t.scrollUntilVisible(satir, 200, scrollable: find.byType(Scrollable).last);
        expect(satir, findsOneWidget);
        expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
      });
    }

    testWidgets('seçili etikete yeniden dokununca kalkar; etiketsiz besleme eskisi gibi', (t) async {
      await kampaGel(t);
      final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
      Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
      await bekle(t);
      final besle = find.text('Biraz daha besle');
      await t.scrollUntilVisible(besle, 200, scrollable: find.byType(Scrollable).last);
      await t.ensureVisible(besle);
      await t.pump();
      await t.tap(besle);
      await bekle(t);
      await t.enterText(find.byType(TextField), '10');
      await bekle(t);
      await t.tap(find.text('Hediye'));
      await bekle(t);
      await t.tap(find.text('Hediye'));
      await bekle(t);
      await t.ensureVisible(find.text("Sincap'a ver"));
      await t.tap(find.text("Sincap'a ver"));
      await bekle(t);
      expect(kap.read(hareketlerProvider).single.kaynak, isNull);
    });
  });
}
