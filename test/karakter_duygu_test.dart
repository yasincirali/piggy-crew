import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Duygu sözlüğü sözleşmesi: yüz sürekli değişir (atlama yok), sevinç her
/// yerde aynı yüzle gelir (^ göz + açık gülüş, uykulu kapak DEĞİL) ve
/// "artıya geçti" sevinci yalnız gerçek geçişte, bir kez oynar.
void main() {
  const adim = 1 / 1000;

  void surekli(String ad, double Function(double) f, {double esik = .06}) {
    var once = f(0);
    for (var t = adim; t <= 1; t += adim) {
      final d = f(t);
      expect((d - once).abs(), lessThan(esik), reason: '$ad t=${t.toStringAsFixed(3)} sıçradı');
      once = d;
    }
  }

  test('besleme yüzü her değerde sürekli, başta ve sonda nötr', () {
    for (var i = 0; i < 6; i++) {
      surekli('yuz[$i]', (t) => yemeYuzu(t).degerler[i]);
      expect(yemeYuzu(0).degerler[i], 0);
      expect(yemeYuzu(1).degerler[i], 0);
    }
    surekli('bakış', yemeBakisY);
    expect(yemeBakisY(0), 0);
    expect(yemeBakisY(1), 0);
  });

  test('besleme sevinci gülen göz ve açık gülüşle gelir, uykulu kapakla değil', () {
    var enSevinc = 0.0, enKahkaha = 0.0;
    for (var t = 0.0; t <= 1; t += adim) {
      final y = yemeYuzu(t);
      expect(y.kapak, 0, reason: 'sevinçte göz kapağı kapanmaz');
      enSevinc = y.sevinc > enSevinc ? y.sevinc : enSevinc;
      enKahkaha = y.kahkaha > enKahkaha ? y.kahkaha : enKahkaha;
    }
    expect(enSevinc, greaterThan(.95));
    expect(enKahkaha, greaterThan(.95));
  });

  test('zarf uçlarda sıfır, içeride sürekli', () {
    surekli('zarf', (t) => zarf(t, gir: .12, cik: .3));
    expect(zarf(0), 0);
    expect(zarf(1), 0);
    expect(zarf(.5), 1);
  });

  test('ruh gülüşü: mutlu > düz > bulutlu, düz hafif gülümser', () {
    expect(Yuz.ruhGulusu(Ruh.mutlu), greaterThan(Yuz.ruhGulusu(Ruh.duz)));
    expect(Yuz.ruhGulusu(Ruh.duz), greaterThan(Yuz.ruhGulusu(Ruh.bulutlu)));
    expect(Yuz.ruhGulusu(Ruh.duz), greaterThan(0));
  });

  group('artıya geçiş', () {
    const a = VarlikTuru.altin, d = VarlikTuru.dolar;
    test('düz → mutlu ve bulutlu → mutlu kutlanır', () {
      expect(artiyaGecenler({a: Ruh.duz, d: Ruh.bulutlu}, {a: Ruh.mutlu, d: Ruh.mutlu}), {a, d});
    });
    test('ilk görülen, zaten mutlu olan ve düşüş kutlanmaz', () {
      expect(artiyaGecenler({}, {a: Ruh.mutlu}), isEmpty);
      expect(artiyaGecenler({a: Ruh.mutlu}, {a: Ruh.mutlu}), isEmpty);
      expect(artiyaGecenler({a: Ruh.mutlu}, {a: Ruh.duz}), isEmpty);
    });
    test('fiyatı bilinmeyen ve nakit bilinen hâl sayılmaz', () {
      final k = [
        KarakterDurumu(tur: a, miktar: 1, maliyetTl: 100, fiyat: null),
        KarakterDurumu(tur: VarlikTuru.nakit, miktar: 50, maliyetTl: 50, fiyat: null),
        KarakterDurumu(tur: d, miktar: 1, maliyetTl: 30, fiyat: 40),
      ];
      expect(bilinenRuhlar(k), {d: Ruh.mutlu});
    });
    test('depo son hâli saklar, bozuk kaydı yok sayar', () async {
      SharedPreferences.setMockInitialValues({});
      final depo = await Depo.ac();
      expect(depo.sonRuhOku(), isEmpty);
      await depo.sonRuhYaz({a: Ruh.bulutlu, d: Ruh.mutlu});
      expect(depo.sonRuhOku(), {a: Ruh.bulutlu, d: Ruh.mutlu});
      SharedPreferences.setMockInitialValues({'son_ruh_v1': '{"altin":"uzgun","x":"mutlu"'});
      expect((await Depo.ac()).sonRuhOku(), isEmpty);
      await depo.hepsiniSil();
    });
  });

  Widget sahne(List<Ses> calinan, int sevinc, {bool hareketsiz = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: hareketsiz),
          child: Center(child: Karakter(tur: VarlikTuru.dolar, ruh: Ruh.mutlu, sevincTetik: sevinc, ses: calinan.add)),
        ),
      );

  testWidgets('sevinç tetiği bir kez yaşasın çalar ve biter', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(sahne(calinan, 0));
    await t.pumpWidget(sahne(calinan, 1));
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calinan, [Ses.yasasin]);
    expect(t.takeException(), isNull);
  });

  testWidgets('hareketi azalt: sevinç sesle gelir, hareket yok', (t) async {
    final calinan = <Ses>[];
    await t.pumpWidget(sahne(calinan, 0, hareketsiz: true));
    await t.pumpWidget(sahne(calinan, 1, hareketsiz: true));
    expect(t.hasRunningAnimations, isFalse);
    expect(calinan, [Ses.yasasin]);
  });

  testWidgets('ruh değişince gülüş kayarak geçer', (t) async {
    Widget w(Ruh r) => MaterialApp(home: Center(child: Karakter(tur: VarlikTuru.euro, ruh: r)));
    await t.pumpWidget(w(Ruh.duz));
    await t.pumpWidget(w(Ruh.mutlu));
    await t.pump(const Duration(milliseconds: 300));
    final p = t.widget<CustomPaint>(find.byType(CustomPaint).last).painter! as KarakterPainter;
    expect(p.yuz!.gulus, inExclusiveRange(Yuz.ruhGulusu(Ruh.duz), 1));
    await t.pump(const Duration(milliseconds: 400));
    final p2 = t.widget<CustomPaint>(find.byType(CustomPaint).last).painter! as KarakterPainter;
    expect(p2.yuz!.gulus, 1);
  });
}
