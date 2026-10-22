import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

/// Dynamic Type kilidi (HIG kontrolü, sandık kuralı: 3×'e kadar bozulmamalı).
/// Taşma (RenderFlex overflow) Flutter'da test hatasıdır; bu yüzden akışın
/// her ekranını büyük yazıyla dolaşmak yeterli bir ölçüdür. Küçük telefon
/// (iPhone SE, 375×667) en dar durumdur.
void main() {
  for (final olcek in [1.0, 2.0, 3.0]) {
    testWidgets('yazı ölçeği $olcek× ve küçük ekranda akış taşmadan ilerler', (
      t,
    ) async {
      t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
      t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
      t.platformDispatcher.textScaleFactorTestValue = olcek;
      t.view.physicalSize = const Size(375 * 3, 667 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.platformDispatcher.clearAllTestValues);
      addTearDown(t.view.reset);

      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final sahteHttp = MockClient(
        (_) async => http.Response(
          '{"USD":{"Satış":41.2},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      await t.pumpWidget(
        ProviderScope(
          overrides: [
            depoProvider.overrideWithValue(Depo(sp)),
            fiyatServisiProvider.overrideWithValue(
              FiyatServisi(istemci: sahteHttp, tercihler: sp),
            ),
          ],
          child: const HarcliklarimApp(),
        ),
      );
      await bekle(t);

      Future<void> dokun(String metin) async {
        final f = find.text(metin);
        await t.ensureVisible(f.first);
        await t.tap(f.first);
        await bekle(t);
      }

      await dokun('Başla');
      await t.enterText(find.byType(TextField), 'Deniz');
      await bekle(t);
      await dokun('Devam');
      await dokun('Devam');
      await dokun('Devam');
      await dokun('Şimdilik geç');
      expect(find.text('Merhaba Deniz'), findsOneWidget);

      // Diğer sekmeler.
      for (final sekme in [
        Icons.menu_book_outlined,
        Icons.star_outline_rounded,
        Icons.tune_rounded,
      ]) {
        final f = find.byIcon(sekme);
        if (f.evaluate().isNotEmpty) {
          await t.tap(f.first);
          await bekle(t);
        }
      }

      // Veli köşesi › Geri bildirim (PIN kurulu olunca açılır).
      final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
      await kap.read(cocukProvider.notifier).guncelle((c) => c.copyWith(pinOzeti: Depo.pinOzeti('1234')));
      await bekle(t);
      // Satır alt çubuğun arkasında kalmasın: listenin sonuna kadar kaydır.
      await t.scrollUntilVisible(find.text('Anne baba köşesi'), 300, scrollable: find.byType(Scrollable).hitTestable().first);
      await t.drag(find.byType(Scrollable).hitTestable().first, const Offset(0, -2000));
      await bekle(t);
      await t.tap(find.text('Anne baba köşesi'));
      await bekle(t);
      await t.enterText(find.byType(TextField), '1234');
      await bekle(t);
      await dokun('Geri bildirim gönder');
      expect(find.text('Gönderilecek bilgiler'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Paylaş'), 200, scrollable: find.byType(Scrollable).last);
      Navigator.of(t.element(find.text('Paylaş'))).pop();
      await bekle(t);
      Navigator.of(t.element(find.text('Geri bildirim gönder'))).pop();
      await bekle(t);
    });
  }
}
