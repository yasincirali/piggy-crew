import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';

/// Canlı karakter sözleşmesi: besleme sahnesi sesleri doğru sırada çalar
/// (üç para → yum → yaşasın), dokunma karakterin kendi sesini çalar,
/// hareketi azalt açıkken hareket olmadan yalnız ses gelir ve boşta
/// zamanlayıcıları sayfa kapanınca sarkmaz.
Widget _sahne({
  required List<Ses> calinan,
  VarlikTuru tur = VarlikTuru.altin,
  int yeme = 0,
  int tepki = 0,
  bool bosta = false,
  bool hareketsiz = false,
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: hareketsiz),
        child: Center(
          child: Karakter(
            tur: tur,
            ruh: Ruh.mutlu,
            yemeTetik: yeme,
            tepkiTetik: tepki,
            bosta: bosta,
            ses: calinan.add,
          ),
        ),
      ),
    );

void main() {
  testWidgets('besleme: üç para, yum, yaşasın sırasıyla', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 1));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan, [Ses.para, Ses.para, Ses.para, Ses.yum, Ses.yasasin]);
    expect(t.takeException(), isNull);
  });

  testWidgets('besleme ikinci kez de tam çalar', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 1));
    await t.pump(const Duration(milliseconds: 1500));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 2));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan.where((s) => s == Ses.yasasin).length, 2);
  });

  for (final tur in VarlikTuru.values) {
    testWidgets('dokununca ${tur.name} kendi sesini çalar', (t) async {
      final calinan = <Ses>[];
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur));
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur, tepki: 1));
      await t.pump(const Duration(milliseconds: 800));
      expect(calinan, [tur.ses]);
    });
  }

  testWidgets('hareketi azalt: hareket yok, ses gelir', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, hareketsiz: true));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 1, hareketsiz: true));
    expect(t.hasRunningAnimations, isFalse);
    await t.pump(const Duration(milliseconds: 400));
    expect(calinan, [Ses.para, Ses.yasasin]);
  });

  testWidgets('boşta hareket çalışır, kapanınca zamanlayıcı kalmaz', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, bosta: true));
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }
    expect(t.takeException(), isNull);
    expect(calinan, isEmpty, reason: 'boşta hareket sessizdir');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('açık ağız dört karakterde çizilir', (t) async {
    for (final tur in VarlikTuru.values) {
      await t.pumpWidget(MaterialApp(
        home: CustomPaint(size: const Size(110, 110), painter: KarakterPainter(tur: tur, ruh: Ruh.uzgun, agizAcik: true)),
      ));
      expect(t.takeException(), isNull);
    }
  });
}
