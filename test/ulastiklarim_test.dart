import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/main.dart';
import 'package:harcliklarim/models/cizim.dart';
import 'package:harcliklarim/models/hedef.dart';
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

/// "Ulaştıklarım": dolmuş hedef yenisi konunca ya da kaldırılınca silinmez,
/// karakter ekranında sayısız bir şeritte kalır; "tüm veriyi sil" götürür.
void main() {
  final ekim = DateTime(2026, 10, 20);
  final dolu = Hedef(esya: HedefEsya.top, fiyatTl: 100, ulasildi: ekim);
  const cizim = Cizim([Cizgi(renk: 1, noktalar: [Offset(.2, .2), Offset(.8, .8)])]);

  Future<ProviderContainer> kap() async {
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [depoProvider.overrideWithValue(Depo(sp))]);
    addTearDown(c.dispose);
    return c;
  }

  group('kayıt', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('dolmuş hedefin yerine yenisi gelince eskisi saklanır, dolmamış saklanmaz', () async {
      final c = await kap();
      final n = c.read(hedeflerProvider.notifier);
      await n.koy(VarlikTuru.nakit, const Hedef(esya: HedefEsya.kitap, fiyatTl: 50));
      await n.koy(VarlikTuru.nakit, dolu);
      expect(c.read(ulasilanlarProvider), isEmpty, reason: 'dolmamış kitap saklanmaz');
      await n.koy(VarlikTuru.nakit, dolu);
      expect(c.read(ulasilanlarProvider), isEmpty, reason: 'aynı hedef yeniden konunca çoğalmaz');
      await n.koy(VarlikTuru.nakit, const Hedef(esya: HedefEsya.cizim, fiyatTl: 80, cizim: cizim));
      expect(c.read(ulasilanlarProvider)[VarlikTuru.nakit], [dolu]);
      final cizildi = Hedef(esya: HedefEsya.cizim, fiyatTl: 80, cizim: cizim, ulasildi: DateTime(2026, 11, 2));
      await n.koy(VarlikTuru.nakit, cizildi);
      await n.kaldir(VarlikTuru.nakit);
      expect(c.read(ulasilanlarProvider)[VarlikTuru.nakit], [dolu, cizildi], reason: 'kaldırılan dolu hedef de saklanır');

      // Kayıttan aynı okunur; eski kurulum (anahtar yok) boş okur.
      final sp = await SharedPreferences.getInstance();
      expect(Depo(sp).ulasilanlariOku()[VarlikTuru.nakit], [dolu, cizildi]);
      await Depo(sp).hepsiniSil();
      expect(Depo(sp).ulasilanlariOku(), isEmpty);
    });

    test('en eskisi sınırı aşınca düşer; bozuk ve dolmamış kayıt atlanır', () async {
      final c = await kap();
      final u = c.read(ulasilanlarProvider.notifier);
      for (var i = 0; i < UlasilanlarNotifier.enFazla + 3; i++) {
        await u.ekle(VarlikTuru.dolar, Hedef(esya: HedefEsya.oyun, fiyatTl: i + 1.0, ulasildi: ekim));
      }
      final l = c.read(ulasilanlarProvider)[VarlikTuru.dolar]!;
      expect(l.length, UlasilanlarNotifier.enFazla);
      expect(l.first.fiyatTl, 4);

      SharedPreferences.setMockInitialValues({
        'ulasilan_hedefler_v1': '{"euro":[{"esya":"top","fiyatTl":5},{"esya":"x","fiyatTl":5,"ulasildi":"2026-10-01T00:00:00.000"},'
            '{"esya":"kitap","fiyatTl":5,"ulasildi":"2026-10-01T00:00:00.000"}],"yok":[]}',
      });
      final oku = Depo(await SharedPreferences.getInstance()).ulasilanlariOku();
      expect(oku.keys, [VarlikTuru.euro]);
      expect(oku[VarlikTuru.euro]!.map((h) => h.esya), [HedefEsya.kitap]);
    });
  });

  group('şerit', () {
    Future<void> ac(WidgetTester t, {double yazi = 1, bool bos = false}) async {
      t.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
      t.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.platformDispatcher.clearAllTestValues);
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      rootBundle.clear();
      final sp = await SharedPreferences.getInstance();
      final sahteHttp = MockClient(
        (_) async => http.Response('{"USD":{"Satış":40},"EUR":{"Satış":48},"GRA":{"Satış":5800},"GBP":{"Satış":55}}', 200, headers: {'content-type': 'application/json; charset=utf-8'}),
      );
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
      for (final d in ['Devam', 'Devam', 'Şimdilik geç']) {
        await t.tap(find.text(d));
        await bekle(t);
      }
      if (!bos) {
        final k = ProviderScope.containerOf(t.element(find.byType(HarcliklarimApp)));
        await k.read(ulasilanlarProvider.notifier).ekle(VarlikTuru.nakit, dolu);
        await k.read(ulasilanlarProvider.notifier)
            .ekle(VarlikTuru.nakit, Hedef(esya: HedefEsya.cizim, fiyatTl: 80, cizim: cizim, ulasildi: DateTime(2026, 11, 2)));
      }
      t.platformDispatcher.textScaleFactorTestValue = yazi;
      Navigator.of(t.element(find.byType(KampEkrani))).push(VarlikDetayEkrani.rota(VarlikTuru.nakit));
      await bekle(t);
    }

    Finder liste() => find.descendant(of: find.byType(VarlikDetayEkrani), matching: find.byType(Scrollable)).first;

    testWidgets('boşken görünmez', (t) async {
      await ac(t, bos: true);
      await t.scrollUntilVisible(find.text('Hedef seç'), 200, scrollable: liste());
      expect(find.text('Ulaştıklarım'), findsNothing);
    });

    // HIG: Dynamic Type 3,1×'e kadar taşma yok (taşma test hatasıdır).
    for (final yazi in [1.0, 3.1]) {
      testWidgets('dolan hedefler ay adıyla, sayısız; dokununca açılır (yazı $yazi×)', (t) async {
        await ac(t, yazi: yazi);
        await t.scrollUntilVisible(find.text('Ulaştıklarım'), 200, scrollable: liste());
        await t.ensureVisible(find.text('Ulaştıklarım'));
        await bekle(t);
        expect(find.text('Ekim'), findsOneWidget);
        expect(find.text('Kasım'), findsOneWidget);
        expect(find.bySemanticsLabel('Top, Ekim 2026'), findsOneWidget);
        expect(find.bySemanticsLabel('Senin çizimin, Kasım 2026'), findsOneWidget);
        expect(find.textContaining('2 '), findsNothing, reason: 'sayı yok');
        await t.tap(find.bySemanticsLabel('Top, Ekim 2026'));
        await bekle(t);
        expect(find.text('Ulaştın: Ekim 2026'), findsOneWidget);
      });
    }
  });
}
