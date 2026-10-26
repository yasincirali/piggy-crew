import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/gizlilik_sayfasi.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Gizlilik politikası (App Store 5.1.1, Kids kategorisi): mağaza URL'sindeki
/// `legal/*.md` her dil için var, aynı maddeleri taşır, uygulamada okunur.
void main() {
  group('legal/', () {
    final diller = Directory('lib/l10n')
        .listSync()
        .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?[1])
        .whereType<String>()
        .toSet();

    test('uygulamanın her dili için politika dosyası var', () {
      expect(gizlilikDosyalari.keys.toSet(), diller);
      for (final ad in gizlilikDosyalari.values) {
        expect(File('legal/$ad.md').existsSync(), isTrue, reason: 'legal/$ad.md');
      }
    });

    test('her dilde aynı yedi madde ve aynı sürüm; dil bağlantıları var olan dosyaya gider', () {
      for (final ad in gizlilikDosyalari.values) {
        final s = File('legal/$ad.md').readAsStringSync();
        final maddeler = RegExp(r'^(\d)\. \*\*', multiLine: true).allMatches(s).map((m) => m[1]).toList();
        expect(maddeler, ['1', '2', '3', '4', '5', '6', '7'], reason: ad);
        expect(RegExp(r'^\S+ 2 · ', multiLine: true).hasMatch(s), isTrue, reason: '$ad: sürüm 2');
        for (final m in RegExp(r'legal/(\w+)\.md\)').allMatches(s)) {
          expect(File('legal/${m[1]}.md').existsSync(), isTrue, reason: '$ad → ${m[1]}');
        }
      }
    });

    test('markdown alt kümesi: kalın, bağlantı etiketi, sürüm satırındaki dil listesi düşer', () {
      expect(gizlilikParcalari('1. **Veri:** Hiçbiri. [buradan](https://x)'), [('1. ', false), ('Veri:', true), (' Hiçbiri. buradan', false)]);
      expect(gizlilikParcalari('Sürüm 1 · 24 Ekim 2026 · [Türkçe](https://x) · [English](https://y)'), [('Sürüm 1 · 24 Ekim 2026', false)]);
    });
  });

  // HIG: Dynamic Type 3,1×'e kadar taşma yok (taşma test hatasıdır).
  for (final yazi in [1.0, 3.1]) {
    testWidgets('Ayarlar › Gizlilik uygulamada okunur (yazı $yazi×)', (t) async {
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
      final sahteHttp = MockClient((_) async => http.Response('{}', 200));
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
      t.platformDispatcher.textScaleFactorTestValue = yazi;
      await bekle(t);
      await t.tap(find.byIcon(Icons.tune_rounded).first);
      await bekle(t);
      await t.scrollUntilVisible(find.text('Gizlilik'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
      await t.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -2000));
      await bekle(t);
      await t.tap(find.text('Gizlilik'));
      // Dosya gerçek G/Ç ile okunur; sahte saat onu ilerletmez.
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await bekle(t);
      expect(find.text('Harçlıklarım Gizlilik Politikası'), findsOneWidget);
      expect(find.textContaining('Topladığımız veri:', findRichText: true), findsOneWidget);
      expect(find.textContaining('[English]', findRichText: true), findsNothing, reason: 'dil bağlantıları uygulamada gösterilmez');
      await t.scrollUntilVisible(find.textContaining('İletişim:', findRichText: true), 200, scrollable: find.byType(Scrollable).last);
    });
  }
}
