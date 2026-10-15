import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/theme/dunya.dart';
import 'package:harcliklarim/widgets/kamp_atesi.dart';
import 'package:harcliklarim/widgets/karakter.dart';

/// Ateş canlı yanar, besleme parlaması oynar, hareketi azalt açıkken saat
/// durur. Zıplama eğrisi sınırlarda sıçramaz (karakter yerinden "ışınlanmasın").
Widget _ates({int parlama = 0, bool hareketsiz = false}) => MaterialApp(
      theme: dunyaTemasi(Dunya.values.first),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: hareketsiz),
        child: Center(child: KampAtesi(toplamTl: 2500, boyut: 140, parlamaTetik: parlama)),
      ),
    );

void main() {
  testWidgets('ateş yanar, parlama oynar, kapanınca bir şey sarkmaz', (t) async {
    await t.pumpWidget(_ates());
    expect(t.binding.hasScheduledFrame, isTrue); // sürekli yanıyor
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpWidget(_ates(parlama: 1));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('hareketi azalt: ateş durağan çizilir', (t) async {
    await t.pumpWidget(_ates(hareketsiz: true));
    await t.pumpWidget(_ates(hareketsiz: true, parlama: 1));
    expect(t.binding.hasScheduledFrame, isFalse);
    expect(find.byType(KampAtesi), findsOneWidget);
  });

  test('zıplama eğrisi sınırlarda yerinde, ortada havada', () {
    for (final t in [0.0, 1.0]) {
      final z = ziplamaEgrisi(t, 16);
      expect([z.y, z.sx, z.sy], [0, 1, 1]);
    }
    // Hazırlıkta çömelir (yere basık), havada yukarıda, inişte basık.
    expect(ziplamaEgrisi(.15, 16).sy, lessThan(1));
    expect(ziplamaEgrisi(.46, 16).y, lessThan(-15));
    expect(ziplamaEgrisi(.76, 16).sy, lessThan(1));
    // Parçalar arası geçiş sürekli: komşu örnekler arasında sıçrama yok.
    var once = ziplamaEgrisi(0, 16);
    for (var i = 1; i <= 1000; i++) {
      final z = ziplamaEgrisi(i / 1000, 16);
      expect((z.y - once.y).abs(), lessThan(.5), reason: 't=${i / 1000}');
      expect((z.sy - once.sy).abs(), lessThan(.03), reason: 't=${i / 1000}');
      once = z;
    }
  });
}
