import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Ürün tezi: ekranda en fazla iki sayı, toplam ve fark (Ar-Ge 24 Eki 11:07 #2).
/// Kamp'ta karakter başına fark ve liste miktarı yazılmaz; karakter ekranında durur.
void main() {
  testWidgets('kamp ekranında yalnız toplam ve fark', (t) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final sahteHttp = MockClient((_) async => http.Response(
        '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    await t.pumpWidget(ProviderScope(
      overrides: [
        depoProvider.overrideWithValue(Depo(sp)),
        fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
      ],
      child: const HarcliklarimApp(),
    ));
    await bekle(t);
    expect(find.textContaining('Gerçek kumbarana'), findsOneWidget, reason: 'uygulama para tutmaz: karşılama söyler');
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
      await t.tap(find.text(d));
      await bekle(t);
    }
    expect(find.textContaining('Kumbarana para koyduğunda'), findsOneWidget, reason: 'boş kamp ritüeli söyler');

    await sp.setString('hareketler_v1',
        '[{"id":"a","tur":"altin","tarih":"2026-10-01T10:00:00.000","tutarTl":580,"birimFiyat":5000},'
        '{"id":"b","tur":"dolar","tarih":"2026-10-01T10:00:00.000","tutarTl":380,"birimFiyat":38},'
        '{"id":"c","tur":"nakit","tarih":"2026-10-01T10:00:00.000","tutarTl":50,"birimFiyat":1}]');
    final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
    kap.invalidate(hareketlerProvider);
    await bekle(t);

    final kamp = find.byType(KampEkrani);
    final sayilar = find.descendant(
      of: kamp,
      matching: find.byWidgetPredicate((w) => w is Text && RegExp(r'\d').hasMatch(w.data ?? '') && RegExp(r'[₺$€g]').hasMatch(w.data ?? '')),
    );
    expect(sayilar.evaluate().map((e) => (e.widget as Text).data).toList(), hasLength(2), reason: 'toplam ve fark');
  });
}
