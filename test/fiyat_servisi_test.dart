import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';

void main() {
  group('truncgil ayrıştırma', () {
    test('sayı değerleri okur, satışı tercih eder', () {
      final m = FiyatServisi.ayristir(
          '{"USD":{"Alış":41.10,"Satış":41.20},"EUR":{"Alış":47.9,"Satış":48.0},"GRA":{"Satış":5800.5},"GBP":{"Buying":"55,10"}}');
      expect(m['USD'], 41.20);
      expect(m['EUR'], 48.0);
      expect(m['GRA'], 5800.5);
      expect(m['GBP'], 55.10);
    });

    test('eksik veya sıfır değer ATLANIR, uydurulmaz', () {
      final m = FiyatServisi.ayristir('{"USD":{"Satış":0},"EUR":"bozuk"}');
      expect(m, isEmpty);
    });

    test('ev birimi çevrimi: USD evinde altın USD cinsinden', () {
      final f = Fiyatlar(degerler: const {'GRA': 5800, 'USD': 40, 'EUR': 48}, zaman: DateTime(2026), taze: true);
      expect(f.fiyat(VarlikTuru.altin, ParaBirimi.usd), 145);
      expect(f.fiyat(VarlikTuru.euro, ParaBirimi.usd), 1.2);
      expect(f.fiyat(VarlikTuru.nakit, ParaBirimi.usd), 1);
      // Kur yoksa null — sabit yok.
      expect(f.fiyat(VarlikTuru.altin, ParaBirimi.gbp), isNull);
    });
  });

  group('karakter durumu', () {
    test('yüz ifadesi ±0,5 bandı', () {
      const d = KarakterDurumu(tur: VarlikTuru.altin, miktar: 1, maliyetTl: 1000, fiyat: 1004);
      expect(d.ruh, Ruh.duz);
      const m = KarakterDurumu(tur: VarlikTuru.altin, miktar: 1, maliyetTl: 1000, fiyat: 1060);
      expect(m.ruh, Ruh.mutlu);
      const u = KarakterDurumu(tur: VarlikTuru.altin, miktar: 1, maliyetTl: 1000, fiyat: 940);
      expect(u.ruh, Ruh.uzgun);
    });

    test('nakit hep düz; fiyat yoksa değer null', () {
      const n = KarakterDurumu(tur: VarlikTuru.nakit, miktar: 500, maliyetTl: 500, fiyat: 1);
      expect(n.ruh, Ruh.duz);
      expect(n.degerTl, 500);
      const y = KarakterDurumu(tur: VarlikTuru.dolar, miktar: 10, maliyetTl: 400, fiyat: null);
      expect(y.degerTl, isNull);
      expect(y.ruh, Ruh.duz);
    });

    test('dolar evinde dolar karakteri gizli', () {
      expect(VarlikTuru.dolar.gorunur(ParaBirimi.usd), isFalse);
      expect(VarlikTuru.euro.gorunur(ParaBirimi.eur), isFalse);
      expect(VarlikTuru.dolar.gorunur(ParaBirimi.tryy), isTrue);
      expect(VarlikTuru.fromAnahtar('tl'), VarlikTuru.nakit);
    });
  });
}
