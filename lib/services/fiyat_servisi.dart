import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/varlik.dart';

/// Güncel fiyatlar. Kaynak sandık ile AYNI: finans.truncgil.com v4
/// (yurt içi altın/döviz kotasyonu). Sözleşme sandık `FiyatKaynagi` ile aynı:
///  1. hangi anahtarın hangi varlığı beslediğine yalnız `VarlikTuru` karar verir;
///  2. uydurma sayı yasak — kaynak düşerse son bilinen fiyat ve zaman damgası
///     gösterilir, sabit yazılmaz; hiç fiyat yoksa değer gösterilmez.
///
/// Sunucu gerektirmez: ücretsiz bütçe + çocuk verisi ağa çıkmaz (yalnız
/// fiyat iner). 2. kapıda sandık Frankfurt Supabase'inden salt-okunur RPC
/// seçeneği değerlendirilir; bu sınıfın imzası değişmez.
@immutable
class Fiyatlar {
  const Fiyatlar({required this.degerler, required this.zaman, required this.taze});

  /// Anahtar: truncgil anahtarı (GRA, USD, EUR, GBP), değer TRY cinsinden.
  final Map<String, double> degerler;
  final DateTime zaman;

  /// Bu çalıştırmada ağdan geldi mi (false → önbellek).
  final bool taze;

  /// Ev para birimine çevrilmiş birim fiyat. Kaynak TRY kote eder; ev birimi
  /// TRY değilse o birimin TRY kuruna bölünür. Kur yoksa null — uydurma yok.
  double? fiyat(VarlikTuru t, ParaBirimi ev) {
    if (t.nakitMi) return 1;
    final tryFiyat = degerler[t.fiyatAnahtari];
    if (tryFiyat == null) return null;
    final kur = evKuru(ev);
    return kur == null ? null : tryFiyat / kur;
  }

  /// 1 ev birimi = ? TRY. TRY için 1.
  double? evKuru(ParaBirimi ev) => ev == ParaBirimi.tryy ? 1 : degerler[ev.kod];

  static final bos = Fiyatlar(degerler: const {}, zaman: DateTime.fromMillisecondsSinceEpoch(0), taze: false);
  bool get yok => degerler.isEmpty;
}

class FiyatServisi {
  FiyatServisi({http.Client? istemci, SharedPreferences? tercihler})
      : _http = istemci ?? http.Client(),
        _tercihler = tercihler;

  final http.Client _http;
  SharedPreferences? _tercihler;

  static const _onbellekAnahtari = 'fiyat_onbellek_v1';
  static final _uri = Uri.parse('https://finans.truncgil.com/v4/today.json');

  Future<SharedPreferences> get _sp async => _tercihler ??= await SharedPreferences.getInstance();

  /// Önbellekten (anında) — açılışta ekran boş kalmasın.
  Future<Fiyatlar> onbellek() async {
    final ham = (await _sp).getString(_onbellekAnahtari);
    if (ham == null) return Fiyatlar.bos;
    try {
      final j = jsonDecode(ham) as Map<String, dynamic>;
      return Fiyatlar(
        degerler: (j['d'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
        zaman: DateTime.parse(j['z'] as String),
        taze: false,
      );
    } catch (_) {
      return Fiyatlar.bos;
    }
  }

  /// Ağdan çek, başarılıysa önbelleğe yaz. Hata → null (çağıran önbelleği kullanır).
  Future<Fiyatlar?> cek() async {
    try {
      final yanit = await _http.get(_uri).timeout(const Duration(seconds: 8));
      if (yanit.statusCode != 200) return null;
      final degerler = ayristir(utf8.decode(yanit.bodyBytes, allowMalformed: true));
      if (degerler.isEmpty) return null;
      final f = Fiyatlar(degerler: degerler, zaman: DateTime.now(), taze: true);
      await (await _sp).setString(
        _onbellekAnahtari,
        jsonEncode({'d': f.degerler, 'z': f.zaman.toIso8601String()}),
      );
      return f;
    } catch (_) {
      return null;
    }
  }

  /// Okunan anahtarlar: varlıklar + ev para birimleri (çevrim için).
  static const anahtarlar = ['GRA', 'USD', 'EUR', 'GBP'];

  /// truncgil v4 gövdesi: düz sözlük `{"USD":{"Alış":..,"Satış":..},...}`.
  /// Çocuk "alır", o yüzden SATIŞ fiyatı esas alınır (kuyumcu/banka satış);
  /// yoksa alış. Sayı olmayan/0 değer atlanır.
  @visibleForTesting
  static Map<String, double> ayristir(String govde) {
    final j = jsonDecode(govde);
    if (j is! Map<String, dynamic>) return {};
    final sonuc = <String, double>{};
    for (final k in anahtarlar) {
      final e = j[k];
      if (e is! Map) continue;
      final ham = e['Satış'] ?? e['Selling'] ?? e['Alış'] ?? e['Buying'];
      final v = _sayi(ham);
      if (v != null && v > 0) sonuc[k] = v;
    }
    return sonuc;
  }

  static double? _sayi(dynamic ham) {
    if (ham is num) return ham.toDouble().isFinite ? ham.toDouble() : null;
    if (ham is String) return double.tryParse(ham.replaceAll('.', '').replaceAll(',', '.'));
    return null;
  }
}
