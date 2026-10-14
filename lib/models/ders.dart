import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cocuk.dart';
import 'varlik.dart';

/// Dersler `assets/dersler.json`'dan gelir — metin kodda değil, içerikte.
/// Her ders: kavram, iki yaş modu için ayrı metin, tek soru, üç seçenek.
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
  });

  final String id, kavram, baslik, metinKucuk, metinBuyuk, soru;
  final List<String> secenekler;
  final int dogru;
  final VarlikTuru? karakter;

  String metin(YasModu y) => y == YasModu.kucuk ? metinKucuk : metinBuyuk;

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
      );

  static Future<List<Ders>> yukle() async {
    final s = await rootBundle.loadString('assets/dersler.json');
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>().map(Ders.fromJson).toList();
  }
}
