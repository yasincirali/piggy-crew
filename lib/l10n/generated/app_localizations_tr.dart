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
      'Birikimlerin dört sevimli karakterde yaşar. Onları besle, kamp ateşin büyüsün.';

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
  String get paraSoru => 'Paran hangisi?';

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
      'Kamp ateşin henüz yanmadı. Bir karaktere dokun ve besle.';

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
  String get ogrenSoru => 'Soru';

  @override
  String ogrenDogru(String karakter) {
    return 'Doğru! $karakter seninle gurur duyuyor.';
  }

  @override
  String get ogrenYanlis => 'Bir daha düşün. İpucu metinde gizli.';

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
  String get gorunum3d => '3D (deneme)';

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
}
