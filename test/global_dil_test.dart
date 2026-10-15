import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/l10n/l10n.dart';
import 'package:harcliklarim/models/ders.dart';
import 'package:harcliklarim/models/varlik.dart';

/// Global uygulama sözleşmesi: her desteklenen dilin dersi, dil seçicide adı
/// ve iOS dil listesinde kaydı var; dersler aynı yapıda; tutar metne
/// yazılmaz, çocuğun para biriminde gösterilir; desteklenmeyen cihaz dili
/// İngilizce'ye düşer.
void main() {
  final diller = AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
  List<dynamic> ders(String d) => jsonDecode(File('assets/dersler/$d.json').readAsStringSync()) as List;
  Set<String> tutarlar(Object o) => RegExp(r'\{p:\d+\}').allMatches(jsonEncode(o)).map((m) => m[0]!).toSet();

  test('her dilin dersi, adı ve iOS kaydı var', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(Ders.diller.toSet(), diller.toSet());
    for (final d in diller) {
      expect(File('assets/dersler/$d.json').existsSync(), isTrue, reason: d);
      expect(dilAdlari[d], isNotNull, reason: d);
      expect(plist, contains('<string>$d</string>'), reason: 'CFBundleLocalizations: $d');
    }
  });

  test('dersler her dilde aynı yapıda, tutarlar yer tutucuyla', () {
    final en = ders('en');
    for (final d in diller) {
      final x = ders(d);
      expect(x.length, en.length, reason: d);
      for (var i = 0; i < en.length; i++) {
        final a = en[i] as Map, b = x[i] as Map;
        expect(b['id'], a['id'], reason: '$d #$i');
        expect(b['dogru'], a['dogru'], reason: '$d ${a['id']}');
        expect(b['karakter'], a['karakter'], reason: '$d ${a['id']}');
        expect((b['secenekler'] as List).length, 3, reason: '$d ${a['id']}');
        expect(tutarlar(b), tutarlar(a), reason: '$d ${a['id']}: tutar yer tutucuları');
        expect(jsonEncode(b), isNot(matches(RegExp(r'[₺$€£]'))), reason: '$d ${a['id']}: sabit para simgesi');
      }
    }
  });

  test('tutar çocuğun para biriminde', () {
    expect(Ders.paraYerlestir('{p:50} biriktir', ParaBirimi.tryy), '50 ₺ biriktir');
    expect(Ders.paraYerlestir('save {p:3000}', ParaBirimi.usd), r'save $3,000');
  });

  test('cihaz dili: destekleniyorsa o, bölge diline iner, yoksa İngilizce', () {
    const destek = AppLocalizations.supportedLocales;
    expect(dilCoz(const Locale('de', 'AT'), destek).languageCode, 'de');
    expect(dilCoz(const Locale('tr', 'TR'), destek).languageCode, 'tr');
    expect(dilCoz(const Locale('ja', 'JP'), destek).languageCode, 'en');
    expect(dilCoz(null, destek).languageCode, 'en');
  });
}
