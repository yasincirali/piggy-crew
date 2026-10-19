import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcliklarim/models/varlik.dart';
import 'package:harcliklarim/providers/saglayicilar.dart';
import 'package:harcliklarim/services/depo.dart';
import 'package:harcliklarim/widgets/acilis_katmani.dart';
import 'package:harcliklarim/widgets/karakter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Açılış sahnesi (hazine sandığı, para yuvası; 2026-10-19):
/// - zaman çizelgesi: para yuvaya düşer, sonra kapak açılır, içtekiler belirir,
///   dalışta sahne söner;
/// - dokununca hemen kapanır, alttaki uygulama erişilebilir kalır;
/// - VoiceOver açıkken hiç oynamaz; hareketi azalt kısa ve dalışsız;
/// - aynı gün ikinci açılış kısa sürüm.
void main() {
  test('sandık kareleri ve karakter kareleri var', () {
    for (final k in ['sandik_arka', 'sandik_on']) {
      expect(File('assets/karakter3d/acilis/$k.webp').existsSync(), isTrue, reason: k);
    }
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/karakter3d/acilis/'));
  });

  test('zaman çizelgesi: önce para, sonra kapak, sonra takım, sonra dalış', () {
    // Para Sincap'ın elinde başlar, yuvaya düşmeden kapak kapalı.
    expect(const AcilisAni(0).para.gorunur, isTrue);
    expect(const AcilisAni(.9).kapak, 0);
    expect(const AcilisAni(1.0).para.gorunur, isFalse);
    // Kapak açılır ve 1'e oturur (taşma 1,1).
    expect(const AcilisAni(1.42).kapak, closeTo(1.1, .01));
    expect(const AcilisAni(1.8).kapak, closeTo(1.0, .01));
    // İçtekiler kapak açılmadan görünmez, sonra yerine oturur.
    expect(const AcilisAni(1.0).karakter(VarlikTuru.dolar).opak, 0);
    expect(const AcilisAni(2.0).karakter(VarlikTuru.dolar).ayak.dy, closeTo(985, .5));
    // Yandakiler baştan görünür (para ve hayvanlar net).
    expect(const AcilisAni(0).karakter(VarlikTuru.altin).opak, 1);
    expect(const AcilisAni(0).karakter(VarlikTuru.nakit).opak, 1);
    // Sevinç anında hepsi sevinçli.
    for (final t in VarlikTuru.values) {
      expect(const AcilisAni(1.9).karakter(t).yuz, AtlasIfade.sevinc, reason: t.name);
    }
    // Dalış: parlama, sahne söner.
    expect(const AcilisAni(AcilisAni.dalis).parlama, 0);
    expect(const AcilisAni(AcilisAni.dalis + .6).parlama, 1);
    expect(const AcilisAni(AcilisAni.toplam).sahne, 0);
    expect(const AcilisAni(AcilisAni.toplam).parlama, 0);
  });

  Future<Depo> depo([Map<String, Object> d = const {}]) async {
    SharedPreferences.setMockInitialValues(d);
    return Depo.ac();
  }

  Widget uygulama(Depo d, {MediaQueryData mq = const MediaQueryData(size: Size(393, 852))}) => ProviderScope(
        overrides: [depoProvider.overrideWithValue(d)],
        child: MediaQuery(
          data: mq,
          child: MaterialApp(
            home: AcilisKatmani(
              oynasin: true,
              child: Scaffold(body: Center(child: ElevatedButton(onPressed: () {}, child: const Text('ana ekran')))),
            ),
          ),
        ),
      );

  testWidgets('tam oynar, bitince kalkar; gün kaydedilir', (t) async {
    final d = await depo();
    await t.pumpWidget(uygulama(d));
    expect(find.byType(AcilisSahnesi), findsOneWidget);
    expect(d.sonAcilisOku(), acilisGunu(DateTime.now()));
    await t.pump(const Duration(milliseconds: 3500));
    await t.pump();
    expect(find.byType(AcilisSahnesi), findsNothing);
    expect(find.text('ana ekran'), findsOneWidget);
  });

  testWidgets('dokununca hemen kapanır', (t) async {
    await t.pumpWidget(uygulama(await depo()));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(AcilisSahnesi));
    await t.pump();
    await t.pump(const Duration(milliseconds: 250));
    await t.pump();
    expect(find.byType(AcilisSahnesi), findsNothing);
  });

  testWidgets('aynı gün ikinci açılış kısa', (t) async {
    await t.pumpWidget(uygulama(await depo({'son_acilis_v1': acilisGunu(DateTime.now())})));
    final s = t.widget<AcilisSahnesi>(find.byType(AcilisSahnesi));
    expect(s.kisa, isTrue);
    // Kısa sürüm para atışını atlar: tam sürümden en az 0,9 sn önce biter.
    await t.pump(Duration(milliseconds: ((AcilisAni.toplam - AcilisAni.kisaBaslangic) * 1000).round() + 50));
    await t.pump();
    expect(find.byType(AcilisSahnesi), findsNothing);
  });

  testWidgets('VoiceOver açıkken oynamaz', (t) async {
    await t.pumpWidget(uygulama(await depo(), mq: const MediaQueryData(size: Size(393, 852), accessibleNavigation: true)));
    await t.pump();
    await t.pump();
    expect(find.byType(AcilisSahnesi), findsNothing);
  });

  testWidgets('hareketi azalt: dalışsız, 1,7 sn', (t) async {
    await t.pumpWidget(uygulama(await depo(), mq: const MediaQueryData(size: Size(393, 852), disableAnimations: true)));
    await t.pump(const Duration(milliseconds: 1750));
    await t.pump();
    expect(find.byType(AcilisSahnesi), findsNothing);
  });

  testWidgets('testte varsayılan olarak oynamaz (var olan testler etkilenmesin)', (t) async {
    final d = await depo();
    await t.pumpWidget(ProviderScope(
      overrides: [depoProvider.overrideWithValue(d)],
      child: const MaterialApp(home: AcilisKatmani(child: Text('x'))),
    ));
    expect(find.byType(AcilisSahnesi), findsNothing);
    expect(d.sonAcilisOku(), isNull);
  });
}
