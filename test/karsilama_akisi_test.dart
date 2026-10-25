import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:harcliklarim/widgets/avuc_parasi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Karakterler sürekli salınır (bob), bu yüzden `pumpAndSettle` hiç bitmez;
/// birkaç kare ilerletmek yeter.
Future<void> bekle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

/// Duman testi: karşılama → ad → kamp yeri → PIN'i geç (para birimi orada) → kamp ekranı.
/// Ağ sahte: truncgil gövdesi sabit; gerçek istek çıkmaz.
void main() {
  testWidgets('karşılama akışı kamp ekranına ulaşır ve besleme çalışır', (t) async {
    // Test ortamı en_US; uygulama cihaz dilini izler → Türkçe'ye sabitle.
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
    await t.tap(find.text('Devam'));
    await bekle(t);
    await t.tap(find.text('Devam')); // kamp yeri (varsayılan)
    await bekle(t);
    await t.tap(find.text('Şimdilik geç'));
    await bekle(t);

    expect(find.text('Merhaba Deniz'), findsOneWidget);
    expect(find.text('Kamp ateşim'), findsOneWidget);

    // Tortu'yu besle: 250 ₺ → 0,043 g.
    await t.tap(find.text('Besle').first);
    await bekle(t);
    await t.enterText(find.byType(TextField), '250');
    await bekle(t);
    expect(find.textContaining('alırsın'), findsOneWidget);
    await t.tap(find.text("Tortu'ya ver"));
    await bekle(t);
    // Yiyecek avuçta bekler; çocuk uzatır (burada dokunur).
    expect(find.byType(AvucParasi), findsOneWidget);
    await t.tap(find.bySemanticsLabel("Tortu'ya ver"));
    await bekle(t);
    expect(find.byType(AvucParasi), findsNothing);

    expect(find.text('Tortu doydu!'), findsNothing); // ilk besleme çıkartma açar
    expect(find.textContaining('Yeni çıkartma'), findsOneWidget);
    expect(find.text('250 ₺'), findsWidgets);
    // Toast (2,2 sn) kapanmadan test bitmesin.
    await t.pump(const Duration(seconds: 3));
  });
}
