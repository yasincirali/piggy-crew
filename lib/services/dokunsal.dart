import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/varlik.dart';

/// Dokunsal geri bildirim (titreşim) sözlüğü. Her an kendi desenini taşır;
/// ekranlar `HapticFeedback.*` çağırmaz, anın adını söyler.
///
/// Neden (yasin 2026-10-17, "titreşim ve efektleri profesyonel hâle
/// getirelim"): eskiden her yerde üç hazır darbe vardı (hafif/orta/ağır) ve
/// karakterler arasında hiç fark yoktu. Artık iPhone'da Core Haptics ile her
/// an kendi dokusunu taşır: karo "tık" keskin, kanat çırpışı yumuşak ve
/// geniş, ısırık minik, sevinç jingle'ın notalarıyla aynı anda yükselir.
/// Ses ile titreşim aynı zaman çizelgesinden çalar (bkz. `yemeIpuclari`).
///
/// Kararlar:
/// - Tek kaynak: desenler burada, Swift tarafı yalnız oynatıcı. Yeni an
///   eklemek = buraya bir satır (Xcode'a dokunmadan).
/// - Ölçü: Apple'ın dokunsal tasarım önerisi; kısa ve az. Hiçbir desen
///   0,5 saniyeyi geçmez, şiddet 1'e çıkmaz (çocuğun elinde rahatsız
///   etmesin). `dokunsal_test` bunu kilitler.
/// - Android'de Core Haptics yok: her desenin ilk/en güçlü vuruşu sistemin
///   hazır darbesine eşlenir (v1 yalnız iOS'ta yayında).
/// - Ayarlar'daki "Titreşim" kapalıysa hiçbir şey çalmaz. Hata sessizce
///   yutulur: titreşim süsdür, uygulamayı durdurmaz.
enum Dokunus {
  /// Düğme ve kart dokunuşu (ortak düğmeler).
  dokunma,

  /// Seçim değişti (segment, sekme).
  secim,

  /// Bir işlem onaylandı ("Ver").
  onay,

  /// Veli köşesi PIN'i yanlış (yalnız veli görür).
  hata,

  /// Avuçtaki yiyecek parmakla tutuldu.
  tutma,

  /// Sürüklenen yiyecek karakterin yakalama alanına girdi ("mıknatıs" çentiği).
  yaklasma,

  /// Yiyecek avuca geri döndü.
  avucaDonus,

  /// Yiyecek karaktere atıldı.
  firlatma,

  /// Karakter yiyeceği yakaladı (Zıpzıp, Sincap).
  yakalama,

  /// Tortu: çini karo kabuğa oturdu.
  karo,

  /// Tortu: kabukta ışık dolaşıyor (uzun, çok yumuşak kabarma).
  isilti,

  /// Zıpzıp: yere konuş / Tortu: keyifli "bloop".
  konma,

  /// Zıpzıp: kemirme ısırığı.
  isirik,

  /// Baykuş: yıldız gözlerine girdi (inen üç pırıltı).
  pirilti,

  /// Baykuş: kanat çırpışı.
  kanat,

  /// Sincap: palamut para sekti.
  sekme,

  /// Sincap: yanaklar şişti.
  sisme,

  /// Sincap: kendi etrafında döndü.
  donme,

  /// Ortak sevinç (yaşasın jingle'ının dört notasıyla).
  sevinc,

  /// Yeni çıkartma / büyüme ışığı.
  cikartma,

  /// Büyüme: yükselen kabarma.
  buyume,

  /// Karaktere dokunma: her birinin sesine göre.
  tortuSesi,
  zipzipSesi,
  baykusSesi,
  sincapSesi,
}

extension KarakterDokunusu on VarlikTuru {
  /// Karaktere dokununca sesiyle birlikte çalan titreşim (sesin vuruşlarına
  /// göre: Tortu tek kalın "bloop", Zıpzıp sönen yay, Baykuş iki yumuşak
  /// "hu", Sincap iki keskin "cik").
  Dokunus get sesDokunusu => switch (this) {
        VarlikTuru.altin => Dokunus.tortuSesi,
        VarlikTuru.dolar => Dokunus.zipzipSesi,
        VarlikTuru.euro => Dokunus.baykusSesi,
        VarlikTuru.nakit => Dokunus.sincapSesi,
      };
}

/// Desendeki tek vuruş (an) ya da sürekli titreşim.
/// [zaman] ve [sure] saniye; [siddet] ve [keskinlik] 0–1 (Core Haptics
/// `hapticIntensity`, `hapticSharpness`). [sure] > 0 ise sürekli titreşimdir;
/// [son] verilirse şiddet sürenin sonunda [son]'a kayar (kabarma/sönme).
@immutable
class Vurus {
  const Vurus(this.zaman, this.siddet, this.keskinlik, {this.sure = 0, this.son});

  final double zaman, siddet, keskinlik, sure;
  final double? son;

  bool get surekli => sure > 0;

  Map<String, Object> get harita => {
        'z': zaman,
        's': siddet,
        'k': keskinlik,
        'd': sure,
        'e': ?son,
      };
}

