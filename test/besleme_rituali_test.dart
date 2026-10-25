import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/avuc_parasi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Besleme ritüeli: "Ver"den sonra yiyecek avuçta bekler; çocuk sürükleyip
/// karaktere uzatır, fırlatır ya da dokunur. Uzakta bırakırsa avuca döner.
/// Karaktere dokunmak da verir. Kamp gizlenirse kendiliğinden verilir.
/// Hareketi azalt açıkken avuç yok. Kayıt her durumda "Ver"de yapılmıştır.
void main() {
  Future<void> kampaGel(WidgetTester t, {bool hareketsiz = false}) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: hareketsiz);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final sahteHttp = MockClient((_) async => http.Response(
        '{"USD":{"Satış":41.2},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    await t.pumpWidget(ProviderScope(
      overrides: [
        depoProvider.overrideWithValue(Depo(sp)),
        fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
      ],
      child: const HarcliklarimApp(),
    ));
    await bekle(t);
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
      await t.tap(find.text(d));
      await bekle(t);
    }
  }

  /// Zıpzıp'i (ikinci satır) besler: 100 ₺ ver. Avuç açılır.
  Future<void> zipzipiBesle(WidgetTester t) async {
    await t.tap(find.text('Besle').at(1));
    await bekle(t);
    await t.enterText(find.byType(TextField), '100');
    await bekle(t);
    await t.tap(find.text("Zıpzıp'a ver"));
    await bekle(t);
  }

  Finder avuc() => find.bySemanticsLabel("Zıpzıp'a ver");
  Finder zipzip() => find.byWidgetPredicate((w) => w is Karakter && w.tur == VarlikTuru.dolar && w.boyut == 92);

  testWidgets('avuçta bekler, karakter ona bakar; karaktere sürükleyince yer', (t) async {
    await kampaGel(t);
    await zipzipiBesle(t);
    expect(avuc(), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing, reason: 'mesaj yiyecek verilince gelir');
    expect(t.widget<Karakter>(zipzip()).avuc, isNotNull, reason: 'karakter avucu izler');
    // Yalnız bu karakter izler.
    final baska = t.widget<Karakter>(find.byWidgetPredicate((w) => w is Karakter && w.tur == VarlikTuru.euro && w.boyut == 92));
    expect(baska.avuc, isNull);

    final bas = t.getCenter(avuc());
    final hedef = t.getCenter(zipzip());
    final g = await t.startGesture(bas);
    for (var i = 1; i <= 10; i++) {
      await g.moveTo(Offset.lerp(bas, hedef, i / 10)!);
      await t.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await bekle(t);
    expect(avuc(), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('uzakta bırakınca avuca döner, sonra karaktere dokununca yer', (t) async {
    await kampaGel(t);
    await zipzipiBesle(t);
    final bas = t.getCenter(avuc());
    await t.dragFrom(bas, const Offset(0, 160));
    await bekle(t);
    expect(avuc(), findsOneWidget);
    expect((t.getCenter(avuc()) - bas).distance, lessThan(8), reason: 'avuca geri döndü');

    await t.tap(zipzip());
    await bekle(t);
    expect(avuc(), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Zıpzıp'), findsWidgets, reason: 'detay sayfası açılmadı, kampta');
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('başka sekmeye geçilirse kendiliğinden verilir', (t) async {
    await kampaGel(t);
    await zipzipiBesle(t);
    expect(avuc(), findsOneWidget);
    await t.tap(find.byIcon(Icons.menu_book_outlined));
    await bekle(t);
    expect(avuc(), findsNothing);
    expect(t.takeException(), isNull);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('hareketi azalt: avuç yok, mesaj hemen', (t) async {
    await kampaGel(t, hareketsiz: true);
    await zipzipiBesle(t);
    expect(find.byType(AvucParasi), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  test('her karakterin kendi yiyeceği çizilir', () {
    for (final tur in VarlikTuru.values) {
      expect(yemekGirisNoktasi[tur], isNotNull);
      expect(yemeZamani(tur).tutma, lessThan(yemeZamani(tur).yum));
      expect(yemeZamani(tur).yum, lessThan(yemeZamani(tur).sevinc));
    }
  });
}
