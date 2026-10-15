import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/varlik.dart';

/// Ses efektleri. Dosyalar `tool/sesler_uret.py` ile sentezlenir (lisanssız).
enum Ses { para, yum, yasasin, cikartma, tortu, zipzip, baykus, sincap }

extension SesKarakter on VarlikTuru {
  /// Dokununca çalan karakter sesi.
  Ses get ses => switch (this) {
        VarlikTuru.altin => Ses.tortu,
        VarlikTuru.dolar => Ses.zipzip,
        VarlikTuru.euro => Ses.baykus,
        VarlikTuru.nakit => Ses.sincap,
      };
}

/// Kararlar:
/// - iOS oturumu `ambient`: sessiz anahtarı açıksa ses çıkmaz, çocuğun
///   dinlediği müziği kesmez (Apple'ın oyun/efekt önerisi). Android'de ses
///   odağı istenmez, aynı davranış.
/// - Her ses için ayrı, önceden yüklenmiş düşük gecikmeli oyuncu; aynı ses
///   üst üste gelirse baştan başlar (para yağmurunda birikme yok).
/// - Hata sessizce yutulur: ses süsdür, uygulamayı asla durdurmaz.
/// - Testte (`FLUTTER_TEST`) hiç kanal açılmaz.
class SesServisi {
  SesServisi({required this.acik});

  bool acik;
  final _oyuncular = <Ses, AudioPlayer>{};
  bool _hazir = false;

  static bool get _testte => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _hazirla() async {
    if (_hazir || _testte) return;
    _hazir = true;
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      for (final s in Ses.values) {
        final o = AudioPlayer(playerId: 'ses_${s.name}');
        await o.setPlayerMode(PlayerMode.lowLatency);
        await o.setReleaseMode(ReleaseMode.stop);
        await o.setSource(AssetSource('sesler/${s.name}.wav'));
        _oyuncular[s] = o;
      }
    } catch (_) {
      // Ses yoksa uygulama sessiz devam eder.
    }
  }

  Future<void> cal(Ses s) async {
    if (!acik || _testte) return;
    try {
      await _hazirla();
      final o = _oyuncular[s];
      if (o == null) return;
      await o.stop();
      await o.resume();
    } catch (_) {}
  }
}
