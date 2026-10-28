import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Başlık fontu (Baloo 2) Latin alt kümesine indirildi (`tool/font/altkume.sh`,
/// 2026-10-23). Bu kilit, uygulamanın gösterdiği her metin karakterinin
/// fontta glifi olduğunu doğrular: yeni dil ya da yeni simge eklenip fonttan
/// düşerse burada kırılır (ekranda sessizce yedek fonta düşmesin).
void main() {
  final metinler = [
    ...Directory('lib/l10n').listSync().where((f) => f.path.endsWith('.arb')),
    ...Directory('assets/dersler').listSync().where((f) => f.path.endsWith('.json')),
    ...Directory('legal').listSync().where((f) => f.path.endsWith('.md')),
  ].map((f) => File(f.path).readAsStringSync());
  // Kontrol karakterleri (satır sonu vb.) çizilmez.
  final gerekli = {for (final m in metinler) ...m.runes.where((r) => r >= 0x20)};

  // Nunito da 27 Eki'de aynı alt kümeye indi (gövde metni, daha çok metin çizer).
  for (final ad in ['Baloo2-600', 'Baloo2-700', 'Baloo2-800', 'Nunito-400', 'Nunito-600', 'Nunito-700']) {
    test('$ad metinlerdeki her karakteri çizer', () {
      final kapsanan = _cmap(File('assets/fonts/$ad.ttf').readAsBytesSync());
      final eksik = gerekli.where((r) => !kapsanan.contains(r)).map((r) => 'U+${r.toRadixString(16).toUpperCase()} ${String.fromCharCode(r)}');
      expect(eksik, isEmpty, reason: 'fontta olmayan karakter; tool/font/altkume.sh aralığını genişlet');
      // Alt küme gerçekten küçük kalsın (Devanagari/Kiril geri gelmesin).
      expect(File('assets/fonts/$ad.ttf').lengthSync(), lessThan(150 * 1024));
    });
  }
}

/// TrueType `cmap` tablosundan glifi olan kod noktaları (biçim 4 ve 12).
Set<int> _cmap(Uint8List b) {
  final d = ByteData.sublistView(b);
  final tabloSayisi = d.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < tabloSayisi; i++) {
    final k = 12 + 16 * i;
    if (String.fromCharCodes(b.sublist(k, k + 4)) == 'cmap') cmap = d.getUint32(k + 8);
  }
  if (cmap < 0) throw StateError('cmap yok');
  final sonuc = <int>{};
  final altSayi = d.getUint16(cmap + 2);
  for (var i = 0; i < altSayi; i++) {
    final kayit = cmap + 4 + 8 * i;
    final o = cmap + d.getUint32(kayit + 4);
    switch (d.getUint16(o)) {
      case 4:
        final seg = d.getUint16(o + 6) ~/ 2;
        final son = o + 14, bas = son + 2 * seg + 2, delta = bas + 2 * seg, aralik = delta + 2 * seg;
        for (var s = 0; s < seg; s++) {
          final e = d.getUint16(son + 2 * s), st = d.getUint16(bas + 2 * s);
          final dl = d.getInt16(delta + 2 * s), ro = d.getUint16(aralik + 2 * s);
          for (var c = st; c <= e && c != 0xFFFF; c++) {
            var g = 0;
            if (ro == 0) {
              g = (c + dl) & 0xFFFF;
            } else {
              final gi = d.getUint16(aralik + 2 * s + ro + 2 * (c - st));
              if (gi != 0) g = (gi + dl) & 0xFFFF;
            }
            if (g != 0) sonuc.add(c);
          }
        }
      case 12:
        final n = d.getUint32(o + 12);
        for (var j = 0; j < n; j++) {
          final g = o + 16 + 12 * j;
          for (var c = d.getUint32(g); c <= d.getUint32(g + 4); c++) {
            sonuc.add(c);
          }
        }
    }
  }
  return sonuc;
}
