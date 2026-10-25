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
    expect(fmtFark(-1e-13, ParaBirimi.tryy), '0 ₺', reason: 'kayan nokta artığı "−0" yazmaz');
    expect(fmtFark(-0.001, ParaBirimi.usd), r'$0');
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

  test('tek ayırıcı ve ardından üç hane binliktir (TR "1.500" = bin beş yüz)', () {
    expect(parseSayi('1.500'), 1500);
    expect(parseSayi('1,500'), 1500);
    expect(parseSayi('12.000'), 12000);
    expect(parseSayi('1.250.000'), 1250000);
    expect(parseSayi('1,250,000'), 1250000);
    // Üç haneden az ya da çok: ondalık.
    expect(parseSayi('12,5'), 12.5);
    expect(parseSayi('12.50'), 12.5);
    expect(parseSayi('0.25'), 0.25);
    expect(parseSayi('1.2345'), 1.2345);
    // Başı 0 olan grup binlik olamaz.
    expect(parseSayi('0,500'), 0.5);
    expect(parseSayi(',5'), 0.5);
  });

  test('ev birimindeki nakit tutar gibi yazılır, yabancı birim miktar gibi', () {
    expect(fmtMiktar(12, r'$', ParaBirimi.usd), r'$12');
    expect(fmtMiktar(360, '₺', ParaBirimi.tryy), '360 ₺');
    expect(fmtMiktar(8.738, r'$', ParaBirimi.tryy), r'8,738 $');
  });
}
