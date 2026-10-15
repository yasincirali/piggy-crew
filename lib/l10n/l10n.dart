import 'package:flutter/widgets.dart';

import '../models/cikartma.dart';
import '../models/varlik.dart';
import '../theme/dunya.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.anahtar` — sandık ile aynı erişim biçimi.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Karakter/varlık adları yerelleşir (global uygulama): enum ad taşımaz.
extension VarlikAdlari on AppLocalizations {
  String karakter(VarlikTuru t) => switch (t) {
        VarlikTuru.altin => karakterAltin,
        VarlikTuru.dolar => karakterDolar,
        VarlikTuru.euro => karakterEuro,
        VarlikTuru.nakit => karakterNakit,
      };

  String varlik(VarlikTuru t) => switch (t) {
        VarlikTuru.altin => varlikAltin,
        VarlikTuru.dolar => varlikDolar,
        VarlikTuru.euro => varlikEuro,
        VarlikTuru.nakit => varlikNakit,
      };

  String huy(VarlikTuru t) => switch (t) {
        VarlikTuru.altin => huyAltin,
        VarlikTuru.dolar => huyDolar,
        VarlikTuru.euro => huyEuro,
        VarlikTuru.nakit => huyNakit,
      };

  /// Miktar birimi: altın gram, döviz kendi sembolü, nakit ev birimi sembolü.
  String birim(VarlikTuru t, ParaBirimi ev) => switch (t) {
        VarlikTuru.altin => birimGram,
        VarlikTuru.dolar => ParaBirimi.usd.sembol,
        VarlikTuru.euro => ParaBirimi.eur.sembol,
        VarlikTuru.nakit => ev.sembol,
      };

  String dunya(Dunya d) => switch (d) {
        Dunya.bahce => dunyaBahce,
        Dunya.uzay => dunyaUzay,
        Dunya.okyanus => dunyaOkyanus,
        Dunya.neon => dunyaNeon,
        Dunya.seker => dunyaSeker,
        Dunya.safari => dunyaSafari,
      };
}

extension CikartmaAdlari on AppLocalizations {
  String cikartmaAd(Cikartma c) => switch (c.id) {
        'ilk_besleme' => ckIlkbeslemeAd,
        'tortu_sapka' => ckTortusapkaAd,
        'zipzip_atki' => ckZipzipatkiAd,
        'baykus_gozluk' => ckBaykusgozlukAd,
        'sincap_fular' => ckSincapfularAd,
        'takim_tam' => ckTakimtamAd,
        'ates_1000' => ckAtes1000Ad,
        'ates_5000' => ckAtes5000Ad,
        'ders_5' => ckDers5Ad,
        'ders_10' => ckDers10Ad,
        'sabir_30' => ckSabir30Ad,
        'tortu_parlak' => ckTortuparlakAd,
        _ => c.id,
      };

  String cikartmaAciklama(Cikartma c) => switch (c.id) {
        'ilk_besleme' => ckIlkbeslemeAciklama,
        'tortu_sapka' => ckTortusapkaAciklama,
        'zipzip_atki' => ckZipzipatkiAciklama,
        'baykus_gozluk' => ckBaykusgozlukAciklama,
        'sincap_fular' => ckSincapfularAciklama,
        'takim_tam' => ckTakimtamAciklama,
        'ates_1000' => ckAtes1000Aciklama,
        'ates_5000' => ckAtes5000Aciklama,
        'ders_5' => ckDers5Aciklama,
        'ders_10' => ckDers10Aciklama,
        'sabir_30' => ckSabir30Aciklama,
        'tortu_parlak' => ckTortuparlakAciklama,
        _ => '',
      };
}

/// Cihaz dilini desteklenen dile eşler: dil kodu tutuyorsa o, değilse
/// İngilizce (global varsayılan). Bölge (pt_BR, es_MX) dil koduna iner.
Locale dilCoz(Locale? cihaz, Iterable<Locale> destek) {
  if (cihaz != null) {
    for (final d in destek) {
      if (d.languageCode == cihaz.languageCode) return d;
    }
  }
  return const Locale('en');
}

/// Dil seçicide her dil kendi adıyla yazılır (endonym): çocuk kendi dilini
/// tanısın, arayüz dili ne olursa olsun.
const dilAdlari = <String, String>{
  'tr': 'Türkçe',
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
};
