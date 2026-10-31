import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/cikartma.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Kostüm görünür (Ar-Ge 30 Eki 20:07 #1a): açılan şapka/atkı/gözlük/fular
/// karakterin üstünde; açılmamış kostüm görünmez; 2D çizimde de var.
void main() {
  test('her karakterin tek kostümü var ve o karakterin çıkartması', () {
    final ids = {for (final t in VarlikTuru.values) Cikartma.kostum(t)};
    expect(ids, hasLength(4));
    for (final t in VarlikTuru.values) {
      expect(Cikartma.bul(Cikartma.kostum(t))?.tur, t);
    }
  });

  Future<ui.Image> ciz(VarlikTuru t, bool kostum) {
    final kayit = ui.PictureRecorder();
    KarakterPainter(tur: t, ruh: Ruh.mutlu, kostum: kostum).paint(Canvas(kayit), const Size(110, 110));
    return kayit.endRecording().toImage(110, 110);
  }

  test('2D: kostüm çizimi değiştirir, kostümsüz çizim aynı kalır', () async {
    for (final t in VarlikTuru.values) {
      final a = await (await ciz(t, false)).toByteData();
      final b = await (await ciz(t, true)).toByteData();
      final c = await (await ciz(t, false)).toByteData();
      expect(a!.buffer.asUint8List(), c!.buffer.asUint8List());
      expect(a.buffer.asUint8List(), isNot(b!.buffer.asUint8List()), reason: '${t.name} kostümü çizilmedi');
    }
    final p = KarakterPainter(tur: VarlikTuru.altin, ruh: Ruh.mutlu);
    expect(KarakterPainter(tur: VarlikTuru.altin, ruh: Ruh.mutlu, kostum: true).shouldRepaint(p), isTrue);
  });

  Future<void> uygulama(WidgetTester t, Set<String> cik) async {
    rootBundle.clear();
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'cocuk_v1': '{"ad":"Deniz","yas":"kucuk","dunya":"orman","olusturma":"2026-10-01T10:00:00.000","para":"TRY"}',
      'cikartmalar_v1': cik.toList(),
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
  }

  Map<VarlikTuru, bool> giyenler(WidgetTester t) =>
      {for (final k in t.widgetList<Karakter>(find.byType(Karakter))) k.tur: k.kostum};

  testWidgets('kampta yalnız açılan kostüm giyilir', (t) async {
    await uygulama(t, {'tortu_sapka', 'baykus_gozluk', 'ilk_besleme'});
    expect(giyenler(t), {
      VarlikTuru.altin: true,
      VarlikTuru.dolar: false,
      VarlikTuru.euro: true,
      VarlikTuru.nakit: false,
    });
  });

  testWidgets('çıkartma kartında açılan kostüm giyilir, kilitli olan giyilmez', (t) async {
    await uygulama(t, {'zipzip_atki'});
    await t.tap(find.text('Çıkartmalar'));
    await bekle(t);
    final kartlar = t.widgetList<Karakter>(find.byType(Karakter)).toList();
    final atki = kartlar.where((k) => k.tur == VarlikTuru.dolar);
    expect(atki.any((k) => k.kostum), isTrue);
    final sapka = kartlar.where((k) => k.tur == VarlikTuru.altin);
    expect(sapka.every((k) => !k.kostum), isTrue);
  });
}
