import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/evre.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Büyüme evreleri sözleşmesi: evre besleme GÜNÜNE bağlı (tutara değil, aynı
/// gün tek sayılır), geri gitmez, sahne yumuşak ve sesi doğru sırada; hareketi
/// azalt açıkken yeni evre hemen görünür, ses gelir.
Hareket _h(String id, VarlikTuru t, DateTime d, {double tutar = 10}) =>
    Hareket(id: id, tur: t, tarih: d, tutarTl: tutar, birimFiyat: 1);

Widget _sahne({required List<Ses> calinan, required Evre evre, int yeme = 0, bool hareketsiz = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: hareketsiz),
        child: Center(
          child: Karakter(tur: VarlikTuru.dolar, ruh: Ruh.mutlu, evre: evre, evreKutla: true, yemeTetik: yeme, ses: calinan.add),
        ),
      ),
    );

void main() {
  test('evre farklı besleme gününe bağlı; aynı gün tek sayılır, tutar etkilemez', () {
    final g = DateTime(2026, 10, 1);
    final ayniGun = [for (var i = 0; i < 10; i++) _h('$i', VarlikTuru.altin, g.add(Duration(hours: i % 12)), tutar: 5000)];
    expect(beslemeGunu(ayniGun, VarlikTuru.altin), 1);
    expect(evreler(ayniGun)[VarlikTuru.altin], Evre.minik);

    final gunler = [for (var i = 0; i < 10; i++) _h('$i', VarlikTuru.altin, g.add(Duration(days: i * 7)), tutar: 1)];
    expect(evreler(gunler.take(2))[VarlikTuru.altin], Evre.filiz);
    expect(evreler(gunler.take(5))[VarlikTuru.altin], Evre.cicek);
    expect(evreler(gunler)[VarlikTuru.altin], Evre.yildiz);
    // Beslenmeyen karakterin evresi yok (hesaplanmaz).
    expect(evreler(gunler).containsKey(VarlikTuru.dolar), isFalse);
  });

  test('evre geri gitmez: besleme silinse de saklanan evre kalır', () async {
    SharedPreferences.setMockInitialValues({});
    final depo = Depo(await SharedPreferences.getInstance());
    final c = ProviderContainer(overrides: [depoProvider.overrideWithValue(depo)]);
    addTearDown(c.dispose);
    final n = c.read(hareketlerProvider.notifier);
    for (var i = 0; i < 5; i++) {
      await n.ekle(_h('$i', VarlikTuru.euro, DateTime(2026, 9, 1 + i)));
    }
    expect(c.read(evrelerProvider)[VarlikTuru.euro], Evre.cicek);
    for (var i = 0; i < 4; i++) {
      await n.sil('$i');
    }
    expect(evreler(c.read(hareketlerProvider))[VarlikTuru.euro], Evre.minik);
    expect(c.read(evrelerProvider)[VarlikTuru.euro], Evre.cicek);
    expect(depo.evreOku()[VarlikTuru.euro], Evre.cicek);
    await depo.hepsiniSil();
    expect(depo.evreOku(), isEmpty);
  });

  test('büyüme sahnesi sürekli: kare kare atlama yok, uçlarda nötr', () {
    var once = evreSahnesi(0);
    expect(once.gecis, 0);
    expect(once.sx, closeTo(1, 1e-9));
    expect(once.sy, closeTo(1, 1e-9));
    for (var i = 1; i <= 2400; i++) {
      final s = evreSahnesi(i / 2400);
      expect(s.gecis, greaterThanOrEqualTo(once.gecis), reason: 'geçiş geri gitmez');
      expect((s.sx - once.sx).abs(), lessThan(.01), reason: 't=${i / 2400}');
      expect((s.sy - once.sy).abs(), lessThan(.01), reason: 't=${i / 2400}');
      final a = s.yuz.degerler, b = once.yuz.degerler;
      for (var k = 0; k < a.length; k++) {
        expect((a[k] - b[k]).abs(), lessThan(.03), reason: 'yüz değeri $k, t=${i / 2400}');
      }
      once = s;
    }
    expect(once.gecis, 1);
    expect(once.yuz, const Yuz());
    // Sevinç yüzü büyümeden sonra gelir; kapalı ‿ göz (kapak) kullanılmaz.
    expect(evreSahnesi(.7).yuz.sevinc, greaterThan(.9));
    for (var i = 0; i <= 100; i++) {
      expect(evreSahnesi(i / 100).yuz.kapak, 0);
    }
  });

  testWidgets('evre artınca sahne bir kez: ışık sesi, sonra yaşasın', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.minik));
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.filiz));
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan, [Ses.cikartma, Ses.yasasin]);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('beslemeyle aynı anda gelirse yeme bittikten sonra oynar', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.filiz));
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.cicek, yeme: 1));
    for (var i = 0; i < 90; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan, [Ses.para, Ses.yum, Ses.yasasin, Ses.cikartma, Ses.yasasin]);
  });

  testWidgets('hareketi azalt: yeni evre hemen, yalnız ses', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.cicek, hareketsiz: true));
    await t.pumpWidget(_sahne(calinan: calinan, evre: Evre.yildiz, hareketsiz: true));
    expect(t.hasRunningAnimations, isFalse);
    expect(calinan, [Ses.cikartma]);
  });

  test('her evre, her karakter, 2,5D açık/kapalı çizilir', () {
    for (final tur in VarlikTuru.values) {
      for (final e in [null, ...Evre.values]) {
        for (final d in [true, false]) {
          for (final g in [0.0, .5, 1.0]) {
            final r = ui.PictureRecorder();
            KarakterPainter(
              tur: tur,
              ruh: Ruh.mutlu,
              evre: e,
              evreOnceki: e?.index == 0 || e == null ? null : Evre.values[e.index - 1],
              evreGecis: g,
              derinlik: d,
              bakis: const Offset(.8, 0),
            ).paint(Canvas(r), const Size(110, 110));
            r.endRecording().dispose();
          }
        }
      }
    }
  });
}
