// ignore_for_file: invalid_use_of_visible_for_testing_member
// Mağaza önizleme videosu kareleri (Ar-Ge 1 Kas 11:07, yasin "yap"): gerçek
// uygulama, demo profil, animasyonlar açık, 30 kare/sn. Kareler PNG olarak
// yazılır, `tool/magaza/onizleme_videosu.sh` ffmpeg ile MP4'e çevirir.
//
// test/ altında DEĞİL: CI'da koşmaz. Elle:
//   flutter test tool/magaza/onizleme_videosu_test.dart --update-goldens \
//     --dart-define=CIKTI=/mutlak/klasor [--dart-define=DIL=en]
//
// Neden ekran kaydı değil de kare kare: bulutta cihaz yok; kareler aynı
// Flutter çizicisinden, aynı demo veriyle gelir ve her seferinde birebir aynı
// çıkar (mağaza görüntüleriyle aynı yol). Apple önizlemede "uygulamanın
// kendisinden görüntü" ister; buradaki her kare uygulamanın çizdiği ekrandır,
// üstüne metin/efekt bindirilmez.
//
// Akış (~24 sn): Kamp (karakterler yaşıyor) → Tortu'yu besle (banknotlar,
// avuçtan verme, sevinç) → karakter detayı (kostüm) → Öğren dondurma kartı →
// Çıkartmalar. Sincap'ın ikilemi gibi bir kez görülen anlar konmaz.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/avuc_parasi.dart';
import 'package:harcliklarim/widgets/ortak.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'magaza_goruntuleri_test.dart' show demolar, fontYukle;

const cikti = String.fromEnvironment('CIKTI', defaultValue: 'build/onizleme');
const dil = String.fromEnvironment('DIL', defaultValue: 'tr');
const _usd = 41.2, _eur = 48.0, _gram = 5800.0;
const _kare = Duration(microseconds: 33333); // 30 kare/sn

void main() {
  testWidgets('önizleme videosu $dil', (t) async {
    final (ad, para) = demolar[dil]!;
    await t.runAsync(fontYukle);
    t.platformDispatcher.localeTestValue = const Locale(dil);
    t.platformDispatcher.localesTestValue = const [Locale(dil)];
    // App Store 6,9" önizleme boyutu 886×1920.
    t.view.physicalSize = const Size(886, 1920);
    t.view.devicePixelRatio = 2;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);

    final ev = switch (para) { 'USD' => _usd, 'EUR' => _eur, _ => 1.0 };
    final fiyat = {
      VarlikTuru.nakit: 1.0,
      VarlikTuru.dolar: _usd / ev,
      VarlikTuru.euro: _eur / ev,
      VarlikTuru.altin: _gram / ev,
    };
    final bugun = DateTime.now();
    final hareketler = [
      for (var h = 0; h < 6; h++)
        for (final tur in VarlikTuru.values)
          if ((h + tur.index) % 2 == 0)
            {
              'id': '$h${tur.name}',
              'tur': tur.anahtar,
              'tarih': bugun.subtract(Duration(days: 7 * h + 1)).toIso8601String(),
              'tutarTl': para == 'TRY' ? (tur == VarlikTuru.altin ? 400.0 : 120.0) : (tur == VarlikTuru.altin ? 15.0 : 5.0),
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
      'cikartmalar_v1': ['ilk_besleme', 'sabir_30', 'tortu_sapka', 'zipzip_atki', 'baykus_gozluk', 'sincap_fular'],
      'son_gorulme_v1': bugun.millisecondsSinceEpoch,
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
    // Karakter atlasları gerçek G/Ç ile çözülür; ilk karede hazır olsunlar.
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(KampEkrani), findsOneWidget);

    final uygulama = find.byType(MaterialApp);
    var n = 0;
    Future<void> kayit(double saniye) async {
      final adet = (saniye * 30).round();
      for (var i = 0; i < adet; i++) {
        await t.pump(_kare);
        await expectLater(uygulama, matchesGoldenFile('$cikti/$dil/k_${(n++).toString().padLeft(4, '0')}.png'));
      }
    }

    Future<void> dokun(Finder f) async {
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f, warnIfMissed: false);
    }

    // 1) Kamp: takım yaşıyor.
    await kayit(4);

    // 2) Tortu'yu besle: banknotlara dokun, ver, avuçtan uzat.
    await dokun(find.byKey(const ValueKey('besle-altin')));
    await kayit(1.2);
    final kupurler = ParaBirimi.fromKod(para).kupurler;
    for (final v in [kupurler[kupurler.length ~/ 2], kupurler.first]) {
      await dokun(find.byKey(ValueKey('kupur-$v')));
      await kayit(0.6);
    }
    await kayit(0.6);
    await dokun(find.byType(AnaDugme).last);
    await kayit(1.2);
    // Yiyecek avuçta bekler; çocuk uzatır.
    await t.tap(find.byType(AvucParasi), warnIfMissed: false);
    await kayit(3);

    // 3) Karakter detayı: kostüm, büyüme.
    Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.altin));
    await kayit(3);
    Navigator.of(t.element(find.byType(VarlikDetayEkrani))).pop();
    await kayit(0.6);

    // 4) Öğren: dondurma kartı.
    await dokun(find.byIcon(Icons.menu_book_outlined));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await kayit(2);
    final kart = find.byKey(const ValueKey('dene-dondurma'));
    final cipler = find.descendant(of: kart, matching: find.byType(Wrap));
    await dokun(find.descendant(of: cipler, matching: find.byType(Text)).last);
    await kayit(2.5);

    // 5) Çıkartmalar: kostümler açılmış.
    await dokun(find.byIcon(Icons.star_outline_rounded));
    await kayit(2.5);
  });
}
