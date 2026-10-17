// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get uygulamaAdi => 'Mein Taschengeld';

  @override
  String get karakterAltin => 'Schildi';

  @override
  String get karakterDolar => 'Hoppel';

  @override
  String get karakterEuro => 'Schuhu';

  @override
  String get karakterNakit => 'Nussi';

  @override
  String get varlikAltin => 'Gold';

  @override
  String get varlikDolar => 'Dollar';

  @override
  String get varlikEuro => 'Euro';

  @override
  String get varlikNakit => 'Bargeld';

  @override
  String get birimGram => 'g';

  @override
  String get huyAltin =>
      'Ich gehe langsam, aber mein Panzer ist stark. An schweren Tagen halte ich durch.';

  @override
  String get huyDolar => 'Ich hüpfe! Mal hoch, mal runter. Geduld gewinnt.';

  @override
  String get huyEuro =>
      'Ich schaue ganz ruhig zu. Ich hüte das Geld ferner Länder.';

  @override
  String get huyNakit =>
      'Ich bewahre alles auf, was du mir gibst. Aber wenn die Preise steigen, kann man damit weniger kaufen.';

  @override
  String get karsilamaBaslik => 'Die Sparbande wartet';

  @override
  String get karsilamaAlt =>
      'Dein Erspartes wohnt in vier freundlichen Figuren. Füttere sie, und dein Lagerfeuer wächst.';

  @override
  String get karsilamaBasla => 'Los geht\'s';

  @override
  String get adSoru => 'Wie sollen wir dich nennen?';

  @override
  String get adIpucu => 'Dein Name oder Spitzname';

  @override
  String get yasSoru => 'Wie alt bist du?';

  @override
  String get yasKucuk => '7–10';

  @override
  String get yasBuyuk => '11–15';

  @override
  String get paraSoru => 'Welches Geld benutzt du?';

  @override
  String get dunyaSoru => 'Wo sollen wir unser Lager aufschlagen?';

  @override
  String get dunyaAlt => 'Du kannst es jederzeit ändern.';

  @override
  String get devam => 'Weiter';

  @override
  String get geri => 'Zurück';

  @override
  String get veliBaslik => 'Elternecke';

  @override
  String get veliAciklama =>
      'Diese 4-stellige PIN schützt Preiskorrekturen, das Löschen von Daten und die Einstellungen. Die Kinderbildschirme haben keine Werbung, keine Benachrichtigungen und keine Käufe.';

  @override
  String get veliPinIpucu => '4-stellige PIN';

  @override
  String get veliPinTekrar => 'PIN wiederholen';

  @override
  String get veliPinUyusmaz => 'Die PINs stimmen nicht überein';

  @override
  String get veliPinSonra => 'Jetzt überspringen';

  @override
  String get hazir => 'Ich bin bereit!';

  @override
  String get sekmeKamp => 'Lager';

  @override
  String get sekmeOgren => 'Lernen';

  @override
  String get sekmeCikartma => 'Sticker';

  @override
  String get sekmeAyarlar => 'Einstellungen';

  @override
  String kampSelam(String ad) {
    return 'Hallo $ad';
  }

  @override
  String get kampAtesim => 'Mein Lagerfeuer';

  @override
  String get kampBos =>
      'Dein Lagerfeuer brennt noch nicht. Tippe auf eine Figur und füttere sie.';

  @override
  String get kampFiyatYok =>
      'Keine Preise da, der Wert kann nicht angezeigt werden.';

  @override
  String kampFiyatEski(String zaman) {
    return 'Preisstand: $zaman';
  }

  @override
  String get fark => 'Unterschied';

  @override
  String farkMutlu(String karakter, String fark) {
    return '$karakter lächelt: $fark';
  }

  @override
  String farkUzgun(String karakter, String fark) {
    return '$karakter hat eine Wolke über sich: $fark';
  }

  @override
  String farkDuz(String karakter) {
    return '$karakter ist ruhig: keine Änderung';
  }

  @override
  String get besle => 'Füttern';

  @override
  String besleBaslik(String karakter, String tur) {
    return '$karakter füttern';
  }

  @override
  String get besleTutar => 'Wie viel?';

  @override
  String besleBugunFiyat(String birim, String fiyat) {
    return 'Heute 1 $birim = $fiyat';
  }

  @override
  String besleAlir(String tutar, String miktar) {
    return 'Für $tutar bekommst du $miktar';
  }

  @override
  String besleVer(String karakter) {
    return 'An $karakter geben';
  }

  @override
  String get besleFiyatYok =>
      'Der heutige Preis konnte nicht geladen werden. Versuch es noch mal, wenn du online bist.';

  @override
  String get besleGecersiz => 'Gib einen Betrag ein';

  @override
  String besleDoydu(String karakter) {
    return '$karakter ist satt!';
  }

  @override
  String cikartmaAcildi(String ad) {
    return 'Neuer Sticker: $ad';
  }

  @override
  String get detayVerdin => 'Du hast gegeben';

  @override
  String get detayBugun => 'Heute';

  @override
  String detayMiktar(String miktar) {
    return 'Du hast $miktar';
  }

  @override
  String detayBos(String karakter) {
    return '$karakter wurde noch nicht gefüttert.';
  }

  @override
  String detayNedenBaslik(String karakter) {
    return '$karakter erklärt';
  }

  @override
  String detayNedenMutlu(String varlik, String fark) {
    return 'Seit du es gekauft hast, ist $varlik mehr wert geworden. Die gleiche Menge ist jetzt mehr wert: $fark.';
  }

  @override
  String detayNedenUzgun(String varlik, String fark) {
    return 'Seit du es gekauft hast, ist $varlik ein bisschen billiger geworden. Das ist nicht deine Schuld; Preise ändern sich wie das Wetter. Deine Menge ist noch genauso groß, nur der Wert heute ist etwas kleiner: $fark. Wolken kommen und gehen.';
  }

  @override
  String get detayNedenNakit =>
      'Bargeld zeigt immer dieselbe Zahl. Aber wenn die Preise steigen, kann man mit demselben Geld weniger kaufen. Das nennt man Inflation.';

  @override
  String get detayBeslemeler => 'Deine Fütterungen';

  @override
  String get detayBirazDaha => 'Noch ein bisschen füttern';

  @override
  String get detaySil => 'Diese Fütterung löschen';

  @override
  String get detaySilOnay => 'Diese Fütterung löschen?';

  @override
  String get iptal => 'Abbrechen';

  @override
  String get sil => 'Löschen';

  @override
  String get ogrenBaslik => 'Die Idee des Tages';

  @override
  String ogrenSayac(int n, int toplam) {
    return '$n / $toplam';
  }

  @override
  String get ogrenSoru => 'Frage';

  @override
  String ogrenDogru(String karakter) {
    return 'Richtig! $karakter ist stolz auf dich.';
  }

  @override
  String get ogrenYanlis => 'Denk noch mal nach. Der Tipp steht im Text.';

  @override
  String get ogrenSonraki => 'Nächste Lektion';

  @override
  String get ogrenBitti =>
      'Du hast alle Lektionen geschafft. Neue kommen bald.';

  @override
  String get ogrenBastan => 'Noch mal lesen';

  @override
  String get cikartmaBaslik => 'Meine Sticker';

  @override
  String get cikartmaAlt =>
      'Du bekommst sie für das, was du tust, nicht durch Glück.';

  @override
  String get cikartmaKilitli => 'Gesperrt';

  @override
  String cikartmaSayac(int n, int toplam) {
    return '$n / $toplam freigeschaltet';
  }

  @override
  String get ayarlarBaslik => 'Einstellungen';

  @override
  String get ayarlarDunya => 'Lagerplatz';

  @override
  String get ayarlarYas => 'Altersmodus';

  @override
  String get ayarlarPara => 'Währung';

  @override
  String get ayarlarSes => 'Töne';

  @override
  String get sesAcik => 'An';

  @override
  String get sesKapali => 'Aus';

  @override
  String get ayarlarTitresim => 'Vibration';

  @override
  String get ayarlarDil => 'Sprache';

  @override
  String get ayarlarVeli => 'Elternecke';

  @override
  String ayarlarSurum(String s) {
    return 'Version $s';
  }

  @override
  String get ayarlarKaynak =>
      'Die Preise kommen von öffentlichen Marktdatenanbietern und sind keine Anlageberatung.';

  @override
  String get dilCihaz => 'Gerätesprache';

  @override
  String get kilitBaslik => 'PIN eingeben';

  @override
  String get kilitYanlis => 'Falsche PIN';

  @override
  String get kilitKur => 'PIN festlegen';

  @override
  String get veliSil => 'Alle Daten löschen';

  @override
  String get veliSilOnay =>
      'Profil, Fütterungen und Sticker werden gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get veliSilOnayDugme => 'Ja, löschen';

  @override
  String get veliPinDegistir => 'PIN ändern';

  @override
  String veliOzet(String ad, int n, String toplam) {
    return '$ad hat insgesamt $n-mal gefüttert. Lagerfeuer: $toplam.';
  }

  @override
  String get veliNot =>
      'Die Kinderbildschirme haben keine Benachrichtigungen, keine Werbung und keine Käufe. Die Daten bleiben nur auf diesem Gerät.';

  @override
  String get dunyaBahce => 'Garten';

  @override
  String get dunyaUzay => 'Weltall';

  @override
  String get dunyaOkyanus => 'Ozean';

  @override
  String get dunyaNeon => 'Neon';

  @override
  String get dunyaSeker => 'Süßigkeiten';

  @override
  String get dunyaSafari => 'Safari';

  @override
  String get ckIlkbeslemeAd => 'Erster Funke';

  @override
  String get ckIlkbeslemeAciklama =>
      'Du hast das Lagerfeuer zum ersten Mal angezündet.';

  @override
  String get ckTortusapkaAd => 'Schildis Hut';

  @override
  String get ckTortusapkaAciklama => 'Du hast Schildi dreimal gefüttert.';

  @override
  String get ckZipzipatkiAd => 'Hoppels Schal';

  @override
  String get ckZipzipatkiAciklama => 'Du hast Hoppel dreimal gefüttert.';

  @override
  String get ckBaykusgozlukAd => 'Schuhus Brille';

  @override
  String get ckBaykusgozlukAciklama => 'Du hast Schuhu dreimal gefüttert.';

  @override
  String get ckSincapfularAd => 'Nussis Halstuch';

  @override
  String get ckSincapfularAciklama => 'Du hast Nussi dreimal gefüttert.';

  @override
  String get ckTakimtamAd => 'Ganze Bande';

  @override
  String get ckTakimtamAciklama => 'Du hast jede Figur gefüttert.';

  @override
  String get ckAtes1000Ad => 'Großes Feuer';

  @override
  String get ckAtes1000Aciklama =>
      'Du hast die Bande in vier verschiedenen Wochen gefüttert.';

  @override
  String get ckAtes5000Ad => 'Riesenfeuer';

  @override
  String get ckAtes5000Aciklama =>
      'Du hast die Bande in zwölf verschiedenen Wochen gefüttert.';

  @override
  String get ckDers5Ad => 'Neugierig';

  @override
  String get ckDers5Aciklama => 'Du hast fünf Lektionen geschafft.';

  @override
  String get ckDers10Ad => 'Schlau';

  @override
  String get ckDers10Aciklama => 'Du hast zehn Lektionen geschafft.';

  @override
  String get ckSabir30Ad => 'Geduldig';

  @override
  String get ckSabir30Aciklama =>
      '30 Tage seit deiner ersten Fütterung, und du bist immer noch dabei.';

  @override
  String get ckTortuparlakAd => 'Glänzender Schildi';

  @override
  String get ckTortuparlakAciklama =>
      'Du hast Schildi in fünf verschiedenen Wochen gefüttert.';

  @override
  String get donusKarsilama => 'Das Team kommt angerannt, um dich zu sehen!';
}
