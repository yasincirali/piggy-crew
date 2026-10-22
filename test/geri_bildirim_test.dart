import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/l10n/generated/app_localizations.dart';
import 'package:harcliklarim/models/cocuk.dart';
import 'package:harcliklarim/models/geri_bildirim.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/theme/dunya.dart';

/// Veli onaylı geri bildirim (Ar-Ge raporu 2026-10-23 #3): metin çocuğun
/// adını ve hiçbir tutarı taşımaz; yalnız cihazda zaten saklanan sayılar.
void main() {
  final cocuk = Cocuk(
    ad: 'Deniz',
    yas: YasModu.kucuk,
    dunya: Dunya.values.first,
    pinOzeti: 'x',
    olusturma: DateTime(2026, 10, 1),
  );
  final hareketler = [
    Hareket(id: 'a', tur: VarlikTuru.altin, tarih: DateTime(2026, 10, 5, 9), tutarTl: 1234.5, birimFiyat: 5800),
    Hareket(id: 'b', tur: VarlikTuru.nakit, tarih: DateTime(2026, 10, 5, 18), tutarTl: 777, birimFiyat: 1),
    Hareket(id: 'c', tur: VarlikTuru.nakit, tarih: DateTime(2026, 10, 12), tutarTl: -333, birimFiyat: 1),
  ];

  for (final dil in AppLocalizations.supportedLocales) {
    test('${dil.languageCode}: ad ve tutar yok, sayılar doğru', () {
      final l = lookupAppLocalizations(dil);
      final m = geriBildirimMetni(
        l: l,
        cocuk: cocuk,
        hareketler: hareketler,
        odun: 1,
        ders: 4,
        cikartma: 3,
        ucBoyut: false,
        surum: '0.1.0 (42)',
        dil: dil.languageCode,
        simdi: DateTime(2026, 10, 23),
        cevaplar: ['Tortu', '', 'Unuttuk'],
      );
      expect(m, isNot(contains('Deniz')));
      for (final tutar in ['1234', '1.234', '1,234', '777', '333']) {
        expect(m, isNot(contains(tutar)), reason: 'tutar sızmamalı: $tutar');
      }
      expect(m, contains('${l.gbGun}: 1'), reason: 'aynı gündeki iki besleme bir gün; alma sayılmaz');
      expect(m, contains('${l.gbCikis}: 1'));
      expect(m, contains('${l.gbKurulu}: 22'));
      expect(m, contains(l.geriBildirimSoru1));
      expect(m, isNot(contains(l.geriBildirimSoru2)), reason: 'boş cevabın sorusu yazılmaz');
      expect(m, contains('Unuttuk'));
    });
  }

  test('cevap yoksa yalnız özet', () {
    final l = lookupAppLocalizations(const Locale('tr'));
    final m = geriBildirimMetni(
      l: l, cocuk: cocuk, hareketler: const [], odun: 0, ders: 0, cikartma: 0,
      ucBoyut: true, surum: null, dil: 'tr', simdi: DateTime(2026, 10, 1),
    );
    expect(m, isNot(contains(l.geriBildirimSoru1)));
    expect(m, contains('${l.gbGorunum}: 3D'));
  });
}
