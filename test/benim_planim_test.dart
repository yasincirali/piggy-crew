import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/ders.dart';
import 'package:harcliklarim/models/plan.dart';
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

const _govde = '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}';

/// "Benim planım" (Ar-Ge 26 Eki): karakter ekranında hedefin altında, çocuk
/// üç cümleden birini seçer; kalıcı, değiştirilir, kaldırılır, "Tüm veriyi
/// sil" siler. Sayı ve denetim yok.
void main() {
  late List<Ders> dersler;
  late SharedPreferences sp;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dersler = await Ders.yukle('tr');
  });

  Future<ProviderContainer> detay(WidgetTester t, {Map<String, Object> on = const {}, double yazi = 1}) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(on);
    sp = await SharedPreferences.getInstance();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          derslerProvider.overrideWith((_, _) => dersler),
          depoProvider.overrideWithValue(Depo(sp)),
          fiyatServisiProvider.overrideWithValue(
            FiyatServisi(
              istemci: MockClient(
                (_) async => http.Response(_govde, 200, headers: {'content-type': 'application/json; charset=utf-8'}),
              ),
              tercihler: sp,
            ),
          ),
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
    final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
    t.platformDispatcher.textScaleFactorTestValue = yazi;
    Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.altin));
    await bekle(t);
    return kap;
  }

  Future<void> gor(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(
      f,
      300,
      scrollable: find.descendant(of: find.byType(VarlikDetayEkrani), matching: find.byType(Scrollable)).first,
    );
    await bekle(t);
  }

  testWidgets('plan seçilir, kartta görünür ve saklanır; değişir, kalkar', (t) async {
    final kap = await detay(t);
    await gor(t, find.text('Plan seç'));
    expect(find.textContaining('Kimse kontrol etmez'), findsOneWidget);
    await t.tap(find.text('Plan seç'));
    await bekle(t);
    expect(find.text('Harçlığımı alınca bir kısmını Tortu ile biriktiririm.'), findsOneWidget);
    await t.tap(find.text('Bir şey almadan önce bir gün beklerim.'));
    await bekle(t);

    expect(kap.read(planlarProvider), {VarlikTuru.altin: PlanSablon.beklerim});
    expect(jsonDecode(sp.getString('planlar_v1')!), {'altin': 'beklerim'});
    expect(find.text('Bir şey almadan önce bir gün beklerim.'), findsOneWidget, reason: 'kartta çocuğun cümlesi');
    expect(find.text('Plan seç'), findsNothing);

    // Kart dokununca sayfa yeniden açılır: değiştir.
    await t.tap(find.text('Bir şey almadan önce bir gün beklerim.'));
    await bekle(t);
    await t.tap(find.text('Hafta sonu Tortu ile kumbarama bakarım.'));
    await bekle(t);
    expect(kap.read(planlarProvider)[VarlikTuru.altin], PlanSablon.bakarim);

    await t.tap(find.text('Hafta sonu Tortu ile kumbarama bakarım.'));
    await bekle(t);
    await t.ensureVisible(find.text('Planı kaldır'));
    await t.tap(find.text('Planı kaldır'));
    await bekle(t);
    expect(kap.read(planlarProvider), isEmpty);
    expect(find.text('Plan seç'), findsOneWidget);
  });

  testWidgets('plan karakter başına: başka karakterin ekranında görünmez', (t) async {
    final kap = await detay(t, on: {'planlar_v1': jsonEncode({'nakit': 'biriktiririm'})});
    expect(kap.read(planlarProvider), {VarlikTuru.nakit: PlanSablon.biriktiririm});
    await gor(t, find.text('Plan seç'));
    expect(find.textContaining('biriktiririm.'), findsNothing);
  });

  testWidgets('bozuk ya da bilinmeyen kayıt atlanır', (t) async {
    final kap = await detay(t, on: {'planlar_v1': jsonEncode({'altin': 'uydurma', 'yok': 'beklerim', 'nakit': 'bakarim'})});
    expect(kap.read(planlarProvider), {VarlikTuru.nakit: PlanSablon.bakarim});
  });

  // HIG: Dynamic Type 3,1×'te kart ve alt sayfa taşmaz (taşma test hatasıdır).
  testWidgets('3,1× yazıda kart ve sayfa taşmaz', (t) async {
    await detay(t, yazi: 3.1, on: {'planlar_v1': jsonEncode({'altin': 'biriktiririm'})});
    await gor(t, find.text('Harçlığımı alınca bir kısmını Tortu ile biriktiririm.'));
    await t.tap(find.text('Harçlığımı alınca bir kısmını Tortu ile biriktiririm.'));
    await bekle(t);
    expect(find.text('Planı kaldır'), findsOneWidget);
  });

  testWidgets('Tüm veriyi sil planları ve öğretilenleri de siler', (t) async {
    final kap = await detay(t, on: {
      'planlar_v1': jsonEncode({'altin': 'beklerim'}),
      'ogretilen_dersler_v1': ['birikim'],
    });
    await kap.read(cocukProvider.notifier).hepsiniSil();
    expect(sp.getString('planlar_v1'), isNull);
    expect(kap.read(planlarProvider), isEmpty);
    expect(kap.read(ogretilenProvider), isNull, reason: 'silinen çocuğun rafı yeni çocukta kalmaz');
  });
}
