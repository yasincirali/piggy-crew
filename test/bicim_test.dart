import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/utils/bicim.dart';

void main() {
  test('para biçimi ev birimini izler', () {
    expect(fmtPara(1240, ParaBirimi.tryy), '1.240 ₺');
    expect(fmtPara(1240, ParaBirimi.usd), r'$1,240');
    expect(fmtPara(12.5, ParaBirimi.tryy), '12,50 ₺');
  });

  test('fark işaretli, gerçek eksi', () {
    expect(fmtFark(64, ParaBirimi.tryy), '+64 ₺');
    expect(fmtFark(64.5, ParaBirimi.tryy), '+64,50 ₺');
    expect(fmtFark(-12, ParaBirimi.usd), '−\$12');
  });

  test('yüzde konumu dile göre', () {
    expect(fmtYuzde(5.4, ParaBirimi.tryy), '+%5,4');
    expect(fmtYuzde(-5.4, ParaBirimi.usd), '−5.4%');
  });

  test('sayı ayrıştırma yerel bağımsız', () {
    expect(parseSayi('1.250,50'), 1250.5);
    expect(parseSayi('1,250.50'), 1250.5);
    expect(parseSayi('1250.50'), 1250.5);
    expect(parseSayi('250'), 250);
    expect(parseSayi('0'), isNull);
    expect(parseSayi('abc'), isNull);
  });
}
