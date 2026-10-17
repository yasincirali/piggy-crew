import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/donus.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Geri dönüş karşılaması (yol haritası 1.4): birkaç gün sonra açılınca takım
/// koşarak gelir; yokluk süresi yazılmaz, haftada en çok bir kez, ilk
/// kurulumda değil. Sahne kenarda görünmez başlar, yerinde durarak biter.
void main() {
  group('karar', () {
    final simdi = DateTime(2026, 10, 17, 9);
    bool karar(DateTime? gorulme, [DateTime? donus]) =>
        donusKarsilamasiGerekli(sonGorulme: gorulme, sonDonus: donus, simdi: simdi);

    test('ilk kurulumda oynamaz', () => expect(karar(null), isFalse));
    test('aynı gün ve iki gün sonra oynamaz', () {
      expect(karar(DateTime(2026, 10, 17, 7)), isFalse);
      expect(karar(DateTime(2026, 10, 15, 23, 59)), isFalse);
    });
    test('üç takvim günü sonra oynar (saat önemsiz)', () {
      expect(karar(DateTime(2026, 10, 14, 23, 50)), isTrue);
      expect(karar(DateTime(2026, 9, 1)), isTrue);
    });
    test('haftada en çok bir kez', () {
      final eski = DateTime(2026, 10, 1);
      expect(karar(eski, DateTime(2026, 10, 12)), isFalse);
      expect(karar(eski, DateTime(2026, 10, 10, 23)), isTrue);
    });
    test('saat geri alınmışsa oynamaz', () {
      expect(karar(DateTime(2026, 10, 20)), isFalse);
      expect(karar(DateTime(2026, 10, 1), DateTime(2026, 10, 25)), isFalse);
    });
    test('yaz saati geçişi gün farkını bozmaz', () {
      expect(takvimGunFarki(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 31, 0, 30)), 3);
      expect(takvimGunFarki(DateTime(2026, 10, 24, 1), DateTime(2026, 10, 27, 1)), 3);
    });
  });

  group('sahne', () {
    test('kenarda görünmez başlar, yerinde ve yerde biter', () {
      final bas = donusSahnesi(0);
      expect(bas.uzaklik, 1);
      expect(bas.opaklik, 0);
      final son = donusSahnesi(1);
      expect(son.uzaklik, closeTo(0, 1e-9));
      expect(son.opaklik, 1);
      expect(son.y, 0);
      expect(son.egim, 0);
      expect(son.yuz.sevinc, 0);
    });

    test('varınca sevinç yüzü (aynı duygu sözlüğü), koşarken gülümser', () {
      expect(donusSahnesi(.3).yuz.gulus, greaterThan(.9));
      final enCok = [for (var i = 0; i <= 100; i++) donusSahnesi(i / 100).yuz.sevinc].reduce((a, b) => a > b ? a : b);
      expect(enCok, greaterThan(.95));
    });

    test('yol ve yüz sıçramaz', () {
      var onceki = donusSahnesi(0);
      for (var i = 1; i <= 300; i++) {
        final s = donusSahnesi(i / 300);
        expect((s.uzaklik - onceki.uzaklik).abs(), lessThan(.05), reason: 't=${i / 300}');
        for (var k = 0; k < s.yuz.degerler.length; k++) {
          expect((s.yuz.degerler[k] - onceki.yuz.degerler[k]).abs(), lessThan(.08), reason: 't=${i / 300} yüz[$k]');
        }
        onceki = s;
      }
    });
  });

  group('depo', () {
    test('anlar yazılıp okunur, veriyi sil temizler, bozuk değer hiç sayılır', () async {
      SharedPreferences.setMockInitialValues({'son_donus_v1': 'bozuk'});
      final depo = Depo(await SharedPreferences.getInstance());
      expect(depo.sonGorulmeOku(), isNull);
      expect(depo.sonDonusOku(), isNull);
      final t = DateTime(2026, 10, 17, 9, 30);
      await depo.sonGorulmeYaz(t);
      await depo.sonDonusYaz(t);
      expect(depo.sonGorulmeOku(), t);
      expect(depo.sonDonusOku(), t);
      await depo.hepsiniSil();
      expect(depo.sonGorulmeOku(), isNull);
      expect(depo.sonDonusOku(), isNull);
    });
  });

  group('karakter', () {
    Widget sahne({int donus = 0, bool hareketsiz = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: hareketsiz),
            child: Center(child: Karakter(tur: VarlikTuru.dolar, ruh: Ruh.mutlu, donusTetik: donus)),
          ),
        );
    double? opaklik(WidgetTester t) {
      final f = find.descendant(of: find.byType(Karakter), matching: find.byType(Opacity));
      return f.evaluate().isEmpty ? null : t.widget<Opacity>(f.first).opacity;
    }

    testWidgets('soğuk açılışta ilk karede görünmez, sonra yerine oturur', (t) async {
      await t.pumpWidget(sahne(donus: 1));
      expect(opaklik(t), 0);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 400));
      expect(opaklik(t), isNull, reason: 'koşu ortasında tam görünür');
      await t.pump(const Duration(milliseconds: 1600));
      expect(opaklik(t), isNull);
      final tr = t.widget<Transform>(find.descendant(of: find.byType(Karakter), matching: find.byType(Transform)).first);
      expect(tr.transform.getTranslation().x, 0, reason: 'sahne bitince yerinde');
      expect(t.takeException(), isNull);
    });

    testWidgets('tetik artınca oynar, azalınca oynamaz', (t) async {
      await t.pumpWidget(sahne());
      expect(opaklik(t), isNull);
      await t.pumpWidget(sahne(donus: 1));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(opaklik(t), lessThan(1));
      await t.pump(const Duration(milliseconds: 1600));
      await t.pumpWidget(sahne());
      await t.pump(const Duration(milliseconds: 16));
      expect(opaklik(t), isNull);
    });

    testWidgets('hareketi azalt: karakter yerinde kalır', (t) async {
      await t.pumpWidget(sahne(donus: 1, hareketsiz: true));
      expect(opaklik(t), isNull);
      await t.pumpWidget(sahne(donus: 2, hareketsiz: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(opaklik(t), isNull);
    });
  });

  testWidgets('kamp: birkaç gün sonra dönünce bir kez karşılar, aynı hafta tekrar etmez', (t) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    addTearDown(t.platformDispatcher.clearAllTestValues);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final sahteHttp = MockClient((_) async => http.Response(
        '{"USD":{"Satış":41.2},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
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
    expect(find.text('Merhaba Deniz'), findsOneWidget);
    const mesaj = 'Takım seni görünce koşa koşa geldi!';
    expect(find.text(mesaj), findsNothing, reason: 'ilk kurulumda karşılama yok');
    final depo = Depo(sp);
    expect(depo.sonGorulmeOku(), isNotNull);

    Future<void> uzaklasipDon(Duration once) async {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await sp.setInt('son_gorulme_v1', DateTime.now().subtract(once).millisecondsSinceEpoch);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await bekle(t);
      await t.pump(const Duration(milliseconds: 500));
    }

    await uzaklasipDon(const Duration(days: 5));
    expect(find.text(mesaj), findsOneWidget);
    expect(depo.sonDonusOku(), isNotNull);
    for (var i = 0; i < 4; i++) {
      await bekle(t); // toast (2,2 sn) kapansın
    }
    expect(find.text(mesaj), findsNothing);

    await uzaklasipDon(const Duration(days: 4));
    expect(find.text(mesaj), findsNothing, reason: 'haftada en çok bir kez');
    await t.pump(const Duration(seconds: 3));

    // Başka sekmedeyken dönerse karşılama bekler, kampa geçince oynar.
    await sp.remove('son_donus_v1');
    await t.tap(find.byIcon(Icons.menu_book_outlined));
    await bekle(t);
    await uzaklasipDon(const Duration(days: 6));
    expect(find.text(mesaj), findsNothing, reason: 'kamp görünmüyor');
    expect(depo.sonDonusOku(), isNull);
    await t.tap(find.byIcon(Icons.local_fire_department_outlined));
    await bekle(t);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text(mesaj), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });
}
