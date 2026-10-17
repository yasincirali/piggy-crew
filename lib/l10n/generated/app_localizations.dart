import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('tr'),
  ];

  /// No description provided for @uygulamaAdi.
  ///
  /// In tr, this message translates to:
  /// **'Harçlıklarım'**
  String get uygulamaAdi;

  /// No description provided for @karakterAltin.
  ///
  /// In tr, this message translates to:
  /// **'Tortu'**
  String get karakterAltin;

  /// No description provided for @karakterDolar.
  ///
  /// In tr, this message translates to:
  /// **'Zıpzıp'**
  String get karakterDolar;

  /// No description provided for @karakterEuro.
  ///
  /// In tr, this message translates to:
  /// **'Baykuş'**
  String get karakterEuro;

  /// No description provided for @karakterNakit.
  ///
  /// In tr, this message translates to:
  /// **'Sincap'**
  String get karakterNakit;

  /// No description provided for @varlikAltin.
  ///
  /// In tr, this message translates to:
  /// **'Altın'**
  String get varlikAltin;

  /// No description provided for @varlikDolar.
  ///
  /// In tr, this message translates to:
  /// **'Dolar'**
  String get varlikDolar;

  /// No description provided for @varlikEuro.
  ///
  /// In tr, this message translates to:
  /// **'Euro'**
  String get varlikEuro;

  /// No description provided for @varlikNakit.
  ///
  /// In tr, this message translates to:
  /// **'Nakit'**
  String get varlikNakit;

  /// No description provided for @birimGram.
  ///
  /// In tr, this message translates to:
  /// **'g'**
  String get birimGram;

  /// No description provided for @huyAltin.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş yürürüm ama kabuğum sağlamdır. Zor günlerde ben dayanırım.'**
  String get huyAltin;

  /// No description provided for @huyDolar.
  ///
  /// In tr, this message translates to:
  /// **'Zıplarım! Bazen yukarı, bazen aşağı. Sabırlı olan kazanır.'**
  String get huyDolar;

  /// No description provided for @huyEuro.
  ///
  /// In tr, this message translates to:
  /// **'Sakin bakarım. Uzaktaki ülkelerin parası bende saklı.'**
  String get huyEuro;

  /// No description provided for @huyNakit.
  ///
  /// In tr, this message translates to:
  /// **'Ne verirsen onu saklarım. Ama fiyatlar artarsa aldığım şey azalır.'**
  String get huyNakit;

  /// No description provided for @karsilamaBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Kumbara Takımı seni bekliyor'**
  String get karsilamaBaslik;

  /// No description provided for @karsilamaAlt.
  ///
  /// In tr, this message translates to:
  /// **'Birikimlerin dört sevimli karakterde yaşar. Onları besle, kamp ateşin büyüsün.'**
  String get karsilamaAlt;

  /// No description provided for @karsilamaBasla.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get karsilamaBasla;

  /// No description provided for @adSoru.
  ///
  /// In tr, this message translates to:
  /// **'Sana ne diyelim?'**
  String get adSoru;

  /// No description provided for @adIpucu.
  ///
  /// In tr, this message translates to:
  /// **'Adın ya da takma adın'**
  String get adIpucu;

  /// No description provided for @yasSoru.
  ///
  /// In tr, this message translates to:
  /// **'Kaç yaşındasın?'**
  String get yasSoru;

  /// No description provided for @yasKucuk.
  ///
  /// In tr, this message translates to:
  /// **'7–10'**
  String get yasKucuk;

  /// No description provided for @yasBuyuk.
  ///
  /// In tr, this message translates to:
  /// **'11–15'**
  String get yasBuyuk;

  /// No description provided for @paraSoru.
  ///
  /// In tr, this message translates to:
  /// **'Paran hangisi?'**
  String get paraSoru;

  /// No description provided for @dunyaSoru.
  ///
  /// In tr, this message translates to:
  /// **'Kampını nereye kuralım?'**
  String get dunyaSoru;

  /// No description provided for @dunyaAlt.
  ///
  /// In tr, this message translates to:
  /// **'İstediğin zaman değiştirebilirsin.'**
  String get dunyaAlt;

  /// No description provided for @devam.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get devam;

  /// No description provided for @geri.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get geri;

  /// No description provided for @veliBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Anne baba köşesi'**
  String get veliBaslik;

  /// No description provided for @veliAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Bu 4 haneli PIN gerçek fiyatı düzeltmek, veriyi silmek ve ayarlar için. Çocuk ekranlarında reklam, bildirim ve satın alma yoktur.'**
  String get veliAciklama;

  /// No description provided for @veliPinIpucu.
  ///
  /// In tr, this message translates to:
  /// **'4 haneli PIN'**
  String get veliPinIpucu;

  /// No description provided for @veliPinTekrar.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'i tekrar yaz'**
  String get veliPinTekrar;

  /// No description provided for @veliPinUyusmaz.
  ///
  /// In tr, this message translates to:
  /// **'İki PIN aynı değil'**
  String get veliPinUyusmaz;

  /// No description provided for @veliPinSonra.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get veliPinSonra;

  /// No description provided for @hazir.
  ///
  /// In tr, this message translates to:
  /// **'Hazırım!'**
  String get hazir;

  /// No description provided for @sekmeKamp.
  ///
  /// In tr, this message translates to:
  /// **'Kamp'**
  String get sekmeKamp;

  /// No description provided for @sekmeOgren.
  ///
  /// In tr, this message translates to:
  /// **'Öğren'**
  String get sekmeOgren;

  /// No description provided for @sekmeCikartma.
  ///
  /// In tr, this message translates to:
  /// **'Çıkartmalar'**
  String get sekmeCikartma;

  /// No description provided for @sekmeAyarlar.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get sekmeAyarlar;

  /// No description provided for @kampSelam.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {ad}'**
  String kampSelam(String ad);

  /// No description provided for @kampAtesim.
  ///
  /// In tr, this message translates to:
  /// **'Kamp ateşim'**
  String get kampAtesim;

  /// No description provided for @kampBos.
  ///
  /// In tr, this message translates to:
  /// **'Kamp ateşin henüz yanmadı. Bir karaktere dokun ve besle.'**
  String get kampBos;

  /// No description provided for @kampFiyatYok.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alınamadı, değer gösterilemiyor.'**
  String get kampFiyatYok;

  /// No description provided for @kampFiyatEski.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatlar {zaman} itibarıyla'**
  String kampFiyatEski(String zaman);

  /// No description provided for @fark.
  ///
  /// In tr, this message translates to:
  /// **'Fark'**
  String get fark;

  /// No description provided for @farkMutlu.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} gülüyor: {fark}'**
  String farkMutlu(String karakter, String fark);

  /// No description provided for @farkUzgun.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} bulutların altında: {fark}'**
  String farkUzgun(String karakter, String fark);

  /// No description provided for @farkDuz.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} sakin: değişim yok'**
  String farkDuz(String karakter);

  /// No description provided for @besle.
  ///
  /// In tr, this message translates to:
  /// **'Besle'**
  String get besle;

  /// Besle sayfası başlığı. tur: altin/dolar/euro/nakit (Türkçe belirtme hâli eki karaktere göre: Tortu'yu, Zıpzıp'ı, Baykuş'u, Sincap'ı).
  ///
  /// In tr, this message translates to:
  /// **'{tur, select, altin{{karakter}\'yu besle} euro{{karakter}\'u besle} other{{karakter}\'ı besle}}'**
  String besleBaslik(String karakter, String tur);

  /// No description provided for @besleTutar.
  ///
  /// In tr, this message translates to:
  /// **'Ne kadar?'**
  String get besleTutar;

  /// No description provided for @besleBugunFiyat.
  ///
  /// In tr, this message translates to:
  /// **'Bugün 1 {birim} = {fiyat}'**
  String besleBugunFiyat(String birim, String fiyat);

  /// No description provided for @besleAlir.
  ///
  /// In tr, this message translates to:
  /// **'{tutar} ile {miktar} alırsın'**
  String besleAlir(String tutar, String miktar);

  /// No description provided for @besleVer.
  ///
  /// In tr, this message translates to:
  /// **'{karakter, select, Tortu{Tortu\'ya ver} other{{karakter}\'a ver}}'**
  String besleVer(String karakter);

  /// No description provided for @besleFiyatYok.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün fiyatı alınamadı. İnternete bağlanınca tekrar dene.'**
  String get besleFiyatYok;

  /// No description provided for @besleGecersiz.
  ///
  /// In tr, this message translates to:
  /// **'Bir tutar yaz'**
  String get besleGecersiz;

  /// No description provided for @besleDoydu.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} doydu!'**
  String besleDoydu(String karakter);

  /// No description provided for @cikartmaAcildi.
  ///
  /// In tr, this message translates to:
  /// **'Yeni çıkartma: {ad}'**
  String cikartmaAcildi(String ad);

  /// No description provided for @detayVerdin.
  ///
  /// In tr, this message translates to:
  /// **'Verdin'**
  String get detayVerdin;

  /// No description provided for @detayBugun.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get detayBugun;

  /// No description provided for @detayMiktar.
  ///
  /// In tr, this message translates to:
  /// **'Elinde {miktar}'**
  String detayMiktar(String miktar);

  /// No description provided for @detayBos.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} henüz hiç beslenmedi.'**
  String detayBos(String karakter);

  /// No description provided for @detayNedenBaslik.
  ///
  /// In tr, this message translates to:
  /// **'{karakter} anlatıyor'**
  String detayNedenBaslik(String karakter);

  /// No description provided for @detayNedenMutlu.
  ///
  /// In tr, this message translates to:
  /// **'Aldığın günden beri {varlik} değerlendi. Aynı miktar şimdi daha çok para ediyor: {fark}.'**
  String detayNedenMutlu(String varlik, String fark);

  /// No description provided for @detayNedenUzgun.
  ///
  /// In tr, this message translates to:
  /// **'Aldığın günden beri {varlik} biraz ucuzladı. Bu senin hatan değil; fiyatlar hava gibi değişir. Miktarın aynı duruyor, bugünkü değeri biraz az: {fark}. Bulutlar gelir, geçer.'**
  String detayNedenUzgun(String varlik, String fark);

  /// No description provided for @detayNedenNakit.
  ///
  /// In tr, this message translates to:
  /// **'Nakit hep aynı sayıyı gösterir. Ama fiyatlar artarsa aynı para daha az şey alır; buna enflasyon denir.'**
  String get detayNedenNakit;

  /// No description provided for @detayBeslemeler.
  ///
  /// In tr, this message translates to:
  /// **'Beslemelerin'**
  String get detayBeslemeler;

  /// No description provided for @detayBirazDaha.
  ///
  /// In tr, this message translates to:
  /// **'Biraz daha besle'**
  String get detayBirazDaha;

  /// No description provided for @detaySil.
  ///
  /// In tr, this message translates to:
  /// **'Bu beslemeyi sil'**
  String get detaySil;

  /// No description provided for @detaySilOnay.
  ///
  /// In tr, this message translates to:
  /// **'Bu besleme silinsin mi?'**
  String get detaySilOnay;

  /// No description provided for @iptal.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get iptal;

  /// No description provided for @sil.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get sil;

  /// No description provided for @ogrenBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün kavramı'**
  String get ogrenBaslik;

  /// No description provided for @ogrenSayac.
  ///
  /// In tr, this message translates to:
  /// **'{n} / {toplam}'**
  String ogrenSayac(int n, int toplam);

  /// No description provided for @ogrenSoru.
  ///
  /// In tr, this message translates to:
  /// **'Soru'**
  String get ogrenSoru;

  /// No description provided for @ogrenDogru.
  ///
  /// In tr, this message translates to:
  /// **'Doğru! {karakter} seninle gurur duyuyor.'**
  String ogrenDogru(String karakter);

  /// No description provided for @ogrenYanlis.
  ///
  /// In tr, this message translates to:
  /// **'Bir daha düşün. İpucu metinde gizli.'**
  String get ogrenYanlis;

  /// No description provided for @ogrenSonraki.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ders'**
  String get ogrenSonraki;

  /// No description provided for @ogrenBitti.
  ///
  /// In tr, this message translates to:
  /// **'Bütün dersleri bitirdin. Yenileri yolda.'**
  String get ogrenBitti;

  /// No description provided for @ogrenBastan.
  ///
  /// In tr, this message translates to:
  /// **'Baştan oku'**
  String get ogrenBastan;

  /// No description provided for @cikartmaBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Çıkartmalarım'**
  String get cikartmaBaslik;

  /// No description provided for @cikartmaAlt.
  ///
  /// In tr, this message translates to:
  /// **'Davranışın için verilir, şans için değil.'**
  String get cikartmaAlt;

  /// No description provided for @cikartmaKilitli.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get cikartmaKilitli;

  /// No description provided for @cikartmaSayac.
  ///
  /// In tr, this message translates to:
  /// **'{n} / {toplam} açıldı'**
  String cikartmaSayac(int n, int toplam);

  /// No description provided for @ayarlarBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get ayarlarBaslik;

  /// No description provided for @ayarlarDunya.
  ///
  /// In tr, this message translates to:
  /// **'Kamp yeri'**
  String get ayarlarDunya;

  /// No description provided for @ayarlarYas.
  ///
  /// In tr, this message translates to:
  /// **'Yaş modu'**
  String get ayarlarYas;

  /// No description provided for @ayarlarPara.
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get ayarlarPara;

  /// No description provided for @ayarlarSes.
  ///
  /// In tr, this message translates to:
  /// **'Sesler'**
  String get ayarlarSes;

  /// No description provided for @sesAcik.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get sesAcik;

  /// No description provided for @sesKapali.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get sesKapali;

  /// Ayarlar: titreşim (dokunsal geri bildirim) bölüm başlığı; seçenekler sesAcik/sesKapali
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get ayarlarTitresim;

  /// No description provided for @ayarlarDil.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get ayarlarDil;

  /// No description provided for @ayarlarVeli.
  ///
  /// In tr, this message translates to:
  /// **'Anne baba köşesi'**
  String get ayarlarVeli;

  /// No description provided for @ayarlarSurum.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {s}'**
  String ayarlarSurum(String s);

  /// No description provided for @ayarlarKaynak.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatlar kamuya açık piyasa verisi sağlayıcılarından alınır, yatırım tavsiyesi değildir.'**
  String get ayarlarKaynak;

  /// No description provided for @dilCihaz.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz dili'**
  String get dilCihaz;

  /// No description provided for @kilitBaslik.
  ///
  /// In tr, this message translates to:
  /// **'PIN gir'**
  String get kilitBaslik;

  /// No description provided for @kilitYanlis.
  ///
  /// In tr, this message translates to:
  /// **'PIN yanlış'**
  String get kilitYanlis;

  /// No description provided for @kilitKur.
  ///
  /// In tr, this message translates to:
  /// **'PIN oluştur'**
  String get kilitKur;

  /// No description provided for @veliSil.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriyi sil'**
  String get veliSil;

  /// No description provided for @veliSilOnay.
  ///
  /// In tr, this message translates to:
  /// **'Profil, beslemeler ve çıkartmalar silinir. Geri alınamaz.'**
  String get veliSilOnay;

  /// No description provided for @veliSilOnayDugme.
  ///
  /// In tr, this message translates to:
  /// **'Evet, sil'**
  String get veliSilOnayDugme;

  /// No description provided for @veliPinDegistir.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'i değiştir'**
  String get veliPinDegistir;

  /// No description provided for @veliOzet.
  ///
  /// In tr, this message translates to:
  /// **'{ad} toplam {n} kez besledi. Kamp ateşi: {toplam}.'**
  String veliOzet(String ad, int n, String toplam);

  /// No description provided for @veliNot.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk ekranlarında bildirim, reklam ve satın alma yoktur. Veri yalnız bu cihazda durur.'**
  String get veliNot;

  /// No description provided for @dunyaBahce.
  ///
  /// In tr, this message translates to:
  /// **'Bahçe'**
  String get dunyaBahce;

  /// No description provided for @dunyaUzay.
  ///
  /// In tr, this message translates to:
  /// **'Uzay'**
  String get dunyaUzay;

  /// No description provided for @dunyaOkyanus.
  ///
  /// In tr, this message translates to:
  /// **'Okyanus'**
  String get dunyaOkyanus;

  /// No description provided for @dunyaNeon.
  ///
  /// In tr, this message translates to:
  /// **'Neon'**
  String get dunyaNeon;

  /// No description provided for @dunyaSeker.
  ///
  /// In tr, this message translates to:
  /// **'Şeker'**
  String get dunyaSeker;

  /// No description provided for @dunyaSafari.
  ///
  /// In tr, this message translates to:
  /// **'Safari'**
  String get dunyaSafari;

  /// No description provided for @ckIlkbeslemeAd.
  ///
  /// In tr, this message translates to:
  /// **'İlk kıvılcım'**
  String get ckIlkbeslemeAd;

  /// No description provided for @ckIlkbeslemeAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Kamp ateşini ilk kez yaktın.'**
  String get ckIlkbeslemeAciklama;

  /// No description provided for @ckTortusapkaAd.
  ///
  /// In tr, this message translates to:
  /// **'Tortu\'nun şapkası'**
  String get ckTortusapkaAd;

  /// No description provided for @ckTortusapkaAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Tortu\'yu üç kez besledin.'**
  String get ckTortusapkaAciklama;

  /// No description provided for @ckZipzipatkiAd.
  ///
  /// In tr, this message translates to:
  /// **'Zıpzıp\'ın atkısı'**
  String get ckZipzipatkiAd;

  /// No description provided for @ckZipzipatkiAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Zıpzıp\'ı üç kez besledin.'**
  String get ckZipzipatkiAciklama;

  /// No description provided for @ckBaykusgozlukAd.
  ///
  /// In tr, this message translates to:
  /// **'Baykuş\'un gözlüğü'**
  String get ckBaykusgozlukAd;

  /// No description provided for @ckBaykusgozlukAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Baykuş\'u üç kez besledin.'**
  String get ckBaykusgozlukAciklama;

  /// No description provided for @ckSincapfularAd.
  ///
  /// In tr, this message translates to:
  /// **'Sincap\'ın fuları'**
  String get ckSincapfularAd;

  /// No description provided for @ckSincapfularAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Sincap\'ı üç kez besledin.'**
  String get ckSincapfularAciklama;

  /// No description provided for @ckTakimtamAd.
  ///
  /// In tr, this message translates to:
  /// **'Takım tamam'**
  String get ckTakimtamAd;

  /// No description provided for @ckTakimtamAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Bütün karakterleri besledin.'**
  String get ckTakimtamAciklama;

  /// No description provided for @ckAtes1000Ad.
  ///
  /// In tr, this message translates to:
  /// **'Büyük ateş'**
  String get ckAtes1000Ad;

  /// No description provided for @ckAtes1000Aciklama.
  ///
  /// In tr, this message translates to:
  /// **'Takımı dört ayrı haftada besledin.'**
  String get ckAtes1000Aciklama;

  /// No description provided for @ckAtes5000Ad.
  ///
  /// In tr, this message translates to:
  /// **'Şenlik ateşi'**
  String get ckAtes5000Ad;

  /// No description provided for @ckAtes5000Aciklama.
  ///
  /// In tr, this message translates to:
  /// **'Takımı on iki ayrı haftada besledin.'**
  String get ckAtes5000Aciklama;

  /// No description provided for @ckDers5Ad.
  ///
  /// In tr, this message translates to:
  /// **'Meraklı'**
  String get ckDers5Ad;

  /// No description provided for @ckDers5Aciklama.
  ///
  /// In tr, this message translates to:
  /// **'Beş dersi bitirdin.'**
  String get ckDers5Aciklama;

  /// No description provided for @ckDers10Ad.
  ///
  /// In tr, this message translates to:
  /// **'Bilge'**
  String get ckDers10Ad;

  /// No description provided for @ckDers10Aciklama.
  ///
  /// In tr, this message translates to:
  /// **'On dersi bitirdin.'**
  String get ckDers10Aciklama;

  /// No description provided for @ckSabir30Ad.
  ///
  /// In tr, this message translates to:
  /// **'Sabırlı'**
  String get ckSabir30Ad;

  /// No description provided for @ckSabir30Aciklama.
  ///
  /// In tr, this message translates to:
  /// **'İlk beslemenden 30 gün geçti ve hâlâ buradasın.'**
  String get ckSabir30Aciklama;

  /// No description provided for @ckTortuparlakAd.
  ///
  /// In tr, this message translates to:
  /// **'Parlayan Tortu'**
  String get ckTortuparlakAd;

  /// No description provided for @ckTortuparlakAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Tortu\'yu beş ayrı haftada besledin.'**
  String get ckTortuparlakAciklama;

  /// Birkaç gün sonra açılışta takım koşarak gelince görünen kısa mesaj. Yokluk süresini anmaz, bir şey istemez.
  ///
  /// In tr, this message translates to:
  /// **'Takım seni görünce koşa koşa geldi!'**
  String get donusKarsilama;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
