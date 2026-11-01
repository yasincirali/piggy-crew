// ignore_for_file: invalid_use_of_visible_for_testing_member
// Mağaza ekran görüntüleri: 4 ekran × 6 dil, gerçek uygulama, demo veri.
//
// test/ altında DEĞİL: CI'da koşmaz (her PR'da 24 PNG üretmek boşa), elle:
//   flutter test tool/magaza/magaza_goruntuleri_test.dart --update-goldens \
//     --dart-define=CIKTI=/mutlak/klasor
// Boyut App Store 6,9" (1320×2868). `--dart-define=PLAY=true` Google Play
// boyutunu üretir (1080×2160): Play uzun kenarın kısa kenarın iki katını
// aşmasını kabul etmiyor, 1320×2868 (2,17) reddedilir (Ar-Ge 29 Eki 20:07 #1).
// PLAY'de ayrıca 1024×500 özellik görseli (`ozellik.png`, dil bağımsız,
// metinsiz: Play onu bazen yazının arkasında kırpar). Metin görüntüye gömülmez; mağaza başlığı
// ASC'deki metinden gelir (Ar-Ge 23 Eki 20:07: Sincap'ın ikilemi gibi bir kez
// görülen anlar vitrine konmaz, "her açılışta soru soruyor" sanılır).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/besle_sayfasi.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const cikti = String.fromEnvironment('CIKTI', defaultValue: 'build/magaza');
const play = bool.fromEnvironment('PLAY');

/// Dil → demo çocuk adı ve para birimi (o dilin mağazasındaki tipik veli).
const demolar = {
  'tr': ('Deniz', 'TRY'),
  'en': ('Sam', 'USD'),
  'de': ('Lena', 'EUR'),
  'es': ('Lucía', 'EUR'),
  'fr': ('Léo', 'EUR'),
  'pt': ('Bia', 'EUR'),
};

/// Sahte günün fiyatları (TRY): truncgil v4 biçimi.
const _usd = 41.2, _eur = 48.0, _gram = 5800.0;

Future<void> fontYukle() async {
  for (final e in {'Baloo2': ['600', '700', '800'], 'Nunito': ['400', '600', '700', '800']}.entries) {
    final f = FontLoader(e.key);
    for (final w in e.value) {
      f.addFont(rootBundle.load('assets/fonts/${e.key}-$w.ttf'));
    }
    await f.load();
  }
  // flutter_tester <flutter>/bin/cache/... altında koşar; ikon fontu oradan.
  final yol = Platform.resolvedExecutable;
  final kok = yol.substring(0, yol.indexOf('/bin/cache/'));
  final ikon = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(
        File('$kok/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await ikon.load();
}

Future<void> _bekle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final MapEntry(key: dil, value: (ad, para)) in demolar.entries) {
    testWidgets('mağaza $dil', (t) async {
      await t.runAsync(fontYukle);
      t.platformDispatcher.localeTestValue = Locale(dil);
      t.platformDispatcher.localesTestValue = [Locale(dil)];
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      t.view.physicalSize = play ? const Size(1080, 2160) : const Size(1320, 2868);
      t.view.devicePixelRatio = play ? 2.5 : 3;
      addTearDown(t.platformDispatcher.clearAllTestValues);
      addTearDown(t.view.reset);

      // Ev birimine göre birim fiyatlar (tutarlar ev biriminde saklanır).
      final ev = switch (para) { 'USD' => _usd, 'EUR' => _eur, _ => 1.0 };
      final fiyat = {
        VarlikTuru.nakit: 1.0,
        VarlikTuru.dolar: _usd / ev,
        VarlikTuru.euro: _eur / ev,
        VarlikTuru.altin: _gram / ev,
      };
      final bugun = DateTime.now();
      // Altı farklı haftada düzenli, küçük beslemeler: ateşin yanında odun, evreler büyümüş.
      final hareketler = [
        for (var h = 0; h < 6; h++)
          for (final tur in VarlikTuru.values)
            if ((h + tur.index) % 2 == 0)
              {
                'id': '$h${tur.name}',
                'tur': tur.anahtar,
                'tarih': bugun.subtract(Duration(days: 7 * h + 1)).toIso8601String(),
                'tutarTl': para == 'TRY' ? (tur == VarlikTuru.altin ? 400.0 : 120.0) : (tur == VarlikTuru.altin ? 15.0 : 5.0),
                // Geçmiş fiyat biraz düşük: vitrinde "Fark" sıfır değil, kur hafif yükselmiş.
                'birimFiyat': fiyat[tur]! * (tur == VarlikTuru.nakit ? 1 : 1 - .015 * (h + 1)),
              },
      ];
      SharedPreferences.setMockInitialValues({
        'cocuk_v1': jsonEncode({
          'ad': ad,
          'yas': 'kucuk',
          'dunya': 'bahce',
          'pinOzeti': null,
          'olusturma': bugun.subtract(const Duration(days: 45)).toIso8601String(),
          'para': para,
          'dil': dil,
        }),
        'hareketler_v1': jsonEncode(hareketler),
        // Kostümler mağaza görüntüsünde görünsün (açılmış, karakterin üstünde).
        'cikartmalar_v1': ['ilk_besleme', 'sabir_30', 'tortu_sapka', 'zipzip_atki', 'baykus_gozluk', 'sincap_fular'],
        // "Geri döndün" karşılaması vitrine girmez (açılış sahnesi testte zaten oynamaz).
        'son_gorulme_v1': bugun.millisecondsSinceEpoch,
        // Öğren vitrini enflasyon dersinde: "Dokunarak dene" dondurma kartı
        // görünsün (Ar-Ge 1 Kas; hareketli ders anı durağan görüntüde de okunur).
        'ders_ilerleme_v1': 1,
      });
      rootBundle.clear();
      final sp = await SharedPreferences.getInstance();
      final sahteHttp = MockClient((_) async => http.Response(
          '{"USD":{"Satış":$_usd},"EUR":{"Satış":$_eur},"GRA":{"Satış":$_gram},"GBP":{"Satış":55}}', 200,
          headers: {'content-type': 'application/json; charset=utf-8'}));
      await t.pumpWidget(ProviderScope(
        overrides: [
          depoProvider.overrideWithValue(Depo(sp)),
          fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
        ],
        child: const HarcliklarimApp(),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await _bekle(t);
      final uygulama = find.byType(MaterialApp);

      expect(find.byType(KampEkrani), findsOneWidget, reason: 'açılış/karşılama araya girmemeli');
      await expectLater(uygulama, matchesGoldenFile('$cikti/$dil/1_kamp.png'));

      final kamp = t.element(find.byType(KampEkrani));
      besleGoster(kamp, kamp as WidgetRef, VarlikTuru.altin);
      await _bekle(t);
      await t.enterText(find.byType(TextField).last, para == 'TRY' ? '50' : '5');
      await _bekle(t);
      await expectLater(uygulama, matchesGoldenFile('$cikti/$dil/2_besle.png'));
      Navigator.of(t.element(find.byType(TextField).last)).pop();
      await _bekle(t);

      Navigator.of(kamp).push(VarlikDetayEkrani.rota(VarlikTuru.altin));
      await _bekle(t);
      await expectLater(uygulama, matchesGoldenFile('$cikti/$dil/3_karakter.png'));
      Navigator.of(t.element(find.byType(VarlikDetayEkrani))).pop();
      await _bekle(t);

      await t.tap(find.byIcon(Icons.menu_book_outlined));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await _bekle(t);
      await expectLater(uygulama, matchesGoldenFile('$cikti/$dil/4_ogren.png'));
    });
  }
}
