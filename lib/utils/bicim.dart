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

/// Çocuğun yazdığı metni sayıya çevirir: "1.250,50", "1,250.50", "1250.50", "1.500".
/// İki ayırıcı da varsa SON ayırıcı ondalıktır. Tek tür ayırıcı varsa:
/// birden çok kez geçiyorsa ya da tek kez geçip ardından tam üç hane geliyorsa
/// binliktir ("1.500" = bin beş yüz, "1,500" = bin beş yüz); yoksa ondalıktır
/// ("12,5", "12.50"). Yerel bağımsız. Eskiden virgülsüz nokta hep ondalık
/// sayılıyordu: Türkiye'de hedefe "1.500" yazan aile 1,5 ₺'lik hedef kuruyordu
/// ve hedef ilk beslemede kalıcı olarak "ulaşıldı" oluyordu (Ar-Ge 25 Eki).
/// Bedeli: "0,500" gibi üç haneli ondalık; başı 0 olan grup ondalık kalır.
double? parseSayi(String s) {
  var t = s.trim().replaceAll(RegExp(r'[^0-9.,]'), '');
  if (t.isEmpty) return null;
  final virgul = t.contains(','), nokta = t.contains('.');
  if (virgul && nokta) {
    t = t.lastIndexOf(',') > t.lastIndexOf('.') ? t.replaceAll('.', '').replaceAll(',', '.') : t.replaceAll(',', '');
  } else if (virgul || nokta) {
    final ayirici = virgul ? ',' : '.';
    final parcalar = t.split(ayirici);
    final binlik = parcalar.length > 2 ||
        (parcalar[1].length == 3 && parcalar[0].isNotEmpty && int.tryParse(parcalar[0]) != 0);
    t = binlik ? parcalar.join() : parcalar.join('.');
  }
  final v = double.tryParse(t);
  return (v == null || !v.isFinite || v <= 0) ? null : v;
}
