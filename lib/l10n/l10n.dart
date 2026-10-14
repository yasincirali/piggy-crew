import 'package:flutter/widgets.dart';

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
