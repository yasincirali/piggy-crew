import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/widgets/karakter.dart';

/// Değer düşünce karakter üzülmez, başının üstüne bulut gelir; dokununca
/// güneş açar ve bulut geri döner (yasin kararı 2026-10-15).
Widget _sahne({Ruh ruh = Ruh.bulutlu, int tepki = 0, bool hareketsiz = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: hareketsiz),
        child: Center(child: Karakter(tur: VarlikTuru.dolar, ruh: ruh, tepkiTetik: tepki)),
      ),
    );

double? _gunes(WidgetTester t) {
  final p = t.widgetList<CustomPaint>(find.byType(CustomPaint)).map((c) => c.painter).whereType<HavaPainter>();
  return p.isEmpty ? null : p.first.gunes;
}

void main() {
  testWidgets('bulutluyken bulut var, dokununca güneş açar, sonra bulut döner', (t) async {
    await t.pumpWidget(_sahne());
    expect(_gunes(t), 0);
    await t.pumpWidget(_sahne(tepki: 1));
    await t.pump(const Duration(milliseconds: 1000));
    expect(_gunes(t), 1);
    await t.pump(const Duration(milliseconds: 2000));
    expect(_gunes(t), 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('mutlu ya da düzken hava katmanı yok', (t) async {
    for (final r in [Ruh.mutlu, Ruh.duz]) {
      await t.pumpWidget(_sahne(ruh: r));
      expect(_gunes(t), isNull);
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('hareketi azalt: güneş anında açar, süre dolunca kapanır, timer sarkmaz', (t) async {
    await t.pumpWidget(_sahne(hareketsiz: true));
    await t.pumpWidget(_sahne(hareketsiz: true, tepki: 1));
    await t.pump();
    expect(_gunes(t), 1);
    await t.pump(const Duration(milliseconds: 2700));
    expect(_gunes(t), 0);
    await t.pumpWidget(const SizedBox());
  });

  test('hava çizimi uçlarda hata vermez', () {
    final kayit = PictureRecorder();
    final cv = Canvas(kayit);
    for (final g in [0.0, .5, 1.0]) {
      HavaPainter(gunes: g, kayma: 1.5).paint(cv, const Size(110, 110));
    }
    kayit.endRecording();
  });
}
