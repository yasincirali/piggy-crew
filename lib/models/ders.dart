import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cocuk.dart';
import '../utils/bicim.dart';
import 'varlik.dart';

/// Dersler `assets/dersler/<dil>.json`'dan gelir — metin kodda değil, içerikte.
/// Her ders: kavram, iki yaş modu için ayrı metin, tek soru, üç seçenek.
///
/// Global uygulama: dil dosyası yoksa İngilizce. Tutarlar metne yazılmaz,
/// `{p:50}` yer tutucusuyla gelir ve çocuğun para biriminde gösterilir
/// ([paraYerlestir]); eskiden metin "50 ₺" sabitti, İngilizce çocuk da ₺ görüyordu.
@immutable
class Ders {
  const Ders({
    required this.id,
    required this.kavram,
    required this.baslik,
    required this.metinKucuk,
    required this.metinBuyuk,
    required this.soru,
    required this.secenekler,
    required this.dogru,
    required this.karakter,
    this.hatirla,
    this.etkilesim,
  });

  final String id, kavram, baslik, metinKucuk, metinBuyuk, soru;
  final List<String> secenekler;
  final int dogru;
  final VarlikTuru? karakter;

  /// Dersler bitince sorulan "Hatırlıyor musun?" sorusu (Ar-Ge 31 Eki, yasin
  /// "yap"): aynı kavram, yeni durum. Eski içerikte yoksa ders atlanır.
  final HatirlaSorusu? hatirla;

  /// "Dokunarak dene" kartı (Ar-Ge 1 Kas 11:07 #1, yasin "yap"): metnin altında
  /// elle oynanan tek an. Önce yalnız enflasyon (`dondurma`); TestFlight
  /// ailesinden tepki gelirse birikim ve çeşitlendirme. Bilinmeyen değer
  /// (ileriki içerik) yok sayılır, ders kart olmadan açılır. Kart ödül değildir:
  /// soru yine sonra gelir, yanlış yapılamaz, sayaç yok.
  final String? etkilesim;

  String metin(YasModu y) => y == YasModu.kucuk ? metinKucuk : metinBuyuk;

  /// Desteklenen ders dilleri; her biri için `assets/dersler/<dil>.json` var.
  static const diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  /// `{p:50}` → çocuğun para biriminde "50 ₺" / "$50" / "50 €".
  static String paraYerlestir(String s, ParaBirimi p) =>
      s.replaceAllMapped(RegExp(r'\{p:(\d+)\}'), (m) => fmtPara(double.parse(m[1]!), p));

  static Ders fromJson(Map<String, dynamic> j) => Ders(
        id: j['id'] as String,
        kavram: j['kavram'] as String,
        baslik: j['baslik'] as String,
        metinKucuk: j['metin_k'] as String,
        metinBuyuk: j['metin_b'] as String,
        soru: j['soru'] as String,
        secenekler: (j['secenekler'] as List).cast<String>(),
        dogru: j['dogru'] as int,
        karakter: j['karakter'] == null ? null : VarlikTuru.fromAnahtar(j['karakter'] as String),
        hatirla: j['hatirla'] == null ? null : HatirlaSorusu.fromJson(j['hatirla'] as Map<String, dynamic>),
        etkilesim: j['etkilesim'] as String?,
      );

  static Future<List<Ders>> yukle(String dil) async {
    final d = diller.contains(dil) ? dil : 'en';
    final s = await rootBundle.loadString('assets/dersler/$d.json');
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>().map(Ders.fromJson).toList();
  }
}

/// Geri getirme sorusu: açıklama metni gösterilmeden sorulur, yanlışta ders
/// metni ipucu olarak açılır (Karpicke, Blunt ve Smith 2016: ilkokul
/// çocuklarında geri getirme pratiği; küçük çocukta rehberli geri getirme,
/// yani seçenekler ve ipucu). Puan, sayaç, seri yok.
@immutable
class HatirlaSorusu {
  const HatirlaSorusu({required this.soru, required this.secenekler, required this.dogru});
  final String soru;
  final List<String> secenekler;
  final int dogru;

  static HatirlaSorusu fromJson(Map<String, dynamic> j) => HatirlaSorusu(
        soru: j['soru'] as String,
        secenekler: (j['secenekler'] as List).cast<String>(),
        dogru: j['dogru'] as int,
      );
}
