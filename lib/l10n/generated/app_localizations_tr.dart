// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get uygulamaAdi => 'Harçlıklarım';

  @override
  String get karakterAltin => 'Tortu';

  @override
  String get karakterDolar => 'Zıpzıp';

  @override
  String get karakterEuro => 'Baykuş';

  @override
  String get karakterNakit => 'Sincap';

  @override
  String get varlikAltin => 'Altın';

  @override
  String get varlikDolar => 'Dolar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Nakit';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'Yavaş yürürüm ama kabuğum sağlamdır. Zor günlerde ben dayanırım.';

  @override
  String get huyDolar =>
      'Zıplarım! Bazen yukarı, bazen aşağı. Sabırlı olan kazanır.';

  @override
  String get huyEuro => 'Sakin bakarım. Uzaktaki ülkelerin parası bende saklı.';

  @override
  String get huyNakit =>
      'Ne verirsen onu saklarım. Ama fiyatlar artarsa aldığım şey azalır.';

  @override
  String get karsilamaBaslik => 'Kumbara Takımı seni bekliyor';

  @override
  String get karsilamaAlt =>
      'Gerçek kumbarana para koyunca burada bir karaktere ver. Dört karakter birikimle büyür, kamp ateşin yanar.';

  @override
  String get karsilamaBasla => 'Başla';

  @override
  String get adSoru => 'Sana ne diyelim?';

  @override
  String get adIpucu => 'Adın ya da takma adın';

  @override
  String get yasSoru => 'Kaç yaşındasın?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get dunyaSoru => 'Kampını nereye kuralım?';

  @override
  String get dunyaAlt => 'İstediğin zaman değiştirebilirsin.';

  @override
  String get devam => 'Devam';

  @override
  String get geri => 'Geri';

  @override
  String get veliBaslik => 'Anne baba köşesi';

  @override
  String get veliAciklama =>
      'Bu 4 haneli PIN gerçek fiyatı düzeltmek, veriyi silmek ve ayarlar için. Çocuk ekranlarında reklam, bildirim ve satın alma yoktur.';

  @override
  String get veliPinIpucu => '4 haneli PIN';

  @override
  String get veliPinTekrar => 'PIN\'i tekrar yaz';

  @override
  String get veliPinUyusmaz => 'İki PIN aynı değil';

  @override
  String get veliPinSonra => 'Şimdilik geç';

  @override
  String get hazir => 'Hazırım!';

  @override
  String get sekmeKamp => 'Kamp';

  @override
  String get sekmeOgren => 'Öğren';

  @override
  String get sekmeCikartma => 'Çıkartmalar';

  @override
  String get sekmeAyarlar => 'Ayarlar';

  @override
  String kampSelam(String ad) {
    return 'Merhaba $ad';
  }

  @override
  String get kampAtesim => 'Kamp ateşim';

  @override
  String get kampBos =>
      'Kamp ateşin henüz yanmadı. Kumbarana para koyduğunda bir karaktere dokun ve ona ver.';

  @override
  String get kampFiyatYok => 'Fiyat alınamadı, değer gösterilemiyor.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Fiyatlar $zaman itibarıyla';
  }

  @override
  String get fark => 'Fark';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter gülüyor: $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter bulutların altında: $fark';
  }

  @override
  String farkDuz(String karakter) {
    return '$karakter sakin: değişim yok';
  }

  @override
  String get besle => 'Besle';

  @override
  String besleBaslik(String karakter, String tur) {
    String _temp0 = intl.Intl.selectLogic(tur, {
      'altin': '$karakter\'yu besle',
      'euro': '$karakter\'u besle',
      'other': '$karakter\'ı besle',
    });
    return '$_temp0';
  }

  @override
  String get besleTutar => 'Ne kadar?';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Bugün 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return '$tutar ile $miktar alırsın';
  }

  @override
  String besleVer(String karakter) {
    String _temp0 = intl.Intl.selectLogic(karakter, {
      'Tortu': 'Tortu\'ya ver',
      'other': '$karakter\'a ver',
    });
    return '$_temp0';
  }

  @override
  String get besleFiyatYok =>
      'Bugünün fiyatı alınamadı. İnternete bağlanınca tekrar dene.';

  @override
  String get besleGecersiz => 'Bir tutar yaz';

  @override
  String besleDoydu(String karakter) {
    return '$karakter doydu!';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'Yeni çıkartma: $ad';
  }

  @override
  String get detayVerdin => 'Verdin';

  @override
  String get detayBugun => 'Bugün';

  @override
  String detayMiktar(String miktar) {
    return 'Elinde $miktar';
  }

  @override
  String detayBos(String karakter) {
    return '$karakter henüz hiç beslenmedi.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter anlatıyor';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Aldığın günden beri $varlik değerlendi. Aynı miktar şimdi daha çok para ediyor: $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Aldığın günden beri $varlik biraz ucuzladı. Bu senin hatan değil; fiyatlar hava gibi değişir. Miktarın aynı duruyor, bugünkü değeri biraz az: $fark. Bulutlar gelir, geçer.';
  }

  @override
  String get detayNedenNakit =>
      'Nakit hep aynı sayıyı gösterir. Ama fiyatlar artarsa aynı para daha az şey alır; buna enflasyon denir.';

  @override
  String get detayBeslemeler => 'Beslemelerin';

  @override
  String get detayBirazDaha => 'Biraz daha besle';

  @override
  String get detaySil => 'Bu beslemeyi sil';

  @override
  String get detaySilOnay => 'Bu besleme silinsin mi?';

  @override
  String get iptal => 'Vazgeç';

  @override
  String get sil => 'Sil';

  @override
  String get ogrenBaslik => 'Bugünün kavramı';

  @override
  String ogrenSayac(int n, int toplam) {
    return '$n / $toplam';
  }

  @override
  String get ogrenSonraki => 'Sonraki ders';

  @override
  String get ogrenBitti => 'Bütün dersleri bitirdin. Yenileri yolda.';

  @override
  String get ogrenBastan => 'Baştan oku';

  @override
  String get cikartmaBaslik => 'Çıkartmalarım';

  @override
  String get cikartmaAlt => 'Davranışın için verilir, şans için değil.';

  @override
  String get cikartmaKilitli => 'Kilitli';

  @override
  String cikartmaSayac(int n, int toplam) {
    return '$n / $toplam açıldı';
  }

  @override
  String get ayarlarBaslik => 'Ayarlar';

  @override
  String get ayarlarDunya => 'Kamp yeri';

  @override
  String get ayarlarYas => 'Yaş modu';

  @override
  String get ayarlarPara => 'Para birimi';

  @override
  String get ayarlarSes => 'Sesler';

  @override
  String get sesAcik => 'Açık';

  @override
  String get sesKapali => 'Kapalı';

  @override
  String get ayarlarTitresim => 'Titreşim';

  @override
  String get ayarlarGorunum => 'Karakter görünümü';

  @override
  String get gorunumKlasik => 'Klasik';

  @override
  String get gorunum3d => '3D';

  @override
  String get ayarlarDil => 'Dil';

  @override
  String get ayarlarVeli => 'Anne baba köşesi';

  @override
  String ayarlarSurum(String s) {
    return 'Sürüm $s';
  }

  @override
  String get ayarlarKaynak =>
      'Fiyatlar kamuya açık piyasa verisi sağlayıcılarından alınır, yatırım tavsiyesi değildir.';

  @override
  String get dilCihaz => 'Cihaz dili';

  @override
  String get kilitBaslik => 'PIN gir';

  @override
  String get kilitYanlis => 'PIN yanlış';

  @override
  String get kilitKur => 'PIN oluştur';

  @override
  String get veliSil => 'Tüm veriyi sil';

  @override
  String get veliSilOnay =>
      'Profil, beslemeler ve çıkartmalar silinir. Geri alınamaz.';

  @override
  String get veliSilOnayDugme => 'Evet, sil';

  @override
  String get veliYedekNot =>
      'Veriler yalnız bu telefonda ve açıksa telefonun kendi yedeğinde (iCloud ya da Google) durur. Bu yedeği biz göremeyiz.';

  @override
  String get veliPinDegistir => 'PIN\'i değiştir';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad toplam $n kez besledi. Kamp ateşi: $toplam.';
  }

  @override
  String get veliNot =>
      'Çocuk ekranlarında bildirim, reklam ve satın alma yoktur. Veri yalnız bu cihazda durur.';

  @override
  String get dunyaBahce => 'Bahçe';

  @override
  String get dunyaUzay => 'Uzay';

  @override
  String get dunyaOkyanus => 'Okyanus';

  @override
  String get dunyaNeon => 'Neon';

  @override
  String get dunyaSeker => 'Şeker';

  @override
  String get dunyaSafari => 'Safari';

  @override
  String get ckIlkbeslemeAd => 'İlk kıvılcım';

  @override
  String get ckIlkbeslemeAciklama => 'Kamp ateşini ilk kez yaktın.';

  @override
  String get ckTortusapkaAd => 'Tortu\'nun şapkası';

  @override
  String get ckTortusapkaAciklama => 'Tortu\'yu üç kez besledin.';

  @override
  String get ckZipzipatkiAd => 'Zıpzıp\'ın atkısı';

  @override
  String get ckZipzipatkiAciklama => 'Zıpzıp\'ı üç kez besledin.';

  @override
  String get ckBaykusgozlukAd => 'Baykuş\'un gözlüğü';

  @override
  String get ckBaykusgozlukAciklama => 'Baykuş\'u üç kez besledin.';

  @override
  String get ckSincapfularAd => 'Sincap\'ın fuları';

  @override
  String get ckSincapfularAciklama => 'Sincap\'ı üç kez besledin.';

  @override
  String get ckTakimtamAd => 'Takım tamam';

  @override
  String get ckTakimtamAciklama => 'Bütün karakterleri besledin.';

  @override
  String get ckAtes1000Ad => 'Büyük ateş';

  @override
  String get ckAtes1000Aciklama => 'Takımı dört ayrı haftada besledin.';

  @override
  String get ckAtes5000Ad => 'Şenlik ateşi';

  @override
  String get ckAtes5000Aciklama => 'Takımı on iki ayrı haftada besledin.';

  @override
  String get ckDers5Ad => 'Meraklı';

  @override
  String get ckDers5Aciklama => 'Beş dersi bitirdin.';

  @override
  String get ckDers10Ad => 'Bilge';

  @override
  String get ckDers10Aciklama => 'On dersi bitirdin.';

  @override
  String get ckSabir30Ad => 'Sabırlı';

  @override
  String get ckSabir30Aciklama =>
      'İlk beslemenden 30 gün geçti ve hâlâ buradasın.';

  @override
  String get ckTortuparlakAd => 'Parlayan Tortu';

  @override
  String get ckTortuparlakAciklama => 'Tortu\'yu beş ayrı haftada besledin.';

  @override
  String get donusKarsilama => 'Takım seni görünce koşa koşa geldi!';

  @override
  String kampOdunEtiket(int n) {
    return 'Kamp ateşi, $n odun';
  }

  @override
  String get odunEklendi => 'Bu hafta ateşe bir odun eklendi!';

  @override
  String get cikisBaslik => 'Kumbaradan aldım';

  @override
  String cikisAlt(String karakter) {
    return '$karakter senin için sakladı. Ne kadar aldın?';
  }

  @override
  String cikisKumbarada(String tutar) {
    return 'Kumbarada: $tutar';
  }

  @override
  String get cikisHepsi => 'Hepsi';

  @override
  String get cikisFazla => 'Bu, kumbaradakinden fazla.';

  @override
  String get cikisDugme => 'Aldım';

  @override
  String cikisTamam(String karakter) {
    return '$karakter: İyi kullan!';
  }

  @override
  String get cikisSatir => 'Kumbaradan alındı';

  @override
  String get cikisSil => 'Bu kaydı sil';

  @override
  String get cikisSilOnay => 'Bu kayıt silinsin mi?';

  @override
  String get geriBildirim => 'Geri bildirim gönder';

  @override
  String get geriBildirimAciklama =>
      'Yalnız aşağıdakiler gönderilir: tutar, ad ya da kişisel bilgi yok. Göndermeden önce okuyabilir, nereye gideceğini sen seçersin.';

  @override
  String get geriBildirimOzet => 'Gönderilecek bilgiler';

  @override
  String get geriBildirimSoru1 => 'Çocuğunun en sevdiği an neydi?';

  @override
  String get geriBildirimSoru2 => 'Nerede takıldı?';

  @override
  String get geriBildirimSoru3 => 'Kullanmayı bıraktıysa, neden?';

  @override
  String get geriBildirimPaylas => 'Paylaş';

  @override
  String get geriBildirimKilitGerek => 'Göndermek için önce veli kilidi kur.';

  @override
  String get geriBildirimKonu => 'Harçlıklarım geri bildirim';

  @override
  String get gbSurum => 'Sürüm';

  @override
  String get gbDil => 'Dil';

  @override
  String get gbPara => 'Para birimi';

  @override
  String get gbYas => 'Yaş modu';

  @override
  String get gbGorunum => 'Karakter görünümü';

  @override
  String get gbKurulu => 'Kurulalı (gün)';

  @override
  String get gbGun => 'Farklı besleme günü';

  @override
  String get gbOdun => 'Kamp odunu';

  @override
  String get gbCikis => 'Kumbaradan alma';

  @override
  String get gbDers => 'Okunan ders';

  @override
  String get gbCikartma => 'Açılan çıkartma';

  @override
  String ikilemBaslik(String karakter) {
    return '$karakter düşünüyor';
  }

  @override
  String ikilemSoru(String karakter) {
    return '$karakter\'ın biraz parası var. Yeni palamut mu alsın, kış yuvasına tahta mı?';
  }

  @override
  String get ikilemIstek => 'Yeni palamut';

  @override
  String get ikilemIhtiyac => 'Yuvaya tahta';

  @override
  String get ikilemIstekCevap =>
      'Canının çektiği bir şey! Bu bir istek. İstekler de güzel, sırası gelince.';

  @override
  String get ikilemIhtiyacCevap =>
      'Kışın sıcak bir yuva lazım! Bu bir ihtiyaç. Önce ihtiyaç, sonra istek.';

  @override
  String get ikilemTamam => 'Tamam';

  @override
  String get ayarlarGizlilik => 'Gizlilik';

  @override
  String get hedefBaslik => 'Hedef';

  @override
  String get hedefSec => 'Hedef seç';

  @override
  String get hedefDegistir => 'Değiştir';

  @override
  String get hedefYeni => 'Yeni hedef';

  @override
  String get hedefKaydet => 'Hedefi koy';

  @override
  String get hedefKaldir => 'Hedefi kaldır';

  @override
  String hedefYok(String karakter) {
    return 'Bir şey için mi biriktiriyorsun? Seçersen $karakter onu taşır; sen besledikçe eşya dolar.';
  }

  @override
  String hedefEsyaAdi(String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'Bisiklet',
      'top': 'Top',
      'kitap': 'Kitap',
      'kulaklik': 'Kulaklık',
      'oyuncak': 'Oyuncak',
      'kaykay': 'Kaykay',
      'oyun': 'Oyun',
      'hediye': 'Hediye',
      'cizim': 'Kendin çiz',
      'other': 'Hediye',
    });
    return '$_temp0';
  }

  @override
  String hedefCumle(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'bisiklet',
      'top': 'top',
      'kitap': 'kitap',
      'kulaklik': 'kulaklık',
      'oyuncak': 'oyuncak',
      'kaykay': 'kaykay',
      'oyun': 'oyun',
      'hediye': 'hediye',
      'cizim': 'senin çizdiğin şey',
      'other': 'hediye',
    });
    return '$karakter $_temp0 için biriktiriyor';
  }

  @override
  String hedefHazir(String karakter, String esya) {
    String _temp0 = intl.Intl.selectLogic(esya, {
      'bisiklet': 'Bisiklet hazır!',
      'top': 'Top hazır!',
      'kitap': 'Kitap hazır!',
      'kulaklik': 'Kulaklık hazır!',
      'oyuncak': 'Oyuncak hazır!',
      'kaykay': 'Kaykay hazır!',
      'oyun': 'Oyun hazır!',
      'hediye': 'Hediye hazır!',
      'cizim': 'Çizdiğin şey hazır!',
      'other': 'Hedef hazır!',
    });
    return '$_temp0 $karakter çok sevindi.';
  }

  @override
  String hedefKademe(String kademe) {
    String _temp0 = intl.Intl.selectLogic(kademe, {
      'yeni': 'İlk beslemeyle dolmaya başlar',
      'basladi': 'Dolmaya başladı',
      'yarim': 'Yarısı doldu',
      'neredeyse': 'Neredeyse doldu',
      'hazir': 'Doldu!',
      'other': 'Dolmaya başladı',
    });
    return '$_temp0';
  }

  @override
  String hedefSayfaBaslik(String karakter) {
    return '$karakter ne için biriktirsin?';
  }

  @override
  String get hedefFiyat => 'Yaklaşık ne kadar?';

  @override
  String get hedefFiyatNot =>
      'Bu sayı yalnız burada görünür; sonra ekranda eşya dolar.';

  @override
  String get karsilamaParaNot =>
      'Para birimi, karakterlere ilk kez para verildikten sonra değişmez.';

  @override
  String ogrenKarakterSoruyor(String karakter) {
    return '$karakter buna takıldı. Ona anlatır mısın?';
  }

  @override
  String ogrenOgretti(String karakter) {
    return '$karakter: \"Şimdi anladım, teşekkürler!\"';
  }

  @override
  String ogrenBirlikte(String karakter) {
    return '$karakter: \"Hmm, ben de karıştırdım. Metne birlikte bir daha bakalım mı?\"';
  }

  @override
  String detayOgrettiklerin(String karakter) {
    return '$karakter senden öğrendi';
  }

  @override
  String get planBaslik => 'Benim planım';

  @override
  String get planYok =>
      'Kendine küçük bir plan seçebilirsin. Kimse kontrol etmez.';

  @override
  String get planSec => 'Plan seç';

  @override
  String get planSayfaAlt =>
      'Bir cümle seç, senin sözün olsun. İstediğin zaman değiştirebilirsin.';

  @override
  String planCumle(String sablon, String karakter) {
    String _temp0 = intl.Intl.selectLogic(sablon, {
      'biriktiririm':
          'Harçlığımı alınca bir kısmını $karakter ile biriktiririm.',
      'beklerim': 'Bir şey almadan önce bir gün beklerim.',
      'bakarim': 'Hafta sonu $karakter ile kumbarama bakarım.',
      'other': 'Bir şey almadan önce bir gün beklerim.',
    });
    return '$_temp0';
  }

  @override
  String get planKaldir => 'Planı kaldır';

  @override
  String get cizimBaslik => 'Hedefini çiz';

  @override
  String get cizimAlt => 'Ne için biriktiriyorsan parmağınla buraya çiz.';

  @override
  String get cizimAlani => 'Çizim alanı. Parmağınla çiz.';

  @override
  String get cizimGeriAl => 'Geri al';

  @override
  String get cizimTemizle => 'Temizle';

  @override
  String get cizimBitti => 'Bitti';

  @override
  String get cizimVazgec => 'Kapat';

  @override
  String get cizimYeniden => 'Yeniden çiz';

  @override
  String get cizimEtiket => 'Senin çizimin';

  @override
  String cizimRenk(String renk) {
    String _temp0 = intl.Intl.selectLogic(renk, {
      'r0': 'Siyah',
      'r1': 'Kırmızı',
      'r2': 'Sarı',
      'r3': 'Yeşil',
      'r4': 'Mavi',
      'other': 'Siyah',
    });
    return '$_temp0';
  }
}
