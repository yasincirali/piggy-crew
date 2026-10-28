import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cocuk.dart';
import '../models/evre.dart';
import '../models/hedef.dart';
import '../models/plan.dart';
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
  static const _ogretilen = 'ogretilen_dersler_v1';
  static const _sesAcik = 'ses_acik_v1';
  static const _titresimAcik = 'titresim_acik_v1';
  static const _karakter3d = 'karakter_3d_v1';
  static const _sonAcilis = 'son_acilis_v1';
  static const _sonRuh = 'son_ruh_v1';
  static const _evre = 'evre_v1';
  static const _sonGorulme = 'son_gorulme_v1';
  static const _sonDonus = 'son_donus_v1';
  static const _odun = 'odun_v1';
  static const _ikilem = 'ikilem_gosterildi_v1';
  static const _hedefler = 'hedefler_v1';
  static const _planlar = 'planlar_v1';

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

  /// Çocuğun karakterlere öğrettiği derslerin id'leri. null: hiç yazılmadı
  /// (bu özellikten önceki kurulum; ilk okuyan ders ilerlemesinden tohumlar).
  Set<String>? ogretilenOku() => _sp.getStringList(_ogretilen)?.toSet();
  Future<void> ogretilenYaz(Set<String> s) => _sp.setStringList(_ogretilen, s.toList());

  /// Sesler varsayılan açık. Cihaz tercihidir, kişisel veri değil: "veriyi
  /// sil" dokunmaz.
  bool sesAcikOku() => _sp.getBool(_sesAcik) ?? true;
  Future<void> sesAcikYaz(bool v) => _sp.setBool(_sesAcik, v);

  /// Titreşim varsayılan açık; sesle aynı türden cihaz tercihi.
  bool titresimAcikOku() => _sp.getBool(_titresimAcik) ?? true;
  Future<void> titresimAcikYaz(bool v) => _sp.setBool(_titresimAcik, v);

  /// 3D karakterler varsayılan açık (yasin 2026-10-26, önceden render 3D).
  /// Anahtar yoksa 3D; "Klasik" seçmiş olan (false yazılı) 2D'de kalır.
  bool karakter3dOku() => _sp.getBool(_karakter3d) ?? true;
  Future<void> karakter3dYaz(bool v) => _sp.setBool(_karakter3d, v);

  /// Açılış sahnesinin en son tam oynadığı gün (yyyy-aa-gg, yerel saat).
  /// Aynı gün sonraki açılışlarda kısa sürüm oynar. Cihaz tercihi gibi:
  /// "veriyi sil" dokunmaz.
  String? sonAcilisOku() => _sp.getString(_sonAcilis);
  Future<void> sonAcilisYaz(String gun) => _sp.setString(_sonAcilis, gun);

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

  /// Ulaşılan en yüksek odun sayısı (odun eksilmez; bkz. [Odun]).
  int odunOku() => _sp.getInt(_odun) ?? 0;
  Future<void> odunYaz(int n) => _sp.setInt(_odun, n);

  /// Geri dönüş karşılaması için iki an (bkz. `donusKarsilamasiGerekli`):
  /// uygulamanın en son ön planda olduğu ve karşılamanın en son oynadığı an.
  /// Milisaniye olarak; bozuk değer "hiç" sayılır (karşılama oynamaz, zarar yok).
  DateTime? sonGorulmeOku() => _anOku(_sonGorulme);
  Future<void> sonGorulmeYaz(DateTime t) => _sp.setInt(_sonGorulme, t.millisecondsSinceEpoch);
  DateTime? sonDonusOku() => _anOku(_sonDonus);
  Future<void> sonDonusYaz(DateTime t) => _sp.setInt(_sonDonus, t.millisecondsSinceEpoch);

  /// Sincap'ın ikilemi ilk kumbaradan almadan sonra bir kez gösterilir;
  /// sayaç değil, yalnız "gösterildi" bilgisi (Ar-Ge raporu 2026-10-23 11:07).
  bool ikilemGosterildiOku() => _sp.getBool(_ikilem) ?? false;
  Future<void> ikilemGosterildiYaz() => _sp.setBool(_ikilem, true);

  /// Karakter başına bir hedef (bkz. [Hedef]). Bozuk kayıt atlanır.
  Map<VarlikTuru, Hedef> hedefleriOku() {
    final s = _sp.getString(_hedefler);
    if (s == null) return const {};
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          if (VarlikTuru.values.any((t) => t.name == e.key) && e.value is Map<String, dynamic>)
            VarlikTuru.values.byName(e.key): ?Hedef.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> hedefleriYaz(Map<VarlikTuru, Hedef> m) =>
      _sp.setString(_hedefler, jsonEncode({for (final e in m.entries) e.key.name: e.value.toJson()}));

  /// Karakter başına bir plan (bkz. [PlanSablon]). Bilinmeyen kayıt atlanır.
  Map<VarlikTuru, PlanSablon> planlariOku() {
    final s = _sp.getString(_planlar);
    if (s == null) return const {};
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          if (VarlikTuru.values.any((t) => t.name == e.key) && PlanSablon.values.any((p) => p.name == e.value))
            VarlikTuru.values.byName(e.key): PlanSablon.values.byName(e.value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> planlariYaz(Map<VarlikTuru, PlanSablon> m) =>
      _sp.setString(_planlar, jsonEncode({for (final e in m.entries) e.key.name: e.value.name}));

  DateTime? _anOku(String anahtar) {
    final v = _sp.get(anahtar);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  /// Tüm veriyi sil (veli köşesi). Fiyat önbelleği kalır, kişisel değil.
  Future<void> hepsiniSil() async {
    await _sp.remove(_cocuk);
    await _sp.remove(_hareketler);
    await _sp.remove(_cikartmalar);
    await _sp.remove(_dersIlerleme);
    await _sp.remove(_ogretilen);
    await _sp.remove(_sonRuh);
    await _sp.remove(_evre);
    await _sp.remove(_odun);
    await _sp.remove(_ikilem);
    await _sp.remove(_hedefler);
    await _sp.remove(_planlar);
    // Yeni çocuk "geri dönmüş" sayılmasın: kullanım anları da gider.
    await _sp.remove(_sonGorulme);
    await _sp.remove(_sonDonus);
  }

  /// PIN düz metin saklanmaz; tuzlu SHA-256 özeti saklanır. Tuz sabit ve
  /// uygulamaya özgü — hedef "kardeş tahmin edemesin", bankacılık değil.
  static String pinOzeti(String pin) =>
      sha256.convert(utf8.encode('harcliklarim:$pin')).toString();
}
