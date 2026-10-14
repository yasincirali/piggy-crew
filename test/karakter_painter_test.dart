import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/widgets/karakter.dart';

/// Dört karakter × üç ruh hâli hatasız çizilmeli (yol dizeleri bozulursa
/// path_drawing fırlatır; bu test onu yakalar).
void main() {
  for (final t in VarlikTuru.values) {
    for (final r in Ruh.values) {
      testWidgets('${t.name} ${r.name} çizilir', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: CustomPaint(
              size: const Size(110, 110),
              painter: KarakterPainter(tur: t, ruh: r, pulSayisi: 3, parlak: true, gozKapali: r == Ruh.duz),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
