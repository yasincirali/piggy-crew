import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/evre.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// 3D karakterler (deneme, 2026-10-17):
/// - her karakter × evre × sahne için kare dosyası var ve yerleşim tablosunda;
/// - yüz değerleri atlas karışımına doğru düşer (kırpma, esneme, sevinç);
/// - kapalıyken 2D çizim birebir, açıkken 3D katman çizilir;
/// - veli köşesindeki seçim kalıcı, varsayılan kapalı.
void main() {
  const sahneler = ['dokunma', 'arti', 'ziplama', 'keyif', 'etrafa_bak', 'dans'];
  final tablo = File('lib/widgets/karakter_3d_yerlesim.g.dart').readAsStringSync();

  test('her kare dosyası var ve yerleşim tablosunda', () {
    for (final t in VarlikTuru.values) {
      expect(tablo.contains('VarlikTuru.${t.name}:'), isTrue, reason: '${t.name} kalibrasyonu yok');
      final anahtarlar = [
        for (final e in Evre.values) '${t.name}/atlas_${e.name}',
        for (final s in sahneler) for (final k in ['beden', 'filiz', 'cicek', 'yildiz']) '${t.name}/${s}_$k',
      ];
      for (final a in anahtarlar) {
        expect(File('assets/karakter3d/$a.webp').existsSync(), isTrue, reason: '$a.webp yok');
        expect(tablo.contains("'$a':"), isTrue, reason: '$a kırpım tablosunda yok');
      }
    }
  });

  Map<AtlasIfade, double> karisim(Yuz y, [Offset b = Offset.zero]) => {for (final (i, w) in atlasKarisimi(y, b)) i: w};

  test('atlas karışımı: taban gülüş, bakış, kırpma, esneme, sevinç', () {
    expect(karisim(const Yuz(gulus: 1))[AtlasIfade.mutlu], 1);
    expect(karisim(const Yuz(gulus: .1)).keys, [AtlasIfade.bulutlu]);
    expect(karisim(const Yuz(gulus: 1), const Offset(-1, 0))[AtlasIfade.mutluSol], 1);
    // Küçük bakış kaymasında baş çevrilmez (yarı opak iki baş = hayalet).
    expect(karisim(const Yuz(gulus: 1), const Offset(.3, -.2)).keys, isNot(contains(AtlasIfade.mutluSag)));
    expect(karisim(const Yuz(gulus: 1, kapak: 1))[AtlasIfade.kirp], 1);
    // Gerinme: kapalı göz + açık ağız = esneme (kırpma ya da "o" değil).
    final esne = karisim(const Yuz(kapak: 1, agizO: .9));
    expect(esne[AtlasIfade.esne], 1);
    expect(esne.containsKey(AtlasIfade.kirp), isFalse);
    expect(esne.containsKey(AtlasIfade.o), isFalse);
    // Sevinç gözleri kapatır: üstüne kırpma binmez.
    final sev = karisim(const Yuz(gulus: 1, sevinc: 1, kapak: 1));
    expect(sev[AtlasIfade.sevinc], 1);
    expect(sev.containsKey(AtlasIfade.kirp), isFalse);
  });

  Finder ikiDGovde() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter is KarakterPainter);

  for (final acik in [false, true]) {
    testWidgets('3D ${acik ? 'açık: 3D katman' : 'kapalı: 2D çizim'}', (t) async {
      await t.pumpWidget(MaterialApp(
        home: UcBoyut(
          acik: acik,
          child: const Center(child: Karakter(tur: VarlikTuru.nakit, ruh: Ruh.mutlu, boyut: 140, evre: Evre.cicek)),
        ),
      ));
      // Atlas gerçek WebP'den çözülür (gerçek zaman).
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
      await t.pump();
      expect(ikiDGovde(), acik ? findsNothing : findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Ayarlar: karakter görünümü 3D seçilince kalıcı, varsayılan klasik', (t) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    expect(Depo(sp).karakter3dOku(), isFalse);
    final sahteHttp = MockClient((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json; charset=utf-8'}));
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
    await t.tap(find.byIcon(Icons.tune_rounded).first);
    await bekle(t);
    final secim = find.text('3D (deneme)');
    await t.ensureVisible(secim);
    await bekle(t);
    await t.tap(secim);
    await bekle(t);
    expect(sp.getBool('karakter_3d_v1'), isTrue);
  });
}
