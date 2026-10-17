import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/varlik.dart';

/// Ses efektleri. Gerçek kayıtlar (Kenney, Freesound, OpenGameArt; hepsi
/// CC0), kaynak ve düzenleme `assets/sesler/LISANS.md`'de. Eskiden numpy ile
/// sentezleniyordu; yapay duyuldu (yasin 2026-10-15), kaldırıldı. Yeni ses
/// eklerken yalnız CC0/kamu malı al: Kids kategorisinde atıf ekranı yok.
///
/// Besleme ritüelinin ince sesleri (2026-10-17, "efektleri profesyonel"):
/// her an kendi sesini taşır (avuçtan alma, atma, karo şıngırtısı, ısırık,
/// kanat, sekme…), seviyeleri birbirine göre dengeli ve kısık; ana vurgu
/// yine `yasasin`. Tekrarlanan ses (ısırık) birkaç kayıt arasında döner:
/// aynı kaydın art arda çalması makineli tüfek gibi duyulur.
enum Ses {
  para,
  yum,
  yasasin,
  cikartma,
  tortu,
  zipzip,
  baykus,
  sincap,
  belir,
  al,
  firlat,
  don,
  karo,
  parilti,
  kapma,
  isirik,
  yildiz,
  kanat,
  sek,
  plop,
  vin,
}

/// Bir sesin kayıtları (çoğunda tek). Isırık üç ayrı ısırıktan döner.
List<String> sesDosyalari(Ses s) => switch (s) {
      Ses.isirik => const ['isirik_1', 'isirik_2', 'isirik_3'],
      _ => [s.name],
    };

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
  final _oyuncular = <Ses, List<AudioPlayer>>{};
  final _sira = <Ses, int>{};
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
        final liste = <AudioPlayer>[];
        for (final d in sesDosyalari(s)) {
          final o = AudioPlayer(playerId: 'ses_$d');
          await o.setPlayerMode(PlayerMode.lowLatency);
          await o.setReleaseMode(ReleaseMode.stop);
          await o.setSource(AssetSource('sesler/$d.wav'));
          liste.add(o);
        }
        _oyuncular[s] = liste;
      }
    } catch (_) {
      // Ses yoksa uygulama sessiz devam eder.
    }
  }

  Future<void> cal(Ses s) async {
    if (!acik || _testte) return;
    try {
      await _hazirla();
      final liste = _oyuncular[s];
      if (liste == null || liste.isEmpty) return;
      final i = (_sira[s] ?? 0) % liste.length;
      _sira[s] = i + 1;
      final o = liste[i];
      await o.stop();
      await o.resume();
    } catch (_) {}
  }
}
