import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/services/dokunsal.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';

/// Canlı karakter sözleşmesi: besleme ritüelinin sesleri doğru sırada çalar
/// (yiyecek ulaşınca tık → yum → yaşasın), dokunma karakterin kendi sesini çalar,
/// hareketi azalt açıkken hareket olmadan yalnız ses gelir ve boşta
/// zamanlayıcıları sayfa kapanınca sarkmaz.
Widget _sahne({
  required List<Ses> calinan,
  VarlikTuru tur = VarlikTuru.altin,
  int yeme = 0,
  int tepki = 0,
  bool bosta = false,
  bool hareketsiz = false,
  List<Dokunus>? titresen,
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
            dokun: titresen?.add,
          ),
        ),
      ),
    );

void main() {
  for (final tur in VarlikTuru.values) {
    testWidgets('besleme ritüeli (${tur.name}): sesler ve titreşimler çizelge sırasıyla, sonda yaşasın', (t) async {
      final calinan = <Ses>[];
      final titresen = <Dokunus>[];
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur, titresen: titresen));
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur, yeme: 1, titresen: titresen));
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final cizelge = yemeIpuclari(tur);
      expect(calinan, [for (final i in cizelge) ?i.ses]);
      expect(titresen, [for (final i in cizelge) ?i.dokunus]);
      expect(calinan.first, isNot(Ses.yasasin));
      expect(calinan.last, Ses.yasasin);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('besleme ikinci kez de tam çalar', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 1));
    await t.pump(const Duration(milliseconds: 1900));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 2));
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan.where((s) => s == Ses.yasasin).length, 2);
  });

  for (final tur in VarlikTuru.values) {
    testWidgets('dokununca ${tur.name} kendi sesini ve titreşimini çalar', (t) async {
      final calinan = <Ses>[];
      final titresen = <Dokunus>[];
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur, titresen: titresen));
      await t.pumpWidget(_sahne(calinan: calinan, tur: tur, tepki: 1, titresen: titresen));
      await t.pump(const Duration(milliseconds: 800));
      expect(calinan, [tur.ses]);
      expect(titresen, [tur.sesDokunusu]);
    });
  }

  testWidgets('hareketi azalt: hareket yok, ses gelir', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(_sahne(calinan: calinan, hareketsiz: true));
    await t.pumpWidget(_sahne(calinan: calinan, yeme: 1, hareketsiz: true));
    expect(t.hasRunningAnimations, isFalse);
    await t.pump(const Duration(milliseconds: 400));
    expect(calinan, [yakalamaSesi(VarlikTuru.altin), Ses.yasasin]);
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
        home: CustomPaint(size: const Size(110, 110), painter: KarakterPainter(tur: tur, ruh: Ruh.bulutlu, agizAcik: true)),
      ));
      expect(t.takeException(), isNull);
    }
  });
}
