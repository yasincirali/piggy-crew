import 'package:flutter/material.dart';
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

const _govde = '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}';
http.Response _yanit() => http.Response(_govde, 200, headers: {'content-type': 'application/json; charset=utf-8'});

/// Seçimi olan her şey veliye (Ar-Ge 24–25 Eki): para birimi karşılamada ayrı
/// çocuk adımı değil, veli adımında; dil ve yaş modu Ayarlar'ın çocuk
/// tarafında değil, veli köşesinde. Uygulamaya dönüşte eski fiyat yenilenir.
void main() {
  Future<SharedPreferences> hazirla(WidgetTester t, {Map<String, Object> on = const {}}) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    // iPhone SE (2./3. nesil) mantıksal boyutu: en kısa desteklenen ekran.
    t.view.physicalSize = const Size(375 * 2, 667 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(on);
    return SharedPreferences.getInstance();
  }

  Widget uygulama(SharedPreferences sp, http.Client istemci) => ProviderScope(
        overrides: [
          depoProvider.overrideWithValue(Depo(sp)),
          fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: istemci, tercihler: sp)),
        ],
        child: const HarcliklarimApp(),
      );

  testWidgets('karşılama 4 adım; para birimi veli adımında seçilir', (t) async {
    final sp = await hazirla(t);
    await t.pumpWidget(uygulama(sp, MockClient((_) async => _yanit())));
    await bekle(t);
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    await t.tap(find.text('Devam'));
    await bekle(t);
    expect(find.text('Paran hangisi?'), findsNothing);
    await t.tap(find.text('Devam')); // kamp yeri
    await bekle(t);
    // Veli adımı: PIN alanları ve para birimi satırı birlikte; düğmeler
    // kaydırmadan görünür (iPhone SE yüksekliği).
    expect(find.text('Anne baba köşesi'), findsOneWidget);
    expect(find.text('Para birimi: ₺ TRY'), findsOneWidget);
    expect(find.text('Şimdilik geç').hitTestable(), findsOneWidget, reason: 'iPhone SE: düğme kaydırmadan görünür');
    expect(find.text('Hazırım!').hitTestable(), findsOneWidget);
    await t.tap(find.text('Para birimi: ₺ TRY'));
    await bekle(t);
    expect(find.textContaining('ilk kez para verildikten sonra'), findsOneWidget);
    await t.tap(find.text(r'$  USD'));
    await bekle(t);
    expect(find.text(r'Para birimi: $ USD'), findsOneWidget);
    await t.tap(find.text('Şimdilik geç'));
    await bekle(t);
    expect(find.text('Merhaba Deniz'), findsOneWidget);
    final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
    expect(kap.read(cocukProvider)!.para, ParaBirimi.usd);
  });

  testWidgets('dil ve yaş modu çocuk tarafında yok, veli köşesinde var', (t) async {
    final sp = await hazirla(t);
    await t.pumpWidget(uygulama(sp, MockClient((_) async => _yanit())));
    await bekle(t);
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
      await t.tap(find.text(d));
      await bekle(t);
    }
    await t.tap(find.byIcon(Icons.tune_rounded));
    await bekle(t);
    expect(find.text('Kamp yeri'), findsOneWidget);
    expect(find.text('Dil'), findsNothing);
    expect(find.text('Yaş modu'), findsNothing);
    expect(find.text('Cihaz dili'), findsNothing);

    await t.scrollUntilVisible(find.text('Anne baba köşesi'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
    await t.tap(find.text('Anne baba köşesi'));
    await bekle(t);
    await t.scrollUntilVisible(find.text('Dil'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Yaş modu'), findsOneWidget);
    await t.tap(find.text('11–15'));
    await bekle(t);
    final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
    expect(kap.read(cocukProvider)!.yas.anahtar, 'buyuk');
    await t.ensureVisible(find.text('English'));
    await t.tap(find.text('English'));
    await bekle(t);
    expect(kap.read(cocukProvider)!.dil, 'en');
    expect(find.text('Language'), findsOneWidget, reason: 'veli köşesi yeni dilde kalır');
  });

  group('dönüşte fiyat tazeleme', () {
    test('fiyat bir saatten eskiyse çeker, tazeyse çekmez', () async {
      var istek = 0;
      final simdi = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'fiyat_onbellek_v1': '{"d":{"USD":40,"EUR":48,"GRA":5800},"z":"${simdi.subtract(const Duration(minutes: 20)).toIso8601String()}"}',
      });
      final sp = await SharedPreferences.getInstance();
      // Ağ ilk açılışta düşük: önbellek (20 dk önce) kalır.
      var agAcik = false;
      final kap = ProviderContainer(overrides: [
        fiyatServisiProvider.overrideWithValue(FiyatServisi(
          tercihler: sp,
          istemci: MockClient((_) async {
            istek++;
            return agAcik ? _yanit() : http.Response('', 503);
          }),
        )),
      ]);
      addTearDown(kap.dispose);
      await kap.read(fiyatProvider.future);
      await Future<void>.delayed(Duration.zero);
      final ilk = istek;
      agAcik = true;

      final n = kap.read(fiyatProvider.notifier);
      await n.tazeleGerekirse(simdi);
      expect(istek, ilk, reason: '20 dakikalık fiyat taze');
      expect(kap.read(fiyatProvider).value!.taze, isFalse);

      await n.tazeleGerekirse(simdi.add(const Duration(hours: 1)));
      expect(istek, ilk + 1, reason: 'bir saati geçti: sessizce çekilir');
      expect(kap.read(fiyatProvider).value!.taze, isTrue);
    });

    test('çekme başarısızsa eldeki fiyat ve zamanı kalır', () async {
      final eski = DateTime(2026, 10, 20, 9);
      SharedPreferences.setMockInitialValues({
        'fiyat_onbellek_v1': '{"d":{"USD":40,"EUR":48,"GRA":5800},"z":"${eski.toIso8601String()}"}',
      });
      final sp = await SharedPreferences.getInstance();
      final kap = ProviderContainer(overrides: [
        fiyatServisiProvider.overrideWithValue(
            FiyatServisi(tercihler: sp, istemci: MockClient((_) async => http.Response('', 503)))),
      ]);
      addTearDown(kap.dispose);
      await kap.read(fiyatProvider.future);
      await kap.read(fiyatProvider.notifier).tazeleGerekirse(DateTime(2026, 10, 25));
      final f = kap.read(fiyatProvider).value!;
      expect(f.zaman, eski);
      expect(f.degerler['GRA'], 5800);
    });
  });
}
