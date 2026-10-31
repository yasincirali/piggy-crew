import 'dart:convert';
import 'dart:io';

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

/// Kamp'ta "Besle" karakterin altında (Ar-Ge 31 Eki 20:07): her görünür karakter
/// için bir düğme, en az 44 pt, karakterin varlık adı görünür; büyük yazıda
/// sahne düğmeleri yerine satır listesi.
void main() {
  Future<void> kampaGel(WidgetTester t, {double olcek = 1, Size ekran = const Size(390, 844), Map<String, Object> ek = const {}}) async {
    // Önceki testin sahte zamanında başlamış varlık yüklemesi önbellekte
    // asılı kalmasın (ders dosyası).
    rootBundle.clear();
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.platformDispatcher.textScaleFactorTestValue = olcek;
    t.view.physicalSize = ekran * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({
      'cocuk_v1': '{"ad":"Deniz","yas":"kucuk","dunya":"orman","olusturma":"2026-10-01T10:00:00.000","para":"TRY"}',
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
  }

  testWidgets('her karakterin altında Besle, 44 pt+, varlık adı görünür; liste yok', (t) async {
    await kampaGel(t);
    for (final v in VarlikTuru.values) {
      final d = find.byKey(ValueKey('besle-${v.name}'));
      expect(d, findsOneWidget, reason: '${v.name} düğmesi');
      final boy = t.getSize(d);
      expect(boy.height, greaterThanOrEqualTo(44));
      expect(boy.width, greaterThanOrEqualTo(44));
    }
    expect(find.text('Altın'), findsOneWidget, reason: 'Tortu · Altın bağı sahnede kalır');
    expect(find.text('Tortu · Altın'), findsNothing, reason: 'eski liste normal yazıda yok');
  });

  testWidgets('dar ekranda (iPhone SE) düğmeler küçülmez', (t) async {
    await kampaGel(t, ekran: const Size(320, 568));
    for (final v in VarlikTuru.values) {
      expect(t.getSize(find.byKey(ValueKey('besle-${v.name}'))).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('büyük yazıda sahne düğmesi yok, satır listesi döner', (t) async {
    await kampaGel(t, olcek: 2);
    expect(find.byKey(const ValueKey('besle-altin')), findsNothing);
    await t.scrollUntilVisible(find.text('Tortu · Altın'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Tortu · Altın'), findsOneWidget);
  });

  testWidgets('kupürler ekler, geri al sonuncuyu çıkarır, elle yazınca liste silinir', (t) async {
    await kampaGel(t);
    await t.tap(find.byKey(const ValueKey('besle-nakit')));
    await bekle(t);
    alan() => t.widget<TextField>(find.byType(TextField)).controller!.text;
    expect(find.byKey(const ValueKey('kupur-geri')), findsNothing);
    for (final v in [100, 20, 20, 5]) {
      await t.tap(find.byKey(ValueKey('kupur-$v')));
      await bekle(t);
    }
    expect(alan(), '145', reason: '100 + 20 + 20 + 5');
    expect(t.getSize(find.byKey(const ValueKey('kupur-5'))).height, greaterThanOrEqualTo(44));
    await t.tap(find.byKey(const ValueKey('kupur-geri')));
    await bekle(t);
    expect(alan(), '140');
    await t.enterText(find.byType(TextField), '30');
    await bekle(t);
    expect(find.byKey(const ValueKey('kupur-geri')), findsNothing, reason: 'elle yazınca kupür listesi silinir');
    await t.tap(find.byKey(const ValueKey('kupur-10')));
    await bekle(t);
    expect(alan(), '40', reason: 'yazılan tutarın üstüne eklenir');
    await t.tap(find.byKey(const ValueKey('kupur-geri')));
    await bekle(t);
    expect(alan(), '30', reason: 'geri alma yazılana döner');
    expect(find.bySemanticsLabel(RegExp('^20 ₺ ekle')), findsOneWidget);
  });

  test('her birimin kupürleri artan ve gerçek', () {
    for (final p in ParaBirimi.values) {
      final k = p.kupurler;
      expect(k, isNotEmpty);
      expect([...k]..sort(), k);
    }
    expect(ParaBirimi.tryy.kupurler, isNot(contains(250)), reason: '250 ₺ banknot yok');
  });

  testWidgets('dersler bitince "Hatırlıyor musun?": yanlışta ipucu, doğruda sıra ilerler, sayaç yok', (t) async {
    await kampaGel(t, ek: {
      'ders_ilerleme_v1': 10,
      'ogretilen_dersler_v1': <String>['birikim', 'enflasyon'],
    });
    await t.tap(find.text('Öğren'));
    // Ders dosyası gerçek asenkron yüklenir (sahte zamanda takılabilir).
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await bekle(t);
    expect(find.text('Hatırlıyor musun?'), findsOneWidget);
    expect(find.textContaining('/ 10'), findsNothing, reason: 'sayaç yok');
    expect(find.text('Hangisi ay sonunda daha çok para eder?'), findsOneWidget, reason: 'ilk öğretilen ders');
    expect(find.textContaining('Bekleyen para büyür'), findsNothing, reason: 'metin önce gösterilmez (geri getirme)');
    await t.tap(find.text('Hiç koymamak'));
    await bekle(t);
    expect(find.textContaining('Bekleyen para büyür'), findsOneWidget, reason: 'yanlışta ders metni ipucu');
    await t.tap(find.textContaining('Her hafta'));
    await bekle(t);
    expect(find.textContaining('şimdi hatırladım'), findsOneWidget);
    final sp = await SharedPreferences.getInstance();
    expect(sp.getInt('hatirla_sira_v1'), 1);
    expect(find.text('Hangisi ay sonunda daha çok para eder?'), findsOneWidget, reason: 'aynı açılışta yeni soru gelmez');
    expect(find.text('Baştan oku'), findsOneWidget);
  });

  test('her ders, her dilde hatırla sorusu taşır ve doğru seçenek geçerli', () async {
    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      final d = jsonDecode(File('assets/dersler/$dil.json').readAsStringSync()) as List;
      for (final x in d) {
        final h = x['hatirla'] as Map;
        expect((h['secenekler'] as List).length, 3, reason: '$dil ${x['id']}');
        expect(h['dogru'], inInclusiveRange(0, 2));
        expect(h['soru'], isNot(x['soru']), reason: 'yeni soru, aynısı değil');
      }
    }
  });
}
