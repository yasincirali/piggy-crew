import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Ar-Ge 1 Kas 11:07 (yasin "Yap dediklerini ilerlet"):
/// #2 küçük yaşta Besle'de fiyat ve gram satırı yerine karakter cümlesi,
///    11–15 iki satırı korur;
/// #1 kupür düğmeleri banknot (renk şeridi + kâğıt), 44 pt altına inmez;
/// #5 veli köşesinde "son 30 günde n kez kendi kazandığından koydu", 0'da yok.
void main() {
  Future<void> besleyeGel(WidgetTester t, {required String yas, required String tur, Map<String, Object> ek = const {}}) async {
    rootBundle.clear();
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'cocuk_v1': '{"ad":"Deniz","yas":"$yas","dunya":"orman","olusturma":"2026-10-01T10:00:00.000","para":"TRY"}',
      ...ek,
    });
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
    await t.tap(find.byKey(ValueKey('besle-$tur')));
    await bekle(t);
  }

  testWidgets('7–10: fiyat ve gram satırı yok, karakter cümlesi var', (t) async {
    await besleyeGel(t, yas: 'kucuk', tur: 'altin');
    expect(find.text('Tortu bunu altın olarak saklar.'), findsOneWidget);
    expect(find.textContaining('Bugün 1 g'), findsNothing);
    await t.enterText(find.byType(TextField), '250');
    await bekle(t);
    expect(find.textContaining('alırsın'), findsNothing);
  });

  testWidgets('11–15: fiyat ve gram satırı kalır, karakter cümlesi yok', (t) async {
    await besleyeGel(t, yas: 'buyuk', tur: 'altin');
    expect(find.text('Tortu bunu altın olarak saklar.'), findsNothing);
    await t.enterText(find.byType(TextField), '250');
    await bekle(t);
    expect(find.textContaining('alırsın'), findsOneWidget);
  });

  testWidgets('kupürler banknot: renk şeridi, 44 pt+, etiket aynı', (t) async {
    await besleyeGel(t, yas: 'kucuk', tur: 'nakit');
    for (final v in ParaBirimi.tryy.kupurler) {
      final d = find.byKey(ValueKey('kupur-$v'));
      expect(t.getSize(d).height, greaterThanOrEqualTo(44), reason: '$v ₺');
      final serit = find.descendant(
          of: d, matching: find.byWidgetPredicate((w) => w is Container && w.color == ParaBirimi.tryy.kupurRengi(v)));
      expect(serit, findsOneWidget, reason: '$v ₺ şeridi');
    }
    expect(find.bySemanticsLabel(RegExp('^20 ₺ ekle')), findsOneWidget);
  });

  test('kupür renkleri: TL banknotları birbirinden ayrılır', () {
    final renkler = ParaBirimi.tryy.kupurler.map(ParaBirimi.tryy.kupurRengi).toSet();
    expect(renkler.length, ParaBirimi.tryy.kupurler.length);
    for (final p in ParaBirimi.values) {
      for (final v in p.kupurler) {
        expect(p.kupurRengi(v).a, 1.0, reason: '${p.kod} $v opak');
      }
    }
  });

  test('kendi kazandığı: yalnız emek etiketli, son 30 gün, almalar sayılmaz', () {
    final simdi = DateTime(2026, 11, 1, 12);
    Hareket h(String id, int gunOnce, {HareketKaynagi? k, double tutar = 50}) => Hareket(
        id: id, tur: VarlikTuru.nakit, tarih: simdi.subtract(Duration(days: gunOnce)), tutarTl: tutar, birimFiyat: 1, kaynak: k);
    final liste = [
      h('a', 1, k: HareketKaynagi.emek),
      h('b', 29, k: HareketKaynagi.emek),
      h('c', 31, k: HareketKaynagi.emek), // pencere dışı
      h('d', 2, k: HareketKaynagi.harclik),
      h('e', 3), // etiketsiz
      h('f', 4, k: HareketKaynagi.emek, tutar: -20), // kumbaradan alma
    ];
    expect(liste.kendiKazandigiSon30Gun(simdi), 2);
    expect(<Hareket>[].kendiKazandigiSon30Gun(simdi), 0);
  });
}
