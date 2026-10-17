import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/cikartma.dart';

/// Karakter dili tüzüğü (CLAUDE.md): karakterler çocuğu suçlamaz, bir şey
/// talep etmez, yokluğunu yüzüne vurmaz, zaman baskısı kurmaz. Parasosyal
/// baskı ve "confirmshaming" çocuk uygulamalarındaki en yaygın manipülatif
/// desenler (Radesky vd. 2022; FTC; araştırma `harcliklarim/arastirma/03`).
/// Yeni metin bu listeye takılırsa metni değiştir, listeyi değil.
const _yasak = <String>[
  // TR
  'beni üzdün', 'üzdün', 'beni besle', 'gelmedin', 'neredeydin', 'unuttun',
  'aç kaldım', 'acıktım', 'yalnız bıraktın', 'acele et', 'son şans', 'kaçırma',
  'hemen besle', 'kızdım',
  // EN
  'you made me sad', 'feed me', 'where were you', 'you forgot', "i'm hungry",
  'i am hungry', 'left me', 'last chance', 'hurry', "don't miss", 'angry with you',
  // DE
  'traurig gemacht', 'füttere mich', 'wo warst du', 'hast mich vergessen', 'du hast vergessen', 'ich habe hunger',
  'allein gelassen', 'letzte chance', 'beeil dich', 'verpass nicht', 'böse auf dich',
  // ES
  'me pusiste triste', 'dame de comer', 'aliméntame', 'dónde estabas', 'te olvidaste',
  'tengo hambre', 'me dejaste', 'última oportunidad', 'date prisa', 'no te lo pierdas',
  // FR
  "m'as rendu triste", 'nourris-moi', 'où étais-tu', 'tu as oublié', "j'ai faim",
  'abandonné', 'dernière chance', 'dépêche-toi', 'ne rate pas', 'fâché contre toi',
  // PT
  'me deixou triste', 'me alimenta', 'onde você estava', 'você esqueceu', 'estou com fome',
  'me abandonou', 'última chance', 'se apressa', 'anda logo', 'não perca', 'bravo com você',
  // Yokluğu anma (geri dönüş karşılaması, yol haritası 1.4): "özledik",
  // "günlerdir yoktun" gibi süre ya da hasret dili yok.
  'özledi', 'günlerdir', 'uzun zaman', 'nihayet', 'missed you', 'long time', 'finally back',
  'vermisst', 'endlich wieder', 'te extrañ', 'por fin', 'tu nous as manqué', 'enfin',
  'saudade', 'finalmente',
];

/// Tüm diller: yeni .arb eklenince test kendiliğinden kapsar.
final _diller = Directory('lib/l10n')
    .listSync()
    .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
    .whereType<String>()
    .toList()
  ..sort();

void main() {
  test('dil listesi boş değil', () => expect(_diller, containsAll(['tr', 'en'])));
  for (final dil in _diller) {
    test('$dil: karakter metinlerinde suçlama/talep/baskı yok', () {
      final arb = jsonDecode(File('lib/l10n/app_$dil.arb').readAsStringSync()) as Map<String, dynamic>;
      final ihlal = <String>[];
      arb.forEach((anahtar, deger) {
        if (anahtar.startsWith('@') || deger is! String) return;
        final kucuk = deger.toLowerCase();
        for (final y in _yasak) {
          if (kucuk.contains(y)) ihlal.add('$anahtar: "$deger" ("$y")');
        }
      });
      expect(ihlal, isEmpty, reason: ihlal.join('\n'));
    });
  }

  test('çıkartma açıklamaları tutar eşiği içermez (davranış ödüllenir)', () {
    for (final dil in _diller) {
      final arb = jsonDecode(File('lib/l10n/app_$dil.arb').readAsStringSync()) as Map<String, dynamic>;
      arb.forEach((anahtar, deger) {
        if (!anahtar.startsWith('ck') || deger is! String) return;
        // Tutar gibi duran sayı (100 ve üstü, binlik ayraçlı) yok; "30 gün" serbest.
        expect(RegExp(r'\d[\d.,]{2,}').hasMatch(deger), isFalse, reason: '$dil $anahtar: "$deger"');
      });
    }
  });

  group('farklı hafta sayımı', () {
    test('aynı hafta bir sayılır, ara vermek silmez', () {
      final t = [
        DateTime(2026, 10, 12), // Pzt
        DateTime(2026, 10, 18, 23), // aynı haftanın Pazar'ı
        DateTime(2026, 10, 19), // ertesi hafta
        DateTime(2026, 11, 30), // aylar sonra
      ];
      expect(Cikartma.farkliHaftalar(t), 3);
      expect(Cikartma.farkliHaftalar(const []), 0);
    });
    test('yıl dönümü haftası tek hafta', () {
      expect(Cikartma.farkliHaftalar([DateTime(2026, 12, 31), DateTime(2027, 1, 2)]), 1);
    });
  });
}
