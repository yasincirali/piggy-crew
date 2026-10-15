// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get uygulamaAdi => 'My Pocket Money';

  @override
  String get karakterAltin => 'Tortu';

  @override
  String get karakterDolar => 'Zippy';

  @override
  String get karakterEuro => 'Hoot';

  @override
  String get karakterNakit => 'Nutty';

  @override
  String get varlikAltin => 'Gold';

  @override
  String get varlikDolar => 'Dollar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Cash';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'I walk slowly, but my shell is strong. On hard days, I hold on.';

  @override
  String get huyDolar => 'I hop! Sometimes up, sometimes down. Patience wins.';

  @override
  String get huyEuro =>
      'I watch calmly. I keep the money of faraway countries.';

  @override
  String get huyNakit =>
      'I keep whatever you give me. But when prices rise, it buys less.';

  @override
  String get karsilamaBaslik => 'The Piggy Crew is waiting';

  @override
  String get karsilamaAlt =>
      'Your savings live in four friendly characters. Feed them and your campfire grows.';

  @override
  String get karsilamaBasla => 'Start';

  @override
  String get adSoru => 'What should we call you?';

  @override
  String get adIpucu => 'Your name or nickname';

  @override
  String get yasSoru => 'How old are you?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get paraSoru => 'Which money do you use?';

  @override
  String get dunyaSoru => 'Where should we set up camp?';

  @override
  String get dunyaAlt => 'You can change it any time.';

  @override
  String get devam => 'Continue';

  @override
  String get geri => 'Back';

  @override
  String get veliBaslik => 'Parents\' corner';

  @override
  String get veliAciklama =>
      'This 4-digit PIN protects price fixes, data deletion and settings. Kids\' screens have no ads, notifications or purchases.';

  @override
  String get veliPinIpucu => '4-digit PIN';

  @override
  String get veliPinTekrar => 'Repeat the PIN';

  @override
  String get veliPinUyusmaz => 'The PINs don\'t match';

  @override
  String get veliPinSonra => 'Skip for now';

  @override
  String get hazir => 'I\'m ready!';

  @override
  String get sekmeKamp => 'Camp';

  @override
  String get sekmeOgren => 'Learn';

  @override
  String get sekmeCikartma => 'Stickers';

  @override
  String get sekmeAyarlar => 'Settings';

  @override
  String kampSelam(String ad) {
    return 'Hi $ad';
  }

  @override
  String get kampAtesim => 'My campfire';

  @override
  String get kampBos =>
      'Your campfire isn\'t lit yet. Tap a character and feed it.';

  @override
  String get kampFiyatYok => 'Prices unavailable, value can\'t be shown.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Prices as of $zaman';
  }

  @override
  String get fark => 'Change';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter is smiling: $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter is a bit sad: $fark';
  }

  @override
  String farkDuz(String karakter) {
    return '$karakter is calm: no change';
  }

  @override
  String get besle => 'Feed';

  @override
  String besleBaslik(String karakter) {
    return 'Feed $karakter';
  }

  @override
  String get besleTutar => 'How much?';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Today 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return '$tutar buys $miktar';
  }

  @override
  String besleVer(String karakter) {
    return 'Give to $karakter';
  }

  @override
  String get besleFiyatYok =>
      'Today\'s price couldn\'t be loaded. Try again when you\'re online.';

  @override
  String get besleGecersiz => 'Enter an amount';

  @override
  String besleDoydu(String karakter) {
    return '$karakter is full!';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'New sticker: $ad';
  }

  @override
  String get detayVerdin => 'You gave';

  @override
  String get detayBugun => 'Today';

  @override
  String detayMiktar(String miktar) {
    return 'You hold $miktar';
  }

  @override
  String detayBos(String karakter) {
    return '$karakter hasn\'t been fed yet.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter explains';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Since you bought it, $varlik gained value. The same amount is now worth more: $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Since you bought it, $varlik got a little cheaper. Your amount is the same, today\'s value is a bit lower: $fark. Patience is part of the game.';
  }

  @override
  String get detayNedenNakit =>
      'Cash always shows the same number. But when prices rise, the same money buys less; that\'s called inflation.';

  @override
  String get detayBeslemeler => 'Your feedings';

  @override
  String get detayBirazDaha => 'Feed a bit more';

  @override
  String get detaySil => 'Delete this feeding';

  @override
  String get detaySilOnay => 'Delete this feeding?';

  @override
  String get iptal => 'Cancel';

  @override
  String get sil => 'Delete';

  @override
  String get ogrenBaslik => 'Today\'s idea';

  @override
  String ogrenSayac(int n, int toplam) {
    return '$n / $toplam';
  }

  @override
  String get ogrenSoru => 'Question';

  @override
  String ogrenDogru(String karakter) {
    return 'Correct! $karakter is proud of you.';
  }

  @override
  String get ogrenYanlis => 'Think again. The hint is in the text.';

  @override
  String get ogrenSonraki => 'Next lesson';

  @override
  String get ogrenBitti => 'You finished every lesson. New ones are coming.';

  @override
  String get ogrenBastan => 'Read again';

  @override
  String get cikartmaBaslik => 'My stickers';

  @override
  String get cikartmaAlt => 'Earned for what you do, not for luck.';

  @override
  String get cikartmaKilitli => 'Locked';

  @override
  String cikartmaSayac(int n, int toplam) {
    return '$n / $toplam unlocked';
  }

  @override
  String get ayarlarBaslik => 'Settings';

  @override
  String get ayarlarDunya => 'Camp site';

  @override
  String get ayarlarYas => 'Age mode';

  @override
  String get ayarlarPara => 'Currency';

  @override
  String get ayarlarSes => 'Sounds';

  @override
  String get sesAcik => 'On';

  @override
  String get sesKapali => 'Off';

  @override
  String get ayarlarDil => 'Language';

  @override
  String get ayarlarVeli => 'Parents\' corner';

  @override
  String ayarlarSurum(String s) {
    return 'Version $s';
  }

  @override
  String get ayarlarKaynak =>
      'Prices come from public market data providers and are not investment advice.';

  @override
  String get dilCihaz => 'Device language';

  @override
  String get kilitBaslik => 'Enter PIN';

  @override
  String get kilitYanlis => 'Wrong PIN';

  @override
  String get kilitKur => 'Create a PIN';

  @override
  String get veliSil => 'Delete all data';

  @override
  String get veliSilOnay =>
      'Profile, feedings and stickers will be deleted. This can\'t be undone.';

  @override
  String get veliSilOnayDugme => 'Yes, delete';

  @override
  String get veliPinDegistir => 'Change PIN';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad fed $n times in total. Campfire: $toplam.';
  }

  @override
  String get veliNot =>
      'Kids\' screens have no notifications, ads or purchases. Data stays on this device only.';

  @override
  String get dunyaBahce => 'Garden';

  @override
  String get dunyaUzay => 'Space';

  @override
  String get dunyaOkyanus => 'Ocean';

  @override
  String get dunyaNeon => 'Neon';

  @override
  String get dunyaSeker => 'Candy';

  @override
  String get dunyaSafari => 'Safari';

  @override
  String get ckIlkbeslemeAd => 'First spark';

  @override
  String get ckIlkbeslemeAciklama => 'You lit the campfire for the first time.';

  @override
  String get ckTortusapkaAd => 'Tortu\'s hat';

  @override
  String get ckTortusapkaAciklama => 'You fed Tortu three times.';

  @override
  String get ckZipzipatkiAd => 'Zippy\'s scarf';

  @override
  String get ckZipzipatkiAciklama => 'You fed Zippy three times.';

  @override
  String get ckBaykusgozlukAd => 'Hoot\'s glasses';

  @override
  String get ckBaykusgozlukAciklama => 'You fed Hoot three times.';

  @override
  String get ckSincapfularAd => 'Nutty\'s bandana';

  @override
  String get ckSincapfularAciklama => 'You fed Nutty three times.';

  @override
  String get ckTakimtamAd => 'Full crew';

  @override
  String get ckTakimtamAciklama => 'You fed every character.';

  @override
  String get ckAtes1000Ad => 'Big fire';

  @override
  String get ckAtes1000Aciklama =>
      'Your campfire passed 1,000 for the first time.';

  @override
  String get ckAtes5000Ad => 'Bonfire';

  @override
  String get ckAtes5000Aciklama =>
      'Your campfire passed 5,000 for the first time.';

  @override
  String get ckDers5Ad => 'Curious';

  @override
  String get ckDers5Aciklama => 'You finished five lessons.';

  @override
  String get ckDers10Ad => 'Wise';

  @override
  String get ckDers10Aciklama => 'You finished ten lessons.';

  @override
  String get ckSabir30Ad => 'Patient';

  @override
  String get ckSabir30Aciklama =>
      '30 days since your first feeding, and you\'re still here.';

  @override
  String get ckTortuparlakAd => 'Shining Tortu';

  @override
  String get ckTortuparlakAciklama => 'Tortu\'s value passed 1,500.';
}