/// Desenler. Zamanlar sahnelerin ve seslerin gerçek anlarından ölçüldü
/// (ör. sevinç: `yasasin.wav` nota başları 30/140/260/370 ms).
const Map<Dokunus, List<Vurus>> dokunusDesenleri = {
  Dokunus.dokunma: [Vurus(0, .45, .55)],
  Dokunus.secim: [Vurus(0, .3, .85)],
  Dokunus.onay: [Vurus(0, .6, .5), Vurus(.07, .3, .35)],
  Dokunus.hata: [Vurus(0, .55, .7), Vurus(.1, .55, .7)],
  Dokunus.tutma: [Vurus(0, .4, .75)],
  Dokunus.yaklasma: [Vurus(0, .55, .95)],
  Dokunus.avucaDonus: [Vurus(0, .3, .3)],
  Dokunus.firlatma: [Vurus(0, .25, .4, sure: .12, son: 0)],
  Dokunus.yakalama: [Vurus(0, .7, .9), Vurus(.04, .25, .4, sure: .08, son: 0)],
  Dokunus.karo: [Vurus(0, .75, .85), Vurus(.07, .3, .7)],
  Dokunus.isilti: [Vurus(0, .02, .15, sure: .2, son: .3), Vurus(.2, .3, .15, sure: .25, son: 0)],
  Dokunus.konma: [Vurus(0, .45, .15)],
  Dokunus.isirik: [Vurus(0, .35, .7)],
  Dokunus.pirilti: [Vurus(0, .5, .95), Vurus(.06, .35, .95), Vurus(.12, .2, .95)],
  Dokunus.kanat: [Vurus(0, .5, .05, sure: .09, son: .1)],
  Dokunus.sekme: [Vurus(0, .25, .6)],
  Dokunus.sisme: [Vurus(0, .15, .3, sure: .12, son: .5)],
  Dokunus.donme: [Vurus(0, .1, .5, sure: .3, son: .3), Vurus(.3, .3, .5, sure: .1, son: 0)],
  Dokunus.sevinc: [Vurus(.03, .45, .35), Vurus(.14, .55, .45), Vurus(.26, .7, .55), Vurus(.37, .9, .6)],
  Dokunus.cikartma: [Vurus(0, .4, .7), Vurus(.08, .5, .75), Vurus(.16, .7, .8)],
  Dokunus.buyume: [Vurus(0, .1, .3, sure: .4, son: .6)],
  Dokunus.tortuSesi: [Vurus(0, .55, .1)],
  Dokunus.zipzipSesi: [Vurus(0, .5, .5), Vurus(.12, .3, .5), Vurus(.22, .15, .5)],
  Dokunus.baykusSesi: [Vurus(.03, .4, .05, sure: .08, son: .1), Vurus(.36, .4, .05, sure: .1, son: .1)],
  Dokunus.sincapSesi: [Vurus(.03, .35, .9), Vurus(.2, .35, .9)],
};

/// Titreşim oynatıcısı. iOS'ta yerel `harcliklarim/dokunsal` kanalı (Core
/// Haptics, bkz. `ios/Runner/AppDelegate.swift`), Android'de hazır darbeler.
class DokunsalServisi {
  DokunsalServisi({required bool acik, MethodChannel? kanal, @visibleForTesting this.kaydedici})
      : _acik = acik,
        _kanal = kanal ?? const MethodChannel('harcliklarim/dokunsal');

  final MethodChannel _kanal;
  bool _acik;
  bool _kayitli = false;
  bool _yerelYok = false;
  bool _surekliAcik = false;

  /// Testte çalınan anları toplar (kanal açılmaz).
  final void Function(Dokunus)? kaydedici;

  bool get acik => _acik;
  set acik(bool v) {
    _acik = v;
    if (!v) surekliDur();
  }

  static bool get _testte => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  static bool get _ios => !kIsWeb && Platform.isIOS;

  Future<void> _kaydet() async {
    if (_kayitli) return;
    _kayitli = true;
    await _kanal.invokeMethod<void>('kaydet', {
      for (final e in dokunusDesenleri.entries) e.key.name: [for (final v in e.value) v.harita],
    });
  }

  Future<void> cal(Dokunus d) async {
    if (!_acik) return;
    kaydedici?.call(d);
    if (_testte || kaydedici != null) return;
    if (!_ios || _yerelYok) return _android(d);
    try {
      await _kaydet();
      await _kanal.invokeMethod<void>('cal', d.name);
    } on MissingPluginException {
      _yerelYok = true;
      await _android(d);
    } catch (_) {}
  }

  Future<void> _android(Dokunus d) async {
    // En güçlü vuruş hazır darbeye: keskin ve hafif → seçim tıkı.
    final desen = dokunusDesenleri[d]!;
    final v = desen.reduce((a, b) => b.siddet > a.siddet ? b : a);
    try {
      if (v.siddet < .35 && v.keskinlik > .6) {
        await HapticFeedback.selectionClick();
      } else if (v.siddet < .5) {
        await HapticFeedback.lightImpact();
      } else if (v.siddet < .8) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Sürekli doku (yalnız iOS): yiyecek sürüklenirken karaktere yaklaştıkça
  /// artan hafif bir "mıknatıs". [siddet] 0–1.
  Future<void> surekliBasla() async {
    if (!_acik || _testte || kaydedici != null || !_ios || _yerelYok || _surekliAcik) return;
    _surekliAcik = true;
    try {
      await _kaydet();
      await _kanal.invokeMethod<void>('surekliBasla');
    } catch (_) {
      _surekliAcik = false;
    }
  }

  Future<void> surekliAyarla(double siddet, double keskinlik) async {
    if (!_surekliAcik) return;
    try {
      await _kanal.invokeMethod<void>('surekliAyarla', {'s': siddet.clamp(0.0, 1.0), 'k': keskinlik.clamp(0.0, 1.0)});
    } catch (_) {}
  }

  Future<void> surekliDur() async {
    if (!_surekliAcik) return;
    _surekliAcik = false;
    try {
      await _kanal.invokeMethod<void>('surekliDur');
    } catch (_) {}
  }
}
