import 'package:intl/intl.dart';

import '../models/varlik.dart';

/// Para ve miktar biçimi — TEK yer. Ekranda `toStringAsFixed` yazılmaz
/// (sandık kuralı). Kuruş yalnız 1.000 altında gösterilir: çocuğa
/// "1.240 ₺" yeter, "1.240,37 ₺" gürültüdür.
///
/// Global uygulama: biçim ev para biriminin yerelini izler (TRY → "1.240 ₺",
/// USD → "$1,240"). Sembol konumu yerelden gelir, elle yazılmaz.
String fmtPara(double v, ParaBirimi p) {
  // Kuruş yalnız 1.000 altında VE gerçekten kuruş varsa: "250 ₺", "12,50 ₺".
  final kurus = v.abs() < 1000 && (v - v.truncateToDouble()).abs() >= 0.005;
  // intl tr_TR sembolü öne koyar ("₺1.240"); Türkiye'de yazım "1.240 ₺"
  // (sandık `fmtTRY` ile aynı karar). Diğer birimler yerelin kuralını izler.
  if (p == ParaBirimi.tryy) {
    final n = NumberFormat(kurus ? '#,##0.00' : '#,##0', p.yerel).format(v);
    return '$n ${p.sembol}';
  }
  final f = NumberFormat.currency(
    locale: p.yerel,
    symbol: p.sembol,
    decimalDigits: kurus ? 2 : 0,
  );
  return f.format(v).trim();
}

/// İşaretli fark: "+64 ₺" / "−12 ₺". Eksi için gerçek eksi işareti (U+2212).
String fmtFark(double v, ParaBirimi p) {
  final s = fmtPara(v.abs(), p);
  // Kayan nokta artığı (ör. −1e-13) yuvarlanınca sıfır görünür: "−0 ₺" yazılmaz.
  if (s == fmtPara(0, p)) return s;
  return v > 0 ? '+$s' : '−$s';
}

String fmtYuzde(double v, ParaBirimi p) {
  final s = NumberFormat('0.0', p.yerel).format(v.abs());
  final isaret = v == 0 ? '' : (v > 0 ? '+' : '−');
  // Türkçede yüzde işareti önde, diğer dillerde arkada.
  return p == ParaBirimi.tryy ? '$isaret%$s' : '$isaret$s%';
}

/// Miktar: "0,5 g", "12 $". Sondaki sıfırlar atılır
/// (kullanıcı kuralı: fiyat yuvarlanmaz, sondaki sıfır atılır).
String fmtMiktar(double v, String birim, ParaBirimi p) {
  // Ev birimindeki nakit miktar değil tutardır: "12 $" değil "$12".
  if (birim == p.sembol) return fmtPara(v, p);
  final s = NumberFormat('#,##0.###', p.yerel).format(v);
  return '$s $birim';
}

/// Çocuğun yazdığı metni sayıya çevirir: "1.250,50", "1,250.50" ve "1250.50".
/// Hangi işaretin ondalık olduğuna SON ayırıcı karar verir — yerel bağımsız.
double? parseSayi(String s) {
  var t = s.trim().replaceAll(RegExp(r'[^0-9.,]'), '');
  if (t.isEmpty) return null;
  final sonVirgul = t.lastIndexOf(',');
  final sonNokta = t.lastIndexOf('.');
  if (sonVirgul > sonNokta) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else {
    t = t.replaceAll(',', '');
  }
  final v = double.tryParse(t);
  return (v == null || !v.isFinite || v <= 0) ? null : v;
}
