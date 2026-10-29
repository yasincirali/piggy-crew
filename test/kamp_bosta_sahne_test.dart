import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

const _govde = '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}';

/// Kampta boşta 3D hareketler (Ar-Ge 29 Eki #1): aynı anda yalnız bir
/// karakter pişmiş sahne oynar, oynanan filmler önbellekte kalır (her
/// seferinde baştan çözülmez).
void main() {
  testWidgets('iki dakika boyunca aynı anda en çok bir pişmiş boşta sahne', (t) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          depoProvider.overrideWithValue(Depo(sp)),
          fiyatServisiProvider.overrideWithValue(
            FiyatServisi(
              istemci: MockClient(
                (_) async => http.Response(_govde, 200, headers: {'content-type': 'application/json; charset=utf-8'}),
              ),
              tercihler: sp,
            ),
          ),
        ],
        child: const HarcliklarimApp(),
      ),
    );
    await bekle(t);
    await t.tap(find.text('Başla'));
    await bekle(t);
    await t.enterText(find.byType(TextField), 'Deniz');
    await bekle(t);
    for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
      await t.tap(find.text(d));
      await bekle(t);
    }

    // Minik evrede bitki katmanı yok: oynayan her pişmiş sahne tek film.
    var enCok = 0, toplamFilm = 0;
    for (var i = 0; i < 1200; i++) {
      await t.pump(const Duration(milliseconds: 100));
      final d = sahneOnbellekDurumu();
      if (d.oynayan > enCok) enCok = d.oynayan;
      toplamFilm = d.film;
    }
    expect(enCok, 1, reason: 'iki dakikada en az bir, aynı anda en çok bir pişmiş boşta sahne');
    expect(toplamFilm, greaterThanOrEqualTo(1), reason: 'oynanan film bırakılınca önbellekte kalır');
    expect(sahneOnbellekDurumu().bayt, lessThanOrEqualTo(sahneOnbellekBayt));

    // Uygulamayı kaldır: zamanlayıcılar sarkmasın.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
}
