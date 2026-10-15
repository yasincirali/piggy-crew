import 'package:flutter/foundation.dart';
import '../theme/dunya.dart';
import 'varlik.dart';

/// Yaş modu: 7–10 kısa cümle, büyük sayı, az kavram; 11–15 yüzde ve kavram
/// adları görünür. Aynı ekran, farklı söz dizimi (prototipteki `.k/.b`).
enum YasModu {
  kucuk('kucuk', '7–10'),
  buyuk('buyuk', '11–15');

  const YasModu(this.anahtar, this.etiket);
  final String anahtar;
  final String etiket;
  static YasModu fromAnahtar(String? a) =>
      YasModu.values.firstWhere((y) => y.anahtar == a, orElse: () => YasModu.kucuk);
}

/// Cihaz bazlı profil — e-posta yok, şifre yok (karar: kayıt zorunluluğu olmaz).
/// Veli PIN'i 4 hane, cihazda SHA-256 özeti saklanır (bkz. `Depo`).
@immutable
class Cocuk {
  const Cocuk({
    required this.ad,
    required this.yas,
    required this.dunya,
    required this.pinOzeti,
    required this.olusturma,
    this.para = ParaBirimi.tryy,
    this.dil,
  });

  final String ad;
  final YasModu yas;
  final Dunya dunya;
  final String? pinOzeti;
  final DateTime olusturma;
  final ParaBirimi para;

  /// Uygulama dili (dil kodu, ör. 'tr', 'de'); null → cihaz dili, o da
  /// desteklenmiyorsa İngilizce (`dilCoz`).
  final String? dil;

  bool get veliKilidiVar => pinOzeti != null && pinOzeti!.isNotEmpty;

  Cocuk copyWith({String? ad, YasModu? yas, Dunya? dunya, String? pinOzeti, ParaBirimi? para, String? dil}) =>
      Cocuk(
        ad: ad ?? this.ad,
        yas: yas ?? this.yas,
        dunya: dunya ?? this.dunya,
        pinOzeti: pinOzeti ?? this.pinOzeti,
        olusturma: olusturma,
        para: para ?? this.para,
        dil: dil ?? this.dil,
      );

  Map<String, dynamic> toJson() => {
        'ad': ad,
        'yas': yas.anahtar,
        'dunya': dunya.anahtar,
        'pinOzeti': pinOzeti,
        'olusturma': olusturma.toIso8601String(),
        'para': para.kod,
        'dil': dil,
      };

  static Cocuk fromJson(Map<String, dynamic> j) => Cocuk(
        ad: j['ad'] as String,
        yas: YasModu.fromAnahtar(j['yas'] as String?),
        dunya: Dunya.fromAnahtar(j['dunya'] as String?),
        pinOzeti: j['pinOzeti'] as String?,
        olusturma: DateTime.tryParse(j['olusturma'] as String? ?? '') ?? DateTime.now(),
        para: ParaBirimi.fromKod(j['para'] as String?),
        dil: j['dil'] as String?,
      );
}
