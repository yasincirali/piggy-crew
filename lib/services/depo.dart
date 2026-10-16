import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cocuk.dart';
import '../models/evre.dart';
import '../models/varlik.dart';

/// Yerel kalıcılık — tek dosya, tek sürüm anahtarı.
///
/// v1 "yerel-önce": tüm veri cihazda (`shared_preferences`), sunucu yok.
/// Anonim Supabase hesabı + yedekleme 2. kapıda, bayrakla gelir. Anahtar
/// adları SÜRÜMLÜDÜR (`_v1`): biçim değişirse eski anahtar okunup taşınır,
/// silinmez (sandık kuralı: kullanıcı verisi taşınır, sıfırlanmaz).
class Depo {
  Depo(this._sp);
  final SharedPreferences _sp;

  static Future<Depo> ac() async => Depo(await SharedPreferences.getInstance());

  static const _cocuk = 'cocuk_v1';
  static const _hareketler = 'hareketler_v1';
  static const _cikartmalar = 'cikartmalar_v1';
  static const _dersIlerleme = 'ders_ilerleme_v1';
  static const _sesAcik = 'ses_acik_v1';
  static const _sonRuh = 'son_ruh_v1';
  static const _evre = 'evre_v1';

  Cocuk? cocukOku() {
    final s = _sp.getString(_cocuk);
    if (s == null) return null;
    try {
      return Cocuk.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cocukYaz(Cocuk c) => _sp.setString(_cocuk, jsonEncode(c.toJson()));

  List<Hareket> hareketleriOku() {
    final s = _sp.getString(_hareketler);
    if (s == null) return const [];
    try {
      return (jsonDecode(s) as List).cast<Map<String, dynamic>>().map(Hareket.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> hareketleriYaz(List<Hareket> h) =>
      _sp.setString(_hareketler, jsonEncode(h.map((e) => e.toJson()).toList()));

  Set<String> cikartmalariOku() => (_sp.getStringList(_cikartmalar) ?? const []).toSet();
  Future<void> cikartmalariYaz(Set<String> s) => _sp.setStringList(_cikartmalar, s.toList());

  int dersIlerlemeOku() => _sp.getInt(_dersIlerleme) ?? 0;
  Future<void> dersIlerlemeYaz(int n) => _sp.setInt(_dersIlerleme, n);

  /// Sesler varsayılan açık. Cihaz tercihidir, kişisel veri değil: "veriyi
  /// sil" dokunmaz.
  bool sesAcikOku() => _sp.getBool(_sesAcik) ?? true;
  Future<void> sesAcikYaz(bool v) => _sp.setBool(_sesAcik, v);

  /// Son bilinen ruh hâlleri ("artıya geçti" sevinci bir kez oynasın diye).
  Map<VarlikTuru, Ruh> sonRuhOku() {
    final s = _sp.getString(_sonRuh);
    if (s == null) return const {};
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          if (VarlikTuru.values.any((t) => t.name == e.key) && Ruh.values.any((r) => r.name == e.value))
            VarlikTuru.values.byName(e.key): Ruh.values.byName(e.value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> sonRuhYaz(Map<VarlikTuru, Ruh> m) =>
      _sp.setString(_sonRuh, jsonEncode({for (final e in m.entries) e.key.name: e.value.name}));

  /// Ulaşılan en yüksek büyüme evreleri (evre geri gitmez; bkz. [Evre]).
  Map<VarlikTuru, Evre> evreOku() {
    final s = _sp.getString(_evre);
    if (s == null) return const {};
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          if (VarlikTuru.values.any((t) => t.name == e.key) && Evre.values.any((v) => v.name == e.value))
            VarlikTuru.values.byName(e.key): Evre.values.byName(e.value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> evreYaz(Map<VarlikTuru, Evre> m) =>
      _sp.setString(_evre, jsonEncode({for (final e in m.entries) e.key.name: e.value.name}));

  /// Tüm veriyi sil (veli köşesi). Fiyat önbelleği kalır, kişisel değil.
  Future<void> hepsiniSil() async {
    await _sp.remove(_cocuk);
    await _sp.remove(_hareketler);
    await _sp.remove(_cikartmalar);
    await _sp.remove(_dersIlerleme);
    await _sp.remove(_sonRuh);
    await _sp.remove(_evre);
  }

  /// PIN düz metin saklanmaz; tuzlu SHA-256 özeti saklanır. Tuz sabit ve
  /// uygulamaya özgü — hedef "kardeş tahmin edemesin", bankacılık değil.
  static String pinOzeti(String pin) =>
      sha256.convert(utf8.encode('harcliklarim:$pin')).toString();
}
