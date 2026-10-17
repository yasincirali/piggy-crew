/// Geri dönüş karşılaması (yol haritası 1.4): çocuk birkaç gün sonra
/// uygulamayı açınca takım kenarlardan koşarak gelir ve sevinir.
///
/// Neden yokluk süresi yazılmaz, karakter "özledim" demez (araştırma
/// `harcliklarim/arastirma/03`, karakter dili tüzüğü): yokluğu hatırlatmak
/// parasosyal baskıdır ve çocuğu suçlu hissettirir. Karşılama yalnız
/// "seni görmek güzel" der; ne kadar uzak kaldığını söylemez, bir şey istemez.
///
/// Neden haftada en çok bir kez: sık oynarsa değeri düşer ve "her gelişte
/// ödül" döngüsüne (değişken ödül) döner. Neden en az 3 takvim günü:
/// hafta içi her gün açan çocuk için sıradan bir açılış özel karşılama
/// beklemez; hafta sonu boşluğu (Cuma → Pazartesi) zaten 3 gündür.
///
/// İlk kurulumda oynamaz: daha önce görülmemiş çocuk "geri dönmüş" sayılmaz.
const donusEnAzGun = 3;
const donusAraligiGun = 7;

/// Yerel takvim günü farkı (saat dilimi ve yaz saati kaymasından bağımsız).
int takvimGunFarki(DateTime once, DateTime sonra) {
  final a = DateTime.utc(once.year, once.month, once.day);
  final b = DateTime.utc(sonra.year, sonra.month, sonra.day);
  return b.difference(a).inDays;
}

/// Karşılama oynasın mı? [sonGorulme]: uygulamanın en son ön planda olduğu
/// an; [sonDonus]: en son karşılamanın oynadığı an. Saf fonksiyon
/// (`donus_karsilamasi_test`).
bool donusKarsilamasiGerekli({
  required DateTime? sonGorulme,
  required DateTime? sonDonus,
  required DateTime simdi,
}) {
  if (sonGorulme == null) return false;
  if (takvimGunFarki(sonGorulme, simdi) < donusEnAzGun) return false;
  // Saat geri alınmışsa (gelecekte bir karşılama kaydı) yine haftada bir kuralı:
  // negatif fark "yakın zamanda oynadı" sayılır.
  if (sonDonus != null && takvimGunFarki(sonDonus, simdi) < donusAraligiGun) return false;
  return true;
}
