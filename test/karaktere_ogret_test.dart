import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/ders.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/screens/kamp_ekrani.dart';
import 'package:harcliklarim/screens/varlik_detay_ekrani.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/services/fiyat_servisi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'karsilama_akisi_test.dart' show bekle;

const _govde = '{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}';

/// "Tortu'ya öğret" (Ar-Ge 26 Eki, protégé etkisi): soruyu karakter sorar,
/// çocuk doğru anlatınca ders o karakterin "öğrettiklerin" rafına girer.
/// Yanlışta karakter suçlamaz, "birlikte bakalım" der; raf sayı göstermez.
void main() {
  // Ders dosyası gerçek G/Ç ile yüklenir; sahte saatli testin içinde değil,
  // bir kez burada (rootBundle önbelleği başka testin bölgesinde takılmasın).
  late List<Ders> dersler;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dersler = await Ders.yukle('tr');
  });

  Future<ProviderContainer> kampa(WidgetTester t, {Map<String, Object> on = const {}}) async {
    t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.platformDispatcher.clearAllTestValues);
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(on);
    final sp = await SharedPreferences.getInstance();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          derslerProvider.overrideWith((_, _) => dersler),
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
    final kap = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
    // Ders dosyası gerçek G/Ç ile yüklenir; sahte saatte beklemek yetmez.
    await t.runAsync(() => kap.read(derslerProvider('tr').future));
    await bekle(t);
    return kap;
  }

  Future<void> detayAc(WidgetTester t, VarlikTuru tur) async {
    Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(tur));
    await bekle(t);
  }

  testWidgets('karakter sorar; yanlışta birlikte bakar, doğruda ders rafa girer', (t) async {
    final kap = await kampa(t);
    await t.tap(find.text('Öğren'));
    await bekle(t);
    expect(find.textContaining('buna takıldı. Ona anlatır mısın?'), findsOneWidget);

    // İlk ders "birikim" (nakit karakteri): 10 haftada 50 ₺ → 500 ₺.
    await t.ensureVisible(find.text('5.000 ₺'));
    await t.tap(find.text('5.000 ₺'));
    await bekle(t);
    expect(find.textContaining('Metne birlikte bir daha bakalım mı?'), findsOneWidget);
    expect(kap.read(ogretilenProvider), isEmpty, reason: 'yanlış cevap rafa bir şey yazmaz');

    await t.tap(find.text('500 ₺'));
    await bekle(t);
    expect(find.textContaining('Şimdi anladım, teşekkürler!'), findsOneWidget);
    expect(kap.read(ogretilenProvider), {'birikim'});

    await t.tap(find.text('Kamp'));
    await bekle(t);
    await detayAc(t, VarlikTuru.nakit);
    expect(find.textContaining('senden öğrendi'), findsOneWidget);
    await t.ensureVisible(find.text('Para neden bekler?'));
    await bekle(t);
    await t.tap(find.text('Para neden bekler?'));
    await bekle(t);
    expect(find.textContaining('Bekleyen para büyür'), findsOneWidget, reason: 'ders metni yeniden okunur');
  });

  testWidgets('raf yalnız o karakterin dersleri; boşsa hiç görünmez', (t) async {
    final kap = await kampa(t);
    await kap.read(ogretilenProvider.notifier).ekle('birikim');
    await detayAc(t, VarlikTuru.altin);
    expect(find.textContaining('senden öğrendi'), findsNothing);
  });

  testWidgets('özellikten önce geçilen dersler rafa taşınır', (t) async {
    final kap = await kampa(t, on: {'ders_ilerleme_v1': 2});
    // Öğren sekmesi açılışta kurulur ve tohumlar; karakter ekranı rafı gösterir.
    expect(kap.read(ogretilenProvider), {'birikim', 'enflasyon'});
    await detayAc(t, VarlikTuru.nakit);
    expect(find.textContaining('senden öğrendi'), findsOneWidget);
  });

  // HIG: Dynamic Type 3,1×'te raf ve ders sayfası taşmaz (taşma test hatasıdır).
  testWidgets('raf 3,1× yazıda taşmaz', (t) async {
    final kap = await kampa(t, on: {'ders_ilerleme_v1': 2});
    t.platformDispatcher.textScaleFactorTestValue = 3.1;
    await detayAc(t, VarlikTuru.nakit);
    await bekle(t);
    expect(kap.read(ogretilenProvider), isNotEmpty);
    await t.scrollUntilVisible(
      find.text('Para küçülür mü?'),
      300,
      scrollable: find.descendant(of: find.byType(VarlikDetayEkrani), matching: find.byType(Scrollable)).first,
    );
    await bekle(t);
    await t.tap(find.text('Para küçülür mü?'));
    await bekle(t);
    expect(find.textContaining('Paran aynı kaldı'), findsOneWidget);
  });

  test('Tüm veriyi sil öğretilenleri de siler', () async {
    SharedPreferences.setMockInitialValues({
      'ogretilen_dersler_v1': ['birikim'],
    });
    final sp = await SharedPreferences.getInstance();
    final depo = Depo(sp);
    expect(depo.ogretilenOku(), {'birikim'});
    await depo.hepsiniSil();
    expect(depo.ogretilenOku(), isNull);
  });
}
