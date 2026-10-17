import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/l10n/l10n.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/dokunsal.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/services/ses_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Ses, titreşim ve görsel efekt sözleşmesi (2026-10-17, "titreşim ve
/// efektler profesyonel"):
/// - her sesin dosyası var ve lisans tablosunda;
/// - her titreşim deseni kısa, ölçülü ve zaman sırasında;
/// - besleme çizelgesi sahne eğrileriyle aynı anda (ısırık, kanat);
/// - parçacıklar kısa yaşar, sahne dışında yok;
/// - Ayarlar'daki Titreşim seçimi kalıcı.
void main() {
  test('her sesin dosyası var ve LISANS.md tablosunda', () {
    final lisans = File('assets/sesler/LISANS.md').readAsStringSync();
    for (final s in Ses.values) {
      for (final d in sesDosyalari(s)) {
        expect(File('assets/sesler/$d.wav').existsSync(), isTrue, reason: '$d.wav yok');
      }
      final ad = s == Ses.isirik ? 'isirik_1..3.wav' : '${s.name}.wav';
      expect(lisans.contains('| $ad |'), isTrue, reason: '$ad lisans tablosunda yok');
    }
  });

  test('titreşim desenleri kısa, ölçülü, zaman sırasında', () {
    for (final d in Dokunus.values) {
      final desen = dokunusDesenleri[d];
      expect(desen, isNotNull, reason: '$d deseni yok');
      expect(desen, isNotEmpty);
      var once = -1.0;
      for (final v in desen!) {
        expect(v.zaman, greaterThanOrEqualTo(once), reason: '$d sırasız');
        once = v.zaman;
        // Şiddet 0,9'u geçmez (çocuğun elinde rahatsız etmesin); keskinlik serbest.
        for (final x in [v.siddet, v.son ?? 0]) {
          expect(x, inInclusiveRange(0, .9), reason: '$d: şiddet 0–0,9 dışında');
        }
        expect(v.keskinlik, inInclusiveRange(0, 1));
        expect(v.zaman + v.sure, lessThanOrEqualTo(.5), reason: '$d yarım saniyeyi aşıyor');
      }
    }
  });

  test('titreşim kapalıysa hiçbir şey çalmaz', () async {
    final kayit = <Dokunus>[];
    final s = DokunsalServisi(acik: false, kaydedici: kayit.add);
    await s.cal(Dokunus.sevinc);
    expect(kayit, isEmpty);
    s.acik = true;
    await s.cal(Dokunus.sevinc);
    expect(kayit, [Dokunus.sevinc]);
  });

  for (final tur in VarlikTuru.values) {
    test('besleme çizelgesi (${tur.name}): sıralı, sahne içinde, sevinçle biter', () {
      final c = yemeIpuclari(tur);
      for (var i = 0; i < c.length; i++) {
        expect(c[i].t, inExclusiveRange(0, 1));
        if (i > 0) expect(c[i].t, greaterThanOrEqualTo(c[i - 1].t));
      }
      expect(c.where((i) => i.ses == Ses.yasasin).single.t, yemeZamani(tur).sevinc);
      expect(c.where((i) => i.ses == yakalamaSesi(tur)).single.t, yemeZamani(tur).tutma);
    });

    test('efektler (${tur.name}): yakalamada kıvılcım, sahne dışında yok', () {
      expect(yemeEfektleri(tur, 0), isEmpty);
      expect(yemeEfektleri(tur, 1), isEmpty);
      final yakalama = yemeEfektleri(tur, yemeZamani(tur).tutma + .01);
      expect(yakalama.where((p) => p.bicim == ParcacikBicim.kivilcim).length, greaterThanOrEqualTo(7));
      for (var t = 0.0; t <= 1; t += .01) {
        for (final p in yemeEfektleri(tur, t)) {
          expect(p.opak, inInclusiveRange(0, 1));
        }
      }
    });
  }

  test('Zıpzıp ısırık sesleri kemirmenin tepelerinde', () {
    final isirik = yemeIpuclari(VarlikTuru.dolar).where((i) => i.ses == Ses.isirik).map((i) => i.t).toList();
    expect(isirik, hasLength(5));
    // Kemirmede ağız ısırıkla açılır: ses anında açık, iki ısırık arasında kapalı.
    double agiz(double t) => yemeSahnesi(VarlikTuru.dolar, t).yuz.agizO;
    for (var i = 0; i < isirik.length; i++) {
      expect(agiz(isirik[i]), greaterThan(.25), reason: '${i + 1}. ısırıkta ağız açık (sonuncusu sönerken yarım)');
      if (i > 0) expect(agiz((isirik[i] + isirik[i - 1]) / 2), lessThan(.05), reason: 'arada kapalı');
    }
  });

  test('Baykuş kanat sesleri çırpışın tepelerinde', () {
    final kanat = yemeIpuclari(VarlikTuru.euro).where((i) => i.ses == Ses.kanat).map((i) => i.t).toList();
    expect(kanat, hasLength(2));
    for (final t in kanat) {
      expect(yemeSahnesi(VarlikTuru.euro, t).kanat, closeTo(.9, .01));
    }
  });

  test('Türkçe ekler karaktere göre: Tortu\'yu, Zıpzıp\'ı, Baykuş\'u, Sincap\'ı besle', () {
    final l = lookupAppLocalizations(const Locale('tr'));
    expect([for (final t in VarlikTuru.values) l.besleBaslik(l.karakter(t), t.name)],
        ["Tortu'yu besle", "Zıpzıp'ı besle", "Baykuş'u besle", "Sincap'ı besle"]);
    expect([for (final t in VarlikTuru.values) l.besleVer(l.karakter(t))],
        ["Tortu'ya ver", "Zıpzıp'a ver", "Baykuş'a ver", "Sincap'a ver"]);
  });

  testWidgets('Ayarlar: Titreşim kapatılınca kalıcı olarak kapanır', (t) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final sahteHttp = MockClient((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json; charset=utf-8'}));
    await t.pumpWidget(ProviderScope(
      overrides: [
        depoProvider.overrideWithValue(Depo(sp)),
        fiyatServisiProvider.overrideWithValue(FiyatServisi(istemci: sahteHttp, tercihler: sp)),
      ],
      child: const HarcliklarimApp(),
    ));
    await bekle(t);
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    for (final d in ['Devam', 'Devam', 'Devam', 'Şimdilik geç']) {
      await t.tap(find.text(d));
      await bekle(t);
    }
    await t.tap(find.byIcon(Icons.tune_rounded).first);
    await bekle(t);
    final baslik = find.text('Titreşim');
    await t.ensureVisible(baslik);
    await bekle(t);
    // Titreşim bölümündeki "Kapalı" (Seslerinkinden sonra ikinci).
    await t.tap(find.text('Kapalı').at(1));
    await bekle(t);
    expect(sp.getBool('titresim_acik_v1'), isFalse);
    expect(sp.getBool('ses_acik_v1'), isNull, reason: 'ses seçimi değişmedi');
  });
}
