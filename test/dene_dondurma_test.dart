import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/ders.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/dene_dondurma.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Öğren "Dokunarak dene" (Ar-Ge 1 Kas 11:07 #1): yalnız enflasyon dersinde
/// dondurma kartı; yıl değişince cümle değişir, top küçülür; çipler 44 pt+;
/// büyük yazıda taşma yok; diğer derslerde kart yok.
void main() {
  late List<Ders> dersler;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dersler = await Ders.yukle('tr');
  });

  Future<void> ogreneGel(WidgetTester t, {required String dersId, double olcek = 1}) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.platformDispatcher.textScaleFactorTestValue = olcek;
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'cocuk_v1': '{"ad":"Deniz","yas":"kucuk","dunya":"orman","olusturma":"2026-10-01T10:00:00.000","para":"TRY"}',
      'ders_ilerleme_v1': dersler.indexWhere((d) => d.id == dersId),
    });
    final sp = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: [
        derslerProvider.overrideWith((_, _) => dersler),
        depoProvider.overrideWithValue(Depo(sp)),
        fiyatServisiProvider.overrideWithValue(FiyatServisi(
          istemci: MockClient((_) async => http.Response(
              '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})),
          tercihler: sp,
        )),
      ],
      child: const HarcliklarimApp(),
    ));
    await bekle(t);
    await t.tap(find.text('Öğren').last);
    await bekle(t);
  }

  double topOrani(WidgetTester t) {
    final cp = t.widget<CustomPaint>(
        find.descendant(of: find.byType(DeneDondurma), matching: find.byType(CustomPaint)).first);
    return (cp.painter as dynamic).top as double;
  }

  test('yalnız enflasyon dersinde etkileşim var (6 dil)', () async {
    for (final dil in Ders.diller) {
      final d = await Ders.yukle(dil);
      expect(d.where((x) => x.etkilesim != null).map((x) => x.id), ['enflasyon'], reason: dil);
    }
  });

  testWidgets('enflasyon: yıl değişince cümle değişir, top küçülür, sayı yok', (t) async {
    await ogreneGel(t, dersId: 'enflasyon');
    expect(find.byType(DeneDondurma), findsOneWidget);
    expect(find.text('Bu para koca bir top dondurmaya yeter.'), findsOneWidget);
    expect(topOrani(t), 1.0);
    for (final c in ['Bu yıl', 'Gelecek yıl']) {
      expect(t.getSize(find.ancestor(of: find.text(c), matching: find.byType(AnimatedContainer)).first).height,
          greaterThanOrEqualTo(44));
    }
    await t.ensureVisible(find.text('Gelecek yıl'));
    await t.tap(find.text('Gelecek yıl'));
    await bekle(t);
    expect(find.text('Aynı para, daha küçük dondurma. Fiyatlar arttı.'), findsOneWidget);
    expect(topOrani(t), lessThan(1.0));
    // Kart sayı göstermez: içindeki hiçbir metinde rakam yok.
    final metinler = t.widgetList<Text>(find.descendant(of: find.byType(DeneDondurma), matching: find.byType(Text)));
    for (final m in metinler) {
      expect(RegExp(r'\d').hasMatch(m.data ?? ''), isFalse, reason: m.data);
    }
    await t.tap(find.text('Bu yıl'));
    await bekle(t);
    expect(topOrani(t), 1.0);
  });

  testWidgets('başka derste kart yok', (t) async {
    await ogreneGel(t, dersId: 'birikim');
    expect(find.byType(DeneDondurma), findsNothing);
  });

  testWidgets('3,1× yazıda taşmaz', (t) async {
    await ogreneGel(t, dersId: 'enflasyon', olcek: 3.1);
    await t.scrollUntilVisible(find.text('Gelecek yıl'), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text('Gelecek yıl'));
    await bekle(t);
    expect(t.takeException(), isNull);
  });
}
